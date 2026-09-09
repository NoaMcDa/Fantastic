# Architecture — Fantastic

## Principles

1. **Offline-first** — every feature works without a network connection.
2. **Unidirectional data flow** — UI observes state; state changes only via explicit actions through the application layer.
3. **Feature isolation** — features share domain models and `core/` utilities, never each other's internal layers.
4. **Testability at every layer** — domain and application layers have zero Flutter dependencies.
5. **Code generation, not boilerplate** — Isar schemas, Riverpod providers, and JSON serialisation are all generated.

---

## Layer Model

```
┌──────────────────────────────────────────────────────────┐
│                     Presentation Layer                    │
│   Flutter Widgets  ·  Screens  ·  UI Riverpod Providers  │
└────────────────────────────┬─────────────────────────────┘
                             │ depends on
┌────────────────────────────▼─────────────────────────────┐
│                    Application Layer                      │
│  Use-case Services  ·  State Machines  ·  Calculators    │
│  Business Riverpod Providers  ·  DTOs                    │
└────────────────────────────┬─────────────────────────────┘
                             │ depends on
┌────────────────────────────▼─────────────────────────────┐
│                      Domain Layer                         │
│  Pure Dart Models  ·  Repository Interfaces              │
│  Value Objects  ·  Enums  ·  Domain Exceptions           │
└────────────────────────────┬─────────────────────────────┘
                             │ implemented by
┌────────────────────────────▼─────────────────────────────┐
│                       Data Layer                          │
│  Isar Schema Classes  ·  Repository Implementations      │
│  ML Kit Adapters  ·  Mappers (Isar ↔ Domain)             │
└──────────────────────────────────────────────────────────┘
```

Arrows only point downward. The data layer depends on the domain layer (implements its interfaces), but the domain layer knows nothing about Isar.

---

## Directory Structure

```
lib/
├── core/
│   ├── constants/          # app-wide constants (macro targets, ingredient lists)
│   ├── theme/              # ThemeData, colour tokens, text styles
│   └── utils/              # date helpers, string normalisation, RTL utilities
│
├── features/
│   ├── dashboard/
│   │   ├── presentation/   # DashboardScreen, macro widgets, streak ring
│   │   ├── application/    # DashboardSummaryService, providers
│   │   ├── domain/         # DailyLog, StreakState, AdaptationPhase
│   │   └── data/           # IsarDailyLogRepository, IsarStreakRepository
│   │
│   ├── keto_lens/
│   │   ├── presentation/   # CameraScreen, ResultSheet, BadgeWidget
│   │   ├── application/    # ScanOrchestrator, providers
│   │   ├── domain/         # ParsedLabel, IngredientVerdict, LabelParser (interface)
│   │   └── data/           # MlKitTextRecognizer, HebrewLabelParser, IngredientClassifierImpl
│   │
│   ├── diary/
│   │   ├── presentation/   # DiaryScreen, SymptomRow, BiomarkerCard
│   │   ├── application/    # DiaryService, providers
│   │   ├── domain/         # MealEntry, SymptomLog, BiomarkerLog, DiaryRepository (interfaces)
│   │   └── data/           # IsarMealRepository, IsarSymptomRepository, IsarBiomarkerRepository
│   │
│   ├── adaptation/
│   │   ├── presentation/   # PhaseDetailScreen, TimelineWidget, StreakCalendar
│   │   ├── application/    # AdaptationPhaseService, ElectrolyteAdvisor, providers
│   │   ├── domain/         # StreakState, AdaptationPhase, StreakRepository (interface)
│   │   └── data/           # IsarStreakRepository
│   │
│   ├── restaurant/
│   │   ├── presentation/   # DirectoryScreen, MapView, RestaurantDetailSheet
│   │   ├── application/    # DirectoryService, MenuAnalyzerService, providers
│   │   ├── domain/         # DirectoryEntry, DirectoryFilter, DirectoryReader (interface)
│   │   └── data/           # StaticJsonDirectorySource, MlKitMenuAnalyzer
│   │
│   ├── recipe/
│   │   ├── presentation/   # RecipeConverterScreen, SubstitutionList, RecipeLibraryGrid
│   │   ├── application/    # RecipeConverterService, providers
│   │   ├── domain/         # Recipe, Ingredient, SubstitutionRule, RecipeRepository (interface)
│   │   └── data/           # IsarRecipeRepository, SubstitutionRuleEngine
│   │
│   └── directory/          # (alias entry point — delegates to restaurant feature)
│
└── main.dart               # ProviderScope root, app initialisation, Isar open
```

