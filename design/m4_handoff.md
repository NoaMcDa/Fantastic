# M4 Handoff — Onboarding

M4 is code-complete. All six issues (#69–#74) are merged and CI is green on
`main`. The app now has a first launch: a new install collects four answers,
computes macro targets from them, lets the user disagree with the numbers,
persists the result, and never shows the flow again.

This file records what M4 shipped, what building it taught, and what M5, M6
and M7 inherit.

---

## What shipped

| Issue | What |
|---|---|
| #73 | The value objects, `UserProfileRepository` + sembast store, `OnboardingService`, `macroTargetsProvider` |
| #69 | `OnboardingScreen1` — welcome, and `OnboardingScaffold`, the shell all four share |
| #70 | `OnboardingScreen2` — biometrics, the "כבר בקטו?" toggle, `OnboardingValidators` |
| #71 | `OnboardingScreen3` — goal selection, `GoalCard`, `GoalCopy` |
| #72 | `OnboardingScreen4` — the calculated targets, editable, and the commit |
| #74 | `OnboardingGate` — the first-launch redirect, seeded in `main` |

Built in that order, not in issue order: five of the six issues reference
value objects that none of them defines, and those objects are the service's
input contract. `design/m4_preflight.md` §2 has the reasoning.

**Coverage at closure**, measured on the M4 branch:

| Scope | Lines | |
|---|---|---|
| `domain/` | 246/248 | 99.2% |
| `application/` | 422/450 | 93.8% |
| **Gate: `domain/` + `application/`** | **668/698** | **95.7%** |

Every uncovered `application/` line is generated riverpod boilerplate in a
`.g.dart`. (The figures include M5's and M6's work, which landed on `main`
in parallel.)

---

## What the audit found

`design/m4_preflight.md` is the full record. The three that mattered:

**The flow ended in an infinite redirect back into itself.** #74's plan has
`OnboardingService.completeOnboarding` calling
`ref.invalidate(hasCompletedOnboardingProvider)`. The service holds no `Ref`
and cannot. Nothing else re-read the flag, so the last screen of the flow
would write the profile, navigate to the dashboard, and be bounced straight
back to step 1 — on that navigation and on every launch after it, with no way
out. The fix is one line in screen 4 (`markCompleted()`), and it only exists
because the audit went looking.

**`await provider.future` inside a go_router redirect can hang the app on a
blank screen.** This is M3's riverpod-3 fact in a new costume: a provider that
fails before ever producing a value is `AsyncLoading` **with** an error, and
its `.future` never completes. The gate reads storage, so that is precisely
its first-value failure mode — and an awaited redirect that never returns
leaves go_router unable to resolve any route at all.

**`shared_preferences` was the wrong store and was not added.** #73 and #74
both persist through it. It is not a project dependency; it would be a second
persistence mechanism for the app's longest-lived data; and it breaks three
of `CLAUDE.md`'s layer rules rather than one — a provider calling storage
directly from `application/`, a storage handle as a service constructor
argument, and a failed write escaping as a raw platform exception with no
`guardPersistence` on the path. On web it would also split one user's data
across `localStorage` and IndexedDB, with two eviction policies.

Also worth keeping: **seeding `StreakState.initial()` is worse than a no-op.**
That value is exactly what `AdaptationPhaseService` already substitutes for a
null record, so the write changes no behaviour — while destroying the "never
had a compliant day" sentinel the calendar and the ring are built on.

---

## Conventions M5, M6 and M7 inherit

1. **The `user_profile` record's existence is the first-launch flag.** There
   is no `hasCompletedOnboarding` boolean anywhere, and adding one would give
   two sources of truth to keep in sync. Same sentinel convention as
   `StreakRepository.load()`.
2. **The onboarding gate is a synchronous `bool`, seeded once in `main`.**
   Never await anything inside a go_router redirect. Two explicit
   transitions — `seedOnboardingGate` at startup, `markCompleted()` from
   screen 4 — and no cache invalidation to get right.
3. **`MacroTargets.defaults` is the only definition of the default targets.**
   `MacroSummaryCard` used to read `KetoConstants` directly; it reads
   `macroTargetsProvider` now, which falls back to `MacroTargets.defaults`,
   which is built from those same constants. Anything else that needs a
   default target reads it from there.
4. **`OnboardingValidators.positiveFinite` is the only numeric parse in the
   flow.** `double.tryParse` accepts `Infinity` and `NaN`, neither is null and
   neither is `< 0`, so any `tryParse(...) ?? fallback` is a hole. One helper,
   so the check cannot be forgotten at one call site.
5. **A step that needs navigation data it did not get restarts the flow.**
   `onboardingStepHasData` is the route redirect's predicate and
   `onboardingScreen` is its builder; the two are tested against each other.
   `extra` is not serialisable, so this fires on every browser reload
   mid-flow.
6. **Hebrew copy for a domain enum lives in `core/constants/`** —
   `GoalCopy` next to `PhaseCopy`, with tests that every enum value has an
   entry, that the display order covers the enum exactly once, and that no two
   titles collide.
7. **Whole-day arithmetic goes through two UTC midnights.** Subtracting two
   local dates across a daylight-saving change gives 23 or 25 hours and
   `inDays` truncates — which silently loses or gains a day of streak twice a
   year.
8. `test/helpers/pump_onboarding.dart` is the harness for a screen whose job
   is to navigate; `test/helpers/onboarding_gate_override.dart` is what any
   test pumping the whole app needs so it does not land in onboarding.

---

## Gotchas worth keeping

- **A conflicted PR gets no CI run at all.** GitHub builds `pull_request`
  workflows from the merge ref, and a PR with conflicts has none — so the
  checks list stays empty, indefinitely, with no error anywhere. Twenty
  minutes went into waiting for a run that was never going to start. Merge
  `main` in *before* wondering why CI is quiet.
- **sembast futures do not complete inside `testWidgets`.** A widget test
  that awaits a real in-memory database hangs — not fails, hangs, for
  `pumpAndSettle`'s ten-minute default per call. `onboarding_flow_test.dart`
  uses hand-written in-memory repositories instead. Bound `pumpAndSettle` with
  an explicit short timeout in any test that drives a screen with a spinner on
  it, or a stuck provider costs ten minutes per call instead of failing.
- **A second `pumpWidget` of the same widget type updates the tree rather
  than replacing it.** Relaunching the app in one test with a different
  `ProviderContainer` trips a framework `!_dirty` assertion. Pump a
  `SizedBox.shrink()` in between: a relaunch has to be a relaunch.
- **The date picker's confirm button is `אישור`, not `OK`**, under the
  Hebrew locale the app runs in. A test tapping `find.text('OK')` finds
  nothing and reports it as a missing widget.
- **`verify` consumes the recorded call** — M3 recorded this and it bit again.
  A mocktail capture helper is callable once per test; hold the result.
- A `Semantics` widget's properties can be asserted directly
  (`tester.widget<Semantics>(...).properties.selected`) without enabling the
  semantics tree, which is simpler and less version-sensitive than
  `getSemantics(...).hasFlag(...)`.

---

## Epic #8's Definition of Done

| Item | Status |
|---|---|
| All child issues closed and PRs merged | ✅ #69–#74, six PRs |
| `flutter analyze` — zero issues | ✅ |
| `flutter test` — zero failures | ✅ |
| Onboarding shown exactly once on fresh install | ✅ tested through the real router and again end to end |
| Dashboard macro targets match what onboarding set | ✅ — **no child issue asked for this**; folded into #73 |
| Streak seeded correctly from past start date | ✅ — **no child issue asked for this either**; the toggle went into #70 and the seeding into #73 |

Architectural invariants: `OnboardingService` imports no Flutter widgets; the
flag is persisted, in sembast rather than the Isar the Epic names; and the
target calculation is tested for both sexes and all three goals.

**Two of the six DoD items had no child issue at all.** The Epic asked for the
dashboard to show what onboarding set, and for the streak to be seeded from a
past start date; #69–#74 delivered neither, and shipping them as written would
have computed personalised targets, persisted them, and displayed the
hard-coded ones. Both were folded into M4 rather than left for the Epic to
fail on. This is the third milestone running whose Epic carries invariants its
own decomposition never covered.

---

## Not verified

- **No browser run.** M3 closed by driving the feature in Chromium; no browser
  is installed in this environment, so M4 closed on
  `onboarding_flow_test.dart` instead — the whole flow driven through the real
  `FantasticApp` and the real router, over in-memory repositories. That covers
  screen-to-screen wiring, the gate and the persisted profile. It does not
  cover rendering, RTL on a real canvas, or IndexedDB.
- **The notification prompt.** `requestPermission()` finally has a caller, but
  no iOS device or macOS host exists here, so nothing has confirmed a prompt
  ever appears. This joins M3's standing blocker.
- **`flutter run` on an iOS simulator**, still, from M2.

---

## Known gaps M5, M6 and M7 inherit

- **The flow cannot be skipped.** `mvp.md` §4 says onboarding is "skippable
  (defaults used if skipped)"; no child issue asked for it and Epic #8's own
  scope list does not carry the line either, so it fell between the two
  documents. A user who wants to look around before handing over their weight
  cannot. **Filed as #262**, which also records the model question a skip
  raises: `UserProfile`'s biometrics are non-null and a skipped profile has
  none of them.
- **There is no way to change the targets afterwards.** The profile screen is
  still `ProfilePlaceholder`, and Epic #8 puts post-onboarding profile editing
  out of scope. The targets a user sets in their first thirty seconds are
  permanent until someone builds that screen. `UserProfile.copyWith` and the
  repository's `save` are ready for it.
- **A browser reload mid-flow restarts it.** `extra` is not serialisable, so
  steps 3 and 4 lose their answers on refresh and the route redirects to step
  1. Carrying the answers in a provider instead would fix it; it is a larger
  change than M4's scope.
- **0.8 g/kg of *total* body mass is a low protein target.** #73's prose says
  lean mass, its snippet says total mass, and nothing in the flow collects
  body fat. The snippet shipped. It puts a 70 kg user at 56 g against the 80 g
  `KetoConstants.defaultProteinTargetG` the dashboard showed before. This is a
  product question, not a bug — `m4_preflight.md` §6.5.
- **The activity level is assumed sedentary.** The flow asks no activity
  question, so an active user's TDEE is understated. They can edit the number
  on screen 4, which is the only reason that is acceptable.
- **The three goals do nothing but `weightLoss`.** `metabolicHealth` and
  `athleticPerformance` are recorded and have no effect; the dashboard
  emphasis `ui_ux_design.md` §1c describes is post-MVP. The taxonomy itself
  was settled by the audit rather than by product — see §6.1, which is worth
  revisiting.
- **Water and electrolytes still have no logging flow**, from M2.
- **`EntityNotFoundException` still has no throw site**, from M1.
- **CI does not check codegen freshness**, from M3. `cicd_plan.md` Phase 1.

---

## Next

M5 and M6 were built in parallel with this milestone and have their own
handoffs. M7 (#88–#94) is polish, and inherits the list above; M8 (#95–#102)
is CI and integration, and `integration_test/` still does not exist — but
`test/features/onboarding/onboarding_flow_test.dart` is a reasonable template
for what the onboarding flow's integration test should assert once it does.

**Write `design/m7_preflight.md` first.** M4's six issues were audited before
implementation and **every one carried at least one defect**; three would have
compiled and shipped broken behaviour. M1, M2 and M3 had the same experience.
There is no reason to expect M7's text, written in the same sitting, to be
better.
