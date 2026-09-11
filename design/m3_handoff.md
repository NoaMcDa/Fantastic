# M3 Handoff — Adaptation Phase & Streak

M3 is code-complete. All twelve issues (#57–#68) are merged, CI is green on
`main`, and — the part no previous milestone could claim on the day it closed —
**the feature was driven end to end in a real browser**, not just tested.

This file records what M3 shipped, what building it taught, and what M4 and M5
inherit.

---

## What shipped

| Issue | What |
|---|---|
| #57 | `AdaptationPhaseService` — the state machine |
| #59 | `streakStateProvider` — a stream over `StreakRepository.watch()` |
| #60 | `currentPhaseProvider` — derived phase |
| #58 | Streak evaluation on every meal write |
| #63 | `StreakRingWidget` — animated ratio arc with the day count |
| #64 | `PhaseBadgeWidget` — the phase chip, and the dashboard's real phase |
| #66 | `PhaseDescriptionCard` — phase copy and electrolyte ranges |
| #68 | `GracePeriodBanner` — the countdown |
| #65 | `PhaseDetailScreen` — the timeline; `/adaptation` is a screen at last |
| #67 | `StreakCalendarWidget` — the month grid |
| #61 | `NotificationService` — plugin setup and permission |
| #62 | `StreakNotificationService` — the 20:00 reminder |

**663 tests. `domain/` 100%, `application/` 89.4% line coverage** — every
uncovered `application/` line is generated riverpod boilerplate in a `.g.dart`.

---

## Verified in a browser, not only in tests

Built with the CI flags, served locally and driven with Chromium. What the
run actually proved:

- The dashboard paints, Hebrew renders as Hebrew, **no console errors at all**.
- Logging a compliant meal (45g fat / 3g net carbs / 14g protein, ratio 2.6)
  moved the ring from `0 ימים` to **`1 יום`** — singular, correctly — and
  painted it **full and green**.
- **It was still `1 יום` after a full page reload.** That is the only proof
  the streak reached IndexedDB rather than living in the tab.
- The phase screen showed `ימים 1–7` / `ימים 8–27` / `יום 28 ואילך`, the
  induction card expanded with the phase-1 electrolyte ranges, and a calendar
  whose header reads **א ב ג ד ה ו ש right-to-left** with 1 September under ג.
- The logged meal carried a real time of day, not `00:00` — #201 stays fixed.

M2's lesson was that 482 green tests missed a bug a browser found in a minute.
That check is now part of closing a milestone.

---

## The one thing that cost the most: riverpod 3 async errors

Three separate issues lost time to the same root fact, in three disguises. It
is worth reading once.

**riverpod 3 reports a provider that failed *before ever producing a value* as
`AsyncLoading` with an error attached.** `isLoading` and `hasError` are both
true, and the runtime type is `AsyncLoading`, not `AsyncError`:

```
runtimeType=AsyncLoading<AdaptationPhase> isLoading=true hasError=true hasValue=false
```

Three consequences, all of which shipped as bugs before being caught:

1. **`await ref.watch(p.future)` never completes** for such a provider. A
   derived provider chained that way sits in loading for the life of the app —
   #60 would have shown a spinner that never resolves on any storage failure.
   Read the `AsyncValue` and re-throw its error *before* the await.
2. **A widget that checks `isLoading` before `hasError` shows its loading state
   forever.** #63 shipped with exactly that and its own failure test passed,
   because the loading branch also drew no ring and reserved the same box.
   **Check `hasError` first, and make the failure test assert the loading
   indicator is absent** — otherwise the two branches are indistinguishable.
3. **Matching `AsyncError()` in a `switch` never fires.** Match on the
   `hasError` flag instead. #65's first draft did this and hung.

Two smaller riverpod-3 facts from #59:

- `container.read(provider.future)` alone does **not** hold an auto-disposing
  provider. It is torn down mid-load and the future completes with "disposed
  during loading state". A `container.listen(...)` keeps it mounted — and
  `fireImmediately: true` does *not*.
- Stub a repository stream with a **factory**, not an instance. An errored
  provider is rebuilt on the next read, and handing back the same
  single-subscription stream throws "already been listened to", masking the
  error under test.
- riverpod **coalesces recomputes landing in one microtask drain**. A test
  that emits three values synchronously only ever sees the last; pump between
  them.

---

## Conventions M4 and M5 inherit

1. **Phase thresholds are 8 and 28.** Induction 1–7, fatAdapted 8–27,
   deepKetosis 28+. `AdaptationPhaseService.fatAdaptedFromDay` and
   `deepKetosisFromDay` are the only definition; `PhaseCopy.dayRanges` is
   display copy and a test asserts the two agree.
2. **Never pass `null` to clear a `StreakState` field.** `copyWith` resolves a
   null argument to the existing value; use `clearGracePeriodEnd` /
   `clearLastCompliantDate`. And **assert on the cleared field** — an assertion
   on `inGracePeriod` alone passes with the bug present.
3. **The streak is idempotent per calendar day**, keyed on `lastCompliantDate`,
   because the trigger is per meal. A day already banked is neither
   re-incremented nor breached.
4. **A day with no carbs and no protein is not evaluated.** The ratio reports
   `0` for a zero denominator, and treating that as a breach opens a grace
   period on a butter-coffee morning. `StreakCalendarWidget` paints such a day
   unlogged for the same reason — the two must stay consistent.
5. **Phase copy lives in `lib/core/constants/phase_copy.dart`**, numbers in
   `ElectrolyteConstants`. Never a second hand-written copy of either.
6. **Digit runs need `TextDirection.ltr`** inside the RTL layout, every time.
   `12` renders as `21` otherwise. Three widgets in M3 needed it.
7. **The Hebrew week starts on Sunday.** `DateTime.weekday % 7` is the
   Sunday-first offset; `weekday - 1` is Monday-first and shifts a calendar by
   a column.
8. **Every notification call is a no-op on web** — see below.

---

## Gotchas worth keeping

- **`intl` exports its own `TextDirection`**, which shadows `dart:ui`'s. Import
  it as `hide TextDirection` in any file that also positions text.
- **A zero-extent child of a sliver counts as offstage.** `find.byType` needs
  `skipOffstage: false` to see a collapsed `GracePeriodBanner`.
- **A killed `build_runner` corrupts `.dart_tool/build` permanently.** It then
  hangs on every subsequent run with no error. `rm -rf .dart_tool/build` is the
  fix. This is separate from the documented "completes but never exits"
  behaviour, and it cost an hour.
- **A widget under test that references a not-yet-generated provider blocks its
  own generation.** Move the file aside, generate, move it back.
- **`verify` consumes the recorded call.** A mocktail `captured` helper is
  callable once per test; hold the result rather than calling twice.
- **`Chip` needs a `Material` ancestor.** `pumpApp` supplies one; a bare
  `GoRoute` builder does not.
- **Adding a dependency to a service widens every container that builds it.**
  #58 put the state machine into `MealLoggingService`, and three provider tests
  started trying to open a real database until `streakRepositoryProvider` was
  overridden too.

---

## Notifications: what is real and what is not

**Unverified.** No iOS device and no macOS host exist in this environment, so
nothing has confirmed a notification ever arrives. The tests assert against a
mocked plugin. This joins M2's standing blocker on the simulator.

Three decisions worth revisiting when a device exists:

- **Everything is a no-op on web**, and not because the plugin lacks web
  support — `flutter_local_notifications_web` 1.0.0 exists. `initialize()`
  works there but **registers its own service worker, replacing Flutter's**,
  which an app that bundles CanvasKit to boot offline should not accept; and
  `zonedSchedule()` throws `UnsupportedError` outright, which would crash
  startup on every launch.
- **The reminder zone is pinned to `Asia/Jerusalem`.** `timezone` cannot learn
  the device zone without `flutter_timezone`, and an uninitialised `tz.local`
  is **UTC** — which would fire the 20:00 reminder at 22:00 or 23:00 Israel
  time. A user abroad currently gets Israeli 20:00. Add `flutter_timezone` when
  someone asks.
- **Permission is never requested at launch.** `NotificationService.initialise`
  sets all three Darwin request flags false; `requestPermission()` is for
  M4's onboarding or profile settings. Asking before the user knows what the
  app is for is how an app gets a permanent no. **Nothing calls
  `requestPermission()` yet — M4 must.**

---

## Epic #7's Definition of Done: two items not met

All twelve child issues shipped, but the Epic carries invariants its own
decomposition never covered. Recorded here rather than quietly checked off,
and **Epic #7 stays open** because of them (`milestone_conventions.md` §2
condition 6).

