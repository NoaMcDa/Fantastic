# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Fantastic** is an all-in-one keto companion app built with Flutter, targeting iOS. It features on-device Hebrew label OCR, keto ratio & electrolyte tracking, adaptation phase tracking, restaurant menu analysis, recipe conversion, a biomarker/symptom diary, and a curated Israeli keto directory.

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

# Run a single test file
flutter test test/path/to/test_file.dart

# Run tests with coverage
flutter test --coverage

# Analyze code (lint)
flutter analyze

# Format code
dart format .

# Get/update dependencies
flutter pub get

# Generate code (Isar schemas, Riverpod, etc.)
dart run build_runner build --delete-conflicting-outputs

# Watch for code generation changes
dart run build_runner watch --delete-conflicting-outputs
```

## Architecture

Feature-first layered architecture. Each feature lives in `lib/features/<feature_name>/` and is divided into four layers:

- **presentation/** — Flutter widgets, screens, and Riverpod UI providers
- **application/** — Use-case services and business logic orchestration (e.g., streak calculation, phase state machine)
- **domain/** — Pure Dart models and repository interfaces (no Flutter/Isar dependencies)
- **data/** — Isar/Hive schema implementations of domain repositories

Shared code (constants, utilities, theming) lives in `lib/core/`.

## State Management

Riverpod is the sole state management solution. Providers should be defined in `application/` or `presentation/` layers. Avoid direct Isar access from widgets — always go through a repository interface defined in the domain layer.

## Local Persistence

Isar (preferred) or Hive for offline-first NoSQL storage. Key schemas:
- `MealEntry` — macros, ingredients, timestamp, image reference
- `DailyLog` — net carbs, fats, protein, water, electrolytes (Na/K/Mg)
- `SymptomLog` — energy, mental clarity, hunger, physical symptoms (1–5 scales)
- `BiomarkerLog` — blood/breath ketones, fasting glucose, body weight
- `StreakState` — current streak, highest streak, adaptation phase enum, last reset timestamp

Isar schemas require code generation (`build_runner`). Always run `build_runner build` after modifying schema files annotated with `@collection`.

## OCR & ML

Uses `google_mlkit_text_recognition` for on-device Hebrew text recognition — no network call is made for OCR. The parsing pipeline normalizes Hebrew nutritional label text via regex before ingredient rule evaluation.

Ingredient classification (used by the Keto Lens scanner):
- **Forbidden seed oils:** canola, soybean, corn, sunflower, cottonseed, safflower
- **Insulin-spiking sweeteners:** maltitol, sorbitol, dextrose, maltodextrin, HFCS
- **Clean approvals:** olive oil, avocado oil, coconut oil, butter, ghee, tallow, monk fruit, stevia, allulose, erythritol

Output badges: `Clean Keto` / `Caution / Quantity Dependent` / `Non-Keto`.

## Keto Business Logic

**Keto Ratio:** `Fat (g) / (Net Carbs (g) + Protein (g))`

**Adaptation phases** (streak-driven state machine):
- Phase 1 (Days 1–7): Induction & Keto-Flu Management
- Phase 2 (Days 8–28): Fat-Adapted Transition
- Phase 3 (Days 28+): Deep Ketosis & Long-Term Maintenance

Streak increments on compliant days; breaks trigger reset or grace-period workflows defined in the application layer.
