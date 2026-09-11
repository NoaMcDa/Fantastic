# M4 Pre-flight — corrections to the M4 issue text

Read this before picking up any M4 issue (#69–#74).

This is the fifth such file. `m0_handoff.md` catalogued seven things the M0
issue text got wrong; `m1_preflight.md`, `m2_preflight.md` and
`m3_preflight.md` did the same for their milestones. `m3_handoff.md` closed
with a standing instruction: *audit M4's six issues against the shipped code
before implementing, and write the preflight from what that finds.*

That audit is done. **All six issues carry at least one defect.** Three would
compile and ship broken behaviour, and one of those is the worst kind: the
last screen of the flow writes the "onboarding complete" flag, navigates to
the dashboard, and is immediately bounced back into onboarding — forever, on
every launch, with no way out.

M4's issues were written in the same sitting as M0's, M1's, M2's and M3's —
before any of it met a build, **before Isar was replaced by sembast**, and
before the router, the theme, the dashboard or the streak machine existed in
the shapes they now have.

**The issues have not been rewritten.** This file is the correction layer.

Audited: **#69–#74, all six, in full**, plus Epic #8.

---

## Part 1 — Defects that compile and ship wrong behaviour

### 1.1 The flow ends in an infinite redirect back into itself

The single most expensive trap in M4, and the one a green test suite will not
find.

#74 gates the app on a `hasCompletedOnboardingProvider`. Its own
"Integration Points" says:

> `OnboardingService.completeOnboarding` calls
> `ref.invalidate(hasCompletedOnboardingProvider)` after saving the flag.

`OnboardingService` cannot do that. Its constructor (#73) takes a
`StreakRepository` and a storage handle; it holds no `Ref`, and a service in
`application/` that reached for one would be reaching past its own layer.
Nothing else invalidates anything: #72's `_onConfirm` awaits
`completeOnboarding` and then calls `context.go('/dashboard')`.

So the sequence that actually runs is:

1. the flag is written to storage,
2. the provider still holds its cached `false`,
3. the redirect fires on the navigation and sends the user to
   `/onboarding/1`,
4. and it keeps doing that, because nothing ever re-reads the flag.

**Resolution: the gate is an explicitly-flipped, synchronous `bool`.**

```dart
// lib/features/onboarding/application/providers/onboarding_gate.dart
@Riverpod(keepAlive: true)
class OnboardingGate extends _$OnboardingGate {
  @override
  bool build() => false;          // safe default: a fresh install onboards

  void markCompleted() => state = true;
}
```

`main` seeds it from the profile record it reads at startup; screen 4 flips it
after `completeOnboarding` returns and before it navigates. Both transitions
are explicit, both are one line, and neither depends on a cache invalidation
firing in the right order.

### 1.2 The gate as specified can hang the app on a blank screen

#74's redirect is asynchronous and reads a future:

```dart
redirect: (context, state) async {
  final container = ProviderScope.containerOf(context);
  final completed = await container.read(hasCompletedOnboardingProvider.future);
  ...
}
```

`GoRouterRedirect` is `FutureOr<String?> Function(...)` in go_router 14.8.1,
so this compiles. It is still wrong twice over.

**First, `await ...future` is the riverpod-3 trap that cost M3 three issues.**
A provider that fails *before ever producing a value* is `AsyncLoading` **with
an error attached** — `isLoading` and `hasError` are both true — and its
`.future` never completes. `hasCompletedOnboardingProvider` reads storage, so
a storage failure is exactly its first-value failure mode. The redirect never
returns, go_router never resolves the initial route, and the user gets a blank
screen with no error, no log and no way forward. See `m3_handoff.md`
§"The one thing that cost the most".

**Second, `ProviderScope.containerOf(context)` is unnecessary and its default
`listen: true` registers an inherited-widget dependency from a context that is
not building.** The router is itself built by a provider —
`appRouter(Ref ref)` — so `ref` is already in scope.

**Resolution:** the redirect is synchronous and reads the gate from the `ref`
the router provider already has. Nothing is awaited inside routing at all; the
one asynchronous read happens once, in `main`, alongside `openAppDatabase()`.

```dart
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) => GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final completed = ref.read(onboardingGateProvider);
    final onOnboarding = state.matchedLocation.startsWith('/onboarding');
    if (!completed && !onOnboarding) return '/onboarding/1';
    if (completed && onOnboarding) return '/';
    return null;
  },
  routes: [ /* unchanged */ ],
);
```

The second clause is not in the issue and is needed: without it, a returning
user who deep-links to `/onboarding/2` re-runs the flow and overwrites their
targets.

### 1.3 Seeding `StreakState.initial()` is worse than a no-op

#73 finishes `completeOnboarding` with:

```dart
await _streakRepo.save(StreakState.initial());
```

`StreakState.initial()` is `const StreakState()` — every field at its default.
`AdaptationPhaseService._load()` already substitutes exactly that for a null
record, so the write changes no behaviour anywhere in the app.

It does change one thing, and for the worse. `StreakRepository.load()`
documents null as **the first-launch sentinel** — "the user has never
completed a compliant day". Writing a zeroed record destroys the distinction
between *never started* and *streak reset to zero*, which is the distinction
`StreakCalendarWidget` and the ring are built on (`m3_handoff.md`
convention 4).

**And the seeding the Epic actually asks for is in no child issue at all.**
Epic #8's Definition of Done requires *"Streak seeded correctly from past
start date"*; `design/ui_ux_design.md` §1b specifies a **"כבר בקטו?"** toggle
with a start-date picker; `design/tasks.md` M4 repeats it twice, once as
screen 2's acceptance criterion and once as `OnboardingService`'s. #70 has no
toggle, #73 has no date, and #72 never passes one.

**Resolution.** #70 gains the toggle and the date picker; #73 gains real
seeding; the unconditional `initial()` write is dropped.

The seeding rule, decided in this audit and now the one definition:

| Input | Result |
|---|---|
| No start date given | **no write at all** — the null sentinel is preserved |
| Start date is today or later | no write — day 1 has not been banked yet |
| Start date *D*, today *T* | `currentStreak = highestStreak = T − D` (whole days completed **before** today), `lastCompliantDate = T − 1 day`, phase from the streak |

Counting completed days rather than elapsed days leaves **today still
winnable**: the user's first compliant meal advances the streak from *N* to
*N+1* instead of finding the day already banked and doing nothing. It also
makes "started today" collapse cleanly onto `StreakState.initial()` — which is
why that case writes nothing.

The phase comes from `AdaptationPhaseService.currentPhase(state)`, never from
a second copy of the 8/28 thresholds (`m3_handoff.md` convention 1).

### 1.4 `double.tryParse` is not validation, and #72 relies on it as if it were

```dart
fatG: double.tryParse(_fatCtrl.text) ?? _targets.fatG,
```

`m2_handoff.md` already recorded this for the meal form: **`double.tryParse`
accepts `Infinity` and `NaN`**, and neither is null, so the `??` fallback
never fires. It also accepts `0` and negatives. Any of those is then persisted
as a macro target and divides through every progress bar on the dashboard —
`0/0` and `x/Infinity` both render as a bar that never moves, and a negative
target renders one that is always full.

**Resolution:** screen 4 is a `Form` with the same positive-finite validator
screen 2 uses, and confirm is a no-op until it validates. The `??` fallback
stays as a belt-and-braces default, not as the validation.

---

## Part 2 — Things that do not exist

Five of the six issues reference types that nothing defines — in `lib/`, in
any other M4 issue, or anywhere in the repository.

| Referenced by | Symbol | Status |
|---|---|---|
| #70, #73 | `BiologicalSex` | defined nowhere |
| #70, #71 | `PartialOnboardingData` | defined nowhere; `withGoal` named, never specified |
| #71, #72, #73 | `OnboardingData` | defined nowhere |
| #71 | `GoalCard` | called "a custom widget" in the Approach table and never written |
| #72 | `onboardingServiceProvider` | #73 names it in prose, never declares it |
| #69 | `assets/images/onboarding_welcome.png` | no such file, and `assets/images/` is not declared in `pubspec.yaml` — `Image.asset` throws at paint time, so the issue's own three widget tests fail |

`KetoGoal` and `MacroTargets` are the only two the text defines, in #71 and
#73 respectively.

**Consequence for build order.** #73 is written as if it were independent of
the screens ("Blocked by: #32, #43"), but it consumes `OnboardingData`, which
#70 and #71 build. The dependency actually runs the other way: the value
objects are the service's input contract. **All of them ship in #73**, and the
screens consume them. Build order is therefore

> **#73 → #69 → #70 → #71 → #72 → #74**

not the issue numbering.

**The welcome asset.** #69's DoD allows a placeholder, but committing a
meaningless binary is worse than not committing one: it cannot be reviewed, it
does not respond to the dark palette, and it will be replaced wholesale the
day a real illustration exists. Screen 1 ships a composed hero — Material
icons on a themed gradient — and no image asset. `pubspec.yaml` is untouched.

---

## Part 3 — Snippets that do not compile

### 3.1 riverpod 3 removed the generated `Ref` types

Fifth milestone in a row.

```dart
hasCompletedOnboarding(HasCompletedOnboardingRef ref)   // #74 — WRONG
```

Bare `Ref`, as every shipped provider already writes.

### 3.2 `state.extra` never reaches the screens that require it

#71 and #72 declare `required this.partial` / `required this.data`. The
shipped route is

```dart
GoRoute(
  path: '/onboarding/:step',
  builder: (_, state) =>
      OnboardingPlaceholder(step: onboardingStep(state.pathParameters)),
),
```

— one builder, no arguments, no `extra`. Nothing in any M4 issue wires the
`extra` the screens are pushed with into the constructors that require it, so
as written the flow does not compile once the placeholder is replaced.

**Resolution.** The route builder switches on the step and casts `state.extra`
with a type test, and the route carries a `redirect` that sends a step with
missing or wrong-typed `extra` back to `/onboarding/1`. That matches the
policy the shipped `onboardingStep` helper already documents for a bad deep
link — *start the flow, do not crash the app*.

**Known limitation, worth stating once:** `extra` is not serialisable and does
not survive a browser reload. Reloading the page mid-flow restarts it at step
1. Carrying the answers in a provider instead would fix it and is a larger
change than M4's scope; noted in the handoff.

### 3.3 `_streakRepo` / `_prefs` initializer pairing

#73 writes `required StreakRepository streakRepo` into a private `_streakRepo`
field. `m2_handoff.md` records why `MealLoggingService`'s injected
collaborators are public instead: Dart forbids a named parameter starting with
`_`, and the rename-to-private pairing trips `prefer_initializing_formals`.
Follow the shipped convention — public `final` fields, initializing formals.

### 3.4 Undeclared identifiers and missing imports

#72 uses `MacroTargets`, `OnboardingData` and `onboardingServiceProvider` with
no imports; #71 uses `PartialOnboardingData` with none; #70 uses
`BiologicalSex` and `PartialOnboardingData` with none. Mechanical, listed for
completeness.

---

## Part 4 — `shared_preferences` is the wrong store, and it is not needed

#73 and #74 both persist through `shared_preferences`. It is **not a
dependency of this project** and it should not become one.

**It is a second persistence mechanism for one feature's data.** Everything
else the app stores — meals, daily logs, symptom logs, the streak — is a
sembast record behind a repository interface, with a mapper, a contract test
and a name pinned in `test/core/database/store_names_test.dart`. Onboarding's
output is the *most* long-lived data in the app; it is the last thing that
should sit outside that.

**It breaks three of the layer rules in `CLAUDE.md`, not one.**

- #74's provider calls `SharedPreferences.getInstance()` directly from
  `application/` — *"No new provider calls the database directly — always
  through a service"*.
- #73's service takes a `SharedPreferences` handle as a constructor argument.
  That is a storage handle in the application layer, which is precisely what
  the sembast `Database` is never allowed to be.
- *"No storage error escapes `data/`"*. A failed preference write inside
  `OnboardingService` escapes as a raw platform exception, not a
  `PersistenceException`, and no `guardPersistence` sits anywhere on the path.

**On web it splits the user's data across two eviction policies.**
`shared_preferences` is `localStorage`; sembast_web is IndexedDB. A browser
that clears one and not the other leaves targets without a profile, or a
completed-onboarding flag with no streak.

**And it buys nothing.** sembast already has exactly the shape this needs —
the `streak_state` store is a singleton record at key 0, with the same
"record absent means first launch" sentinel the gate wants.

**Resolution: a `user_profile` store, behind a repository.**

```
lib/features/onboarding/
  domain/models/         biological_sex.dart, keto_goal.dart,
                         macro_targets.dart, onboarding_data.dart,
                         user_profile.dart
  domain/repositories/   user_profile_repository.dart
  data/mappers/          user_profile_mapper.dart
  data/repositories/     sembast_user_profile_repository.dart
  data/providers.dart
  application/           onboarding_service.dart, providers/
  presentation/screens/  onboarding_screen1..4.dart
  presentation/widgets/  goal_card.dart
```

`UserProfile` carries the biometrics, the goal, the chosen targets and the
keto start date. **The record's existence is the first-launch flag** — the
same sentinel convention `StreakRepository.load()` already documents — so
there is no separate boolean to keep in sync with it.

Epic #8's invariant reads *"First-launch flag persisted in Isar (or
`shared_preferences`) — not in memory"*. sembast is Isar's successor in this
codebase (`design/web_support.md`), the flag is persisted, and the invariant
is met. The parenthetical is stale, like every other Isar reference in the
M0–M4 issue text.

---

## Part 5 — Where the issue text would regress shipped code

### 5.1 #74 rewrites the whole `GoRouter` literal

Its snippet is `GoRouter(initialLocation: ..., redirect: ..., routes: [ /*
existing routes */ ])`. Pasted, it drops the `/adaptation/phase` redirect, the
`/dashboard` alias, the `errorBuilder`, and the three v1.1 placeholder routes
— everything `app_router.dart` gained after the issue was written. **#74 adds
one `redirect:` parameter to the shipped literal. It does not replace it.**

### 5.2 `initialLocation: '/dashboard'`

The shipped router uses `'/'`, `kTabPaths` lists `'/'`, and `AppShell`'s
active-tab matching keys on it. `/dashboard` exists only as an alias that
redirects to `'/'` — added, per its own comment, *because* downstream issues
including #74 address the dashboard by that name. Setting it as
`initialLocation` puts a non-tab path into the router's initial state and adds
a redirect hop to every cold start, to reach the location it already had.
**Keep `'/'`.** For the same reason #72's `context.go('/dashboard')` becomes
`context.go('/')`.

### 5.3 The dashboard never reads the targets onboarding computes

`MacroSummaryCard` renders against `KetoConstants.defaultFatTargetG` and
friends, with a comment saying M4 replaces them. Epic #8's DoD requires
*"Dashboard macro targets match the values set in onboarding"* — and **no
child issue touches the dashboard**. #72 saves the targets and the flow ends.

Shipped as written, M4 would compute personalised targets, persist them, and
display the hard-coded ones. **A `macroTargetsProvider` ships with the
repository in #73, and `MacroSummaryCard` reads it**, falling back to the
`KetoConstants` defaults when no profile exists.

### 5.4 Net carbs: "not user-adjustable" vs. an editable field

#73: *"Net carbs fixed at 20g for induction — this is a keto protocol
constraint, not user-adjustable."* #72 renders it in an editable
`TextFormField` and saves whatever is typed.

**The editable field wins.** The screen's entire purpose is "calculated
targets (editable)", both `mvp.md` and `tasks.md` say editable, and a target
the dashboard measures the user against has to be one the user agreed to. 20 g
remains the *calculated default*.

### 5.5 Digit runs in an RTL layout

#72 renders `toStringAsFixed(0)` values into `TextEditingController`s and
labels with no direction. Every bare digit run inside the RTL layout needs
`textDirection: TextDirection.ltr` or `120` renders as `021`
(`m3_handoff.md` convention 6, three widgets in M3). Text *fields* handle
their own content, but any digit rendered as a `Text` — the calculated
summary, the streak preview — needs it.

---

## Part 6 — Stale, contradictory and unnumbered

### 6.1 The three goals are three different sets

| Source | Goals |
|---|---|
| #71 (enum + copy) | ירידה במשקל · בריאות מטבולית · ביצועים ספורטיביים |
| `ui_ux_design.md` §1c | ירידה במשקל · שיפור אנרגיה ומיקוד · ניהול מצב רפואי |
| `mvp.md`, `tasks.md` | weight loss · energy · medical |

**#71's set ships**, because it is the one with an enum
(`KetoGoal { weightLoss, metabolicHealth, athleticPerformance }`) that #73
codes against, and because only `weightLoss` changes the arithmetic — the
other two are labels today. `ui_ux_design.md` §1c is corrected to match in the
same change that adds this file.

This is a product decision made by an audit, not by product. It is worth
revisiting: "ניהול מצב רפואי" (medical management) is a materially different
user from "ביצועים ספורטיביים" (athletic performance), and the design doc
intended the goal to steer the dashboard's emphasis — which is post-MVP either
way.

### 6.2 The CTA copy contradicts the UX spec on both ends

| Screen | Issue text | `ui_ux_design.md` |
|---|---|---|
| 1 | `התחל` | `בואו נתחיל` |
| 4 | `אישור — נתחיל!` | `התחל את המסע` |

**The UX spec wins** — it is the document the whole app's Hebrew is written
against, and `tasks.md` agrees with it on screen 1.

### 6.3 "כבר יש לי חשבון"

`ui_ux_design.md` §1a puts an "I already have an account" sub-link on the
welcome screen. There are no accounts: Epic #8 lists *"Social login / account
creation"* as explicitly out of scope. Dropped, and the line is removed from
the design doc.

### 6.4 Electrolyte targets on screen 4

`ui_ux_design.md` §1d shows Na/K/Mg targets alongside the macros. They are
**per-phase, not per-user** — `ElectrolyteConstants`, owned by
`ElectrolyteAdvisor`, and `m3_preflight.md` §4.2 already refused a second
hand-written copy of them. Nothing about onboarding's inputs changes them, so
there is nothing to edit and nothing to save. Out of scope; the dashboard's
electrolytes card is where they belong.

### 6.5 Protein is specified two ways

#73's Approach: *"Protein = 0.8 g × **lean body mass**"*. Its snippet:
`(data.weightKg * 0.8)` — **total** body mass. There is no body-fat input
anywhere in the flow, so lean mass is not computable. **The snippet ships**
and the prose is wrong.

Worth flagging rather than silently changing: 0.8 g/kg of total mass is at the
low end of keto protein guidance (1.2–1.6 g/kg of *lean* mass is the usual
range), and it puts a 70 kg user at 56 g against the 80 g
`KetoConstants.defaultProteinTargetG` the dashboard shows today. The formula
is implemented as specified; the number is a product question.

### 6.6 The fat target is not guaranteed positive

#73's own edge case is *"Very light weight (40 kg) → fat target is always
positive"*. Nothing in the arithmetic enforces that — it is a subtraction, and
a sufficiently low TDEE against a fixed 20 g carb floor produces a negative
remainder. It happens not to go negative anywhere inside the validated input
ranges (age 10–120, positive weight and height), but "happens not to" is not
an invariant. A floor is applied, and the test asserts the floor rather than
the luck.

### 6.7 Misplacements and stale references

| Written in | Says | Actually |
|---|---|---|
| `tasks.md` M4 | `OnboardingService` lives in `dashboard/application/` | `onboarding/application/` — #73 has it right |
| Epic #8 | first-launch flag in **Isar** | sembast; see Part 4 |
| #74 Coverage | "ProviderContainer + **mock SharedPreferences**" | `SharedPreferences.getInstance()` is static and mocktail cannot stub it; moot once the store is sembast |
| #69 "Why Now" | "All M3 issues must be closed" | they are — #57–#68 all merged |
| #73 "Blocked by #32, #43" | correct, both closed | — |

### 6.8 Notification permission has no issue at all

`m3_handoff.md` closes on it: `NotificationService.requestPermission()`
exists, is tested, and **nothing calls it**. `design/tasks.md` line 261 says
*"Permission request shown after onboarding completes"*. No M4 issue mentions
it.

**It ships in #73**, at the end of `completeOnboarding` — the moment the user
has just told the app what they want from it, which is the only moment the
prompt is worth spending. A no-op on web and on any platform where
`initialise()` returned false; a refusal is not an error and does not fail the
onboarding write.

---

## Part 7 — What M4 must code against

The shipped API, so no issue has to guess.

```dart
// lib/features/adaptation/domain/models/streak_state.dart
StreakState({currentStreak = 0, highestStreak = 0, phase = induction,
             lastCompliantDate, inGracePeriod = false, gracePeriodEnd})
StreakState.initial()
copyWith({..., clearLastCompliantDate = false, clearGracePeriodEnd = false})

// lib/features/adaptation/domain/repositories/streak_repository.dart
Future<StreakState?> load();      // null = never had a compliant day
Future<StreakState>  save(StreakState state);
Stream<StreakState?> watch();     // fires immediately

// lib/features/adaptation/application/adaptation_phase_service.dart
AdaptationPhase currentPhase(StreakState state);   // the only 8/28 definition
static const int fatAdaptedFromDay = 8, deepKetosisFromDay = 28;

// lib/core/services/notification_service.dart
Future<bool> initialise();        // false on web
Future<bool> requestPermission(); // false on web; nothing calls it yet

// lib/core/constants/keto_constants.dart
KetoConstants.defaultFatTargetG      // 150.0  — the fallback M4 replaces
KetoConstants.defaultNetCarbTargetG  //  20.0
KetoConstants.defaultProteinTargetG  //  80.0

// lib/core/router/app_router.dart
const kTabPaths = ['/', '/lens', '/diary', '/adaptation', '/profile'];
const int kOnboardingStepCount = 4;
int onboardingStep(Map<String, String> pathParameters);  // clamps to 1
```

Providers already wired: `streakRepositoryProvider`,
`adaptationPhaseServiceProvider`, `notificationServiceProvider`,
`todaysDailyLogProvider(date)`, `appRouterProvider`, `databaseProvider`
(overridden in `main`).

Conventions inherited and not restated in any M4 issue: `pumpApp` is the
widget-test harness; fixtures live in `test/fixtures/`; every repository
method wraps its storage call in `guardPersistence`; enums are stored by
`.name`; `DateTime` is stored as `millisecondsSinceEpoch`; every number is
decoded through `num`; a new store name is added to
`test/core/database/store_names_test.dart` or two features can silently share
one collection.

---

## Summary — before starting M4

1. **Build order is #73 → #69 → #70 → #71 → #72 → #74** (Part 2). The value
   objects the screens need are the service's input contract and ship with it.
2. **No `shared_preferences`.** A `user_profile` sembast store behind a
   repository, record-exists as the first-launch flag (Part 4).
3. **The gate is a synchronous `bool` flipped explicitly**, seeded in `main`
   and flipped by screen 4. Never `await ...future` inside a redirect
   (§1.1, §1.2).
4. **Seed the streak from the start date, or do not write at all** (§1.3).
   Never write `StreakState.initial()` over the null sentinel.
5. **Two Epic #8 DoD items have no child issue** — the past-start-date seeding
   (§1.3) and the dashboard reading the persisted targets (§5.3). Both are
   folded into M4 rather than left for the Epic to fail on.
6. `flutter analyze` and `flutter test` catch nothing in Part 1. CI catches
   nothing in Part 1. Only a test written against the corrected behaviour
   does.
