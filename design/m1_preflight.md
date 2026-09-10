# M1 Pre-flight — corrections to the M1 issue text

> **Superseded in part:** Isar was replaced by **sembast + sembast_web** when web
> support landed — see `design/web_support.md` and `CLAUDE.md` §Local Persistence.
> Everything below is kept as a record of what was true at the time and is not a
> description of the current data layer.

Read this before picking up any M1 issue (#25–#43).

`design/m0_handoff.md` catalogued seven things the M0 issue text got wrong once
it met a real build. The M1 issues were written from the same assumptions, at
the same time, and carry the same class of error — plus a few of their own.

Every correction below was verified against the issue text and the code on
`main` on 2026-09-10.

## Status: most of this is now fixed at source

A second, deeper audit found more than the eight items first recorded here —
including snippets that do not compile and two conflicts with the design docs.
Those are being fixed where they live rather than only documented:

| Fixed by | What |
|---|---|
| #156 | `meta` added to `pubspec.yaml`, so `@immutable` in `domain/` passes analyze |
| #157 | `base_design.md`, `architecture.md`, `tests.md` reconciled with the decisions below |
| #158 | All 19 M1 issue bodies (#25–#43) rewritten so every snippet compiles |
| #159 | `pubspec.lock` tracked, so dependency resolution is reproducible |

Three decisions settle the conflicts, and the docs now say so:

1. **Repositories throw typed domain exceptions; they do not return `Result<T>`.**
   `base_design.md` previously mandated `Result<T>` — it now records why that
   was dropped (Riverpod's `AsyncValue` already carries the failure).
2. **Domain uses subfolders:** `domain/models/`, `domain/repositories/`,
   `domain/services/`. `architecture.md`'s trees now show this.
3. **Repository contract tests live in `test/features/<f>/data/`**, beside the
   implementation they exercise. `tests.md` now says so.

Sections 1–8 below remain the record of what was wrong and why, and are still
worth reading — they explain the reasoning the corrected issues only assert.

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

## 8. `build_runner` works — it just never exits

An earlier version of this section said code generation "ran over 20 minutes at
~0.1% CPU, blocked rather than computing" and had to be confirmed working before
#35 could start. **That was wrong.** Generation is fine and takes about a
second; see `design/m1_handoff.md` for the full diagnosis.

What it does not do is terminate. Run it with a timeout and check the output
separately:

```bash
timeout 120 dart run build_runner build --verbose   # exit 124 is expected
git status --short                                   # verify the .g.dart files
```

`--verbose` matters — without it, a redirected run produces an empty log.

**Nothing in M1 is blocked on this.** #35–#38 and #43 can proceed.

---

---

## 9. Further defects found in the second audit

These are beyond the original eight, and are fixed at source by #157–#159.

**#43 contains three compile errors in one code block:**
- `MealRepositoryRef` / `DailyLogRepositoryRef` / … — riverpod 3 removed the
  generated `XxxRef` types. Use bare `Ref`, as `lib/core/router/app_router.dart`
  already does.
- `ref.watch(isarProvider).requireValue` — `isarProvider` is **synchronous**
  (`Isar isar(Ref ref)`). There is no `AsyncValue` to unwrap.
- `lib/core/providers/isar_provider.dart` — the real path is
  `lib/core/database/isar_provider.dart`.

**#39 calls the test helper wrongly.** `openTestIsar()` takes no arguments in
the snippet, but the signature is
`openTestIsar(List<CollectionSchema<dynamic>> schemas)` and Isar rejects an
empty list. It also calls `MealEntryMapper.dateIndex(date)` publicly, while #35
declares that method private as `_dateIndex` — the two issues disagree.

**#25–#28 import an undeclared package.** `import 'package:meta/meta.dart'`
trips `depend_on_referenced_packages`, so the first file of M1 fails
`flutter analyze`. `package:flutter/foundation.dart` also exports `@immutable`
but the domain layer may not import Flutter. Fixed by #156.

**Cross-references are wrong, and the offset is not consistent** — #29 is off
by five, #35–#38 by two. Do not bulk-shift them:

| Issue | Says | Correct |
|---|---|---|
| #29 | `IsarMealRepository` (#34), ×3 | **#39** |
| #35 | `IsarMealRepository` (#37) | **#39** |
| #36 | `IsarDailyLogRepository` (#38) | **#40** |
| #37 | `IsarStreakRepository` (#39), ×2 | **#41** |
| #38 | `IsarSymptomLogRepository` (#41), ×2 | **#42** |

**`pubspec.lock` was never committed** — `.gitignore`'s blanket `*.lock`
matched it. An application commits its lockfile; only packages omit it. Several
M0 issues carried a DoD item to stage a file git was ignoring. Fixed by #159.

---

## 10. Every model and its schema disagree on field names

This is the most damaging class found, because each one compiles as a *mapper*
error only once both issues have landed — the model issue looks fine on its own,
and the schema issue looks fine on its own.

The authority is `design/base_design.md` §Domain Models plus
`architecture.md`'s schema table; both now agree with the model issues
(#25–#28), so **the schema issues (#35–#38) are the ones that were wrong**:

| Model | Field | Model issue says | Schema issue says | Correct |
|---|---|---|---|---|
| `MealEntry` | meal name | `mealName` (#25) | `name` (#35) | **`mealName`** |
| `MealEntry` | ingredients | `List<String> ingredients` (#25) | *absent* (#35) | **must persist** |
| `MealEntry` | image | `String? imageRef` (#25) | *absent* (#35) | **must persist** |
| `DailyLog` | water | `waterMl` (#26) | `totalWaterMl` (#36) | **`waterMl`** |
| `DailyLog` | avg ratio | `ketoRatioAvg` (#26) | *absent* (#36) | **must persist** |
| `StreakState` | last compliant day | `lastCompliantDate` (#27) | `lastComplianceDate` (#37) | **`lastCompliantDate`** |
| `SymptomLog` | 5th scale | `moodScore` (#28) | `brainFogScore` (#38) | **`moodScore`** |

`moodScore` is confirmed four times over — `architecture.md`'s schema table,
`mvp.md`'s "energy, mental clarity, hunger, mood, physical symptoms",
`tasks.md`'s explicit field list, and `ui_ux_design.md`'s מצב רוח row. There is
no brain-fog scale anywhere in the design.

The three "absent" rows are silent data loss, not just a rename: #35's mapper
never persists `ingredients` or `imageRef`, and #36's never persists
`ketoRatioAvg`, so a round-trip through the repository would quietly drop them.

## 11. `DailyLog` is a dashboard model, not a diary one

#26 places it at `lib/features/dashboard/domain/models/daily_log.dart`, and
`architecture.md` agrees. #36 and #43 put its schema and provider under
`lib/features/diary/`. Dashboard wins: the diary owns individual meals, the
dashboard owns the per-day aggregate. So `IsarDailyLog`, `DailyLogMapper`,
`IsarDailyLogRepository` and `dailyLogRepositoryProvider` all live under
`lib/features/dashboard/data/`.

## 12. Two model issues fail the repo's own issue standard

#26 and #27 have no API contract code block — just a prose sentence listing
field names. `CLAUDE.md` and `issue_conventions.md` §2 both make a full Dart
signature mandatory ("An issue missing any of the above is sent back"). They
were rewritten to include one.

Two smaller defects in the same set: `base_design.md` typed `MealEntry.id` as
Isar's `Id`, which the domain layer may not import (now `int?`), and #28's
Objective says the constructor throws `ArgumentError` while its asserts throw
`AssertionError` — the Testing Requirements had it right.

---

## Summary — what to fix before starting M1

1. ~~Merge #147, #148 and #154~~ — done, PR #155.
2. Verify `build_runner` locally (§8) — still outstanding, and #35–#38 and #43
   depend on it entirely.
3. Land #156–#159.
4. Sequence #152 between the domain models and the contract tests (§6).
5. #35 must also register its schema in `appIsarSchemas`, update the two
   startup-wiring tests (§3), and carry the `openTestIsar` lifecycle tests
   removed in #147 (§7).
