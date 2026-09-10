# Tasks — Fantastic

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
  - Fields: `id`, `date`, `energyScore`, `clarityScore`, `hungerScore`, `physicalScore`, `moodScore`, `notes` (all scores 1–5)
  - Acceptance: pure Dart; scores validated in constructor (1 ≤ n ≤ 5)

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

- [ ] **Build `OnboardingScreen1` — Welcome with app illustration and CTA**
  - "בואו נתחיל" CTA navigates to screen 2
  - Acceptance: renders in RTL; CTA is tappable

- [ ] **Build `OnboardingScreen2` — About You (sex, age, weight, height)**
  - Hebrew labels; numeric keyboards for weight/height
  - "כבר בקטו?" toggle — if yes, shows date picker to seed streak
  - Acceptance: widget test — all fields validate; toggle shows/hides date picker

- [ ] **Build `OnboardingScreen3` — Goal selection (3 cards, single-select)**
  - Weight loss / Energy & focus / Medical condition management
  - Acceptance: widget test — exactly one card selected at a time

- [ ] **Build `OnboardingScreen4` — Calculated targets (editable)**
  - Auto-computes fat/carb/protein targets from body stats; fields are editable
  - "התחל את המסע" CTA saves profile and navigates to dashboard
  - Acceptance: widget test — defaults populated; editable; saves correctly

- [ ] **Implement `OnboardingService` in `dashboard/application/`**
  - Computes macro targets from sex, age, weight, height, goal
  - Seeds `StreakState` from past keto start date if provided
  - Acceptance: unit tests — target calculation correct for male/female, different goals

- [ ] **Gate app entry — show onboarding on first launch; skip on subsequent launches**
  - Use a `hasCompletedOnboarding` flag persisted in Isar (or `shared_preferences`)
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

## Post-MVP — v1.1 Backlog (Deferred, Lower Priority)

### Biomarker Logging
- [ ] Define `BiomarkerLog` domain model and `BiomarkerLogRepository` interface
- [ ] Implement `IsarBiomarkerLogRepository` and contract tests
- [ ] Build `BiomarkerLogSheet` — ketones, glucose, weight entry
- [ ] Build `BiomarkerTrendChart` — 30-day sparkline per metric using `fl_chart`
- [ ] Add `BiomarkerSection` to `DiaryDayScreen`

### Apple Health Integration
- [ ] Add `health` package and request HealthKit entitlement
- [ ] Read body weight from HealthKit and pre-fill weight field in onboarding/profile
- [ ] Write macro totals (fat, carbs, protein) to HealthKit on each meal log

### Restaurant Directory
- [ ] Curate `assets/data/directory.json` — initial set of Israeli keto-friendly restaurants
- [ ] Define `DirectoryEntry` domain model and `DirectoryReader` interface
- [ ] Implement `JsonDirectorySource` — loads and caches JSON to Isar on first launch
- [ ] Add `mapkit_flutter` and request location permission
- [ ] Build `DirectoryScreen` — search + filter chips + list/map toggle
- [ ] Build `RestaurantDetailSheet` — name, address, keto highlights, tips
- [ ] Build `MapView` with keto pin markers and bottom card on tap

### Recipe Converter
- [ ] Define substitution rule engine with common Hebrew/English ingredient mappings
- [ ] Build `RecipeConverterScreen` — paste or scan input; substitution side-by-side output
- [ ] Build `RecipeLibraryScreen` — saved converted recipes grid

### Menu Analyzer
- [ ] Implement `MenuAnalyzerService` — OCR → dish extraction → keto suitability per dish
- [ ] Build `MenuAnalyzerScreen` — camera input → dish list with badges and modification tips

### iCloud Backup
- [ ] Implement Isar export to JSON; store in iCloud Documents container
- [ ] Implement import/restore flow from iCloud backup

### App Store Submission
- [ ] Add Hebrew `App Store Connect` metadata (description, keywords, screenshots)
- [ ] Complete Apple privacy nutrition labels
- [ ] Submit for TestFlight review with 20–30 beta users
- [ ] Address beta feedback; submit to App Store
