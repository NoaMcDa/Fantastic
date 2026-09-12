# Tasks — Fantastic

> **Superseded in part:** the M0/M1 tasks below describe an Isar data layer.
> Isar was replaced by **sembast + sembast_web** when web support landed —
> `IsarMealRepository` and friends are now `SembastMealRepository`, the
> `data/schemas/` directories are gone, and mappers became record codecs.
> The tasks are kept as a record of what was built; see
> `design/web_support.md` and `CLAUDE.md` §Local Persistence for the
> current data layer.

Ordered strictly by priority: foundation blockers first, MVP features in build-milestone order, polish and post-MVP last. Each task is a single atomic unit of work — one branch, one PR.

Status: `[ ]` not started · `[~]` in progress · `[x]` done

---

## Milestone 0 — Project Foundation (Blockers for Everything)

> Nothing else can start until these are done. They wire the skeleton every feature builds on.

### 0.1 Dependencies & Tooling

- [ ] **Add all MVP dependencies to `pubspec.yaml` and run `flutter pub get`**
  - Add: `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `isar`, `isar_flutter_libs`, `isar_generator`, `go_router`, `build_runner`, `mocktail`, `riverpod_test`, `flutter_lints`
  - Acceptance: `flutter pub get` succeeds, `flutter analyze` returns zero issues

- [ ] **Configure `build_runner` and verify code generation works end-to-end**
  - Run `timeout 120 dart run build_runner build --verbose` with a dummy `@riverpod` annotation
  - Acceptance: `.g.dart` files generated without errors

- [ ] **Set up `analysis_options.yaml` with strict linting rules**
  - Enable: `avoid_print`, `prefer_const_constructors`, `always_use_package_imports`, `unawaited_futures`, `require_trailing_commas`
  - Acceptance: `flutter analyze` passes on the blank project

### 0.2 App Skeleton

- [ ] **Configure `go_router` with all MVP routes and a `ShellRoute` tab bar**
  - Routes: `/` (dashboard), `/lens`, `/diary`, `/adaptation`, `/profile`
  - Acceptance: all tabs navigate without error; back navigation works correctly

- [ ] **Implement RTL app root with Hebrew locale and dark theme**
  - `Directionality(textDirection: TextDirection.rtl)` at `MaterialApp` root
  - `ThemeData` with colour tokens from `design/ui_ux_design.md` (primary `#1C1C1E`, accent `#F5A623`, etc.)
  - Acceptance: app launches in RTL; Hebrew characters render correctly

- [ ] **Build the bottom tab bar shell (5 tabs: Home, Lens, Diary, Adaptation, Profile)**
  - RTL-mirrored tab icons; active state uses accent colour
  - Acceptance: tapping each tab loads the correct (placeholder) screen

- [ ] **Create `lib/core/constants/` with app-wide constants**
  - Macro targets, electrolyte targets per phase, ingredient rule lists (forbidden oils, sweeteners, clean fats)
  - Acceptance: constants are importable from any feature; no magic numbers elsewhere

- [ ] **Open Isar and expose it via a `isarProvider` Riverpod provider in `main.dart`**
  - All schemas registered at open time
  - Acceptance: Isar opens without error on cold launch; provider resolves in any widget test

- [ ] **Scaffold all 7 feature directories with empty placeholder screens**
  - Each feature gets a bare `Scaffold` with a title so navigation is testable immediately
  - Acceptance: `flutter run` launches and all tabs are tappable without crash

### 0.3 Test Infrastructure

- [ ] **Create `test/fixtures/` directory with base fixture helpers**
  - `MealEntry.fixture()`, `DailyLog.fixture()`, `StreakState.initial()`, `StreakState.withStreak(n)`
  - Acceptance: fixtures compile and return valid domain objects

- [ ] **Create `test/helpers/test_isar.dart` — in-memory Isar helper**
  - Opens a uniquely-named Isar instance per test; teardown closes and deletes it
  - Acceptance: two contract tests can run in parallel without sharing state

---

## Milestone 1 — Domain & Data Layer (All Features)

> Define all domain models and Isar schemas before writing any UI or services. These are the foundation every other layer depends on.

### 1.1 Domain Models

- [ ] **Define `MealEntry` domain model (pure Dart, immutable)**
  - Fields: `id`, `timestamp`, `fatG`, `netCarbsG`, `proteinG`, `mealName`, `ingredients`, `imageRef`, `ketoRatio`
  - Includes `copyWith`
  - Acceptance: no Flutter/Isar imports; all fields typed correctly

