# MVP Handoff — the feature set is complete

**All five MVP features ship.** M0 through M6 are code-complete and merged;
inside the MVP boundary only **M7 (polish)** and **M8 (CI & integration)**
remain.

This is the cross-milestone view. Each milestone has its own handoff with the
detail — `m0_handoff.md` through `m6_handoff.md` — and none of them is repeated
here. What follows is what only becomes visible with all six on the table.

| | |
|---|---|
| Tests | **1112**, all green on `main` |
| Coverage | `domain/` **99.2%**, `application/` **100%** (hand-written lines; generated `.g.dart` excluded) |
| Source | 119 hand-written `lib/` files, 94 test files |
| Gate | `analyze` clean, `dart format` clean, `flutter build web` green |

---

## What shipped

| Feature | Milestone | State |
|---|---|---|
| **Daily Macro Tracker** | M2 | Meals, totals, keto ratio, electrolytes, dashboard |
| **Adaptation Phase & Streak** | M3 | 3-phase machine, ring, calendar, grace period, 20:00 reminder |
| **Onboarding** | M4 | 4 screens, Mifflin-St Jeor targets, streak seeding, first-launch gate |
| **Symptom Diary** | M5 | Five 1–5 scales, dashboard strip, diary section |
| **Keto Lens** | M6 | Hebrew OCR → parser → classifier → verdict → prefill the diary |

Five sembast stores back them: `meals`, `daily_logs`, `symptom_logs`,
`streak_state`, `user_profile`. All five are enumerated in
`test/core/database/store_names_test.dart`, which exists because sembast creates
a store on first write — two features choosing one name would silently merge two
collections rather than fail.

---

## The finding that shaped this project

**The issue text was never right.** Not once.

All 115 issues were authored in a single sitting, before any code existed. Every
milestone that audited its issues before implementing found defects that would
otherwise have shipped:

| Milestone | The worst one |
|---|---|
| M0 | Seven corrections, catalogued only after the fact |
| M1 | The named Isar package could not open a database on web at all |
| M2 | `DailyLog.empty()` does not exist; riverpod-2 `Ref` types throughout |
| M3 | `copyWith(gracePeriodEnd: null)` is a **no-op** — the grace period would never have ended, silently, with tests passing |
| M4 | The flow's own last screen bounced the user back into onboarding **forever** |
| M5 | All four issues named `brainFogScore`, a field that has never existed |
| M6 | A **failed scan reported as `Clean Keto`** — specified explicitly, in the issue's own justification |

M6's is the one to remember. A user in a supermarket, told a product is clean
keto *because the app could not read the label*. It was in the spec.

Two structural lessons follow, and both apply to M7 and M8:

- **An audit costs hours; the defects cost a release.** Four of M3's twenty-one
  findings, three of M4's, five of M6's would have compiled and shipped wrong
  behaviour. None would have been caught by `analyze`, by CI, or by a test
  written from the same issue text that contained the defect.
- **A test written from a wrong spec passes.** M5's all-3s fixture would have
  hidden a mood score under a brain-fog label. M3's #63 shipped a permanent
  spinner and its own failure test passed, because the loading and error branches
  drew the same empty box. **Assert on what distinguishes the states**, not on
  what they have in common.

---

## The bug that cost four milestones

riverpod 3 reports a provider that failed **before ever producing a value** as
`AsyncLoading` *with an error attached*. `isLoading` and `hasError` are both
true, and the runtime type is `AsyncLoading`, never `AsyncError`:

```
runtimeType=AsyncLoading<AdaptationPhase> isLoading=true hasError=true hasValue=false
```

It arrived in four disguises, one per milestone, each costing real time:

1. **M3 #59** — `container.read(p.future)` on such a provider never settles; the
   test times out rather than failing.
2. **M3 #60** — `await ref.watch(p.future)` inside a derived provider deadlocks
   it permanently. A storage failure would have shown a spinner forever.
3. **M3 #63 / #64 / #65** — any widget checking `isLoading` before `hasError`
   shows its loading state forever.
4. **M5** — `AsyncValue.when` is loading-first internally, so the `error:` branch
   is dead code on a never-valued failure.

**The rule: check `hasError` first, always. Never match an `AsyncError()`
pattern. Never await the `.future` of a provider that can fail before its first
value.** It is in four handoffs because it was learned four times.

---

## Open defects, consolidated

Scattered across six handoffs and five issues until now.

