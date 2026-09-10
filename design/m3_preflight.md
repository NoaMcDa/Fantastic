# M3 Pre-flight — corrections to the M3 issue text

Read this before picking up any M3 issue (#57–#68).

This is the fourth such file. `m0_handoff.md` catalogued seven things the M0
issue text got wrong; `m1_preflight.md` and `m2_preflight.md` did the same for
their milestones. `m2_handoff.md` closed with a standing instruction: *audit
M3's twelve issues against the shipped code before implementing, and write the
preflight from what that finds.*

That audit is done. **All twelve issues carry at least one defect.** Four would
compile and ship incorrect behaviour, and the worst of those is silent — it
compiles, runs, passes a naive test, and leaves a grace period open forever.

M3's issues were written in the same sitting as M0's, M1's and M2's — before
any of it met a build, and **before Isar was replaced by sembast**. They carry
the same classes of error as their predecessors plus a set specific to M3.

**The issues have not been rewritten.** This file is the correction layer.

Audited: **#57–#68, all twelve, in full.**

---

## Part 1 — Defects that compile and ship wrong behaviour

These are the four that matter. Nothing in the toolchain catches them.

### 1.1 `copyWith(gracePeriodEnd: null)` does not clear the field

The single most expensive trap in M3.

`StreakState.copyWith` (`lib/features/adaptation/domain/models/streak_state.dart`)
resolves a null argument to the *existing* value:

```dart
gracePeriodEnd: clearGracePeriodEnd ? null : gracePeriodEnd ?? this.gracePeriodEnd,
```

Clearing requires the explicit flag. The model documents exactly this, and says
why it exists:

> `clearLastCompliantDate` and `clearGracePeriodEnd` exist because a plain
> `value ?? this.value` cannot express "set this back to null" — which is
> exactly what the service needs when a grace period ends or a streak resets.

#57 passes `gracePeriodEnd: null` in **both** the compliant-day branch and the
grace-expiry reset branch. Both are no-ops. The consequences:

- A streak resumed inside a grace period keeps its stale `gracePeriodEnd`.
- The reset branch clears `inGracePeriod` but leaves the expiry timestamp.
- `GracePeriodBanner` (#68) checks `inGracePeriod && gracePeriodEnd != null`, so
  it survives on the stale value in some orderings and not others.

There is no compile error and no analyzer warning. Write
`clearGracePeriodEnd: true` (and `clearLastCompliantDate: true` where a reset
should drop the date), and **assert on the cleared field in the test** — an
assertion on `inGracePeriod` alone passes with the bug present.

### 1.2 The streak increments once per meal, not once per day

#57's `recordCompliantDay` does `currentStreak + 1` unconditionally, and #58
calls `evaluateToday` after **every** `logMeal`. Three meals logged today leaves
`currentStreak == 3`. A streak of *days* cannot be driven by a per-meal trigger
without a guard.

`StreakState.lastCompliantDate` is the guard, and it already exists for this.
The corrected shape:

```dart
Future<StreakState> recordCompliantDay(DateTime date) async {
  final current = await _repo.load() ?? StreakState.initial();
  final day = _dateOnly(date);
  if (_isSameDay(current.lastCompliantDate, day)) {
    return current;                       // already counted today
  }
  final next = current.currentStreak + 1;
  return _repo.save(current.copyWith(
    currentStreak: next,
    highestStreak: math.max(current.highestStreak, next),
    phase: _phaseFor(next),
    lastCompliantDate: day,
    inGracePeriod: false,
    clearGracePeriodEnd: true,            // the flag, not `null` — see 1.1
  ));
}
```

`handleBreach` takes the mirror guard: a day already recorded compliant is not
breached by a later evaluation of the same day. Without that, one carb-heavy
snack after a compliant dinner opens a grace period on a day already banked.

### 1.3 The first meal of any day almost always registers as a breach

#58 derives compliance from the running day total, and calls `handleBreach` when
the ratio is under 2.0. But `KetoRatioCalculator.calculate` returns **`0`** when
`netCarbs + protein == 0` — deliberately, as "no net carbs or protein logged"
rather than an infinite ratio. Zero is under the threshold.

So a first meal of pure fat — two tablespoons of olive oil, a coffee with
butter — evaluates as a breach and opens a 24-hour grace period on a day the
user has done nothing wrong. This is a daily occurrence on keto, not an edge
case.

**A day with a zero denominator is not evaluated at all** — neither compliant
nor breached. The streak is left untouched until the day has a meaningful ratio:

```dart
if (updated.totalNetCarbsG + updated.totalProteinG == 0) return;
```

### 1.4 Phase boundary off by one

#57 returns `fatAdapted` at `currentStreak >= 7`. Every design document says
Phase 2 begins on **day 8**.

The canonical rule, decided during this audit and now the one true source:

| Phase | Streak | Enum |
|---|---|---|
| Induction | 1–7 | `AdaptationPhase.induction` |
| Fat-Adapted Transition | 8–27 | `AdaptationPhase.fatAdapted` |
| Deep Ketosis | 28+ | `AdaptationPhase.deepKetosis` |

```dart
if (streak >= 28) return AdaptationPhase.deepKetosis;
if (streak >= 8)  return AdaptationPhase.fatAdapted;
return AdaptationPhase.induction;
```

This also settles a contradiction the design docs carried on their own:
`mvp.md` and `ui_ux_design.md` both wrote "Phase 2 (Days 8–28)" and "Phase 3
(Days 28+)", putting day 28 in two phases at once. Both are corrected to
**8–27** in the same change that adds this file. #65's on-screen copy becomes
`ימים 1–7` / `ימים 8–27` / `יום 28+` — the issue's `יום 29+` is wrong.

`AdaptationPhase`'s own doc comment still describes the old ranges. It is
descriptive only — the enum carries no thresholds — but it is corrected too.

---

## Part 2 — Snippets that do not compile

### 2.1 riverpod 3 removed the generated `Ref` types

The same defect corrected in M1's #43 and M2's #45/#47/#48. M3 repeats it five
times:

```dart
adaptationPhaseService(AdaptationPhaseServiceRef ref)   // #57 — WRONG
streakState(StreakStateRef ref)                          // #59 — WRONG
currentPhase(CurrentPhaseRef ref)                        // #60 — WRONG
notificationPlugin(NotificationPluginRef ref)            // #61 — WRONG
notificationService(NotificationServiceRef ref)          // #61 — WRONG
```

All take a bare `Ref`, as `lib/features/adaptation/data/providers.dart` already
does.

### 2.2 `StreakState.lastComplianceDate` does not exist

#57 writes `lastComplianceDate`. The shipped field is **`lastCompliantDate`**.

### 2.3 `max()` with no import

#57 calls `max(...)` and imports neither `dart:math` nor an alias for it.

### 2.4 `DailyLog.empty(date)` does not exist

#58 repeats a defect `m2_preflight.md` §4 already recorded. Use
`DailyLog(date: date)` — every other field defaults to zero.

### 2.5 `kKetoRatioThreshold` does not exist

#58 and #63 both name it. The constant is
**`KetoConstants.targetKetoRatioIdeal`** (2.0) in
`lib/core/constants/keto_constants.dart`. There is also
`targetKetoRatioMin` (1.5), which is the amber/red boundary #63's colour rule
needs — do not hard-code either number.

### 2.6 `meals.fold(0, …)` infers `int`

#58's three folds need `fold<double>`, as the shipped
`_recalculateDailyLog` already writes them.

### 2.7 Wrong import path for `todaysDailyLogProvider`

#63 imports it from `features/diary/application/providers/daily_log_providers.dart`.
It lives at
**`lib/features/dashboard/application/providers/daily_log_providers.dart`** —
`m2_preflight.md` §3 moved it and M3's text never heard.

### 2.8 Undeclared identifiers

#64 uses `kPhaseNames` / `kPhaseColors` with no import of the constants file it
defines in its own Step 1. #65 uses `AdaptationPhase` and `GracePeriodBanner`
with no import for either.

---

## Part 3 — Routes that do not exist

### 3.1 `/adaptation/phase` is not registered

#64 does `context.push('/adaptation/phase')`, and #65 claims the target was
"registered in go_router (M0 #17)". It was not. `lib/core/router/app_router.dart`
has `/adaptation` as a **tab** inside the `ShellRoute`, rendering
`AdaptationPlaceholder`.

**Resolution:** the `/adaptation` tab renders `PhaseDetailScreen` directly —
that is what the tab was always a placeholder for — and `/adaptation/phase` is
registered as a redirect onto it, so #64's `push` works as written.
`adaptation_placeholder.dart` is deleted with #65.

### 3.2 `/diary/<date>` is not registered

#67 taps a calendar day through to
`context.push('/diary/${date.toIso8601String()}')`. `/diary` takes no path
parameter, and `DiaryScreen` holds its selected date in state.

**Resolution: the day tap is dropped from #67.** Adding a date parameter to the
diary route is diary scope, not M3's, and #67's Definition of Done does not
require the navigation. Deferred — worth its own issue when the diary gains
deep-linking.

---

## Part 4 — Where the issue text would regress shipped code

### 4.1 #58's snippet drops `ketoRatioAvg`

#58 rewrites `_recalculateDailyLog` from scratch and its version writes only the
three macro totals. The shipped method also computes and persists
`ketoRatioAvg`, with a comment recording why it is the ratio of the day's totals
rather than the mean of each meal's ratio. Pasting #58's snippet silently drops
a field `MacroSummaryCard` reads.

**#58 appends to the shipped method. It does not replace it.**

### 4.2 #66 would duplicate the electrolyte numbers

#66 wants a `const kPhaseElectrolyteGuide` map of per-phase electrolyte text.
`ElectrolyteAdvisor.advise(phase, log)` already owns per-phase targets and
deliberately sources every number from `ElectrolyteConstants` — its own comment
says why: *"so the numbers the dashboard shows and the numbers the design
documents specify cannot drift apart."* A second hand-written copy is exactly
that drift.

**Resolution:** phase *copy* (`kPhaseDescriptions`) is const as #66 asks; the
*numbers* come from the advisor. This makes `PhaseDescriptionCard` a
`ConsumerWidget`, not the `StatelessWidget` #66 specifies.

---

## Part 5 — Stale, contradictory, and misnumbered

### 5.1 Isar references

#57 says state mutations involve "no direct Isar writes". #59 lists
"Blocked by: `IsarStreakRepository` (#41)". Isar is gone — see
`design/web_support.md`. The repository is `SembastStreakRepository`, and the
service still touches no store type either way.

### 5.2 #59's title and body disagree

The title says "stream watching StreakRepository"; the body specifies a one-shot
`load()` plus manual invalidation after every transition.

**The title is right.** `StreakRepository.watch()` exists, its contract requires
it to fire immediately, and `SembastStreakRepository` implements it that way.
A stream provider removes the invalidation coupling entirely — no caller has to
remember to invalidate after a write:

```dart
@riverpod
Stream<StreakState?> streakState(Ref ref) =>
    ref.watch(streakRepositoryProvider).watch();
```

### 5.3 Cross-references are off by one throughout

| Written in | Says | Actually |
|---|---|---|
| #59 "Integration Points" | `currentPhaseProvider` is #61 | #60 |
| #60 "Why Now" | `ElectrolytesCard` replaces its hardcoded phase | correct, but the card takes a **parameter**, it is not hardcoded |
| `ElectrolytesCard` doc comment | `currentPhaseProvider` (#59) | #60 |
| `DashboardScreen` comment | `StreakRingWidget` lands here in M3 (#64) | #63 |
| `m2_handoff.md` §Known gaps | `StreakRingWidget` (#64) | #63 |
| #63 "Why Now" | `todaysDailyLogProvider` (#47) | correct |

The two in shipped source are corrected as their issues land.

### 5.4 `m2_handoff.md` is stale on enum storage

It closes with:

> **`AdaptationPhase` is stored as an ordinal** via a mirror enum.

That was true under Isar. The sembast migration changed it: enums are stored by
**`.name`**, per `CLAUDE.md` §Local Persistence — *"a stored ordinal silently
reinterprets every existing record the day a value is inserted mid-enum."*
`StreakStateMapper` writes `.name`, and `adaptation_phase.dart` documents it.
`m2_handoff.md` is corrected in the same change as this file.

### 5.5 #61 lists a package it never uses

`permission_handler` is in #61's technology table and appears nowhere in its
snippet — `flutter_local_notifications` requests iOS permission itself, which is
what the snippet actually does. **It is not added to `pubspec.yaml`.**

### 5.6 #63's animation is specified and then not written

The title says "animated arc" and the technology table lists
`AnimatedBuilder` + `AnimationController`. The snippet has neither. Implement
the animation — a `TweenAnimationBuilder` on the fill fraction is enough and
needs no `StatefulWidget`.

---

## Part 6 — Notifications (#61, #62) are web-hostile

New since these issues were written: **CI builds the web target** (step 6 of
`.github/workflows/ci.yml`) and the app is expected to run in a browser.

`flutter_local_notifications` has no web implementation. An unguarded
`await notificationService.initialise()` in `main()` — which is exactly what
#61's Definition of Done requires — is the same class of failure as the Isar
bug that white-screened the app before `runApp` ever ran.

**Both issues are scheduled last in M3, and `main()` guards the call:**

```dart
if (!kIsWeb) {
  await ref.read(notificationServiceProvider).initialise();
}
```

The providers themselves still resolve on web, so nothing else has to branch.

Two further notes:

- Nothing about notification *delivery* is verifiable in this environment — no
  iOS device, no macOS host. #61 and #62 ship with unit tests against a mocked
  plugin and are marked unverified in the M3 handoff, as `m2_handoff.md`'s
  known blocker already records for the simulator generally.
- `IOSFlutterLocalNotificationsPlugin` (#61's `resolvePlatformSpecificImplementation`
  type argument) has been renamed across major versions of the plugin. Check the
  version `pub` actually resolves before writing against the name.

---

## Part 7 — What M3 must code against

The shipped API, so no issue has to guess.

```dart
// lib/features/adaptation/domain/models/streak_state.dart
StreakState({currentStreak = 0, highestStreak = 0, phase = induction,
             lastCompliantDate, inGracePeriod = false, gracePeriodEnd})
StreakState.initial()
copyWith({currentStreak, highestStreak, phase,
          lastCompliantDate, clearLastCompliantDate = false,
          inGracePeriod, gracePeriodEnd, clearGracePeriodEnd = false})

// lib/features/adaptation/domain/repositories/streak_repository.dart
Future<StreakState?> load();          // null = never had a compliant day
Future<StreakState>  save(StreakState state);
Stream<StreakState?> watch();         // fires immediately

// lib/features/dashboard/application/keto_ratio_calculator.dart
double calculate({required double fat, required double netCarbs,
                  required double protein});   // 0 when denominator is 0;
                                               // throws ArgumentError if negative

// lib/features/dashboard/application/electrolyte_advisor.dart
ElectrolyteAdvice advise(AdaptationPhase phase, DailyLog log);

// lib/core/constants/keto_constants.dart
KetoConstants.targetKetoRatioMin    // 1.5
KetoConstants.targetKetoRatioIdeal  // 2.0
```

Providers already wired: `streakRepositoryProvider`, `ketoRatioCalculatorProvider`,
`electrolyteAdvisorProvider`, `todaysDailyLogProvider(date)` (dashboard),
`todaysMealsProvider(date)` (diary), `mealLoggingServiceProvider`.

Waiting hooks: `ElectrolytesCard(date:, phase:)` takes the phase as a parameter
and defaults to induction; `DashboardScreen` has a comment marking where the
streak ring goes, between the macro card and the meal list.

---

## Summary — before starting M3

1. **Build order is #57 → #59 → #60 → #58 → #63 → #64 → #66 → #68 → #65 → #67
   → #61 → #62.** #59/#60 move ahead of #58 so the streak is observable the
   moment the write path starts producing it; #68 moves ahead of #65 because
   #65 embeds it; #61/#62 go last (Part 6).
2. **Phase thresholds are 8 and 28** (§1.4). Nothing else.
3. **Never pass `null` to clear a `StreakState` field** (§1.1). Use the flag,
   and assert on the cleared field.
4. `flutter analyze` and `flutter test` catch none of Part 1. CI catches none of
   Part 1. Only a test written against the corrected behaviour does.