- [ ] **Define `DailyLog` domain model**
  - Fields: `date`, `totalFatG`, `totalNetCarbsG`, `totalProteinG`, `waterMl`, `sodiumMg`, `potassiumMg`, `magnesiumMg`, `ketoRatioAvg`
  - Acceptance: pure Dart; includes `copyWith`

- [ ] **Define `StreakState` domain model**
  - Fields: `currentStreak`, `highestStreak`, `phase` (`AdaptationPhase` enum), `lastCompliantDate`, `inGracePeriod`, `gracePeriodEnd`
  - Acceptance: pure Dart; `AdaptationPhase` enum has values `induction`, `fatAdapted`, `deepKetosis`

- [ ] **Define `SymptomLog` domain model**
  - Fields: `id`, `date`, `energyScore`, `clarityScore`, `hungerScore`, `moodScore` (all 1–5), `symptoms` (`Set<PhysicalSymptom>`), `notes`
  - `PhysicalSymptom` enum: `halitosis`, `constipation`, `muscleCramps`, `headache`, `diarrhea`, `dizziness`, `nausea`, `insomnia`
  - Acceptance: pure Dart; scores validated in constructor (1 ≤ n ≤ 5); equality uses `SetEquality` for `symptoms`, not identity

- [ ] **Define `ParsedLabel` and `IngredientVerdict` domain models**
  - `ParsedLabel`: `productName`, `fatG`, `netCarbsG`, `proteinG`, `fatGPer100`, `netCarbsPer100`, `proteinPer100`, `ingredients`
  - `IngredientVerdict`: `badge` (`VerdictBadge` enum), `flaggedIngredients`, `cautionReason`
  - `VerdictBadge` enum: `cleanKeto`, `cautionQuantityDependent`, `nonKeto`
  - Acceptance: pure Dart; no ML or Flutter imports

### 1.2 Repository Interfaces

- [ ] **Define `MealRepository` interface in `diary/domain/`**
  - Methods: `save`, `findById`, `findByDate`, `delete`
  - Acceptance: pure abstract interface; no Isar types in signature

- [ ] **Define `DailyLogRepository` interface in `dashboard/domain/`**
  - Methods: `upsert`, `findByDate`, `watchDate` (returns `Stream`)
  - Acceptance: pure abstract interface

- [ ] **Define `StreakRepository` interface in `adaptation/domain/`**
  - Methods: `load`, `save`, `watch` (returns `Stream`)
  - Acceptance: pure abstract interface

- [ ] **Define `SymptomLogRepository` interface in `diary/domain/`**
  - Methods: `save`, `findByDate`, `findRange`
  - Acceptance: pure abstract interface

- [ ] **Define `LabelParser` and `IngredientClassifier` interfaces in `keto_lens/domain/`**
  - `LabelParser`: `canParse(String)`, `parse(String) → ParsedLabel`
  - `IngredientClassifier`: `classify(List<String>) → IngredientVerdict`
  - Acceptance: pure abstract interfaces

### 1.3 Isar Schemas & Implementations

- [ ] **Create `IsarMealEntry` schema + mapper in `diary/data/`**
  - `@collection` annotation; all fields persisted; `toDomain()` / `MealEntry.toIsar()` mappers
  - Acceptance: `build_runner` generates schema without errors; mapper round-trips losslessly

- [ ] **Create `IsarDailyLog` schema + mapper in `dashboard/data/`**
  - `date` field indexed for fast lookup
  - Acceptance: `build_runner` generates; mapper round-trips

- [ ] **Create `IsarStreakState` schema + mapper in `adaptation/data/`**
  - Single-row schema (always `id = 0`)
  - Acceptance: `build_runner` generates; `load()` returns `StreakState.initial()` when empty

- [ ] **Create `IsarSymptomLog` schema + mapper in `diary/data/`**
  - `date` field indexed
  - Acceptance: `build_runner` generates; mapper round-trips

- [ ] **Implement `IsarMealRepository` and write contract tests**
  - Passes all cases in `runMealRepositoryContractTests`
  - Acceptance: contract test suite green

- [ ] **Implement `IsarDailyLogRepository` and write contract tests**
  - `watchDate` stream emits on every write to that date
  - Acceptance: contract test suite green; stream emission verified

- [ ] **Implement `IsarStreakRepository` and write contract tests**
  - `watch` stream emits on save; `load` on empty DB returns `StreakState.initial()`
  - Acceptance: contract test suite green

