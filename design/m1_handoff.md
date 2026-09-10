# M1 Handoff — domain models shipped, where the rest stands

State of M1 as of 2026-09-10. Read `design/m1_preflight.md` first if you are
picking up any M1 issue — it explains the corrections the issue text needed and
why the design docs now read as they do.

## Status — M1 is half done

**The entire domain layer is merged to `main`.** `main` passes `flutter analyze`
(zero issues), `dart format --check` (zero diffs), and **133 tests**, up from 30
at the end of M0.

| Group | Issues | State |
|---|---|---|
| Domain models | #25, #26, #27, #28, #30 | ✅ merged (PR #161) |
| Repository & service interfaces, fixtures | #29, #31, #32, #33, #34, #152 | ✅ merged (PR #163) |
| **Isar schemas, repositories, providers** | **#35–#43** | ❌ **open — nine issues, no code written** |

There is **no `data/` directory under any feature yet**. The nine open issues
are the whole persistence layer: four schemas with mappers, four repository
implementations with contract suites, and the provider wiring.

They are **not blocked**. An earlier draft of this file said they were gated on
`build_runner`; that was wrong, and the correction is under "The `build_runner`
hang" below — it works, it just never exits.

**M2 cannot start before they land.** M2's services (#45 `MealLoggingService`,
#47/#48 the providers) depend on the repository *implementations* and on #43's
provider wiring, not merely on the interfaces. The one exception is #44
(`KetoRatioCalculator`), which is pure arithmetic and depends on nothing.

Epic **#5** (M1) and Epic **#4** (M0) both remain open. #4's only outstanding
item is the `flutter run` simulator check.

What shipped, and where it lives:

| Area | Files |
|---|---|
| Meal | `lib/features/diary/domain/models/meal_entry.dart` |
| Daily aggregate | `lib/features/dashboard/domain/models/daily_log.dart` |
| Streak | `lib/features/adaptation/domain/models/{streak_state,adaptation_phase}.dart` |
| Symptoms | `lib/features/diary/domain/models/symptom_log.dart` |
| Keto Lens | `lib/features/keto_lens/domain/models/{verdict_badge,parsed_label,ingredient_verdict}.dart` |
| Repository interfaces | `lib/features/{diary,dashboard,adaptation}/domain/repositories/` |
| Service interfaces | `lib/features/keto_lens/domain/services/{label_parser,ingredient_classifier}.dart` |
| Shared | `lib/core/utils/list_equality.dart` |
| Fixtures | `test/fixtures/` — all four filled, barrel exporting, 13 tests |
| Tests | eight files under `test/features/*/domain/models/`, 100% line coverage on the model sources |

The interfaces carry no executable code, so they have no tests of their own —
coverage lands with their implementations in #39–#42.

The methods each interface actually declares are listed in
`design/m2_preflight.md` §8. M2's issues assume some that do not exist.

---

## Conventions these five issues established

Every later M1 issue inherits these. They are not restated in each issue body.

1. **Domain files live under `domain/models/`**, interfaces under
   `domain/repositories/`, and the keto_lens parser/classifier contracts under
   `domain/services/`. `architecture.md`'s trees were updated to match.
2. **Ids are `int?`, never Isar's `Id`.** `Id` is a typedef from
   `package:isar_community`, which the domain layer must not import. The data
   layer converts. This was the single most repeated correction in the audit.
3. **Value equality is hand-written**, comparing every field, with `Object.hash`
   for `hashCode`. No `equatable` dependency.
4. **`List` fields compare element-wise** via `listEquals` / `listHash` from
   `lib/core/utils/list_equality.dart` — see below.
5. **Test dates are fixed constants**, never `DateTime.now()`, so nothing
   flakes. Each test file declares its own `_date` / `_timestamp` at the top.

### `lib/core/utils/list_equality.dart` — a file no issue named

Three models hold a `List<String>` that must compare by value:
`MealEntry.ingredients`, `ParsedLabel.ingredients`,
`IngredientVerdict.flaggedIngredients`. #25's Definition of Done requires it
explicitly ("two entries with equal-but-not-identical lists are `==`").

