# Architecture — Fantastic

## Principles

1. **Offline-first** — every feature works without a network connection.
2. **Unidirectional data flow** — UI observes state; state changes only via explicit actions through the application layer.
3. **Feature isolation** — features share domain models and `core/` utilities, never each other's internal layers.
4. **Testability at every layer** — domain and application layers have zero Flutter dependencies.
5. **Code generation, not boilerplate** — Riverpod providers are generated. (Persistence is not: sembast records are plain maps, hand-written in each feature's `data/mappers/`.)

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
│  sembast Stores  ·  Repository Implementations           │
│  ML Kit Adapters  ·  Mappers (Record ↔ Domain)           │
└──────────────────────────────────────────────────────────┘
```

Arrows only point downward. The data layer depends on the domain layer (implements its interfaces), but the domain layer knows nothing about sembast.

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
│   │   ├── domain/
│   │   │   ├── models/         # DailyLog, StreakState, AdaptationPhase
│   │   │   └── repositories/   # DailyLogRepository, StreakRepository (interfaces)
│   │   └── data/           # SembastDailyLogRepository, SembastStreakRepository
│   │
│   ├── keto_lens/
│   │   ├── presentation/   # CameraScreen, ResultSheet, BadgeWidget
│   │   ├── application/    # ScanOrchestrator, providers
│   │   ├── domain/
│   │   │   ├── models/         # ParsedLabel, IngredientVerdict, VerdictBadge
│   │   │   └── services/       # LabelParser, IngredientClassifier (interfaces)
│   │   └── data/           # MlKitTextRecognizer, HebrewLabelParser, IngredientClassifierImpl
│   │
│   ├── diary/
│   │   ├── presentation/   # DiaryScreen, SymptomRow, BiomarkerCard
│   │   ├── application/    # DiaryService, providers
│   │   ├── domain/
│   │   │   ├── models/         # MealEntry, SymptomLog, BiomarkerLog
│   │   │   └── repositories/   # MealRepository, SymptomLogRepository (interfaces)
│   │   └── data/
│   │       ├── mappers/        # MealEntryMapper, SymptomLogMapper
│   │       └── repositories/   # SembastMealRepository, SembastSymptomLogRepository
│   │
│   ├── adaptation/
│   │   ├── presentation/   # PhaseDetailScreen, TimelineWidget, StreakCalendar
│   │   ├── application/    # AdaptationPhaseService, ElectrolyteAdvisor, providers
│   │   ├── domain/
│   │   │   ├── models/         # StreakState, AdaptationPhase
│   │   │   └── repositories/   # StreakRepository (interface)
│   │   └── data/           # StreakStateMapper, SembastStreakRepository
│   │
│   ├── restaurant/
│   │   ├── presentation/   # DirectoryScreen, MapView, RestaurantDetailSheet
│   │   ├── application/    # DirectoryService, MenuAnalyzerService, providers
│   │   ├── domain/
│   │   │   ├── models/         # DirectoryEntry, DirectoryFilter
│   │   │   └── repositories/   # DirectoryReader (interface)
│   │   └── data/           # StaticJsonDirectorySource
│   │
│   ├── menu/                # M16 — pasted-text / photographed-page / PDF menu scanner
│   │   ├── presentation/   # MenuScannerScreen, MenuPagesTab, MenuPdfTab, MenuResultView, DishCard
│   │   ├── application/    # MenuPageReader, RemoteMenuAnalyzer
│   │   ├── domain/
│   │   │   ├── models/         # MenuAnalysis, AnalysedDish, DishVerdict, MenuPagesText, PdfPagesText
│   │   │   └── services/       # MenuAnalyzer, PdfPageExtractor (interfaces)
│   │   └── data/
│   │       ├── adapters/       # PdfrxPageExtractor — the only lib/ file importing pdfrx
│   │       └── analysis/       # MenuAnalysisPrompt, MenuResponseParser, provider wiring
│   │       # PDF/photo picking (DocumentPicker, FileSelectorDocumentPicker) lives with
│   │       # PhotoPicker under keto_lens/presentation/camera/ — shared, not duplicated per feature
│   │
│   ├── recipe/
│   │   ├── presentation/   # RecipeConverterScreen, SubstitutionList, RecipeLibraryGrid
│   │   ├── application/    # RecipeConverterService, providers
│   │   ├── domain/
│   │   │   ├── models/         # Recipe, Ingredient, SubstitutionRule
│   │   │   └── repositories/   # RecipeRepository (interface)
│   │   └── data/           # SembastRecipeRepository, SubstitutionRuleEngine
│   │
│   └── directory/          # (alias entry point — delegates to restaurant feature)
│
└── main.dart               # ProviderScope root, app initialisation, database open
```

---

## State Management — Riverpod

### Provider Hierarchy

```
DatabaseProvider (singleton)
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
- `streakProvider` is a stream provider watching the singleton streak record via `onSnapshot`. Automatically emits on subscription and on any write.
- Presentation providers `ref.watch()` service providers — never call the database directly.

---

## Local Persistence — sembast

### Record Overview

Stores of `Map<String, Object?>` records, not typed schemas — see
`CLAUDE.md` §Local Persistence for the store/key table and the value-encoding
rules, and `design/web_support.md` for why sembast replaced Isar.

```
MealEntry         DailyLog          SymptomLog         BiomarkerLog
─────────         ────────          ──────────         ────────────
id                id                id                 id
timestamp         date (indexed)    date (indexed)     date (indexed)
fatG              totalFatG         energyScore 1-5    bloodKetones
netCarbsG         totalNetCarbsG    clarityScore 1-5   breathKetones
proteinG          totalProteinG     hungerScore 1-5    fastingGlucose
ingredients[]     waterMl           moodScore 1-5      bodyWeightKg
imageRef          sodiumMg          symptoms[]         notes
mealName          potassiumMg       notes
                  magnesiumMg
                  ketoRatioAvg
```

`SymptomLog.symptoms` is a `Set<PhysicalSymptom>` stored as a list of enum
`.name` strings, sorted by enum index so two logs with the same symptoms
produce byte-identical records. Renaming a `PhysicalSymptom` value orphans
every record that stored it — see `design/web_support.md` §4.

`MealEntry.ketoRatio` is a **computed getter**, not a stored column — a
persisted copy can go stale against the macros it was derived from.
`DailyLog.ketoRatioAvg` *is* stored, because it averages across meals that are
no longer individually loaded when the dashboard reads the day.

An earlier version of this table listed a `calories` column on `MealEntry`. No
issue implements it and the MVP tracks fat / net carbs / protein only, so it
has been dropped rather than left as a field nobody creates.

```

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

### sembast Patterns

- All `StoreRef`s live in `data/` — never imported from `domain/` or `presentation/`.
- Codecs (`XxxMapper.toRecord` / `fromRecord`) live in `data/mappers/`, beside the repository that uses them.
- Each store is declared next to the repository that owns it and enumerated in `test/core/database/store_names_test.dart`. sembast creates a store on first write, so a name collision merges two collections silently — that test is the only thing that catches it.
- The database is opened once in `main.dart` through the conditional export in `lib/core/database/database_factory.dart` (io on the VM, IndexedDB in a browser) and injected via `databaseProvider`.
- A one-record-per-day collection is keyed on its own `dateIndex`, which makes `save` an upsert with no unique index and no read-modify-write.
- Record values are JSON-compatible only: `DateTime` as epoch millis, enums by `.name`, every number decoded through `num`.

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
MealRepository.save(entry)              → sembast write
       │
       ▼
DailyLogRepository.upsert(updatedLog)   → sembast write (aggregate totals)
       │
       ▼
AdaptationPhaseService.recordCompliantDay(today)
       │  checks if net carbs ≤ target
       ▼
StreakRepository.save(newStreakState)    → sembast write
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
/lens/menu              → MenuScannerScreen (M16 — shipped; reached from the
                          lens tab's `תפריט` chip, a child route so the lens
                          tab stays lit)
/diary                  → DiaryScreen
/diary/:date            → DiaryDayScreen
/adaptation             → PhaseDetailScreen (modal)
/restaurants            → DirectoryScreen
/restaurants/:id        → RestaurantDetailSheet (modal)
/restaurants/:id/menu   → still unbuilt — M11's directory does not exist yet;
                          `MenuScannerScreen` above is the shipped entry point
/recipe                 → RecipeConverterScreen
/recipe/library         → RecipeLibraryScreen
/profile                → ProfileScreen
/settings               → SettingsScreen
/onboarding             → OnboardingFlow (replaces root on first launch)
```

Deep links are supported for `/restaurants/:id` to allow sharing restaurant cards.

---

## Code Generation

Two generators run via `build_runner`:

| Generator | Input annotation | Output |
|---|---|---|
| `riverpod_generator` | `@riverpod` on provider functions/classes | `.g.dart` provider definitions |

`json_serializable` is **not** a dependency — earlier drafts listed it as a
third generator, but nothing uses `@JsonSerializable` and the MVP has no remote
DTOs. Persistence needs no generator at all; see
`design/m0_handoff.md` §1 for why.

Always run:
```bash
timeout 120 dart run build_runner build --verbose
git status --short
```

**`build_runner` never exits.** It finishes in about a second, then idles
indefinitely, so `timeout`'s exit code 124 is the expected outcome — judge the
run by whether the `.g.dart` files are right, not by its exit status.
`--verbose` is required, and never pipe it into `tail` or `head`: those cannot
print until a pipe closes that never does, so you see nothing at all.
after modifying any annotated file.

---

## Error & Loading States

Every async provider exposes `AsyncValue<T>`. UI uses `.when(data:, loading:, error:)`.

Loading states:
- Skeleton shimmer cards (not spinners) for list views
- Inline spinner inside buttons during form submission

Error states:
- Toast-style bottom snackbar for transient errors (network, save failure)
- Full-screen error card with retry button for critical failures (database open failure — `StartupFailureApp` in `main.dart`)

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
| Repository contract | Integration | In-memory sembast (`newDatabaseFactoryMemory`) |
| Riverpod providers | Unit | `ProviderContainer.test()` — riverpod 3's built-in replacement for `riverpod_test`, which is not a dependency (see `design/m0_handoff.md` §3) |
| Widgets | Widget | `flutter_test` + `mocktail` |
| Full flows | Integration | `integration_test` on simulator |

Contract tests (`runXxxRepositoryContractTests`) ensure every repository implementation passes the same behavioural assertions.