- [ ] **Implement `IsarSymptomLogRepository` and write contract tests**
  - Acceptance: contract test suite green

- [ ] **Wire all repository providers in each feature's `data/providers.dart`**
  - Each returns the Isar implementation behind the domain interface
  - Acceptance: `ref.watch(mealRepositoryProvider)` resolves to `IsarMealRepository` in tests and production

---

## Milestone 2 — Daily Macro Tracker

### 2.1 Business Logic

- [ ] **Implement `KetoRatioCalculator` service in `dashboard/application/`**
  - Formula: `fat / (netCarbs + protein)`; returns 0.0 when denominator is 0
  - Throws `ArgumentError` on negative inputs
  - Acceptance: unit tests — happy path, zero fat, zero denominator, negative inputs

- [ ] **Implement `MealLoggingService` in `diary/application/`**
  - Methods: `logMeal(MealEntry)`, `deleteMeal(Id)`, `fetchToday()`, `fetchForDate(DateTime)`
  - On `logMeal`: saves meal, recomputes `DailyLog` aggregates, upserts `DailyLog`
  - Acceptance: unit tests with mocked repos; `DailyLog` totals correct after 3 meals logged

- [ ] **Implement `ElectrolyteAdvisor` service in `adaptation/application/`**
  - Returns phase-appropriate Na/K/Mg targets
  - Phase 1: Na 3000–5000mg / K 3000–4000mg / Mg 300–500mg
  - Phase 2–3: Na 2000–3000mg / K 2500–3500mg / Mg 300–400mg
  - Acceptance: unit tests for all three phases

### 2.2 Providers

- [ ] **Create `todaysDailyLogProvider` (family by date) in `dashboard/application/`**
  - Watches `DailyLogRepository.watchDate(date)` stream
  - Acceptance: widget test — provider emits updated log after `MealLoggingService.logMeal()`

- [ ] **Create `todaysMealsProvider` (family by date) in `diary/application/`**
  - Acceptance: widget test — list updates after meal is saved or deleted

### 2.3 UI — Dashboard Screen

- [ ] **Build `DashboardScreen` scaffold with date header and scroll view**
  - Shows today's date in Hebrew format; RTL layout
  - Acceptance: renders without overflow on iPhone 14 Pro simulator

- [ ] **Build `MacroSummaryCard` widget — four progress bars (fat, net carbs, protein, keto ratio)**
  - Fills proportionally to target; accent colour for keto ratio
  - Acceptance: widget test — bar width matches `logged / target` ratio

- [ ] **Build `MealListSection` — chronological meal cards with swipe-to-delete**
  - Each card shows meal name, macro mini-bar, keto badge
  - Swipe left → delete confirmation → calls `MealLoggingService.deleteMeal()`
  - Acceptance: widget test — meal disappears from list after swipe-delete

- [ ] **Build `ElectrolytesCard` — three mini-gauges (Na / K / Mg) with collapsible state**
  - Shows progress vs. phase-appropriate target from `ElectrolyteAdvisor`
  - Acceptance: widget test — gauges display correct values; collapses on tap

- [ ] **Build `AddMealFAB` and `AddMealBottomSheet` — manual meal entry form**
  - Fields: meal name, fat (g), net carbs (g), protein (g)
  - Validates: all macro fields ≥ 0; name not empty
  - On save: calls `MealLoggingService.logMeal()` and dismisses sheet
  - Acceptance: widget test — valid form saves; invalid form shows inline errors

- [ ] **Build `EmptyMealsState` widget — shown when no meals logged today**
  - Hebrew copy: "לא נרשמו ארוחות להיום"
  - Acceptance: renders correctly; tapping CTA opens `AddMealBottomSheet`

### 2.4 UI — Diary Screen

- [ ] **Build `DiaryScreen` with horizontal date-strip picker (last 30 days)**
  - Today highlighted in accent colour; tapping a date loads that day
  - Acceptance: widget test — selecting yesterday loads yesterday's meals

- [ ] **Build `DiaryDayScreen` — meals + symptoms sections for a given date**
  - Reuses `MealListSection`; shows `SymptomDiarySection` below
  - Acceptance: navigating to a past date shows correct historical data

---

## Milestone 3 — Adaptation Phase Tracker & Streak

### 3.1 Business Logic