Dart's `listEquals` lives in `package:flutter/foundation.dart`, which the domain
layer may not import, and `package:collection` is not a declared dependency. Ten
lines in `lib/core/` beat hand-writing the same loop three times or adding a
fourth dependency. **#152's fixtures and any future list-holding model should
reuse it rather than re-implementing.**

### `StreakState.copyWith` takes explicit clear flags

`clearGracePeriodEnd` and `clearLastCompliantDate`. A plain
`value ?? this.value` cannot express "set this back to null", which is exactly
what `AdaptationPhaseService` (#57) needs when a grace period ends or a streak
resets. #27 permitted either a sentinel `Object` or boolean flags; flags won —
more readable, and lint-clean under `avoid_dynamic_calls`.

A clear flag beats a value passed alongside it. Four tests cover this.

---

## Gotchas found while implementing

**`const` canonicalisation silently defeats list-equality tests.** Two tests
assert that equal-but-not-identical lists compare equal. Written as `const`
literals, Dart canonicalises both into a single object, `identical` returns
true, and the test passes for the wrong reason. `prefer_const_constructors`
will flag the runtime-local form as a lint — the locals are commented so nobody
"fixes" it. Same trap applies to any future equality test over a collection.

**`flutter test --coverage` emits no `LF:`/`LH:` summary lines** in this
project's `lcov.info`. Only `DA:<line>,<hits>` records. Computing coverage with
an `LF`-based script reports a misleading `0/0 = 100%` for every file. Count the
`DA:` lines instead:

```bash
awk '/^SF:/{f=substr($0,4); tot=0; hit=0} /^DA:/{split(substr($0,4),a,","); tot++; if (a[2]+0>0) hit++} /^end_of_record/{if (tot) printf "%-58s %3d/%3d\n", f, hit, tot}' coverage/lcov.info
```

---

## The `build_runner` hang — it works, it just never exits

**Code generation is not broken.** Verified by deleting
`lib/core/utils/app_version.g.dart`, re-running the builder, and getting a
byte-identical file back with a clean `git status`. All builders finish in
about **one second**.

What it does not do is **terminate**. After the build completes it sits in
`futex_do_wait` indefinitely — ~1.6s of CPU consumed in total, and **zero
sockets open**, so it is not waiting on the network.

That behaviour is why it looks broken. Running it as
`dart run build_runner build | tail -8` prints *nothing at all*: `tail` cannot
emit until the pipe closes, and the pipe never closes. Combined with a process
showing ~0.1% CPU, it reads as "hung on something" when it is really "finished
and idling".

**Run it like this:**

```bash
timeout 120 dart run build_runner build --verbose
# exit code 124 means the timeout fired — expected, NOT a failure
git status --short          # confirm the .g.dart files are what you expect
flutter analyze && flutter test
```

`--verbose` is not optional here: without it the progress output is buffered
and a redirected run produces an empty log.

### A newly added builder will not run until you clear the cache

Separate from the non-exit above, and it cost real time on #35. Generation for
the first `@collection` produced **nothing** — only `riverpod_generator` ran,
no `.g.dart` appeared, and no error was printed.

`build_runner` compiles an entrypoint containing the set of builders it knows
about, and caches it under `.dart_tool/build/`. `isar_community_generator` was
added to `dev_dependencies` during M0, by which point that entrypoint had
already been cached without it — and build_runner never rebuilt it. Because no
`@collection` existed until #35, the missing builder was invisible for the
whole of M0 and M1.

**If a generator silently does nothing, clear the cache before anything else:**

```bash
rm -rf .dart_tool/build
timeout 280 dart run build_runner build --verbose
```

Expect the first run afterwards to take a few minutes — it recompiles the
entrypoint and re-analyses every input. Subsequent runs are back to ~1 second.

Two related notes:

- **`--delete-conflicting-outputs` no longer exists.** build_runner 2.15.1
  prints `W These options have been removed and were ignored`. `CLAUDE.md`'s
  Common Commands, `developing_rules.md`, and the Definition of Done on
  #35–#38 and #43 all still pass it. Harmless, but it is a dead flag.
- **Watch for orphaned builder processes.** A run left in the background holds
  the build lock and silently blocks every later invocation:
  ```bash
  ps -eo pid,etime,pcpu,cmd | grep -E 'build_runner|build\.dart\.aot' | grep -v grep
  ```
  This is a real and separate problem — it cost ~50 minutes once — but it is
  not the cause of the non-exit above.

## Known blockers

**`flutter run` on an iOS simulator has never been verified.** No macOS host is
available in this environment. This matters because #154 fixed a bug where the
app could not launch at all (`Isar.open([])` throwing before `runApp`), and that
fix is still unconfirmed on a real device. It is also why **Epic #4 is still
open** — every other item on its checklist is green.

This is now the *only* thing in M1's path that cannot be done from a Linux
container.

---

## Environment notes

- **Isar Core loads offline.** `test/helpers/test_isar.dart` resolves the native
  binary from the installed `isar_community_flutter_libs` package via
  `.dart_tool/package_config.json`. It no longer downloads from
  `binaries.isar-community.dev`, which is blocked here (#147). Note
  `Isolate.resolvePackageUri` is unsupported in the `flutter_tester` runtime —
  that is why the package config is read directly.
- **`openTestIsar` requires a non-empty schema list.** Isar rejects an instance
  with zero collections. `openTestIsar()` with no argument does not compile.
- **`appIsarSchemas`** in `lib/core/database/isar_provider.dart` is the single
  registration point for collections. It is still empty, so `main.dart` skips
  `Isar.open` entirely and the app runs with no database. **#35 is the change
  that turns persistence on** — it must append its schema there and update the
  two `startup Isar wiring` tests, which currently assert the list is empty.
- **`pubspec.lock` is tracked** (#159) — `.gitignore`'s blanket `*.lock` had
  been matching it. Do not regenerate it casually.
- **`meta` is a direct dependency** (#156), needed for `@immutable` in the
  domain layer.

---

## Loose ends

- **Epic #4 (M0) is still open**, pending the `flutter run` check above.
- **Four consecutive PRs have deviated from `pr_conventions.md` §1** (one PR per
  issue): #145, #155, #160, #161. Each was a single pinned branch carrying
  several issues as separate commits. Either the convention should be relaxed to
  allow milestone-scoped PRs explicitly, or the branch constraint should change.
- **#149, #150, #151** are filed and correctly parked in M4, M8 and M7 — not M1
  work, but they were found during the M1 audit and are easy to lose track of.
  #150 (`integration_test` dependency) in particular gates all seven M8 flow
  tests.

---

## Next: the M1 data layer (#35–#43)

Nine issues, in dependency order. Their rewritten bodies (#158) are accurate —
implement from them directly.

1. **#35** `IsarMealEntry` schema + mapper. **This is the change that turns
   persistence on**: it appends the first schema to `appIsarSchemas`, and it
   must also flip the two `startup Isar wiring` tests in
   `test/core/database/isar_provider_test.dart`, which currently assert that
   list is empty. It also carries the `openTestIsar` lifecycle tests that #147
   had to drop for want of a real collection.
2. **#36, #37, #38** — the other three schemas. #36 lives under `dashboard/`.
3. **#39–#42** — repository implementations with contract suites. Each opens a
   real in-memory Isar via `openTestIsar([IsarXxxSchema])` and builds its
   objects from the fixtures, never inline.
4. **#43** — provider wiring. Three `providers.dart` files: diary (meal +
   symptom), dashboard (daily log), adaptation (streak).

Every one of #35–#38 and #43 runs code generation. Use the recipe above, and
remember `git status` is the check, not the exit code.

## Then: M2 (#44–#56)

**Read `design/m2_preflight.md` first.** A spot audit of M2's application layer
found the same class of defects M1 had — riverpod-2 `Ref` types, relative
imports — plus one specific to M2: the `DailyLog` move to the dashboard feature
(#157) was never propagated, so #45 and #47 still import it from `diary/`. #45
also calls a `DailyLog.empty(date)` factory that does not exist.

Tracked by **#165**. #44 is clean and is the right place to start.
