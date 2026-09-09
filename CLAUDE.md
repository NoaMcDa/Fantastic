# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Fantastic** is an all-in-one keto companion app built with Flutter, targeting iOS. It features on-device Hebrew label OCR, keto ratio & electrolyte tracking, adaptation phase tracking, restaurant menu analysis, recipe conversion, a biomarker/symptom diary, and a curated Israeli keto directory.

## Design Documents

All design decisions are documented in `design/`. Read these before making architectural or product decisions.

| File | Contents |
|---|---|
| `design/base_design.md` | SOLID abstractions — repository interfaces, service contracts, domain models, Result<T> pattern |
| `design/architecture.md` | Layer model, Isar schemas, Riverpod provider hierarchy, OCR pipeline, data flow, routing |
| `design/mvp.md` | MVP scope — 5 must-ship features, build order, success metrics, what is deferred |
| `design/technology.md` | Per-feature technology evaluation and full pubspec.yaml dependency list |
| `design/ui_ux_design.md` | Full RTL/Hebrew UI spec for all screens — colour palette, tab structure, page layouts |
| `design/tests.md` | Testing strategy — pyramid, unit/widget/integration patterns, fixture conventions, CI gate |
| `design/developing_rules.md` | **Mandatory developer workflow SOP** — follow this for every issue without exception |
| `design/market_search.md` | Competitor analysis and differentiation strategy |

## Developer Workflow

**Every issue follows the SOP in `design/developing_rules.md` exactly.** The abbreviated sequence is:

```bash
# 1. Branch from latest main
git checkout main && git pull origin main
git checkout -b feat/issue-<n>-<short-description>

# 2. Read the issue
gh issue view <n>

# 3. Implement + lint continuously
flutter analyze
dart format lib/ test/

# 4. Write tests alongside implementation
flutter test test/features/<feature>/

# 5. Full validation gate — all must pass before committing
flutter analyze
dart format --output=none --set-exit-if-changed lib/ test/
flutter test
flutter test --coverage
# if @collection, @riverpod, or @JsonSerializable changed:
dart run build_runner build --delete-conflicting-outputs && flutter test

# 6. Commit (stage specific files only — never git add .)
git add <specific files>
git commit -m "feat(#<n>): <description>

Closes #<n>"

# 7. Push and open PR
git push -u origin <branch>
gh pr create --base main --title "..." --body "..."
```

Branch naming: `feat/issue-<n>-<desc>` · `fix/issue-<n>-<desc>` · `chore/...` · `refactor/...`  
Commit style: Conventional Commits — `feat(#12): add Hebrew OCR scanner`  
PRs always target `main`. Never commit directly to `main`.

## Common Commands

```bash
# Run on iOS simulator
flutter run

# Run on a specific device
flutter run -d <device-id>

# Build for iOS release
flutter build ios --release

# Run all tests
flutter test

# Run tests for a single feature
flutter test test/features/<feature_name>/

# Run a single test file
flutter test test/path/to/test_file.dart

# Run tests with coverage
flutter test --coverage

# Analyze code (lint)
flutter analyze

# Format code
dart format .

# Format check only (no writes — used in CI)
dart format --output=none --set-exit-if-changed lib/ test/

# Get/update dependencies
flutter pub get

# Generate code (Isar schemas, Riverpod, JSON serialisation)
dart run build_runner build --delete-conflicting-outputs

# Watch for code generation changes
dart run build_runner watch --delete-conflicting-outputs

# View a GitHub issue
gh issue view <number>

# Create a PR
gh pr create --base main --title "..." --body "..."
```

## Architecture

Feature-first layered architecture. Each feature lives in `lib/features/<feature_name>/` and is divided into four layers:

- **presentation/** — Flutter widgets, screens, and Riverpod UI providers
- **application/** — Use-case services and business logic orchestration (e.g., streak calculation, phase state machine)
- **domain/** — Pure Dart models and repository interfaces (no Flutter/Isar dependencies)
- **data/** — Isar schema implementations of domain repositories

Shared code (constants, utilities, theming) lives in `lib/core/`.

### Layer Rules — Non-Negotiable
- No Isar types in `domain/` or `presentation/`
- No Flutter imports in `application/` or `domain/`
- No widget reads Isar directly — always through a repository interface
- No new provider calls Isar directly — always through a service

### Features
| Feature | Directory |
|---|---|
| Dashboard & macro tracking | `lib/features/dashboard/` |
| Keto Lens (Hebrew OCR scanner) | `lib/features/keto_lens/` |
| Diary (meals, symptoms, biomarkers) | `lib/features/diary/` |
| Adaptation phase & streak | `lib/features/adaptation/` |
| Restaurant directory | `lib/features/restaurant/` |
| Recipe converter | `lib/features/recipe/` |
| Israeli keto directory | `lib/features/directory/` |

## MVP Scope

The MVP (see `design/mvp.md`) ships exactly these 5 features:
1. **Keto Lens** — Hebrew OCR label scanner with Clean/Caution/Non-Keto badge
2. **Daily Macro Tracker** — manual meal logging, keto ratio, electrolytes, dashboard
3. **Adaptation Phase Tracker & Streak** — 3-phase state machine, streak ring, push notifications
4. **Onboarding** — 4-screen flow, personalised macro targets, streak seeding
5. **Symptom Diary** — lightweight 1–5 daily ratings

Everything else (restaurant directory, recipe converter, menu analyzer, biomarker logging, Apple Health) is deferred to v1.1.

## State Management

Riverpod is the sole state management solution. All providers use `@riverpod` (code-generated via `riverpod_generator`). No manual `Provider(...)` calls.

Provider hierarchy:
```
IsarProvider → Repository Providers → Service Providers → UI Providers
```

Providers are defined in `application/` (services) or `presentation/` (UI state). Never define a provider in `domain/` or `data/`.

## Local Persistence

Isar for offline-first NoSQL storage. Key schemas (all in `data/` layers):
- `MealEntry` — macros, ingredients, timestamp, image reference
- `DailyLog` — net carbs, fats, protein, water, electrolytes (Na/K/Mg)
- `SymptomLog` — energy, mental clarity, hunger, physical symptoms (1–5 scales)
- `BiomarkerLog` — blood/breath ketones, fasting glucose, body weight
- `StreakState` — current streak, highest streak, adaptation phase enum, grace period state
- `RecipeEntry` — converted keto recipes

Always run `build_runner build` after modifying any file annotated with `@collection`.  
Each schema has a domain mapper (`IsarXxx.toDomain()` / `Xxx.toIsar()`) that lives alongside the schema file.

## OCR & ML

Uses `google_mlkit_text_recognition` for on-device Hebrew text recognition — no network call is made for OCR. Pipeline:

```
Camera capture → MlKitTextRecognizer → HebrewLabelParser → IngredientClassifier → IngredientVerdict
```

Ingredient classification rules:
- **Forbidden seed oils:** canola, soybean, corn, sunflower, cottonseed, safflower
- **Insulin-spiking sweeteners:** maltitol, sorbitol, dextrose, maltodextrin, HFCS
- **Clean approvals:** olive oil, avocado oil, coconut oil, butter, ghee, tallow, monk fruit, stevia, allulose, erythritol

Output badges: `Clean Keto` / `Caution / Quantity Dependent` / `Non-Keto`.

## Keto Business Logic

**Keto Ratio:** `Fat (g) / (Net Carbs (g) + Protein (g))`  
**Net Carbs:** `Total Carbs (g) − Dietary Fiber (g)`

**Adaptation phases** (streak-driven state machine):
- Phase 1 (Days 1–7): Induction & Keto-Flu Management
- Phase 2 (Days 8–28): Fat-Adapted Transition
- Phase 3 (Days 28+): Deep Ketosis & Long-Term Maintenance

Streak increments on compliant days. Breach triggers a 24-hour grace period. If a compliant day is logged within the grace period, the streak resumes. If not, the streak resets to 0 and phase returns to Phase 1.

## Testing

Full testing strategy in `design/tests.md`. Summary:

| Layer | Test type | Tooling | Coverage gate |
|---|---|---|---|
| `domain/` | Unit — no mocks | `dart test` | 100% public methods |
| `application/` | Unit — mock interfaces | `dart test` + `mocktail` | 100% public methods |
| `data/` | Repository contract tests | Real in-memory Isar | Contract suite |
| `presentation/` | Widget tests | `flutter_test` + provider overrides | Critical paths |
| Full flows | Integration | `integration_test` on simulator | 7 key flows |

- All fixtures live in `test/fixtures/` — never construct domain objects inline in tests
- Repository contract tests (`runXxxRepositoryContractTests`) must pass for every concrete implementation
- CI gate: 80% line coverage on `application/` and `domain/` layers

## UI & Localisation

- RTL throughout — `Directionality(textDirection: TextDirection.rtl)` at app root
- Hebrew is the primary locale; English secondary
- All directional icons (arrows, chevrons) are mirrored for RTL
- Minimum touch target: 44×44pt (Apple HIG)
- Dark-mode first colour palette — see `design/ui_ux_design.md` for full token list
- Accent colour: `#F5A623` (keto gold)