- [ ] **Implement `AdaptationPhaseService` state machine in `adaptation/application/`**
  - `currentPhase(StreakState)` — returns correct phase for streak day count
  - `recordCompliantDay(DateTime)` — loads state, increments streak, saves
  - `handleBreach(DateTime)` — starts grace period; if grace already expired, resets to 0
  - `isCompliantDay(DailyLog)` — net carbs ≤ target
  - Acceptance: unit tests — all phase thresholds, grace period start, grace period expiry, streak reset

- [ ] **Implement streak auto-evaluation trigger — called after every `MealLoggingService.logMeal()`**
  - At end of day (23:59) or on next-day first launch: evaluate yesterday's `DailyLog`; call `recordCompliantDay` or `handleBreach`
  - Acceptance: unit test — compliant day increments streak; breach starts grace period

### 3.2 Providers

- [ ] **Create `streakStateProvider` — stream provider watching `StreakRepository.watch()`**
  - Acceptance: widget test — provider emits new state after `AdaptationPhaseService.recordCompliantDay()`

- [ ] **Create `currentPhaseProvider` — derived from `streakStateProvider`**
  - Acceptance: widget test — returns `induction` for streak 1, `fatAdapted` for streak 8

### 3.3 Notifications

- [ ] **Integrate `flutter_local_notifications` and request permission on first launch**
  - Permission request shown after onboarding completes
  - Acceptance: permission prompt appears once; not repeated on subsequent launches

- [ ] **Schedule daily streak-risk notification at 20:00**
  - Fires only if no meal logged today; cancelled if a meal is logged
  - Acceptance: manual test — notification appears at 20:00 when no meals logged; does not appear when meals are logged

### 3.4 UI — Dashboard Streak Hero Card

- [ ] **Build `StreakRingWidget` — circular arc showing keto ratio progress**
  - Arc fill animates from 0 to current ratio on first render
  - Inside: streak day count + flame icon + phase badge
  - Acceptance: widget test — arc width proportional to `ketoRatio / targetRatio`; animates on pump

- [ ] **Build `PhaseBadgeWidget` — phase name chip with phase-appropriate colour**
  - Phase 1: amber · Phase 2: green · Phase 3: gold
  - Acceptance: widget test — correct label and colour for each phase enum value

### 3.5 UI — Phase Detail Screen

- [ ] **Build `PhaseDetailScreen` — vertical stepper timeline with 3 phases**
  - Current phase expanded; future phases locked with lock icon; completed phases dimmed with checkmark
  - Acceptance: widget test — correct expansion state for streak = 1, 8, 29

- [ ] **Build `PhaseDescriptionCard` — what to expect + electrolyte recommendation for current phase**
  - Hebrew copy per phase; content from `ElectrolyteAdvisor`
  - Acceptance: renders correct copy for each phase

- [ ] **Build `StreakCalendarWidget` — monthly grid of compliant (gold) vs. breach (red) days**
  - Reads from `StreakRepository` history
  - Acceptance: widget test — correct dot colours for a known history sequence

- [ ] **Build `GracePeriodBanner` — shown in danger colour when `inGracePeriod == true`**
  - Hebrew copy: "הסטריק בסכנה — יש לך עד [time] לחזור למסלול"
  - Acceptance: widget test — banner visible when `inGracePeriod` is true; hidden otherwise

---

## Milestone 4 — Onboarding Flow

- [x] **Build `OnboardingScreen1` — Welcome with app illustration and CTA**
  - "בואו נתחיל" CTA navigates to screen 2
  - Acceptance: renders in RTL; CTA is tappable

- [x] **Build `OnboardingScreen2` — About You (sex, age, weight, height)**
  - Hebrew labels; numeric keyboards for weight/height
  - "כבר בקטו?" toggle — if yes, shows date picker to seed streak
  - Acceptance: widget test — all fields validate; toggle shows/hides date picker

- [x] **Build `OnboardingScreen3` — Goal selection (3 cards, single-select)**
  - Weight loss / Energy & focus / Medical condition management
  - Acceptance: widget test — exactly one card selected at a time

- [x] **Build `OnboardingScreen4` — Calculated targets (editable)**
  - Auto-computes fat/carb/protein targets from body stats; fields are editable
  - "התחל את המסע" CTA saves profile and navigates to dashboard
  - Acceptance: widget test — defaults populated; editable; saves correctly

- [x] **Implement `OnboardingService` in `onboarding/application/`**
  - Computes macro targets from sex, age, weight, height, goal
  - Seeds `StreakState` from past keto start date if provided
  - Acceptance: unit tests — target calculation correct for male/female, different goals