---

## State Management — Riverpod

### Provider Hierarchy

```
IsarProvider (singleton)
    └── Repository Providers  (one per schema)
            └── Service Providers  (one per use-case group)
                    └── UI Providers  (AsyncNotifier / StreamNotifier per screen)
```

### Provider Types by Use

| Use | Provider type |
|---|---|
| Single async value (e.g., today's log) | `@riverpod Future<DailyLog?>` |
| Reactive stream (e.g., streak watch) | `@riverpod Stream<StreakState>` |
| Mutable UI state (e.g., meal form) | `@riverpod class MealFormNotifier extends AsyncNotifier` |
| Singleton service | `@riverpod ServiceClass service(Ref ref)` |
| App-wide config | `@riverpod AppConfig appConfig(Ref ref)` |

All providers use `@riverpod` (code-generated). No manual `Provider(...)` calls.

### Invalidation Strategy

- `dailyLogProvider(date)` is a family provider keyed by `DateTime`. Invalidated on every meal save.
- `streakProvider` is a stream provider watching the Isar collection. Automatically emits on any write.
- Presentation providers `ref.watch()` service providers — never call Isar directly.

---

## Local Persistence — Isar

### Schema Overview

```
MealEntry         DailyLog          SymptomLog         BiomarkerLog
─────────         ────────          ──────────         ────────────
id                id                id                 id
timestamp         date (indexed)    date (indexed)     date (indexed)
fatG              totalFatG         energyScore 1-5    bloodKetones
netCarbsG         totalNetCarbsG    clarityScore 1-5   breathKetones
proteinG          totalProteinG     hungerScore 1-5    fastingGlucose
calories          waterMl           physicalScore 1-5  bodyWeightKg
ingredients[]     sodiumMg          moodScore 1-5      notes
imageRef          potassiumMg       notes
mealName          magnesiumMg
ketoRatio         ketoRatioAvg

StreakState       RecipeEntry       DirectoryEntry (cached)
───────────       ───────────       ───────────────────────
id                id                id (remote)
currentStreak     name              nameHe
highestStreak     originalText      nameEn
phaseEnum         ingredients[]     city
lastCompliantDate substitutions[]   category
inGracePeriod     macrosPerServing  ketoScore
gracePeriodEnd    savedAt           ketoTips[]
                                    lastUpdated
```

### Isar Patterns

- All schemas live in `data/` — never imported from `domain/` or `presentation/`.
- Mappers (`IsarMealEntry.toDomain()` / `MealEntry.toIsar()`) live alongside schemas.
- Collections are opened once in `main.dart` via `Isar.open([...])` and injected via `isarProvider`.
- Queries always use Isar's type-safe query builder, never raw strings.

---

## OCR & ML Pipeline

```
User taps capture
       │
       ▼
ImageCapture (camera / gallery)
       │  XFile
       ▼
MlKitTextRecognizer.recognize(image)
       │  raw String (Hebrew OCR output)
       ▼
HebrewLabelParser.parse(rawText)
       │  normalises whitespace, fixes common OCR mis-reads
       │  extracts: productName, per100g macros, perServing macros, ingredients[]
       ▼
ParsedLabel (domain model)
       │
       ▼
IngredientClassifierImpl.classify(ingredients)
       │  rule-based: forbidden seed oils, insulin-spiking sweeteners, approved fats
       ▼
IngredientVerdict (badge + flaggedIngredients + reason)
       │
       ▼
ResultSheet renders badge + macros + flagged list
```

All steps are synchronous after the async `recognize()` call. No network involved.

---

## Data Flow — Adding a Meal

```
User taps "הוסף ליומן" on ResultSheet
       │
       ▼
MealFormNotifier.submit(MealEntry draft)
       │
       ▼
MealLoggingService.logMeal(draft)
       │  validates: timestamp, non-negative macros
       ▼
MealRepository.save(entry)              → Isar write
       │
       ▼
DailyLogRepository.upsert(updatedLog)   → Isar write (aggregate totals)
       │
       ▼
AdaptationPhaseService.recordCompliantDay(today)
       │  checks if net carbs ≤ target
       ▼
StreakRepository.save(newStreakState)    → Isar write
       │
       ▼
Riverpod invalidates: dailyLogProvider, streakProvider
       │
       ▼
Dashboard automatically rebuilds via reactive stream
```

---

## Navigation

Router: `go_router` with a `ShellRoute` wrapping the tab bar.

```
/                       → HomeScreen (Dashboard)
/lens                   → CameraScreen
/lens/result            → ResultSheet (modal)
/diary                  → DiaryScreen
/diary/:date            → DiaryDayScreen
/adaptation             → PhaseDetailScreen (modal)
/restaurants            → DirectoryScreen
/restaurants/:id        → RestaurantDetailSheet (modal)
/restaurants/:id/menu   → MenuAnalyzerScreen
/recipe                 → RecipeConverterScreen
/recipe/library         → RecipeLibraryScreen
/profile                → ProfileScreen
/settings               → SettingsScreen
/onboarding             → OnboardingFlow (replaces root on first launch)
```

Deep links are supported for `/restaurants/:id` to allow sharing restaurant cards.

---

## Code Generation

Three generators run via `build_runner`:

| Generator | Input annotation | Output |
|---|---|---|
| `isar_generator` | `@Collection` on Isar schema classes | `.g.dart` schema files + query extensions |
| `riverpod_generator` | `@riverpod` on provider functions/classes | `.g.dart` provider definitions |
| `json_serializable` | `@JsonSerializable` on remote DTOs | `.g.dart` `fromJson`/`toJson` |

Always run:
```bash
dart run build_runner build --delete-conflicting-outputs
```
after modifying any annotated file.

---

## Error & Loading States

Every async provider exposes `AsyncValue<T>`. UI uses `.when(data:, loading:, error:)`.

Loading states:
- Skeleton shimmer cards (not spinners) for list views
- Inline spinner inside buttons during form submission

Error states:
- Toast-style bottom snackbar for transient errors (network, save failure)
- Full-screen error card with retry button for critical failures (Isar open failure)

---

## Apple Platform Integrations

| Integration | Purpose |
|---|---|
| Apple Health (HealthKit) | Read body weight, write active energy; read steps for activity context |
| iCloud (CloudKit) | Optional backup of diary data; not used for sync between devices in v1 |
| CoreLocation | "Near me" filtering in restaurant directory |
| AVFoundation | Camera access for Keto Lens and Menu Analyzer |
| UserNotifications | Daily log reminders, streak warnings |

All platform integrations are wrapped behind domain interfaces and injected via Riverpod — no raw platform calls from widgets.

---

## Testing Strategy

| Layer | Test type | Tools |
|---|---|---|
| Domain models | Unit | `dart test` — no mocks needed |
| Application services | Unit | `mocktail` mocks of domain interfaces |
| Repository contract | Integration | Real Isar instance (in-memory) |
| Riverpod providers | Unit | `riverpod_test` + `ProviderContainer` |
| Widgets | Widget | `flutter_test` + `mocktail` |
| Full flows | Integration | `integration_test` on simulator |

Contract tests (`runXxxRepositoryContractTests`) ensure every repository implementation passes the same behavioural assertions.