- **"Notification scheduling cancelled immediately when a compliant meal is
  logged."** Nothing does this. The 20:00 reminder fires whether or not the
  day is already logged, which makes it noise on exactly the days the user is
  doing well — and noise is how a reminder gets switched off. No issue in
  #57–#68 asked for it. Doing it properly means cancelling today's pending
  notification on a compliant evaluation and scheduling the next for
  tomorrow, since `matchDateTimeComponents` cannot express a condition.
- **"Push notification fires at 20:00 when no meal logged."** Unverifiable
  here regardless (no iOS device), but the *"when no meal logged"* half is
  the same gap as above.

Met: the state machine is pure application-layer over the repository
interface; thresholds are tested on both sides of day 8 and day 28; grace
expiry resets the streak; the ring animates on first render; analyze and test
are clean; coverage clears the gate.

**Partially met — "grace period timestamps stored and compared in UTC."** The
comparison is correct: `DateTime.isAfter` compares absolute instants whatever
the flag says, and the mapper stores `millisecondsSinceEpoch`, which is
absolute. But the values are not explicitly UTC-typed on the way back out, so
the invariant holds by construction rather than by declaration. Worth making
explicit if anyone ever formats a grace deadline.

---

## Known gaps M4, M5 and M7 inherit

- **Nothing requests notification permission.** The reminder is scheduled on
  every launch and the OS will deliver nothing until M4 asks.
