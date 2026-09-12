# CLAUDE.md

Keto companion app (Flutter, all 6 platforms). **Only web and Linux have ever been run.** Core features: Hebrew OCR scanner, macro tracker, adaptation phase tracker, onboarding, symptom diary.

## Critical Documents

Read before working: `design/developing_rules.md` (SOP), `design/issue_conventions.md` (issue standard), `design/pr_conventions.md` (PR rules).

Milestone-specific: M1–M8 each have `design/mX_preflight.md` and `design/mX_handoff.md`. **Read the preflight before picking up issues in that milestone.** M10–M15 have research docs.

Reference: `design/architecture.md`, `design/base_design.md`, `design/tests.md`, `design/cicd_plan.md`, `design/technology.md`, `design/ui_ux_design.md`.

## Issue Requirements

Every issue needs per `design/issue_conventions.md`:
- **Implementation Plan**: file paths, API contracts (Dart snippets), business logic inline, integration points
- **Technologies & Approach**: every package, version, why chosen
- **Context & Objective**: Background, Objective, Why Now
- Issues missing these are not ready — sent back on review.

---

## Developer Workflow

**Per `design/developing_rules.md`:**
1. `git checkout main && git pull && git checkout -b feat/issue-<n>-<short-desc>`
2. Implement, write tests, commit specific files only
3. `timeout 120 dart run build_runner build --verbose` if `@riverpod` changed; `flutter pub get` if `pubspec.yaml` changed
4. `git commit -m "feat(#<n>): <desc>\n\nCloses #<n>"`
5. Push, open PR, wait for CI

**CI is the gate** — don't push to skip tests locally. Red runs block the issue. Fix on same branch/PR. Branch: `feat/issue-<n>-<desc>` · `fix/issue-<n>-<desc>`. Commit: Conventional — `feat(#12): add Hebrew OCR`. Never commit to `main`.

## Common Commands

```bash
flutter analyze                                    # Lint
dart format lib/ test/                             # Format
flutter test                                       # Unit + widget (not integration)
flutter test -d flutter-tester integration_test/app_test.dart  # E2E
flutter test --coverage && tool/check_coverage.sh coverage/lcov.info 80  # Coverage gate
flutter run -d chrome                              # Browser
flutter build web --release --no-web-resources-cdn  # Web release
timeout 120 dart run build_runner build --verbose  # Codegen (exit 124 = success)
dart run build_runner watch                        # Watch codegen
```

## Architecture

Feature-first layered: each `lib/features/<name>/` has `presentation/`, `application/`, `domain/`, `data/`. Shared in `lib/core/`.

**Layer Rules:**
- No sembast in `domain/` or `presentation/`
- No Flutter in `application/` or `domain/`
- Widget always reads through repository interface, provider always through service
- Storage errors wrapped in `guardPersistence` — only `PersistenceException` escapes `data/`
- Native code behind firewall: `lib/core/database/database_factory.dart`, `lib/features/keto_lens/data/adapters/text_recognizer_factory.dart`

**Features:** Dashboard · Onboarding · Keto Lens (Hebrew OCR) · Diary (meals/symptoms) · Adaptation & streak · Restaurant · Recipe · Directory

**AddMealFab** (`lib/features/diary/presentation/widgets/`) — unified entry point, three modes: manual, description (text), photo (label OCR first). One validator in the app. Edit mode passes `existing` meal.

## MVP & State

