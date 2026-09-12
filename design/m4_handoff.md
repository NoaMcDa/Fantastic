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

**A seventh M4 issue existed, and is now closed as not planned.** #149 ("Add
`shared_preferences` to `pubspec.yaml`") sits outside the #69–#74 range and
was created after the rest. It was right that three issues — #73, #74 and
M8's #95 — were written against a package no issue owned; the resolution is
the other one. `pubspec.yaml` is unchanged, and #149's comment records why,
including the one claim in its own reasoning that is no longer true: the
database *is* guaranteed open before the first redirect, because `main`
awaits `openAppDatabase()` before `runApp`.

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

- ~~**The flow cannot be skipped.**~~ **Closed by #262, under #431.** Screen 1
  carries a "דלג בינתיים" `TextButton` under the CTA; it writes a
  `UserProfile.skipped()` carrying `MacroTargets.defaults`, opens the gate and
  goes to the dashboard. The model question it raised is answered the way #262
  recommended: `UserProfile`'s biometrics are **nullable** and its goal set may
  be **empty**, because the app genuinely does not know them. `OnboardingData`
  still guarantees all of it, because a *completed* flow really does have every
  answer. The profile tab says the details were not filled in rather than
  showing four dashes.
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
- ~~**The activity level is assumed sedentary.**~~ **Closed by #431.** Screen 2
  asks the question, `ActivityLevel` carries the five standard Mifflin-St Jeor
  factors, and `calculateMacroTargets` multiplies by the user's own. A record
  written before the question existed reads back as `sedentary`, which is not a
  guess — 1.2 is exactly what its targets were computed with. The same issue
  added a per-day layer on top: a day the user marks as a training day is
  measured against a fat target raised by one activity tier
  (`DailyTargetsService.forDay`), as a delta on the targets they agreed to
  rather than a recompute, so an edited number keeps its edit.
- **The goals are a set now, and two of the three change the arithmetic**
  (#431). Screen 3 is multi-select, `UserProfile.goals` is a `Set<KetoGoal>`,
  and `GoalCard` announces itself as a checkbox rather than a radio option.
  `weightLoss` applies the TDEE deficit — to the training-day bump as well —
  and `athleticPerformance` raises the net-carb target, with the weight-loss
  cap winning when both are chosen. `metabolicHealth` is still a label; the
  dashboard emphasis `ui_ux_design.md` §1c describes is post-MVP. The taxonomy
  itself was settled by the audit rather than by product — see §6.1, which is
  still worth revisiting.

- **The net-carb target is no longer a constant** (#431). It was 20 g for
  everybody while fat and protein were computed from the person;
  `OnboardingService.netCarbTargetFor` now reads
  `KetoConstants.netCarbTargetByActivity` and applies the goals, always
  clamping into 20–50 g. `KetoConstants.maxCompliantNetCarbsG` stays a protocol
  constant and is untouched (#303): the streak threshold must not move with an
  editable target.
- **Water and electrolytes still have no logging flow**, from M2.
- **`EntityNotFoundException` still has no throw site**, from M1.
- **CI does not check codegen freshness**, from M3. `cicd_plan.md` Phase 1.
- **#95's integration test opens with `SharedPreferences.getInstance()` and
  `prefs.clear()`**, which is now wrong on both halves: there are no
  preferences, and the reset an onboarding flow test needs is an empty sembast
  store. Nothing is broken today — `integration_test/` does not exist (#150) —
  but whoever picks up #95 should read `m4_preflight.md` §4 first.

---

## Post-milestone bug fixes

A later audit of the shipped M4 and M5 code found four defects in M4's half.
All four are fixed, with tests.

1. **A failed streak seed or permission prompt reported "the save failed" —
   and trapped the user.** `completeOnboarding`'s own doc comment called the
   two steps after the profile write "best-effort extras", but nothing caught
   them. Screen 4 catches `Object` and reports any throw as
   `השמירה נכשלה`, so a broken `streak_state` store told the user their
   profile had not been saved when it had, and never called `markCompleted()`
   — leaving them on the last screen of the flow for the rest of the session.
   Only the next cold start let them in, because `seedOnboardingGate` found
   the profile that had been on disk all along. Both steps are now caught.
   A swallowed seed costs one pre-filled streak; the alternative cost the
   whole flow.
2. **`Form.validate()` could skip a field the `ListView` had disposed.**
   Screens 2 and 4 put their `TextFormField`s in a lazy `ListView` under a
   `Form`. A `FormFieldState` deregisters when it is disposed, so a field
   scrolled past the 250pt cache extent is not validated — and `_onNext`
   then runs `int.parse('')` while `_onConfirm` trips the non-null assertions
   behind `positiveFinite(...)!`. At the default text scale the content is
   too short to reach that, so it did not reproduce; a large accessibility
   text scale is exactly the case that does, and one more field would be
   enough on its own. Both screens are now `SingleChildScrollView` +
   `Column`, which builds every child eagerly — the shape `SymptomLogSheet`
   already used. The regression test is structural, because whether the bug
   reproduces depends on a viewport and a text scale no fixed-size test pins
   down.
3. **A profile record that would not decode bricked the app.**
   `UserProfileMapper.fromRecord` runs inside `guardPersistence`, so a
   renamed enum value surfaces as the same `PersistenceException` a dead
   store does — and `seedOnboardingGate` let it escape into `main`'s catch,
   which shows `לא ניתן לפתוח את מסד הנתונים`. The database had opened fine,
   and there was no screen left to fix the profile from. The gate now
   swallows its own failures and stays shut, which shows onboarding: the only
   recovery path there is.
4. **`showDatePicker`'s result was applied without a `mounted` guard.**
   `context` is not used across the gap, so the lint stays quiet; `setState`
   on a disposed `State` still throws.

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