| | Severity |
|---|---|
| **#257 — scanned macros are per 100 g but logged as the serving** | **Highest.** Scan a 30 g bar, tap through, log 100 g. Corrupts the day's macros, the keto ratio, the streak evaluation *and* the phase. Shipped with a caption asking the user to do the arithmetic |
| #234 — the 20:00 reminder fires on days already logged compliant | Noise on exactly the days the user is doing well, which is how a reminder gets switched off. Epic #7 is open on this |
| #262 — no way to skip onboarding | `UserProfile` requires every field, so there is no path past it |
| #256 — OCR accuracy unmeasured | Epic #10's DoD. Blocked on a device |
| #258 — camera/gallery adapters at 9.8% / 0% coverage | The untested edge of the one feature that cannot be tested here |
| #151, #150 | Hebrew `CFBundleLocalizations`; the `integration_test/` scaffold |
| #165 | M2's issue text still uncorrected |

Two Epics remain open on their own Definition of Done: **#7** (the reminder
suppression invariant no child issue covered) and **#10** (accuracy, unmeasurable
without a camera). **#4** remains open on the simulator. Closing them is not
paperwork — each names something genuinely undone.

---

## What has never been verified

Stated once, plainly, because it is the single largest risk in the project.

- **No iOS device and no macOS host.** `flutter run` has never executed. No
  notification has ever been delivered. Every iOS behaviour is inferred.
- **No camera.** **Nothing in this project has ever read a real Hebrew label.**
  The parser and classifier are covered near-exhaustively against fixtures — but
  a fixture is a transcription of what someone *expected* OCR to return.
- **The browser is the only real runtime exercised.** M2, M3 and M5 were driven
  end to end in Chromium, which caught bugs their test suites missed — #201's
  midnight timestamps, and M5's per-scale routing that no all-3s fixture could
  prove. **M4 and M6 were never driven in a browser**; M6 cannot be, since the
  lens does not scan there.

The browser check earns its place. It found a bug 482 passing tests had missed.
Keep doing it, and treat any milestone that skips it as less verified than its
test count suggests.

---

## What M7 inherits — and four issues that are already done

**M7's issue list is stale in the same way every other milestone's was.** Audit
it before implementing. Four of its seven issues are already satisfied or
obsolete:

| Issue | Reality |
|---|---|
| **#90** "full-screen error state for critical **Isar** open failure" | Isar is gone, and M2 already shipped `StartupFailureApp` in `main.dart` for exactly this case |
| **#93** Hebrew camera/photo usage strings | M6 shipped both in `ios/Runner/Info.plist`, rewritten into grammatical Hebrew |
| **#94** notification entitlements and permission handling | M3 shipped `NotificationService`; M4 made `completeOnboarding` its first caller |
| **#91** empty states for all list screens | M2 shipped `EmptyMealsState`; M5 shipped the symptom equivalent. Partially done |

Genuinely outstanding: **#88** (skeleton shimmer), **#89** (global error
snackbar), **#92** (app icon and launch screen), **#151** (`CFBundleLocalizations`
— verified absent).

Also carried forward from the milestone handoffs: `MealListSection` and
`ElectrolytesCard` still use the loading-first `.when` pattern; `ElectrolytesCard`
renders nothing on a day with no `DailyLog`, so a new user gets no electrolyte
guidance on day one; and the streak ring and macro card disagree on colour for
the same ratio.

**M8** is the other half of the verification gap: #95–#101 are the seven
integration tests, and #150 is the scaffold they need. They are the closest this
project can get to proving the flows end to end without a device.

---

## Outside the MVP: the Login epic

**#206–#226 (16 issues) exist and are not scheduled.** They sit outside the
M0–M8 boundary and no MVP issue depends on them.

They were authored hours before M4 merged, and **reason carefully from premises
M4 then invalidated** — that no `UserProfile` existed, that onboarding would use
`shared_preferences`, and that persistence was Isar. The issue text has since
been reconciled against what shipped; see `#226`'s own Interaction-with-M4
section for the current state and the three model conflicts left as explicit
open decisions.

The lesson generalises: **an unscheduled milestone's issue text decays against a
moving codebase.** Anything not built within days of being written needs the same
audit as M1 through M6 did.

---

## If you pick this up next

1. **#257.** It silently corrupts the numbers the whole app is built on.
2. **Audit M7 (#88–#94) and write `design/m7_preflight.md`** before implementing
   — the four stale issues above are what that audit is for.
3. **M8's integration tests (#95–#101)**, which is the only verification path
   available without hardware.
4. **Get it on a device.** Epics #4 and #10 cannot close until someone does, and
   every iOS claim in every handoff is inference until then.
