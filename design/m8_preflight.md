# M8 Pre-flight — end-to-end tests for every shipped feature, and the CI slot that runs them

Status: **the harness, the CI job and nine of the eleven flows are now
implemented** — see **Part 10**, which also records the three defects the
suite found on its first runs and the two corrections implementing it forced
on this document (§6.2 and §6.5 were both wrong). The audit in Parts 1–9 is
kept as written: it is the record the flow issues have to be corrected
against.

M8 is eight issues: seven flow tests (#95–#101), the harness they need (#150),
and the CI workflow (#102, already shipped and closed as Phase 0). This
document does for M8 what `m1_preflight.md` through `m6_preflight.md` did for
their milestones: it audits the issue text before anyone writes against it, and
settles the one question the whole milestone rests on — **where do these tests
actually run?**

Read Part 0 first. It changes the answer every other design document gives.

---

## Part 0 — Where e2e tests run: the question, measured

### 0.1 What every existing document says

| Source | Claim |
|---|---|
| `design/tests.md` §Integration Tests | "Integration tests run on an **iOS simulator**" |
| `design/tests.md` §CI Integration | "run **nightly** on a simulator (not per-PR — too slow)" |
| `CLAUDE.md` §CI workflow | "scoped to run nightly on an iOS simulator, not per-PR" |
| `design/cicd_plan.md` §6.5 | `integration.yml`, `macos-latest`, `cron: '0 2 * * *'` |
| `design/cicd_plan.md` §7.1 | Phase 3 **parked**: "no complete user flows to click through" |
| `design/cicd_plan.md` §8 | Nightly macOS ≈ **6,000 effective min/mo — 3× the entire free tier** |
| #95, #96, #97, #99, #100, #101, #150 | every Definition of Done says "passes on iOS simulator" |
| `design/mvp_handoff.md` | "No iOS device and no macOS host. `flutter run` has never executed." |

Those five facts compose into a deadlock: the tests require a simulator, the
simulator requires a Mac, no Mac exists, and the CI form of it costs 3× the
free tier. That is why Phase 3 was parked, and it is why M8 has not started.

**The deadlock is false.** Both of its premises — that these flows need a
simulator, and that the flows do not exist yet — are now wrong.

### 0.2 What was measured

Environment: Flutter **3.47.3** (Dart 3.13.3), Linux x64, **no display, no
simulator, no browser, no Android SDK** — the same shape as `ubuntu-latest`.
The repository was copied to a scratch directory, `integration_test:` was added
to `dev_dependencies`, and the flows below were written against the **real**
app: the real `FantasticApp`, the real `GoRouter`, the real Riverpod graph, the
real repositories, over a real in-memory sembast database.

| # | Question | Command | Result |
|---|---|---|---|
| 1 | Do integration tests run with no device? | `flutter test integration_test/x_test.dart` | ✗ `No supported devices connected` |
| 2 | With the headless tester? | `flutter test -d flutter-tester integration_test/x_test.dart` | ✓ **passes, 3 s** |
| 3 | Does real sembast complete under that binding? | in-memory factory + the real repositories | ✓ writes and reads complete; no hang |
| 4 | Can a test drive the whole onboarding flow? | 4 screens, real inputs | ✓ targets computed **149 / 20 / 64 g** |
| 5 | …then log a meal and see the day update? | FAB → sheet → save | ✓ card reads `50/149ג׳`, ratio `10.0/2.0` |
| 6 | …and does the streak react? | same test, no extra setup | ✓ ring reads **1 יום**, badge `שלב ההסתגלות` |
| 7 | Do all five tabs open? | tap each `NavigationBar` label | ✓ incl. the lens tab's no-camera state |
| 8 | Can `test/fixtures/` be reused? | `import '../../test/fixtures/fixtures.dart'` | ✓ relative import resolves |
| 9 | Two flow files in one invocation? | `flutter test -d flutter-tester integration_test/` | ✗ **second file always fails** (§6.1) |
| 10 | One aggregator file, a group per flow? | `flutter test -d flutter-tester integration_test/app_test.dart` | ✓ **4 tests, 14 s test time, 31 s wall** |

Total wall-clock for the full-flow test (onboarding → dashboard → meal →
streak): **12 seconds**, cold.

### 0.3 What follows

**The e2e suite runs on `ubuntu-latest`, per PR, in the pipeline that already
exists.** No macOS runner, no 10× minute multiplier, no nightly-only
compromise, no Apple Developer account, and nothing parked behind hardware
nobody has.

That retires, in order:

- `design/cicd_plan.md` §7.1's Phase 3 parking rationale — **both halves**. The
  flows exist now (M2–M6 shipped them), and the cost argument was about macOS
  minutes that are no longer spent. §8's "3× the free tier" applies to a
  simulator job this plan does not propose.
- Every "passes on iOS simulator" line in #95–#101 and #150.
- `design/tests.md`'s "too slow for per-PR" — 14 seconds is not too slow.

`flutter-tester` is Flutter's headless engine: a real Dart VM, a real widget
tree, a real 800×600 surface, real timers. What it does not have is **platform
plugins** — and that boundary is exactly where this plan stops (§0.4).

### 0.4 What this tier can never prove — stated plainly, up front

The project's worst recurring failure mode is a test that passes for a reason
that has nothing to do with the behaviour it names (`mvp_handoff.md`: "a test
written from a wrong spec passes"). So, explicitly:

| Not covered, and will not be | Why |
|---|---|
| ML Kit Hebrew OCR | Native plugin. Unavailable headless, unavailable on web. **Nothing in this project has ever read a real label** and this changes none of that (#256) |
| Camera capture, torch, permission prompts | `camera` plugin; the headless run lands on `lens_camera_problem` (§4.7) |
| Gallery import | `image_picker` plugin — no platform channel |
| Notification delivery and the 20:00 reminder | `flutter_local_notifications`; already a no-op on web (#234) |
| `path_provider` / the real on-disk database | The harness injects an in-memory store deliberately |
| IndexedDB / `sembast_web` | Browser-only. A Chrome tier could cover it — §5.4 |
| iOS rendering, fonts, safe areas, launch screen | Needs a device. Epic #4 stays open |

**A green e2e suite is not evidence the app works on an iPhone.** It is
evidence that the flows, the routing, the provider graph and the persistence
contracts hold end to end. That is a large gap in this project's verification
story and it is worth closing now; it is not the whole gap.

---

## Part 1 — The harness (#150, re-scoped)

### 1.1 What #150 gets wrong

| # | #150 says | Reality |
|---|---|---|
| 1 | "Boots the real `main()` against a real **Isar** instance" | Isar is gone (`design/web_support.md`). sembast, injected |
| 2 | The smoke test calls `app.main()` | `main()` calls `openAppDatabase()` → `path_provider` → **`MissingPluginException` headless**, and on a device it would use the *real* user database, so tests would share state and leak between runs |
| 3 | "passing on an iOS simulator" | §0.2. `-d flutter-tester`, on Linux |
| 4 | `flutter test` must not pick up `integration_test/` — "confirm rather than assume" | ✓ Confirmed: `flutter test` globs `test/` only. The per-PR gate is unaffected |
| 5 | One smoke file is the deliverable | The deliverable is the **harness plus the aggregator**; a smoke test that proves nothing beyond `pub get` is not worth a file |

### 1.2 No production seam is required — and that is a finding

The obvious plan is to refactor `main.dart` into an injectable `bootstrap()`.
**It is not needed.** `main.dart` already exposes every piece the harness
needs as a public symbol: `FantasticApp`, `seedOnboardingGate` (a top-level
function precisely so it is testable), and `databaseProvider`'s override point.
The harness re-composes them; `lib/` is not touched.

The delta is therefore small, known, and worth writing down. Compared with the
real `main()`, the harness skips exactly three things:

1. `openAppDatabase()` — replaced with `newDatabaseFactoryMemory()`.
2. `NotificationService.initialise()` and `scheduleDailyReminder()` — plugin-bound.
3. The `try/catch` that renders `StartupFailureApp` — coverable separately (§3, F12).

All three are the plugin boundary of §0.4. Nothing else about the app is
stubbed, mocked or overridden.

### 1.3 `integration_test/helpers/app_harness.dart` — verified

```dart
/// Boots the app the way `main()` does, minus the three plugin-bound steps
/// (`design/m8_preflight.md` §1.2), over a database that exists only for
/// this test.
Future<ProviderContainer> bootApp({bool onboarded = false}) async {
  await initializeDateFormatting('he');
  // A fresh factory per call: two tests in one run cannot see each other's
  // records even though they name the same database.
  final db = await newDatabaseFactoryMemory().openDatabase('e2e.db');

  if (onboarded) {
    // The profile record's existence IS the first-launch flag — there is no
    // boolean to set, and no `shared_preferences` (m4_preflight §4). Writing
    // one before the gate is seeded is what makes this a returning user.
    final seed = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    await seed.read(userProfileRepositoryProvider).save(
          UserProfileFixture.profile(),
        );
  }

  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(db)],
  );
  await seedOnboardingGate(container);
  return container;
}

Future<void> pumpApp(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const FantasticApp()),
  );
  await tester.pumpAndSettle(_settle);
}

/// Bound every settle. An unbounded `pumpAndSettle()` on a screen with a
/// spinner costs ten minutes per call instead of failing (m4_handoff).
const Duration _settle = Duration(milliseconds: 100);
```

`UserProfileFixture` comes from `test/fixtures/` by relative import
(`../../test/fixtures/fixtures.dart`, ✓ measured). **Do not fork the
fixtures into `integration_test/`** — `design/tests.md` has one fixture
directory, and two would drift.

### 1.4 Layout

```
integration_test/
  app_test.dart                 ← the only file CI runs (§6.1)
  helpers/app_harness.dart
  flows/
    onboarding_flow.dart        ← each exports `void main()`, no binding call
    meal_logging_flow.dart
    streak_flow.dart
    grace_period_flow.dart
    symptom_diary_flow.dart
    keto_lens_flow.dart
    navigation_smoke_flow.dart
```

```dart
// integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  group('onboarding', onboarding.main);
  group('meal logging', meal_logging.main);
  // …one line per flow.
}
```

Note the file names under `flows/`: **`_flow.dart`, not `_flow_test.dart`.**
A `_test.dart` suffix there would be picked up by a directory-wide run and hit
§6.1's launch limit.

---

## Part 2 — Corrections to the seven flow issues

Every issue was audited against the shipped code. Summary first; detail per
issue follows.

| Issue | Defects | Worst one |
|---|---|---|
| #95 onboarding | 7 | Clears `SharedPreferences` — **a package this project deliberately does not depend on** |
| #96 meal logging | 2 | Asserts the meal name is visible; it is **below the fold** and has no element until scrolled |
| #97 streak | 2 | `find.text('1')` — the digit `1` is not unique on that screen |
| #98 grace period | 3 | Needs a clock seam that does not exist; the issue says "document this as a prerequisite" and no issue ever did |
| #99 symptoms | 4 | Drives **sliders**; the sheet has score chips. Taps `find.text('יומן')`, which is ambiguous |
| #100 navigation | 1 | **Two of the five tab labels do not exist** |
| #101 keto lens | 5 | Taps `gallery_button`, which is absent in the state the headless app is actually in |

### 2.1 #95 — Onboarding → dashboard seeded with targets

| # | Issue says | Reality |
|---|---|---|
| 1 | `SharedPreferences.getInstance()` / `prefs.clear()` | **Not a dependency, deliberately** (`m4_preflight.md` §4). A fresh in-memory database *is* a first launch |
| 2 | "real (but ephemeral) **Isar** instance" | sembast |
| 3 | `'ברוך הבא ל-Fantastic'` | `'ברוכים הבאים ל-Fantastic'` |
| 4 | CTA `'התחל'` | `'בואו נתחיל'` (screen 1 followed `ui_ux_design.md` §1a over the issue) |
| 5 | CTA `'אישור — נתחיל!'` | `'התחל את המסע'` |
| 6 | `Key('age_field')`, `Key('weight_field')`, `Key('height_field')` | **None of the three exists.** No onboarding screen has a single `Key` |
| 7 | Asserts `'לא נרשמו ארוחות להיום'` **and** `'שלב ההסתגלות'` on the dashboard | Both strings are real, but at the tester's 800×600 viewport everything from `MealListSection` down is below the fold and has no element until the page is dragged (§6.3) |

Two things the issue does not ask for and the flow should assert, because they
are what the flow is *for*: the targets reaching the dashboard (`50/149ג׳`
proves the 149 came from onboarding, not from `MacroTargets.defaults`), and the
streak seeding at 0/induction rather than at a phase computed from a start date.

**Deterministic and measured:** male, 30 y, 80 kg, 175 cm, weight-loss →
**fat 149 g, net carbs 20 g, protein 64 g**. Assert those numbers.

### 2.2 #96 — Log a meal → dashboard updates

| # | Issue says | Reality |
|---|---|---|
| 1 | `expect(find.text('ביצים וחמאה'), findsOneWidget)` after save | ✓ only after `tester.drag(...)`: `MealListSection` is a sliver child below the fold and **has no element at all** until scrolled (m5_handoff) |
| 2 | `find.text('שמור')` | Works, but `Key('save_meal_button')` exists — use it. `'שמור'` also becomes `'שומר...'` mid-save |

The sheet's own save button is below the fold *inside the sheet* when the
keyboard metrics apply — `tester.ensureVisible()` before tapping (§6.2).

### 2.3 #97 — Compliant day → streak increments

| # | Issue says | Reality |
|---|---|---|
| 1 | `expect(find.text('1'), findsOneWidget)` | The ring renders a bare `'1'`, but a dashboard with macro rows is full of digits. Scope the finder to `StreakRingWidget` |
| 2 | "verifies `AdaptationPhaseService.evaluateToday` was called" | An e2e test asserts on the screen, not on a call. The observable is the ring **and** the phase badge |

The mechanism works unmodified (✓ measured, §0.2 row 6): `MealLoggingService`
re-evaluates the streak on every write, and 50/2/3 → ratio 10.0 → compliant.

### 2.4 #98 — Breach → grace → expiry → reset

| # | Issue says | Reality |
|---|---|---|
| 1 | "seed via `IsarStreakRepository`" | `SembastStreakRepository`, or the harness's container |
| 2 | "inject mocked `DateTime`" / "may require a `DateTimeProvider`… document this as a prerequisite" | **It is a prerequisite, and nothing ever documented it.** `AdaptationPhaseService.handleBreach(DateTime now)` takes the time — but its only UI caller, `MealLoggingService._evaluateStreak`, calls `DateTime.now()` internally. A test driving the UI cannot advance the clock |
| 3 | `expect(find.text('0'), findsOneWidget)` | Same ambiguity as #97 |

This is the one flow that needs a production change. Two options:

- **A clock provider** — `@riverpod DateTime Function() clock(Ref ref) => DateTime.now;`
  overridden in the harness. One seam, reusable by the dashboard's `_today()`
  (which has the same untestable-midnight problem) and by `OnboardingService`.
  **Recommended.**
- **Seed the expired grace state directly** and assert only the reset half.
  Cheaper, and tests less: it never exercises the transition that
  `m3_preflight.md` found was silently broken (`copyWith(gracePeriodEnd: null)`).

Take A, as its own issue, before #98 (§7).

### 2.5 #99 — Log symptoms → view in diary

| # | Issue says | Reality |
|---|---|---|
| 1 | "Sliders default to 3 — adjust energy to 5… Slider interaction requires drag" | **There are no sliders.** Five rows of 1–5 chips, keyed `score_<scale>_<n>` (✓ all five found). A tap, not a drag |
| 2 | `find.byIcon(Icons.bolt)` to open the sheet | The strip cells are keyed `symptom_cell_<scale>`. Use the key; the icon may be shared |
| 3 | `await tester.tap(find.text('יומן'))` to reach the diary | **Ambiguous — fails.** `DiaryScreen`'s AppBar title is `'יומן'` and so is the tab label (✓ measured: `findsNWidgets(2)`) |
| 4 | `expect(find.textContaining('אנרגיה'), findsOneWidget)` | `'אנרגיה'` appears on the dashboard strip too; and the section header is `'תסמינים'` |

The fifth scale is **`mood` / `'מצב רוח'`**, never brain fog (`m5_preflight.md`).
A flow that logs five scales and reads back four has a hole exactly where M5's
defect was.

### 2.6 #100 — Navigate all tabs

| # | Issue says | Reality |
|---|---|---|
| 1 | `['בית', 'עדשה', 'יומן', 'הסתגלות', 'פרופיל']` | **`['בית', 'מצלמה', 'יומן', 'התאמה', 'פרופיל']`.** Two of five are wrong, and `'יומן'` is ambiguous per §2.5 |

Tap through `NavigationBar` — `find.descendant(of: find.byType(NavigationBar), matching: find.text(label))`
— or add keys (§7, P2). ✓ All five open headless, including the lens tab.

"No assertion needed — if it throws, the test fails" is half right: an
exception inside a provider surfaces as an error *widget*, not a thrown error.
Assert each screen's own marker.

### 2.7 #101 — Keto Lens scan → result sheet → add to diary

| # | Issue says | Reality |
|---|---|---|
| 1 | Tap `Key('gallery_button')` | ✗ **Not present.** Headless, `CameraScreen` lands on `lens_camera_problem` (`'לא ניתן לפתוח את המצלמה'`) whose fallback is `gallery_fallback_button` (✓ measured) |
| 2 | "`image_picker` … requires a platform channel mock" | A channel mock returns a *path*; the file behind it still reaches ML Kit, which has no headless implementation. Mocking the channel is not enough |
| 3 | "`test_assets/hebrew_label.jpg` — known label for deterministic OCR" | There is no such asset, and **no OCR has ever run on a real label** (#256). "Deterministic OCR" is not available at any tier |
| 4 | `find.text('הוסף ליומן')` | Key `add_to_diary_button` exists — use it |
| 5 | Tab label `'עדשה'` | `'מצלמה'` (§2.6) |

**Split it.** The half that can be verified is the half after OCR: override
`TextRecognitionService` with a fake returning one of the raw-text fixtures
`test/fixtures/hebrew_label_fixture.dart` already holds (`tahini`,
`proteinBar`, `unreadable`, …) — which feeds the **real** parser and the
**real** classifier, so only the plugin is faked — then assert
`ScanResultSheet` → badge → `add_to_diary_button` → a prefilled
`AddMealBottomSheet` → the meal on the dashboard. The half that cannot —
camera, picker, ML Kit — belongs to #256 and a device, and should be struck
from #101 rather than faked.

**Do not write this flow until #257 is fixed.** Scanned macros are per-100 g
and logged as the serving; a flow test written today would encode the bug as
the expected result.

---

## Part 3 — Flow coverage for every shipped feature

Seven issues cover five flows and miss several the app already has. The full
map, with what each one is *for* — a flow that only repeats what a widget test
already asserts is not worth 12 seconds of CI.

| # | Flow | Feature(s) | Issue | Notes |
|---|---|---|---|---|
| F1 | Onboarding → targets on the dashboard → streak seeded | Onboarding, dashboard, adaptation | #95 | ✓ proven in the spike |
| F2 | First launch shows onboarding; **relaunch goes straight to the dashboard** | Onboarding gate, persistence | **new** | Epic #8's DoD names it; no child issue covers it. The pattern that bit M4 (`m4_preflight.md` §1.1) is exactly this |
| F3 | Log a meal → totals, ratio, meal row | Diary, dashboard | #96 | ✓ proven |
| F4 | Delete a meal → totals recomputed | Diary, dashboard | **new** | The `Dismissible`-vs-async-delete path (m2_handoff); the recalculation is the app's main write path |
| F5 | Compliant day → streak 1, phase badge | Adaptation | #97 | ✓ proven |
| F6 | Breach → grace banner → expiry → reset to 0 | Adaptation | #98 | Needs the clock seam (§2.4) |
| F7 | Log five symptom scales → strip → diary section | Diary | #99 | All five scales, distinct scores |
| F8 | Browse a past date in the diary | Diary | **new** | M5 was driven by hand in a browser and that is the only time this path has run |
| F9 | Scan result → verdict → prefilled meal → dashboard | Keto Lens, diary | #101 (split) | Post-OCR half only. Blocked on #257 |
| F10 | All five tabs open | Shell, routing | #100 | ✓ proven |
| F11 | Database open fails → `StartupFailureApp`, not a blank screen | Core | **new** | The one `main()` branch the harness skips; cheap to cover with a failing factory |

F2, F4, F8 and F11 are **new issues**, not re-scopes. Each covers a path that
has either never run outside a manual browser session or never run at all.

Deliberately excluded: the v1.1 placeholder routes (`/restaurants`, `/recipe`,
`/directory`) — F10 already proves the shell, and a placeholder has no
behaviour to assert.

---

## Part 4 — The CI slot

### 4.1 Shape

A second job in the existing `.github/workflows/ci.yml`, alongside `verify`:

```yaml
  e2e:
    name: e2e flows
    runs-on: ubuntu-latest
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 3.47.3   # same pin as `verify`
          channel: stable
          cache: true
      - run: flutter pub get
      - name: End-to-end flows
        # -d flutter-tester is not optional: without it the run fails with
        # "No supported devices connected" (design/m8_preflight.md §0.2).
        # One aggregator file, not the directory — a second file in the same
        # invocation cannot launch (§6.1).
        run: flutter test -d flutter-tester integration_test/app_test.dart --no-pub
```

### 4.2 Why a separate job rather than a step in `verify`

`design/cicd_plan.md` §5.2 argues one job, cheapest-first, and that argument
stands for format/analyze/test. This is the same reasoning that gave `codegen`
its own job: **isolate the check whose failures are slowest to attribute.** An
e2e failure and a unit failure look nothing alike in a diff, and burying e2e
behind a 4-minute web build delays the signal. The two jobs also run in
parallel, so wall-clock to first red does not move.

Cost of the extra runner setup: ~1–2 min/run.

### 4.3 Cost

| Workflow | Runner | Est. | Frequency | Effective min/mo |
|---|---|---|---|---|
| `ci.yml` `verify` (today) | ubuntu | ~4 min | ~60 | ~240 |
| `ci.yml` `e2e` (this plan) | ubuntu | ~3–4 min | ~60 | ~210 |
| **Total** | | | | **~450 of 2,000 — 23%** |

Compare `cicd_plan.md` §8's parked nightly simulator: **~6,000 effective
min/mo, 3× the whole free tier.** The Linux tier is ~3.5% of that, and it runs
on every PR instead of once a night.

### 4.4 Blocking, and branch protection

Required, like `verify`. An e2e suite that does not block is a suite people
stop reading — `cicd_plan.md` §6.5's own note about a nightly nobody watches.
Add **`e2e flows`** to the required checks in §5.5's list once it has one green
run on `main`.

### 4.5 What does *not* change

- `flutter test` (the `verify` job) still globs `test/` only — ✓ confirmed with
  `integration_test/` populated: **1112 tests, 61 s, zero failures**, and not
  one of the flow files was picked up. The per-PR unit/widget gate is
  untouched, and coverage is unaffected because
  `--coverage` is not passed to the e2e job (e2e coverage is excluded by
  `design/tests.md` and would distort the `domain/` + `application/` gate).
- `pubspec.lock` changes by one SDK dev-dependency (`integration_test`), which
  the lockfile-freshness step will demand is committed.

---

## Part 5 — Options considered and rejected

| Option | Verdict |
|---|---|
| **`-d flutter-tester` on ubuntu** | **Chosen.** Free, per-PR, 14 s, proven against this repo |
| macOS simulator, nightly | Keep parked. It is the only tier that can cover camera, ML Kit and notifications — unpark it when a Mac exists (Epic #4), as a *supplement*, not the primary |
| Chrome + `chromedriver` via `flutter drive` | **Worth a follow-up, unverified here.** It is the only tier that exercises `sembast_web`/IndexedDB and CanvasKit Hebrew rendering — the one shipping target this plan does not touch. Free on ubuntu. Propose after the flutter-tester tier is green |
| Enable the Linux desktop target | Rejected. A third platform folder to maintain, and the plugins still would not run |
| Put the flows under `test/` and run them in `verify` | Rejected, though it **works** (✓ measured — an `IntegrationTestWidgetsFlutterBinding` file passes under plain `flutter test`). It would drag e2e into the coverage report and into every developer's `flutter test`, and it contradicts #150's separation |

---

## Part 6 — Gotchas, all measured

**6.1 One app launch per `flutter test` invocation.** Running two flow files
together — `flutter test -d flutter-tester integration_test/` — fails the
*second* file with `Failed to launch …: The log reader failed unexpectedly` /
`Unable to start the app on the device`, whichever file is second. Two fixes
work: one invocation per file in a shell loop (49 s for two files), or **one
aggregator file with a `group()` per flow** (31 s for four tests). Take the
aggregator; it is also what keeps CI to one command.

**6.2 A visible widget is not a tappable one.** `save_symptoms_button` is found
by its key and `tap()` still misses it: *"derived an Offset that would not hit
test on the specified widget"* — it sits below the fold inside the modal sheet.
`await tester.ensureVisible(finder)` before every tap in a scrollable sheet.
Note this is a **warning**, not a failure — the test carries on and fails later
somewhere unrelated. Set `WidgetController.hitTestWarningShouldBeFatal = true`
in the harness so it fails where it happens.

**6.3 A sliver below the fold has no element at all.** The meal row does not
exist until the dashboard is dragged (`AFTER SCROLL` in the spike log). This is
`m5_handoff.md`'s finding, reproduced: `find.text('אבוקדו')` returns zero, not
"off-screen".

**6.4 Text finders collide with the tab bar.** `'יומן'` is both a tab label and
`DiaryScreen`'s AppBar title. Scope every tab tap to the `NavigationBar`, or
key the destinations.

**6.5 The `pumpAndSettle` timeout is ten minutes by default — and passing a
duration does not change it. [corrected]** This section first said "always
pass a duration (`m4_handoff.md`)". That is wrong, and the harness shipped
with the bug before the suite caught it: `pumpAndSettle`'s **first**
positional argument is the interval *between* pumps; the timeout is the
**third**. So `pumpAndSettle(Duration(milliseconds: 100))` bounds nothing —
it leaves the ten-minute timeout in place and makes every frame wait 100 ms
of real time under the live binding, which is how one flow came to take 40
seconds. Pass all three:
`pumpAndSettle(frameInterval, EnginePhase.sendSemanticsUpdate, timeout)`.

**6.6 sembast does complete here — the M4 note is binding-specific.**
`m4_handoff.md` says "sembast futures do not complete inside `testWidgets`",
and that holds under the default (fake-async) binding. Under
`IntegrationTestWidgetsFlutterBinding` — a `LiveTestWidgetsFlutterBinding`,
with real timers — real in-memory sembast reads and writes complete normally
(✓ the entire spike depends on it). This is what makes real-database e2e
possible at all, and it is why the flows must not be moved under `test/`.

**6.7 Flipping `onboardingGateProvider` mid-test does not navigate.** The
router's `redirect` reads the gate but has no `refreshListenable`, so nothing
re-routes until the next navigation — which is why
`test/core/router/onboarding_gate_route_test.dart` follows `markCompleted()`
with an explicit `router.go('/')`. Not a bug (onboarding screen 4 navigates
too), but it means a flow cannot skip onboarding by flipping the gate. Seed a
`UserProfile` *before* boot instead (§1.3), which is also closer to what a
returning user actually is.

---

## Part 7 — Build order and the issues to open

Prerequisites first; each is small and independently mergeable.

| | Work | Why it is first |
|---|---|---|
| **P1** | Re-scope **#150**: `integration_test` dev dep, `helpers/app_harness.dart`, `app_test.dart`, and F10 as the first flow | Everything else imports it |
| **P2** | Add the `e2e flows` CI job (§4) with just F10 in it | Prove the slot on a PR before filling it. A green job with one flow beats seven flows nobody runs |
| **P3** | Keys on the onboarding inputs (`age_field`, `weight_field`, `height_field`, sex, goal) | #95 assumes them; none exists. Label-ancestor finders work but break on any copy change |
| **P4** | Keys on the five `NavigationDestination`s (`tab_home`, `tab_lens`, …) | §6.4. Fixes #99, #100, #101 at once |
| **P5** | A `clock` provider, overridden in the harness | §2.4. Blocks #98; also unlocks testing the dashboard's midnight boundary |
| **P6** | Re-scope **#101** to its post-OCR half; move camera/picker/ML Kit to #256 | §2.7 |

Then the flows, cheapest and least entangled first:

**#100 (F10)** → **#95 (F1)** → **F2** → **#96 (F3)** → **F4** → **#97 (F5)** →
**#99 (F7)** → **F8** → **#98 (F6, after P5)** → **F11** → **#101 (F9, after #257)**.

New issues to open: **F2** (first-launch gate across a relaunch), **F4** (delete
a meal), **F8** (past-date diary), **F11** (startup failure), plus P2–P5.

Every one of #95–#101 needs its Implementation Plan corrected per Part 2 before
it is picked up — `design/issue_conventions.md`'s standing rule, and the one
this project has never once been able to skip.

---

## Part 8 — Open questions

1. **Does the aggregator scale to eleven flows?** Four tests ran in one launch
   in 14 s. Eleven flows, each booting a fresh database, should stay well under
   a minute — but the failure mode at scale (one launch for everything) is that
   a single crashed flow takes the run with it. Re-measure at ~6 flows and
   split into two aggregators if needed.
2. **Chrome tier, yes or no?** §5. It is the only tier that covers the web
   target the project actually ships to. Unverified here; `chromedriver` was
   present in this container but was not exercised.
3. **Screenshots on failure.** `IntegrationTestWidgetsFlutterBinding.takeScreenshot`
   works headless and would make a red CI run readable. Cheap; not scoped above.
4. **Does `verify` still need `flutter build web`** once an e2e job exists? Yes
   — they catch different things (§0.4), and the web build is the only guard on
   the conditional-export firewall.
5. **Who owns a red e2e run?** Same answer as every other required check: the
   PR that turned it red. Worth stating in `design/pr_conventions.md` when the
   job lands.

---

## Part 9 — Verification status

**Measured in this container, against a scratch copy of this repository:**
Flutter 3.47.3 on Linux x64, no device, no display. Rows 1–10 of §0.2, and
every gotcha in Part 6. The onboarding targets (149/20/64), the macro card
(`50/149ג׳`), the ratio (`10.0/2.0`), the streak ring (`1 יום`), the five tab
labels, the five `score_<scale>_4` keys and the lens screen's
`lens_camera_problem` state are transcriptions of actual output, not
expectations.

**Not measured:** anything in Part 4 on a GitHub Actions runner — no run of
this workflow has happened (the same residual risk `cicd_plan.md` §10 records
for Phase 0: the action wiring, not the commands). The Chrome tier (§5). And
everything in §0.4, which no tier available to this project can measure.

---

## Part 10 — What shipped, and what it found

The harness (§1), the CI job (§4) and **nine of the eleven flows** (§3) are
implemented. `flutter test -d flutter-tester integration_test/app_test.dart`
runs **10 tests in ~35 s** on this Linux container, and `flutter test` still
reports 1112 green with no flow file picked up.

| Flow | File | State |
|---|---|---|
| F1 onboarding → seeded targets (#95) | `flows/onboarding_flow.dart` | ✅ |
| F2 first launch once, relaunch lands on the dashboard | `flows/onboarding_flow.dart` | ✅ |
| F3 log a meal → totals (#96) | `flows/meal_logging_flow.dart` | ✅ |
| F4 delete a meal → totals recomputed | `flows/meal_logging_flow.dart` | ✅ |
| F5 compliant day → streak 1 (#97) | `flows/streak_flow.dart` | ✅ |
| F5b a second meal does not increment again | `flows/streak_flow.dart` | ✅ |
| F7 five scales → diary (#99) | `flows/symptom_diary_flow.dart` | ✅ |
| F8 a past date shows its own day | `flows/symptom_diary_flow.dart` | ✅ |
| F10 all five tabs (#100) | `flows/navigation_smoke_flow.dart` | ✅ |
| F11 storage failure is reported | `flows/storage_failure_flow.dart` | ✅ |
| F6 breach → grace → reset (#98) | — | **not written** — still blocked on the clock seam (P5, §2.4) |
| F9 scan → prefilled meal (#101) | — | **not written** — still blocked on #257 (§2.7) |

Production changes were the three prerequisites and nothing else: keys on the
onboarding inputs and the shared CTA (P3), keys on the five tab destinations
(P4), and a key per diary date chip. No behaviour changed; all 1112 existing
tests still pass.

### The three defects the suite found

Each was found by a flow failing on its **first** run, and each is real rather
than a test artefact. None is fixed here — that is M7 work — and each is
asserted as it actually behaves, with a comment saying so, rather than
skipped.

1. **The dashboard shows no macro targets at all until the first meal is
   logged.** `MacroSummaryCard` renders `EmptyMealsState` whenever the day has
   no `DailyLog`, so a user who has just agreed to 149/20/64 g sees none of
   those numbers on the screen they land on. Epic #8's Definition of Done —
   "dashboard macro targets match what onboarding set" — is only observable
   from the second screen onwards. `mvp_handoff.md` records the same shape for
   `ElectrolytesCard`; it is the same root cause, one widget wider than
   anyone had noticed.
2. **On a storage failure, `MealListSection` spins forever** while the macro
   card and the symptom strip beside it report the error correctly. This is
   the loading-first `.when` pattern `mvp_handoff.md` lists as outstanding,
   now localised and reproduced: `hasError` before `hasValue` is the fix.
3. **A dismissed meal is deleted from storage asynchronously**, so an
   assertion on the repository in the next frame still sees it. The row goes
   first because `Dismissible` asserts that a dismissed child leaves the tree
   immediately. Not a bug — but a correctness trap for any test, which is why
   the harness has `waitFor`.

### Three things about the runtime that no document had

- **riverpod 3 retries a failed provider on an exponential backoff.** A screen
  over a broken store therefore *never settles* — `pumpAndSettle` times out
  rather than returning, however generous the bound. `pumpFrames` and
  `pumpUntil` exist for exactly that screen, and `pumpApp(settleAfter: false)`
  is how F11 boots.
- **The tab shell keeps the outgoing screen mounted** while the next one comes
  in, so an unscoped finder can match a screen on its way out. Scope
  cross-tab assertions to the screen type under test.
- **§6.2's `hitTestWarningShouldBeFatal` is worth the line.** It turned a
  silent mis-tap into a failure at the tap rather than three steps later.

### Still open

- **F6 and F9**, above, with their prerequisites unchanged.
- **P5**, the clock seam, is the only remaining blocker inside this
  milestone's control — and it is now half-built by someone else. `main`
  gained `lib/core/time/today_tracker.dart` while this branch was in flight:
  `dateOnly`, `todayDate()`, and a `TodayTracker` mixin whose `now()` a
  subclass can override. That is a **widget-level** seam, for the midnight
  rollover. `MealLoggingService._evaluateStreak` still calls `DateTime.now()`
  itself, so a flow driving the UI still cannot advance the clock past a
  grace period. P5 is now "give the service the same seam", which is smaller
  than it was and should follow `today_tracker.dart`'s naming rather than
  invent a second vocabulary for the same idea.
- **Branch protection** — `e2e flows` should join `analyze · format · test`
  as a required check once it has one green run on `main` (§4.4). Needs repo
  admin; not something this PR can do.
- The Chrome tier (§5) and everything in §0.4 are unchanged: still the honest
  limits of what any of this proves.
