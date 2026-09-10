# M1 Pre-flight — corrections to the M1 issue text

Read this before picking up any M1 issue (#25–#43).

`design/m0_handoff.md` catalogued seven things the M0 issue text got wrong once
it met a real build. The M1 issues were written from the same assumptions, at
the same time, and carry the same class of error — plus a few of their own. The
issues have **not** been rewritten; this file is the correction layer, the same
way `m0_handoff.md` is for M0.

Every correction below was verified against the issue text and the code on
`main` on 2026-09-10.

---

## 1. The Isar package is `isar_community`, not `isar`

Every schema issue (#35, #36, #37, #38) opens its API contract with:

```dart
import 'package:isar/isar.dart';   // WRONG — does not resolve
```

M0 swapped to the community fork because the original `isar` /
`isar_flutter_libs` / `isar_generator` `^3.1.0` pin `analyzer <6.0.0` and cannot
co-resolve with `riverpod_generator` at any version (see `m0_handoff.md` §1).
Use:

```dart
import 'package:isar_community/isar.dart';
```

The same substitution applies to every **Technologies & Approach** table in
M1, which name `isar`, `isar_flutter_libs` and `isar_generator`:

| Issue text says | Actually in `pubspec.yaml` |
|---|---|
| `isar` | `isar_community` ^3.3.2 |
| `isar_flutter_libs` | `isar_community_flutter_libs` ^3.3.2 |
| `isar_generator` | `isar_community_generator` ^3.3.2 |
| `flutter_riverpod` ^2.6.1 | `flutter_riverpod` ^3.0.2 |
| `riverpod_generator` ^2.6.1 | `riverpod_generator` ^3.0.2 |
| `riverpod_test` | not a dependency — use `ProviderContainer.test()` |

## 2. Mapper snippets use relative imports, which fail the lint gate

Every mapper contract in #35–#38 is written as:

```dart
import '../../domain/models/meal_entry.dart';   // WRONG — lint error
import '../schemas/isar_meal_entry.dart';
```

`analysis_options.yaml` enables `always_use_package_imports`, so these fail
`flutter analyze` — which is a hard gate in every issue's own Definition of
Done. Write them as:

```dart
import 'package:fantastic/features/diary/domain/models/meal_entry.dart';
import 'package:fantastic/features/diary/data/schemas/isar_meal_entry.dart';
```

## 3. Schemas register in `appIsarSchemas`, and `Isar.open`'s schema list is positional

#35 says the schema is:

> Passed to `Isar.open(schemas: [IsarMealEntrySchema])` in `isarProvider` (M0, issue #21).

Two things are wrong. `schemas` is a **positional** parameter, not named — that
snippet does not compile. And `isarProvider` never opens anything; it is a
`@Riverpod(keepAlive: true)` provider that throws until overridden.

The real registration point, added by #154, is a single list in
`lib/core/database/isar_provider.dart`:

```dart
const List<CollectionSchema<dynamic>> appIsarSchemas = [];
```

`main.dart` reads that list and skips `Isar.open` entirely while it is empty —
`Isar.open` throws `IsarError: At least one collection needs to be opened` on an
empty list, which is what crashed the app at launch before #154.

**So the first schema issue to land (#35) must also append its schema here:**

```dart
const List<CollectionSchema<dynamic>> appIsarSchemas = [IsarMealEntrySchema];
```

and update the two `startup Isar wiring` tests in
`test/core/database/isar_provider_test.dart`, which currently assert the list is
empty. That step is in no issue's Definition of Done — do not skip it, or the
app silently keeps launching without a database.

## 4. Repository cross-references are off by two

Every schema issue names the wrong downstream repository issue. The shift is
consistent — add 2:

| Issue | Says | Should be |
|---|---|---|
| #35 | "before `IsarMealRepository` (#37)" | **#39** (#37 is the StreakState schema) |
| #36 | "before `IsarDailyLogRepository` (#38)" | **#40** (#38 is the SymptomLog schema) |
| #37 | "before `IsarStreakRepository` (#39)" | **#41** (#39 is IsarMealRepository) |
| #38 | "before `IsarSymptomLogRepository` (#41)" | **#42** (#41 is IsarStreakRepository) |

#38's Testing Requirements section repeats the same mistake ("contract tests
(#41)" → **#42**).

## 5. `lib/features/symptom_diary/` does not exist

#38 places its files under:

```
lib/features/symptom_diary/data/schemas/isar_symptom_log.dart   # WRONG
```

There is no `symptom_diary` feature. M0's #22 scaffolded eight directories —
`adaptation`, `dashboard`, `diary`, `directory`, `keto_lens`, `profile`,
`recipe`, `restaurant` — and `CLAUDE.md`'s feature table assigns symptoms to the
diary feature ("Diary (meals, symptoms, biomarkers) — `lib/features/diary/`").
Use:

```
lib/features/diary/data/schemas/isar_symptom_log.dart
```

## 6. `test/fixtures/` is empty, and #152 owns filling it

All five files in `test/fixtures/` are documentation-only stubs — `library;`
declarations with the intended API in a doc comment. The barrel exports nothing.

`design/tests.md` and `CLAUDE.md` both require that *"all fixtures live in
`test/fixtures/` — never construct domain objects inline in tests"*, but no M1
issue owned filling them, so **#152** was opened for it. Sequence it after
#25–#28 (the domain models) and before #39–#42 (the contract tests), or those
four will each build objects inline and the convention dies in its first
milestone of use.

## 7. `openTestIsar` lifecycle coverage lands with #35

`test/helpers/test_isar.dart` no longer downloads Isar Core over the network
(#147) — it loads the binary that `isar_community_flutter_libs` already installs,
resolved through `.dart_tool/package_config.json`.

Its three original tests could not be kept: they called `Isar.open` with an
empty schema list, which Isar rejects outright, so they would have failed with
or without network. Coverage for **open / isolation between instances /
use-after-close** needs a real collection, so it lands with the first schema
(#35). What remains in `test_isar_test.dart` is a regression guard on the
network fix itself.

## 8. `build_runner` is unverified in a Linux container

Every schema issue's Definition of Done requires a committed `.g.dart`. Code
generation could not be verified during the M0 audit — `dart run build_runner
build` ran over 20 minutes at ~0.1% CPU, blocked rather than computing, and was
abandoned. Nothing merged so far depends on it.

Confirm it works locally **before** starting #35, since #35–#38 and #43 are
entirely code generation:

```bash
dart run build_runner build --delete-conflicting-outputs
```

If it stalls, check for an orphaned `build_runner` process holding the build
lock before assuming the toolchain is broken.

---

## Summary — what to fix before starting M1

1. Merge #147, #148 and #154 to `main`; `main` is otherwise red and unlaunchable.
2. Verify `build_runner` locally (§8).
3. Read §1–§5 before writing any schema; the issue snippets do not compile as
   written.
4. Sequence #152 between the domain models and the contract tests (§6).
5. #35 must also register its schema in `appIsarSchemas` and update the two
   startup-wiring tests (§3).