**MVP shipped (M0–M6).** M7: 14 open polish issues. M8: 1 blocker (#98). See `design/mvp_handoff.md`.

**Riverpod 3** — `@riverpod` only (code-gen), no manual `Provider()`. Providers in `application/` (services) or `presentation/` (UI); repository providers in `data/providers.dart` return domain interface only. `databaseProvider` synchronous. Error wrapped in `ProviderException` — match `toString()` in tests, not type.

## Local Persistence

**`sembast` ^3.8.10** (pure Dart, works everywhere). NoSQL, one-record-per-day via `dateIndex(date)`.

| Model | Store | Key |
|---|---|---|
| MealEntry | `meals` | auto-increment |
| DailyLog | `daily_logs` | `dateIndex(date)` |
| SymptomLog | `symptom_logs` | `dateIndex(date)` |
| StreakState | `streak_state` | singleton (0) |
| UserProfile | `user_profile` | singleton |
| EstimationSettings | `estimation_settings` | singleton |

**Codec rules:** (enforced by mapper tests)
- `DateTime` → `millisecondsSinceEpoch` (never string)
- Enums → `.name` (never ordinal)
- Numbers → `(x as num).toDouble()` (never direct `as double`)

Store names in `data/mappers/XxxMapper`. Every mapper has `toRecord(domain)`, `fromRecord(key, record)`, public `dateIndex(DateTime)`. Two features picking same store name silently merge — registered in `test/core/database/store_names_test.dart`.

**`MealEntry.source`** — `manual` / `scannedLabel` / `estimatedFromText` / `estimatedFromPhoto`. Edit that changes macro re-sources to `manual`. `ImageRef` may dangle. **`NumericInput.positiveFinite`** (`lib/core/utils/`) is the one place to parse user input (blocks `Infinity`, `NaN`).

**Error handling:** Repositories throw `RepositoryException` / `PersistenceException` (wrapped by `guardPersistence`). Guard catches `Object` not `Exception` (codec errors are `Error` not `Exception`).

## OCR & ML

**Tesseract, on-device, Hebrew.** No network during scan (Epic #10 invariant). M15's estimation (optional, OpenRouter behind `LlmChatClient`) is separate.

**Scan pipeline:** Camera/gallery → `TextRecognitionService` (domain) → browser: `TesseractJsTextRecognizer` (wasm, self-hosted) · VM: `ScalingTextRecognizer` (greyscale + scale) → `HebrewLabelParser` → `IngredientClassifier` → sealed `ScanResult` → `ScanResultSheet`.

**Settings:** `psm 4`, `heb+eng`, `oem 1`, explicit `user_defined_dpi` (set in all adapters). `preserve_interword_spaces` unset (destroys RTL spacing). Greyscale conversion mandatory (color costs digits).

**Verdict:** Two checks — `IngredientVerdict` from tokens + `MacroVerdict` from numbers → `LabelVerdict.combine`. Panel energy check first (9×fat + 4×protein + 4×carbs vs declared within 25%). Serving basis parsed from label, defaults `unknown` (never guesses). `MealEntry.source` tracks origin.

**Ingredient rules** (`lib/core/constants/ingredient_rules.dart`): Forbidden (canola, soybean, corn, sunflower, cottonseed, safflower) · Insulin-spiking (maltitol, sorbitol, dextrose, maltodextrin, HFCS) · Clean (olive, avocado, coconut, butter, ghee, tallow, monk fruit, stevia, allulose, erythritol).

**Fixtures:** `real_ocr_fixture.dart` auto-generated (never hand-edit); `test/fixtures/real_ocr_fixture.dart`. Regenerate with `tool/capture_ocr_fixtures.sh`. **No camera ever used, no accuracy claim.**

## Keto Business Logic

**Keto Ratio:** `Fat / (NetCarbs + Protein)` | **Net Carbs:** `TotalCarbs − Fiber`

**Compliance:** Net carbs ≤ 50 g/day (see `DayCompliance.of` in `lib/features/adaptation/domain/models/day_compliance.dart` — single source). Breach opens 24-hour grace; compliant day in window resumes streak, else resets to 0 + Phase 1.

**Phases:** Phase 1 (days 1–7) · Phase 2 (days 8–27) · Phase 3 (28+). Streak-driven state machine.

**Derivation:** `AdaptationPhaseService.recomputeFor` re-derives on every write by walking `DailyLog` back from today (365 day cap). Retroactive edits self-correct. **Skipped day breaks streak**, today excepted (winnable until midnight). **All-zero macros = unlogged**. Fat-only day (0 carbs) is compliant. Evaluation from wall clock, not meal timestamp. **On-write only, not on-read** (ring shows stale streak until next meal logged).

## Testing

Per `design/tests.md`:

| Layer | Type | Gate |
|---|---|---|
| `domain/` | Unit (no mocks) | 100% public methods |
| `application/` | Unit (mock interfaces) | 100% public methods |
| `data/` | Repository contract tests | Contract suite per implementation |
| `presentation/` | Widget tests | Critical paths |
| Full flows | E2E (flutter-tester, headless) | 35 tests/PR |

**CI is gate** — push, open PR, wait, fix on same branch. Fixtures in `test/fixtures/` (never inline). Contract tests: factory-parameterised `runXxxRepositoryContractTests(factory, {required breakStore})`. `breakStore` closes db to trigger `DatabaseException`. Test DB: `openTestDatabase()` / `closeTestDatabase()`. Data layer pure Dart (no io/ffi). **Ambiguous `Finder` in tests importing both `flutter_test` and `sembast` — prefix one.**

**OCR tests:** `tesseract_ffi_recognizer_test.dart` skips (loud banner) when libtesseract absent. `scaling_text_recognizer_test.dart` pure-Dart buffer checks. `tesseract_js_text_recognizer_test.dart` `@TestOn('browser')` + `--platform chrome`. **Never assert raw OCR text** — assert parsed macros (stable cross-version). `RealOcrFixture` auto-generated (never edit); regenerate `tool/capture_ocr_fixtures.sh`. **Geresh in Hebrew → use `"""` not `'''`.**

**Gate:** 80% line coverage on `application/` + `domain/`.

## UI & Localisation

**RTL throughout** — `Directionality(textDirection: TextDirection.rtl)` at root. Hebrew primary, English secondary. Icons mirrored. Touch target 44×44pt. Dark-mode first palette (see `design/ui_ux_design.md`). Accent `#F5A623` (keto gold).

**Font:** Assistant 400/700 bundled (`assets/fonts/`), required for web — CanvasKit has no Hebrew glyphs. When changing: request `hebrew` subset from Google Fonts (default is Latin-only), verify against real UI.

## GitHub & CI

**Repo:** `NoaMcDa/Fantastic` · **Board:** #2. Epic tracking #4–#12 (M0–M8) · #264–#270 (M9–M15 + release).

**Milestones:** M0–M8 sequential (MVP), M9–M15 parallel peers. Each has issue range + epic label. **Labels:** 3 per issue — `type:*` (feat/fix/test/refactor/chore/docs/perf) · `layer:*` (core/domain/data/application/presentation/infra/test) · `epic:*` (m0–m8, m9–m15, release-v1, login).

**CI:** `.github/workflows/ci.yml` (flutter 3.47.3, Dart ^3.13.2). Docs-only skip via `tool/docs_only.sh`. Three parallel jobs: `verify` (format, lint, test, coverage 80%), `build web`, `e2e flows`.

**E2E:** `flutter test -d flutter-tester integration_test/app_test.dart --no-pub` (headless, ~2min). Flows in `*_flow.dart` files, harness at `integration_test/helpers/app_harness.dart` — never bare `pumpAndSettle()`.

**Platform workflows:** Android (release-only), Linux (smoke test), Windows/iOS/macOS (paths-filtered). All five found defects: `jcenter()` deprecation, missing iOS model, wrong library names. **Only web and Linux ever launched.**

**Commit & codegen:** `.g.dart` files and `pubspec.lock` must be committed (CI checks freshness).