- [x] **Gate app entry — show onboarding on first launch; skip on subsequent launches**
  - The first-launch flag is the existence of the `user_profile` sembast record —
    no `shared_preferences`, no second store. See `design/m4_preflight.md` §4
  - Acceptance: onboarding shown exactly once; removed on reinstall

---

## Milestone 5 — Symptom Diary

- [ ] **Implement `SymptomLoggingService` in `diary/application/`**
  - Methods: `logSymptoms(SymptomLog)`, `fetchForDate(DateTime)`
  - Acceptance: unit tests with mocked `SymptomLogRepository`

- [ ] **Build `SymptomCheckInStrip` — horizontal row of 5 emoji-scale tappable icons on dashboard**
  - Energy / Clarity / Hunger / Physical / Mood; 1–5 scale
  - Tapping an icon opens a `SymptomLogSheet` pre-focused on that symptom
  - Acceptance: widget test — tapping each opens correct sheet; strip updates after save

- [ ] **Build `SymptomLogSheet` — full 1–5 scale for all 5 symptoms + optional text note**
  - Saves via `SymptomLoggingService.logSymptoms()`
  - Acceptance: widget test — valid form saves; all fields required before save enabled

- [ ] **Build `SymptomDiarySection` in `DiaryDayScreen`**
  - Shows logged symptoms for the selected date; empty state if none
  - Acceptance: widget test — correct values shown for a known fixture

---

## Milestone 6 — Keto Lens (Hebrew OCR Scanner)

### 6.1 OCR & Classification Logic

- [ ] **Add `google_mlkit_text_recognition`, `camera`, `image_picker`, `image` to `pubspec.yaml`**
  - Add required iOS `Info.plist` entries: camera usage description, photo library usage description
  - Acceptance: `flutter pub get` succeeds; app builds with new permissions

- [ ] **Implement `MlKitTextRecognizer` adapter in `keto_lens/data/`**
  - Implements `TextRecognizer` domain interface
  - Wraps `google_mlkit_text_recognition`; returns raw recognised string
  - Acceptance: unit test with a mock image file — returns a non-empty string

- [ ] **Implement `HebrewLabelParser` in `keto_lens/data/`**
  - Extracts: fat, net carbs (total carbs − fiber), protein per 100g and per serving
  - Extracts: product name, ingredients list after "רכיבים:" marker
  - Normalises OCR artefacts (whitespace, ג vs. גר mis-reads)
  - Acceptance: unit tests — correct extraction from 5 real-world Hebrew label OCR fixtures

- [ ] **Implement `IngredientClassifierImpl` in `keto_lens/data/`**
  - Forbidden seed oils → `nonKeto`
  - Insulin-spiking sweeteners → `cautionQuantityDependent`
  - No flags → `cleanKeto`
  - Worst badge wins when multiple flags present
  - Acceptance: unit tests covering all three verdict paths and mixed-ingredient worst-badge rule

- [ ] **Implement `ScanOrchestrator` service in `keto_lens/application/`**
  - Composes: `TextRecognizer` → `HebrewLabelParser` → `IngredientClassifierImpl`
  - Returns `ScanResult` (union of `ParsedLabel` + `IngredientVerdict`)
  - Acceptance: unit test with mocked recogniser — orchestrator returns correct `ScanResult`

### 6.2 UI

- [ ] **Build `CameraScreen` with live viewfinder and crop overlay**
  - Rounded-rectangle overlay with Hebrew label "כוון לתווית"; torch toggle; gallery button
  - Capture button triggers `ScanOrchestrator`; shows loading state during processing
  - Acceptance: widget test — capture button disabled when camera permission denied; permission denied state shows redirect message

- [ ] **Build `ScanResultSheet` — verdict badge, macro strip, flagged ingredients list**
  - Badge colour and Hebrew copy per `VerdictBadge` value
  - Flagged ingredients listed with one-line reason in Hebrew
  - "הוסף ליומן" pre-fills `AddMealBottomSheet` with parsed macros
  - Acceptance: widget test — correct badge, correct flagged list, correct macro values for each `VerdictBadge` case

- [ ] **Build `VerdictBadgeWidget` — standalone reusable badge chip**
  - Three variants: green (Clean Keto) / yellow (Caution) / red (Non-Keto)
  - Acceptance: widget test — correct colour and Hebrew label per variant; accessible contrast ratio