- ~~**A day banked compliant cannot be un-banked.**~~ **Closed by #303, and the
  end-of-day job it was waiting for is no longer needed.** The streak is now
  *derived* by walking the `DailyLog` history rather than accumulated a day at a
  time, so there is nothing to un-bank: every write re-reads the day's totals and
  re-decides. Under the old keto-ratio rule the gap was harmless; under a
  net-carb rule it would not have been, because carbs only accumulate — a
  compliant breakfast would have banked the day and 200 g of carbs at dinner
  could not have taken it back.
- **The streak resets lazily.** An expired grace period is only noticed on the
  next evaluation, so the banner reads "פחות מדקה" until the user logs
  something. A launch-time evaluation would fix it. *(Partly closed — see
  "Defects found after closure" below: both branches now notice an expired
  window, so the reset lands on the next evaluation whatever it is. The banner
  still reads "פחות מדקה" until then.)*
  **[Post-M5 audit] The other half of the same gap: nothing checked
  contiguity either.** A skipped day did not break the streak at all, so
  `currentStreak` was a lifetime count of compliant days — three in January
  and one in February read as four. Fixed by
  `AdaptationPhaseService.reconcile`, which both write paths now run first and
  which folds the expired-window rule above into the same question. **What
  remains is only the display half**: reconciliation is applied on write, not
  on read, so a stale number can sit on the ring until the user's next logged
  meal.
- **Water and electrolytes still have no logging flow** (inherited from M2), so
  the gauges read zero and every electrolyte shows a deficit.
- **`/diary/<date>` does not exist**, so #67's calendar days are not tappable.
  Worth its own issue when the diary gains deep-linking.
- **The ring and the macro card disagree on colour for one number.** At ratio
  2.6 the ring is green (target met, clamped full) and the macro bar is amber
  (2.6 against a 2.0 target). Both are internally consistent; they look
  inconsistent side by side. M7 polish.
- **Macro targets are still the `KetoConstants` defaults** (inherited from M2).
  M4's onboarding persists per-user targets.
- **`EntityNotFoundException` still has no throw site**, from M1.
- **CI does not check codegen freshness.** Two `.g.dart` files were stale on
  `main` during M3 — harmless, but nothing catches it. `cicd_plan.md` Phase 1.

---

## Defects found after closure

A bug sweep over the whole milestone after M6 closed. Five defects, none of
which `analyze` or the 663 green tests could see — three of them in the two
places this project has least ability to check: a grace period that only one
of two branches inspected, and a notification stack no device has ever run.

### 1. An expired grace period was invisible to the compliant path

