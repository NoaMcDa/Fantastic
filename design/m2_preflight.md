# M2 Pre-flight — corrections to the M2 issue text

> **Superseded in part:** Isar was replaced by **sembast + sembast_web** when web
> support landed — see `design/web_support.md` and `CLAUDE.md` §Local Persistence.
> Everything below is kept as a record of what was true at the time and is not a
> description of the current data layer.

Read this before picking up any M2 issue (#44–#56). Tracked by **#165**.

This is the third such file. `m0_handoff.md` catalogued seven things the M0
issue text got wrong; `m1_preflight.md` did the same for M1. The M2 issues were
written in the same sitting as both, before any of it met a build, and they
carry the same classes of error — plus one that is specific to M2.

**The issues have not been rewritten yet.** This file is the correction layer
until #165 lands.

Audited so far: **#44, #45, #47, #48**. #46 and #49–#56 have not been read
individually — see §6.

---

## 1. `#44` is clean

`KetoRatioCalculator` is pure Dart, its path (`lib/features/dashboard/application/`)
is right, and its snippet compiles. It is the correct place to start M2, and it
needs no corrections.

## 2. riverpod 3 removed the generated `Ref` types

Every M2 provider snippet uses one:

```dart
MealLoggingService mealLoggingService(MealLoggingServiceRef ref)   // #45 — WRONG
Future<DailyLog?> todaysDailyLog(TodaysDailyLogRef ref, ...)       // #47 — WRONG
Future<List<MealEntry>> todaysMeals(TodaysMealsRef ref, ...)       // #48 — WRONG
```

None of those types exist. Use a bare `Ref`, as `lib/core/router/app_router.dart`
already does:

```dart
Future<List<MealEntry>> todaysMeals(Ref ref, DateTime date) { ... }
```

This is the same defect #158 corrected in M1's #43.

## 3. `DailyLog` moved to the dashboard feature and M2 never heard

This one is specific to M2. #157 established that `DailyLog` belongs to
**dashboard**, not diary — the diary owns individual meals, the dashboard owns
the per-day aggregate — and #26, #31, #36, #40 and #43 were all corrected. The
M2 issues were not.

| Issue | Says | Correct |
|---|---|---|
| #45 | `import '../../domain/models/daily_log.dart'` from `diary/application/` | `package:fantastic/features/dashboard/domain/models/daily_log.dart` |
| #45 | `dailyLogRepositoryProvider` from `diary/data/providers.dart` | `dashboard/data/providers.dart` |
| #47 | file at `lib/features/diary/application/providers/daily_log_providers.dart` | `lib/features/dashboard/application/providers/…` |

`todaysMealsProvider` (#48) stays under `diary/` — meals genuinely are a diary
concern.

## 4. `DailyLog.empty(date)` does not exist

#45's `_recalculateDailyLog` is written as:

```dart
final updated = (existing ?? DailyLog.empty(date)).copyWith(...);
```

The shipped `DailyLog` (#26) has no `empty` factory. It does not need one —
every numeric field defaults to `0`, so a day with nothing logged is:

```dart
final base = existing ?? DailyLog(date: date);
```

Adding an `empty` factory would be a second way to say what the defaults
already say. Correct the issue, not the model.

## 5. Two smaller defects in #45

**`fold` with an `int` seed over `double` values** does not type-check:

```dart
totalFatG: meals.fold(0, (s, m) => s + m.fatG),          // WRONG
totalFatG: meals.fold<double>(0, (s, m) => s + m.fatG),  // correct
```

**The code-generation command** still passes `--delete-conflicting-outputs`,
removed in build_runner 2.15.1. Use the form in `CLAUDE.md`:

```bash
timeout 120 dart run build_runner build --verbose
```

Remember build_runner never exits — exit 124 from `timeout` is expected. See
`design/m1_handoff.md`.

## 6. Nine issues not yet audited

**#46** (`ElectrolyteAdvisor`) is application-layer and almost certainly carries
§2 and §5. **#49–#56** are presentation — expect the relative-import problem at
minimum, and check every provider reference against §2 and §3.

Read each one rather than pattern-matching. The M1 audit found that the error
*classes* repeated but the specifics did not: cross-reference numbers were off
by five in one issue and two in others, and the field-name mismatches were
different in every model.

## 7. Check every model field name against what shipped

M1's most damaging class of error was models and schemas disagreeing on field
names — seven of them, each of which compiled fine in isolation. M2 consumes
those models, so the same check applies. The shipped names are:

| Model | Fields |
|---|---|
| `MealEntry` | `id`, `timestamp`, `fatG`, `netCarbsG`, `proteinG`, `mealName`, `ingredients`, `imageRef`, `ketoRatio` (computed getter) |
| `DailyLog` | `id`, `date`, `totalFatG`, `totalNetCarbsG`, `totalProteinG`, `waterMl`, `sodiumMg`, `potassiumMg`, `magnesiumMg`, `ketoRatioAvg` |
| `StreakState` | `currentStreak`, `highestStreak`, `phase`, `lastCompliantDate`, `inGracePeriod`, `gracePeriodEnd` |
| `SymptomLog` | `id`, `date`, `energyScore`, `clarityScore`, `hungerScore`, `physicalScore`, `moodScore`, `notes` |

Note `waterMl` (not `totalWaterMl`), `mealName` (not `name`), `moodScore` (not
`brainFogScore`), and `lastCompliantDate` (not `lastComplianceDate`) — all four
were wrong somewhere in M1's text.

## 8. Repository methods available to M2

M2 services must call methods that exist. What shipped in #29–#33:

```dart
MealRepository:        save, findById, findByDate, findAll, delete
DailyLogRepository:    save (upsert by date), findByDate, findAll, deleteByDate
SymptomLogRepository:  save (upsert by date), findByDate, findAll, deleteByDate
StreakRepository:      load, save, watch          // three, not two
```

There is no `upsert` — `DailyLogRepository.save` is the upsert. There is no
`watchDate` on `DailyLogRepository`; the dashboard refreshes by provider
invalidation, which is what #47's own Logic section already describes.

---

## Summary — before starting M2

1. **M1's data layer (#35–#43) must land first.** M2's services depend on the
   repository implementations and the providers from #43. Nothing in M2 can be
   built against interfaces alone.
2. Land **#165** (the issue-text corrections) or work from this file.
3. Start with **#44** — it is clean, pure Dart, and needs nothing else.