- [ ] **Wire gallery import — `image_picker` fallback from `CameraScreen`**
  - Gallery image passes through same `ScanOrchestrator` pipeline
  - Acceptance: manual test — picking an image from gallery produces a result sheet

---

## Milestone 7 — Polish, Empty States & Error Handling

- [ ] **Implement skeleton shimmer loading state for all list views**
  - Dashboard meal list, diary screen, phase timeline
  - Acceptance: shimmer visible during async load; replaced by content or empty state

- [ ] **Implement global error snackbar for transient failures (save failure, Isar error)**
  - Shown at bottom of screen; auto-dismisses after 4 seconds
  - Acceptance: widget test — error snackbar appears when repository throws

- [ ] **Implement full-screen error state for critical failure (Isar open failure)**
  - Shows retry button; tapping retries Isar open
  - Acceptance: widget test — error state renders; retry button calls open again

- [ ] **Add empty states for all list screens (diary, meal list, symptom section)**
  - Each empty state has Hebrew copy and a contextual CTA
  - Acceptance: widget test — empty state renders when provider returns empty list

- [ ] **Add app icon and launch screen assets**
  - App icon: all required sizes for iOS (`appiconset`)
  - Launch screen: branded, no spinner
  - Acceptance: `flutter build ios` completes; icon appears correctly in simulator

- [ ] **Add Hebrew `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` to `Info.plist`**
  - Acceptance: camera permission prompt shows Hebrew text on device

- [ ] **Configure `flutter_local_notifications` iOS entitlements and permission handling**
  - Acceptance: notification permission prompt appears; notifications fire correctly on simulator

---

## Milestone 8 — Integration Tests & CI

- [ ] **Write integration test: Onboarding → Dashboard seeded with targets**
  - Acceptance: after completing onboarding, dashboard shows correct macro targets

- [ ] **Write integration test: Log meal manually → Dashboard updates totals**
  - Acceptance: fat/carb/protein totals on dashboard reflect the logged meal

- [ ] **Write integration test: Complete compliant day → streak increments**
  - Acceptance: streak count increments from 0 to 1; phase badge shows Phase 1

- [ ] **Write integration test: Streak breach → grace period → expiry → reset**
  - Acceptance: grace period banner visible; after expiry, streak resets to 0

- [ ] **Write integration test: Log symptoms → view in diary**
  - Acceptance: symptom scores logged today appear in diary view for today

- [ ] **Write integration test: Navigate all tabs without crash (smoke test)**
  - Acceptance: all 5 tabs reachable; no exceptions thrown

- [ ] **Write integration test: Keto Lens scan (mock image) → result sheet → add to diary**
  - Mock `ScanOrchestrator` to return a fixture result; verify diary receives the meal
  - Acceptance: meal appears in dashboard totals after add

- [ ] **Set up GitHub Actions CI workflow**
  - Runs on every PR: `flutter analyze`, `dart format --check`, `flutter test --coverage`
  - Fails PR if coverage on `domain/` + `application/` drops below 80%
  - Acceptance: `.github/workflows/ci.yml` present; workflow runs successfully on a test PR

---

## Post-MVP — M9–M14 (split out of the former v1.1 backlog)