`AdaptationPhaseService.recordCompliantDay` never looked at `gracePeriodEnd`.
Only `handleBreach` did. So a user who breached, let the whole 24 hours run
out and then logged a good meal **carried on as if the lapse had never
happened** — a twelve-day streak became thirteen, and the phase went with it.

The reset is lazy by design: nothing evaluates the state machine while the
user logs nothing, so an expired window is first seen on the *next*
evaluation — and that is at least as likely to be a compliant meal as a
breach. Both branches now share one `_hasExpired` check.

**Its own test hid it.** `StreakStateFixture.inGracePeriod()` defaults to an
expiry of 2026-09-10 12:00, two and a half hours *before* the service suite's
fixed `now`, so a test named *"resuming inside a grace period keeps the streak
going"* was in fact exercising a window that had already closed — and passing.
The suite now states open-versus-closed explicitly, and the fixture's doc says
why it must.

### 2. Only iOS was ever asked for notification permission

`NotificationService.requestPermission` resolved
`IOSFlutterLocalNotificationsPlugin` and nothing else. On Android 13 (API 33)
and newer, `POST_NOTIFICATIONS` is a runtime permission: nothing requested it,
the reminder was scheduled, the OS dropped it, and there was **no symptom to
chase**. macOS was the same story under a different class name. Each platform
now gets its own prompt; Windows needs no runtime grant.

### 3. The Android reminder could not have been delivered at all

Two independent reasons, both invisible to every check this repo runs:

- **`AndroidManifest.xml` declared none of what a scheduled notification
  needs.** Since `flutter_local_notifications` 16 the plugin ships only
  `POST_NOTIFICATIONS` and `VIBRATE` in its own manifest; the app must declare
  `ScheduledNotificationReceiver` itself, or the alarm fires into nothing.
  `RECEIVE_BOOT_COMPLETED` and `ScheduledNotificationBootReceiver` are what
  re-arm a pending reminder after a reboot — and the app only reschedules at
  launch, so a phone restarted overnight was silent.
- **`AndroidScheduleMode.exactAllowWhileIdle` needs an exact-alarm
  permission** the app neither declared nor requested. Without one the plugin
  logs an error and schedules *nothing*. The reminder is now `inexact`: a
  daily nudge does not need Android 14's alarm-clock privileges, and
  `USE_EXACT_ALARM` is audited on store submission.

### 4. Deleting a meal dated the breach to midnight

`MealLoggingService.deleteMeal` has no timestamp to read — the entry is gone —
so it passed the caller's date, which the diary holds stripped to midnight.
Handing that to `evaluateToday` opened a grace period expiring at midnight
*tomorrow*: a meal deleted at 22:00 bought two hours to recover instead of
twenty-four. The delete path now evaluates at the wall clock. `logMeal` keeps
using the meal's own timestamp.

### 5. The streak ring collapsed to a spinner on every save

`StreakRingWidget` branched on `isLoading`. A **refresh** is `isLoading` with
the previous value still attached, and every meal write produces one —
`AddMealBottomSheet` invalidates `todaysDailyLogProvider` the moment the save
returns. So the ring vanished behind a spinner on each save and then replayed
its 600 ms sweep from zero. The check is now `isLoading && !hasValue`.

This is the same riverpod-3 `AsyncValue` shape that cost M3 three issues,
arriving from the other side: that time the trap was `isLoading` being true
*with an error*; here it is `isLoading` being true *with a value*. **Neither
`isLoading` nor `hasError` alone is ever the whole question.**

---

## Next: M4 (#69–#74)

**Write `design/m4_preflight.md` first.** M3's twelve issues were audited
before implementation and **every one carried at least one defect** — four
would have compiled and shipped wrong behaviour, one of them silently. M1 and
M2 had the same experience. There is no reason to expect M4's text, written in
the same sitting, to be better.

Three things M4 already knows to check:

- **The onboarding route is `/onboarding/:step`**, outside the `ShellRoute`,
  and currently renders `OnboardingPlaceholder`. `app_router.dart` notes that
  #69–#74 were written against paths that did not exist.
- **`StreakState.initial()` is the seed #73 wants**, and
  `AdaptationPhaseService` already treats a null record as that seed — so
  "streak seeding" may be a no-op beyond writing the first record.
- **`NotificationService.requestPermission()` is waiting for a caller.** It
  exists, it is tested, and nothing invokes it.
