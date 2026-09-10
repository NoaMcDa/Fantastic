# M1 Handoff — the layer is complete, M2 is unblocked

State of M1 as of 2026-09-10, after the data layer landed. Read
`design/m1_preflight.md` first if you are picking up any M1 issue — it explains
the corrections the issue text needed and why the design docs now read as they
do.

## Status — M1 is code-complete, pending merge

**Every M1 issue is implemented.** The domain layer is on `main`; the data layer
is in eight open PRs (#168–#175), each green: `flutter analyze` zero issues,
`dart format --check` zero diffs, and **271 tests** at the tip of the chain, up
from 133 when the domain layer merged and 30 at the end of M0.

| Group | Issues | State |
|---|---|---|
| Domain models | #25, #26, #27, #28, #30 | ✅ merged (PR #161) |
| Repository & service interfaces, fixtures | #29, #31, #32, #33, #34, #152 | ✅ merged (PR #163) |
| First schema — turns persistence on | #35 | ✅ merged (PR #167) |
| Remaining schemas + mappers | #36, #37, #38 | 🔵 PRs #168, #169, #170 |
| Repository implementations + contract suites | #39, #40, #41, #42 | 🔵 PRs #171, #172, #173, #174 |
| Provider wiring | #43 | 🔵 PR #175 |

**These eight PRs must be merged in issue order** — `#36 → #37 → #38 → #39 →
#40 → #41 → #42 → #43`. Every one targets `main`, but #36/#37/#38 each append a
line to the same `appIsarSchemas` list, so merging out of order conflicts there.
Each PR body restates this.

The branches are chained (each cut from the previous), which is *not* the M0
stacked-PR mistake — there, each PR's **base** was its parent branch, so merging
never reached `main` and needed consolidation PR #145. Here the base is always
`main`; once #36 merges, #37's diff collapses to its own changes, and so on.

**M2 is unblocked once these land.** M2's services (#45 `MealLoggingService`,
#47/#48 the providers) depend on the repository *implementations* and on #43's
provider wiring, not merely on the interfaces.

Epic **#5** (M1) closes with these merges. Epic **#4** (M0) remains open on the
`flutter run` simulator check alone.

### What the data layer added

| Area | Files |
|---|---|
| Schemas | `lib/features/{diary,dashboard,adaptation}/data/schemas/isar_*.dart` — four `@collection` classes |
| Mappers | `.../data/mappers/*_mapper.dart` — four, each `abstract final` with `toIsar` / `toDomain` |
| Repositories | `.../data/repositories/isar_*_repository.dart` — four |
| Provider wiring | `lib/features/{diary,dashboard,adaptation}/data/providers.dart` |
| Contract suites | `test/features/*/data/*_repository_contract_test.dart` — 78 cases across four files |
| Mapper tests | `test/features/*/data/mappers/` |
| Provider smoke tests | `test/features/*/data/providers_test.dart` — 10 cases |

`appIsarSchemas` in `lib/core/database/isar_provider.dart` now registers all
four collections, and `main.dart` opens Isar at startup. **The app has a real
local database.**

---

## Conventions every later issue inherits

These are not restated in each issue body.

1. **Domain files live under `domain/models/`**, interfaces under
   `domain/repositories/`, the keto_lens contracts under `domain/services/`.
2. **Ids are `int?`, never Isar's `Id`.** `Id` is a typedef from
   `package:isar_community`, which the domain layer must not import. The data
   layer converts. This was the single most repeated correction in the audit.
3. **Value equality is hand-written**, comparing every field, with `Object.hash`
   for `hashCode`. No `equatable` dependency.
4. **`List` fields compare element-wise** via `listEquals` / `listHash` from
   `lib/core/utils/list_equality.dart`.
5. **Test dates are fixed constants**, never `DateTime.now()`.
6. **Mappers are `abstract final class`** with static methods — matching
   `AppTheme`, `KetoConstants` and the fixtures. Not a class with a private
   constructor, which several issue snippets show.
7. **`dateIndex` is public on every mapper.** It encodes
   `year * 10000 + month * 100 + day`, and the repositories call it to build
   their queries — they must use the same encoding the schema was written with.
8. **Contract suites are top-level factory-parameterised functions**
   (`runXxxRepositoryContractTests(XxxRepository Function() factory)`), so any
   future implementation runs against the same cases. That is what enforces
   Liskov at the test level, and it is required for every repository.
9. **Providers return the domain interface, never the concrete class.** A
   consumer then cannot reach past the abstraction to an Isar-specific method —
   the layer rule as a compile error rather than a review comment.

### `StreakState.copyWith` takes explicit clear flags

`clearGracePeriodEnd` and `clearLastCompliantDate`. A plain
`value ?? this.value` cannot express "set this back to null", which is exactly
what `AdaptationPhaseService` (#57) needs when a grace period ends or a streak
resets.

---

## Data-layer decisions worth knowing before M2

**A unique index changes how you write.** `IsarDailyLog` and `IsarSymptomLog`
both carry `@Index(unique: true)` on `dateIndex`, so a plain `put` violates the
index and *throws* rather than replacing. The generator emits typed by-index
accessors for exactly this — `putByDateIndex`, `getByDateIndex`,
`deleteByDateIndex` — and both repositories use them. (#40's issue text
specifies the stringly-typed `putByIndex('dateIndex', schema)` and asserts
"Isar offers no delete-by-index shorthand"; it does.)

**`put` and `putByDateIndex` both write the assigned id back into the schema
object in place.** That is what lets `save` return a domain object carrying its
new id without a re-read.

**`StreakState` is a singleton pinned to row 0.** `StreakStateMapper.toIsar`
forces `id = singletonId`, so duplicates are structurally impossible rather than
prevented by convention. `IsarStreakRepository` reads that same constant instead
of declaring its own `0`, so the id written and the id read cannot drift.

**`AdaptationPhase` is stored as an ordinal** via the mirror enum
`AdaptationPhaseIsar`. Both enums are **append-only** — inserting or reordering
a value silently reinterprets every stored record. Two parity tests in
`streak_state_mapper_test.dart` fail loudly if they drift; do not delete them.

**`watch()` needs `fireImmediately: true`.** `IsarStreakRepository.watch` is the
only stream in the layer, and `streakStateProvider` (#59) subscribes to it
expecting a value straight away. Without the flag a subscriber sees nothing
until the first write.

---

## Known gap: the typed exceptions do not exist

`design/base_design.md` §Error Handling Contract specifies
`RepositoryException`, `EntityNotFoundException` and `PersistenceException`, and
**all four repository interface doc comments** say their methods "throw typed
domain exceptions on failure".

**No such type exists in `lib/`, and no M1 issue owns creating one.**

This was deliberate, not an oversight. Nothing in #39–#42's specified behaviour
needs them — `delete` and `deleteByDate` are idempotent, `findById` and
`findByDate` return null for absent, `load` returns null on first launch, and no
contract test asserts an exception type. Building them would have exceeded every
issue's Definition of Done.

**Whoever first needs typed failures should file an issue for it** — most likely
M2's services, when they need to distinguish "the day has no log" from "the read
failed". The doc comments are already written as though the types exist, so the
work is to create them and make the repositories throw, not to redesign the
contract.

---

## Gotchas found while implementing

**`const` canonicalisation silently defeats list-equality tests.** Two tests
assert that equal-but-not-identical lists compare equal. Written as `const`
literals, Dart canonicalises both into one object, `identical` returns true, and
the test passes for the wrong reason. `prefer_const_constructors` flags the
runtime-local form as a lint — the locals are commented so nobody "fixes" it.

**An all-neutral fixture hides cross-wiring.** `SymptomLogFixture.fixture()`
defaults every one of its five scales to 3, so a mapper or repository that
assigned the wrong field to the wrong scale would pass every round-trip
assertion. Both the symptom mapper test and its contract suite therefore include
a case with five *distinct* values (1/2/3/4/5). Any future model with several
same-typed fields needs the same treatment.

**Assert round-trips against `copyWith(id: saved.id)`, not field-by-field.** A
field-by-field assertion silently stops covering any field added later; the
whole-object comparison keeps covering it for free.

**`flutter test --coverage` emits no `LF:`/`LH:` summary lines** in this
project's `lcov.info` — only `DA:<line>,<hits>` records. An `LF`-based script
reports a misleading `0/0 = 100%` for every file. Count the `DA:` lines:

```bash
awk '/^SF:/{f=substr($0,4); tot=0; hit=0} /^DA:/{split(substr($0,4),a,","); tot++; if (a[2]+0>0) hit++} /^end_of_record/{if (tot) printf "%-58s %3d/%3d\n", f, hit, tot}' coverage/lcov.info
```

---

## The `build_runner` hang — it works, it just never exits

**Code generation is not broken.** All builders finish in about **one second**.
What they do not do is **terminate** — after the build completes the process
sits in `futex_do_wait` indefinitely, ~1.6s of CPU consumed in total and zero
sockets open, so it is not waiting on the network.

That is why it looks broken. `dart run build_runner build | tail -8` prints
*nothing at all*: `tail` cannot emit until the pipe closes, and the pipe never
closes. Combined with ~0.1% CPU, it reads as "hung" when it is "finished and
idling".

**Run it like this:**

```bash
timeout 120 dart run build_runner build --verbose
# exit code 124 means the timeout fired — expected, NOT a failure
git status --short          # confirm the .g.dart files are what you expect
flutter analyze && flutter test
```

`--verbose` is not optional: without it the progress output is buffered and a
redirected run produces an empty log.

### A newly added builder will not run until you clear the cache

Separate from the non-exit above, and it cost real time on #35. Generation for
the first `@collection` produced **nothing** — only `riverpod_generator` ran, no
`.g.dart` appeared, and no error was printed.

`build_runner` compiles an entrypoint containing the builders it knows about and
caches it under `.dart_tool/build/`. `isar_community_generator` was added to
`dev_dependencies` during M0, by which point that entrypoint had already been
cached without it. Because no `@collection` existed until #35, the missing
builder was invisible for all of M0 and M1.

**If a generator silently does nothing, clear the cache first:**

```bash
rm -rf .dart_tool/build
timeout 280 dart run build_runner build --verbose
```

Expect the first run afterwards to take minutes. Subsequent runs are ~1 second.

Two related notes:

- **`--delete-conflicting-outputs` no longer exists.** build_runner 2.15.1
  prints `W These options have been removed and were ignored`. `CLAUDE.md`'s
  Common Commands, `developing_rules.md`, and the Definition of Done on
  #35–#38 and #43 all still pass it. Harmless, but it is a dead flag.
- **Watch for orphaned builder processes.** A background run holds the build
  lock and silently blocks every later invocation:
  ```bash
  ps -eo pid,etime,pcpu,cmd | grep -E 'build_runner|build\.dart\.aot' | grep -v grep
  ```

## Known blockers

**`flutter run` on an iOS simulator has never been verified.** No macOS host is
available in this environment. This matters more now than it did: the app opens
a real database at startup, and #154 fixed a crash-before-`runApp` in exactly
that path. It is why **Epic #4 is still open** — every other item on its
checklist is green.

This remains the only thing in M1's or M2's path that cannot be done from a
Linux container.

---

## Environment notes

- **Isar Core loads offline.** `test/helpers/test_isar.dart` resolves the native
  binary from the installed `isar_community_flutter_libs` package via
  `.dart_tool/package_config.json`. It no longer downloads from
  `binaries.isar-community.dev`, which is blocked here (#147).
  `Isolate.resolvePackageUri` is unsupported in the `flutter_tester` runtime —
  that is why the package config is read directly.
- **`openTestIsar` requires a non-empty schema list.** Isar rejects an instance
  with zero collections; `openTestIsar()` with no argument does not compile.
  Pass only the schemas a test needs.
- **`appIsarSchemas`** in `lib/core/database/isar_provider.dart` is the single
  registration point for collections, and now holds all four. Every new
  `@collection` must be appended there **and** given a registration assertion in
  `test/core/database/isar_provider_test.dart`.
- **`pubspec.lock` is tracked** (#159) — `.gitignore`'s blanket `*.lock` had
  been matching it. Do not regenerate it casually.
- **`meta` is a direct dependency** (#156), needed for `@immutable` in the
  domain layer.

---

## Loose ends

- **Epic #4 (M0) is still open**, pending the `flutter run` check above.
- **The typed-exception gap** described above — unowned, and M2 is the likely
  first caller to need it.
- **`pr_conventions.md` §1 deviations.** Four earlier PRs (#145, #155, #160,
  #161) carried several issues each on one pinned branch. The eight data-layer
  PRs restore one-PR-per-issue, so the convention now matches practice again —
  but the earlier question stands: should milestone-scoped PRs be explicitly
  allowed, or the branch constraint changed?
- **#149, #150, #151** are filed and parked in M4, M8 and M7. #150
  (`integration_test` dependency) gates all seven M8 flow tests.

---

## Next: M2 (#44–#56)

**Read `design/m2_preflight.md` first.** A spot audit of M2's application layer
found the same class of defects M1 had — riverpod-2 `Ref` types, relative
imports — plus one specific to M2: the `DailyLog` move to the dashboard feature
(#157) was never propagated, so #45 and #47 still import it from `diary/`. #45
also calls a `DailyLog.empty(date)` factory that does not exist.

Tracked by **#165**. #44 (`KetoRatioCalculator`) is clean, pure arithmetic, and
the right place to start.

The repository methods M2 must code against are listed in
`design/m2_preflight.md` §8 — several M2 issues assume methods that do not
exist. The provider names to inject are `mealRepositoryProvider`,
`symptomLogRepositoryProvider` (diary), `dailyLogRepositoryProvider`
(dashboard), and `streakRepositoryProvider` (adaptation).