> The single `v1.1 — Post-MVP Backlog` milestone was split into six capability
> milestones plus a release milestone. See `design/v1_1_split.md` for why, and each
> Epic (#264–#270) for its North Star, entry conditions and invariants.
>
> **M9–M14 are numbered by recommended build order, not by dependency** — they are
> parallel peers. **M9 and M10 are the two with no external blocker.**
>
> App Store submission (#125–#128) is **not** post-MVP work — it ships v1.0 and runs
> before M9, under `epic:release-v1` / Epic #270.

### M9 — Biomarker Logging (#264) — *ready now*
- [ ] Define `BiomarkerLog` domain model and `BiomarkerLogRepository` interface
- [ ] Implement `SembastBiomarkerLogRepository` and contract tests
- [ ] Build `BiomarkerLogSheet` — ketones, glucose, weight entry
- [ ] Build `BiomarkerTrendChart` — 30-day sparkline per metric using `fl_chart`
- [ ] Add `BiomarkerSection` to `DiaryDayScreen`

### M13 — Apple Health Sync (#268) — *blocked: HealthKit entitlement*
- [ ] Add `health` package and request HealthKit entitlement
- [ ] Read body weight from HealthKit and pre-fill weight field in onboarding/profile
- [ ] Write macro totals (fat, carbs, protein) to HealthKit on each meal log

### M11 — Restaurant Directory (#266) — *blocked: content curation + map SDK re-decision*
- [ ] Curate `assets/data/directory.json` — initial set of Israeli keto-friendly restaurants
- [ ] Define `DirectoryEntry` domain model and `DirectoryReader` interface
- [ ] Implement `JsonDirectorySource` — loads and caches the bundled JSON to sembast
- [ ] Choose a web-capable map SDK (not `mapkit_flutter` — that is Yandex, and neither it nor `apple_maps_flutter` renders on web) and request location permission
- [ ] Build `DirectoryScreen` — search + filter chips + list/map toggle
- [ ] Build `RestaurantDetailSheet` — name, address, keto highlights, tips
- [ ] Build `MapView` with keto pin markers and bottom card on tap

### M10 — Recipe Converter (#265) — *ready now; audited and re-planned in `design/m10_recipe_converter_research.md`*

> The original three issues built a screen nothing could navigate to, from an engine whose
> `AlreadyKeto` outcome had no table behind it. Rewritten in place and six issues added;
> none closed. Issues 1–3 are the offline converter and the first shippable state; 6–7 the
> opt-in model pass over M15's `LlmChatClient`; 8 is the one the owner may move out.

- [ ] #393 Promote `HebrewTextNormaliser` to `lib/core/utils/` — zero behaviour change; **no final-form folding in the shared normaliser**
- [ ] #118 Substitution engine — parser, four-variant sealed `IngredientOutcome`, substitution + staples tables in `lib/core/constants/`, consistency suite against `IngredientRules`
- [ ] #119 `RecipeConverterScreen` — paste input, stacked per-line output, ratio applied to the quantity, **entry point on Home**
- [ ] #395 `SavedRecipe`, `SavedRecipeRepository`, mapper, auto-increment `saved_recipes` store, contract suite
- [ ] #120 `RecipeLibraryScreen` — list, reopen by `/recipe/saved/:id`, delete; save affordance on the converter
- [ ] #394 Promote the `LlmChatClient` interface to `lib/core/llm/` — the OpenRouter stack stays in `diary/data/`
- [ ] #396 `SubstitutionSuggester` — one request for the unrecognised lines only, on a tap, gated on `EstimationSettings.isEnabled`; every proposal checked against `IngredientRules`; `OutcomeSource.suggested` marker
- [ ] #397 Per-serving macros via `MacroEstimator`; log a serving through `AddMealBottomSheet` as `estimatedFromText`
- [ ] #398 `recipe_converter_flow.dart` (zero-request assertion included), the navigation smoke, the fixture, docs closeout

### M12 — Menu Analyzer (#267) — *superseded by M16 (#351); closure is the owner's call — do not pick up*
- [ ] Implement `MenuAnalyzerService` — OCR → dish extraction → keto suitability per dish, reusing M6's `TextRecognitionService` (Tesseract) and `IngredientVerdict`
- [ ] Build `MenuAnalyzerScreen` — camera input → dish list with badges and modification tips

### M14 — Backup & Restore (#269) — *needs re-spec for sembast + web*
- [ ] Implement versioned JSON backup export (destination decision: platform-neutral share/download vs iOS-only iCloud)
- [ ] Implement validated, atomic import/restore from a backup file

### M15 — Meal Entry (#312) — **shipped**
- [x] #315 Add `MacroSource` to `MealEntry` + mapper + contract tests, decoding a pre-M15 record as `manual`
- [x] #316 Add the sealed `MealEstimate` and the `MacroEstimator` interface
- [x] #317 Store the BYOK API key and consent flag in their own `estimation_settings` store — **never in `user_profile`**, whose record existence is the first-launch sentinel
- [x] #318 Add `OpenRouterClient` with typed transport failures and an injected `http.Client`
- [x] #319 Implement `RemoteMacroEstimator` for a Hebrew description — prompt, tolerant parse, `NumericInput.positiveFinite` on every returned number
- [x] #320 Extend it to a meal photograph — downscale, re-encode, cap, base64
- [x] #321 Add the estimation settings section: key field, disclosure, masked key, state line — the screen itself had already shipped in #310
- [x] #322 Put a three-mode chooser behind `AddMealFab` — inside the FAB, so both hosts get it
- [x] #323 Build the description mode — itemised editable review, one failure copy per reason
- [x] #324 Build the photo mode — **label OCR first**, estimate second, `imageRef` attached
- [x] #325 Show provenance on a meal card so an estimate reads as an estimate
- [x] #326 Add **four** e2e flows and close out the docs (`mvp.md`'s offline claim, the privacy labels) — the issue said three; the edit route needed one of its own

- [x] #327 Add `MealLoggingService.updateMeal`, recalculating both days a moved meal touches
- [x] #328 Let a saved meal be edited from its card, re-sourcing corrected macros to `manual`

**What M15 changed, in one line each.** A `+` now asks *how* before *what*,
from both hosts. A meal can be described in Hebrew or photographed. A
photograph is read as a **label first** and estimated only when that fails,
so the free offline path is never skipped. Every estimate is reviewed item by
item before it is saved, and what the review shows is what gets logged. A
meal carries where its macros came from, and can be corrected after saving —
which re-sources it to `manual`, because a badge that keeps calling a
human-corrected figure a guess is a badge people learn to ignore.

### M16 — AI Menu Scanner (#351) — *shipped; see `design/m16_menu_scanner_research.md`*
- [x] #352 Assemble a Hebrew menu corpus — ≥ 5 real transcripts and one verbatim Tesseract transcript of a photographed menu, as fixtures
- [x] #353 Add the menu domain — `DishVerdict`, `AnalysedDish`, sealed `MenuAnalysis`, `MenuAnalysisFailureReason`, `MenuPagesText`, the `MenuAnalyzer` interface
- [x] #354 Add `PhotoPicker.pickMultiple()` — the only change inside `keto_lens/` besides one chip row
- [x] #355 Lift the LLM transport seam to `lib/core/services/llm/`; add `maxOutputTokens` and `responseSchema` — *after #318*
- [x] #356 Add `MenuVerdictRules` (the three-state definitions the prompt and the legend share) and `MenuAnalysisPrompt`
- [x] #357 Implement `MenuResponseParser` — a yellow without an instruction and a dish the text does not contain both go to *unclassified*
- [x] #358 Implement `MenuPageReader` — sequential on-device OCR per page, unread pages reported
- [x] #359 Build `DishCard` — expandable; why; modification with a copy button
- [x] #360 Extend the estimation disclosure to name menu text — *after #321*
- [x] #361 Implement `RemoteMenuAnalyzer` — one request per menu, **never an image part**
- [x] #362 Build `MenuResultView` — green, yellow, a collapsed red group with a count, unclassified, unread pages
- [x] #364 Build `MenuScannerScreen` with the pasted-text mode, `/lens/menu` and the `תפריט` chip on the lens tab
- [x] #365 Build the photo pages mode — capture or import up to 8 pages, per-page progress
- [x] #366 Add two e2e flows and close out the docs (`technology.md` §6, `ui_ux_design.md` §7, `architecture.md`, `CLAUDE.md`) — a real photographed-menu OCR transcript (#372/#373) is the one honest gap left; see `design/m16_menu_scanner_research.md` §10
- [x] #405 Add `PdfPageExtractor`/`PdfPagesText` domain + `PdfrxPageExtractor` adapter, with the Hebrew legibility guard (trim-empty → `minExtractedLetters` → `minHebrewLetterRatio`) that routes an unreadable page to `pagesWithoutTextLayer` rather than keeping partial text
- [x] #406 Add `renderPages` — rasterise pages with no usable text layer to PNG at `MenuVerdictRules.pdfRenderWidthPx` (derived from `OcrImagePrep.targetWidth`), sequential, aspect-ratio preserved
- [x] #407 Add `DocumentPicker`/`FileSelectorDocumentPicker` over `file_selector`, alongside `photoPickerProvider`
- [x] #408 Add `MenuInputMode` (pasteText / photoPages / pdfFile), `MenuPdfTab`, the extract-then-rasterise-then-analyse path, `pdfUnreadable`/`pdfNeedsOcr` failure reasons, and `menu_pdf_flow.dart` — **code-complete; #373's two remaining real menus and a real Hebrew menu PDF are still open, and only web + Linux are platform-verified for the new `pdfrx`/`file_selector` dependencies** (`design/m16_menu_scanner_research.md` §12)

### Release v1.0 — App Store Launch (#270) — *ships the MVP; runs before M9*
- [ ] Add Hebrew `App Store Connect` metadata (description, keywords, screenshots)
- [ ] Complete Apple privacy nutrition labels
- [ ] Submit for TestFlight review with 20–30 beta users
- [ ] Address beta feedback; submit to App Store
