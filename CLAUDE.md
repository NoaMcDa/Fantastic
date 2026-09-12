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

### Features

| Feature | Directory |
|---|---|
| Dashboard & macro tracking | `lib/features/dashboard/` |
| Onboarding & user profile | `lib/features/onboarding/` |
| Keto Lens (Hebrew OCR scanner) | `lib/features/keto_lens/` |
| Diary (meals, symptoms, biomarkers) | `lib/features/diary/` |
| Menu Scanner (pasted text / photo pages / PDF, M16) | `lib/features/menu/` |
| Adaptation phase & streak | `lib/features/adaptation/` |
| Restaurant directory | `lib/features/restaurant/` |
| Recipe converter | `lib/features/recipe/` |
| Israeli keto directory | `lib/features/directory/` |

**AddMealFab** (`lib/features/diary/presentation/widgets/`) — unified entry point, three modes: manual, description (text), photo (label OCR first). One validator in the app. Edit mode passes `existing` meal.

## MVP & State

**MVP shipped (M0–M6).** M7: 14 open polish issues. M8: 1 blocker (#98). See `design/mvp_handoff.md`.

**Riverpod 3** — `@riverpod` only (code-gen), no manual `Provider()`. Providers in `application/` (services) or `presentation/` (UI); repository providers in `data/providers.dart` return domain interface only. `databaseProvider` synchronous. Error wrapped in `ProviderException` — match `toString()` in tests, not type.

**A provider that owns a cancel-on-close resource must be `keepAlive` (#419).** riverpod
disposes an autoDispose provider one frame after its last listener goes, and a screen that
`ref.read`s an engine in a button handler holds **no** listener while it awaits. So
`llmChatClientProvider`'s `http.Client` was closed mid-request — and closing a client
*cancels what it is carrying* (`BrowserClient.close` aborts the `fetch`, `IOClient.close`
force-closes the socket), which surfaced as an instant "אין חיבור לאינטרנט" on a working
connection. `ref.onDispose` still frees it when the container goes. See
`design/m15_openrouter_models_fix.md`.

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

**A menu analysis (M16, `lib/features/menu/`) is a different feature from a Keto Lens
scan, and it does make one outbound call.** Three `MenuInputMode`s all end up as text
sent over M15's `LlmChatClient` seam: pasted text skips OCR entirely; photographed pages
read each page on the device with the same `TextRecognitionService` Keto Lens uses; a
PDF is read by `PdfPageExtractor` (`PdfrxPageExtractor`, the only file importing `pdfrx`)
— its text layer if present, else rasterised per page and OCR'd through the same
pipeline. Only recognised/extracted **text** ever leaves the device, never an image or
the PDF itself. **A Keto Lens *scan* still sends nothing**: this does not relax Epic
#10's no-network invariant, it adds a second, separate feature next to it — see
`design/m16_menu_scanner_research.md`.

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

**Milestones:** M0–M8 sequential (MVP), M9–M16 parallel peers. Each has issue range + epic label. **Labels:** 3 per issue — `type:*` (feat/fix/test/refactor/chore/docs/perf) · `layer:*` (core/domain/data/application/presentation/infra/test) · `epic:*` (m0–m8, m9–m16, release-v1, login).

**Epics pin the milestones:** #4–#12 (MVP), #264–#270 (post-MVP + v1.0 release), **#312** (M15 Meal Entry) and **#351** (M16 AI Menu Scanner) — the two opened from a user's own request. #13 (v1.1 Post-MVP) is closed, split into seven milestones, recorded in `design/v1_1_split.md`.

**GitHub milestones #11–#19 cover M9–M16 and the release.** Filtering by milestone and filtering by `epic:*` label give the same view, so either is accurate; the Epics additionally report per-child progress through the sub-issue hierarchy.

**CI:** `.github/workflows/ci.yml` (flutter 3.47.3, Dart ^3.13.2). Docs-only skip via `tool/docs_only.sh`. Three parallel jobs: `verify` (format, lint, test, coverage 80%), `build web`, `e2e flows`.

**E2E:** `flutter test -d flutter-tester integration_test/app_test.dart --no-pub` (headless, ~2min). Flows in `*_flow.dart` files, harness at `integration_test/helpers/app_harness.dart` — never bare `pumpAndSettle()`.

**Platform workflows:** Android (release-only), Linux (smoke test), Windows/iOS/macOS (paths-filtered). All five found defects: `jcenter()` deprecation, missing iOS model, wrong library names. **Only web and Linux ever launched.**

**Commit & codegen:** `.g.dart` files and `pubspec.lock` must be committed (CI checks freshness).

| Milestone | Label | Issues | Count |
|---|---|---|---|
| M0 — Foundation | `epic:m0-foundation` | #14–#24 | 11 |
| M1 — Domain & Data | `epic:m1-domain-data` | #25–#43, #177 | 20 |
| M2 — Macro Tracker | `epic:m2-macro-tracker` | #44–#56 | 13 |
| M3 — Adaptation & Streak | `epic:m3-adaptation` | #57–#68 | 12 |
| M4 — Onboarding | `epic:m4-onboarding` | #69–#74 | 6 |
| M5 — Symptom Diary | `epic:m5-symptom-diary` | #75–#78 | 4 |
| M6 — Keto Lens | `epic:m6-keto-lens` | #79–#87 | 9 |
| M7 — Polish | `epic:m7-polish` | #88–#94, #151, #301, #302, #304, #305, #307–#311 | 17 — **14 open** |
| M8 — CI & Integration | `epic:m8-ci-integration` | #95–#102, #150, #197, #199 | 11 — **1 open (#98)** |
| Release v1.0 — App Store | `epic:release-v1` | #125–#128 | 4 |
| M9 — Biomarker Logging | `epic:m9-biomarkers` | #103–#107 | 5 |
| M10 — Recipe Converter | `epic:m10-recipe-converter` | #118–#120, #393–#398 | 9 — see `design/m10_recipe_converter_research.md` |
| M11 — Restaurant Directory | `epic:m11-directory` | #111–#117 | 7 |
| M12 — Menu Analyzer | `epic:m12-menu-analyzer` | #121–#122 | 2 — **superseded by M16, closure pending** |
| M13 — Apple Health Sync | `epic:m13-health-sync` | #108–#110 | 3 |
| M14 — Backup & Restore | `epic:m14-backup` | #123–#124 | 2 |
| M15 — Meal Entry | `epic:m15-meal-entry` | #315–#328 | 14 — **complete** |
| M16 — AI Menu Scanner | `epic:m16-menu-scanner` | #352–#366 (not #363), #372, #373, #405–#408, #421 | 21 — **all three input modes shipped** (text, photo pages, PDF) |
| Login — accounts & identity | `epic:login` | #206–#226 | 16 |

**M9–M16 are numbered by recommended build order, not by dependency** — they are
parallel peers and `milestone_conventions.md` §1.2's sequential gate applies to
M0–M8 only. **`epic:release-v1` ships the MVP**, so it runs before M9, not after.
`epic:post-mvp` is retired — see `design/v1_1_split.md`.

**M15 is the first milestone opened from a user's own request rather than from the
original plan** — issue #312, rewritten into its Epic. It is also the first to make
an outbound network call, which is a different feature from Keto Lens and **does not
relax the OCR no-network invariant**; see `design/m15_meal_entry_research.md` §4.

**M16 is the second milestone opened from a user's request** — Epic #351, milestone #19,
`design/m16_menu_scanner_research.md`. It **supersedes M12 Menu Analyzer** (#267, #121,
#122), whose closure is decision 1 on the Epic and is the owner's call; until it is taken,
#121 and #122 are not to be picked up. It reuses M15's `LlmChatClient` seam and key, sends
only locally-recognised or locally-extracted **text** — neither the menu photograph nor the
PDF ever leaves the device — and, like M15, **does not relax the OCR no-network
invariant**. PDF input (#405–#408) reads a text layer directly where one is legible and
rasterises the pages where it is not; `design/m16_menu_scanner_research.md` §12 records
what that verified and what it did not.

### Epic tracking issues

| Epic | Issue |
|---|---|
| M0 Foundation | #4 |
| M1 Domain & Data | #5 |
| M2 Macro Tracker | #6 |
| M3 Adaptation & Streak | #7 |
| M4 Onboarding | #8 |
| M5 Symptom Diary | #9 |
| M6 Keto Lens | #10 |
| M7 Polish | #11 |
| M8 CI & Integration | #12 |
| Release v1.0 — App Store Launch | #270 |
| M9 Biomarker Logging | #264 |
| M10 Recipe Converter | #265 |
| M11 Restaurant Directory | #266 |
| M12 Menu Analyzer | #267 |
| M13 Apple Health Sync | #268 |
| M14 Backup & Restore | #269 |
| M15 Meal Entry | #312 |
| M16 AI Menu Scanner | #351 |
| ~~v1.1 Post-MVP~~ | ~~#13~~ — closed, split into the seven above |
| Login (unscheduled) | #226 |

### Label taxonomy

**Type labels** (7) — prefix `type:`:
`type:feat` · `type:fix` · `type:test` · `type:refactor` · `type:chore` · `type:docs` · `type:perf`

**Layer labels** (7) — prefix `layer:`:
`layer:core` · `layer:domain` · `layer:data` · `layer:application` · `layer:presentation` · `layer:infra` · `layer:test`

**Epic labels** (19) — prefix `epic:` — see milestone table above. Ten MVP/epic
labels (`epic:m0-foundation`–`epic:m8-ci-integration`, plus `epic` on tracking
issues), eight post-MVP milestones (`epic:m9-biomarkers`–`epic:m16-menu-scanner`),
`epic:release-v1`, and `epic:login`. **`epic:post-mvp` is retired.**

**The Login milestone (#206–#226) sits outside the M0–M8 MVP boundary** and is
unscheduled: no MVP issue depends on it, and the MVP can ship without it. Its
issue text was authored before M4 merged and has since been reconciled against
the shipped `UserProfile` — read `#226`'s Interaction-with-M4 section before
picking up anything in it.

Every issue carries exactly **3 labels**: one `type:*`, one `layer:*`, one `epic:*`.

### CI workflow

`.github/workflows/ci.yml` — **the project's validation gate.** Runs on every PR
to `main`, on every push to `main`, and on demand via `workflow_dispatch`. Uses a
pinned Flutter 3.47.3 (the pubspec needs Dart ^3.13.2; older toolchains cannot
resolve it), and cancels a superseded PR run but never one on `main`.

**A documentation-only change runs neither job.** A `changes` job classifies
the diff with `tool/docs_only.sh`; when every changed path is `design/**`,
`docs/**`, a `**/*.md` or `LICENSE*`, `verify` and `e2e flows` are skipped —
which reports as a pass, unlike a `paths-ignore` filter, whose check would
stay pending forever. Every uncertain case (missing SHA, empty diff, a crash in
the script) runs the full gate instead. **`*.txt` is deliberately not on the
docs list** — `linux/CMakeLists.txt`, `windows/CMakeLists.txt` and
`tool/coverage_ignore.txt` are all load-bearing. See `design/cicd_plan.md` §5.6.

**The gate is three parallel jobs, not one.** `verify`, `build web` and
`e2e flows` all hang off `docs-only?` and run at the same time; the gate
finishes when the slowest of them does, currently `verify` at about 2m45.

`verify` — steps cheapest first, so a formatting slip fails in seconds:
1. `flutter pub get`
2. **`pubspec.lock` unchanged** — fails if `pub get` rewrote the committed lockfile
3. `dart format --output=none --set-exit-if-changed lib/ test/ integration_test/` — zero diffs
4. `flutter analyze --no-pub` — zero issues
5. `flutter test --no-pub --coverage` — zero failures, and writes `coverage/lcov.info`
6. `tool/check_coverage.sh coverage/lcov.info 80` — ≥80% on `domain/` + `application/`
7. `tool/check_coverage_files.sh coverage/lcov.info` — no gated file missing from the report and absent from `tool/coverage_ignore.txt`

`build web` — one step, `flutter build web --release --no-pub --no-web-resources-cdn`.
**It is a job of its own, and was the tail of `verify` until the efficiency
pass** (`design/cicd_plan.md` §5.7): nothing it needs is produced by the test
suite, so waiting ~2 minutes for that suite and then adding its own ~40s to the
critical path bought nothing. Do not fold it back in. It is also not redundant
with `analyze` — a stray `dart:io` or `path_provider` import outside
`lib/core/database/database_factory_io.dart` analyses clean and breaks only the
web build, and now says so under its own name in the checks list.

Two things CI checks but does not generate, because it builds what you committed:
**generated `.g.dart` files** (run `build_runner` and commit) and **`pubspec.lock`**
(run `flutter pub get` and commit).

**Coverage is enforced.** `tool/check_coverage.sh` gates `domain/` +
`application/` at 80% line coverage, and `tool/check_coverage_files.sh` fails a
gated file that has no coverage record and is not on `tool/coverage_ignore.txt`
— lcov emits nothing for a file no test imports, so without that companion an
untested layer reads as 100% rather than 0%. Measured 470/472 = 99.58%. Both
scripts run locally: `flutter test --coverage && tool/check_coverage.sh`.

### The `e2e flows` job

A third job in the same workflow, on `ubuntu-latest`, per PR and in parallel
with `verify` and `build web`:

```bash
flutter test -d flutter-tester integration_test/app_test.dart --no-pub
```

**No simulator, and not nightly** — the nightly-on-an-iOS-simulator scoping
every other document used to state is superseded by `design/m8_preflight.md`
Part 0. The suite drives the real app (real router, real provider graph, real
repositories, real in-memory sembast) headless, in ~2 min.

Two parts of that command are load-bearing:

- **`-d flutter-tester`.** Without a device the run fails with "No supported
  devices connected".
- **`integration_test/app_test.dart`, not the directory.** One app launch is
  allowed per invocation; pointing the runner at the directory fails the
  second file with "The log reader failed unexpectedly". Every flow is
  therefore a library named `*_flow.dart` exporting `main()`, grouped by the
  aggregator.

`flutter test` (the `verify` job) globs `test/` only and never picks these up.
Write flows against `integration_test/helpers/app_harness.dart` — `bootApp`,
`pumpApp`, `settle`, `pumpUntil`, `waitFor` — and never call a bare
`pumpAndSettle()`: its timeout is the **third** positional argument, not the
first, and a screen over a broken store never settles at all because riverpod
3 retries failed providers on a backoff.

### Per-platform build workflows

`ci.yml` is the gate every PR must pass; it builds **web** and nothing else.
Five sibling workflows build the other five targets on a runner of their own
OS, each in its own file so that changing one cannot conflict with another —
plus a sixth that compiles nothing and exists only to warm a cache:

| Workflow | Runner | Builds | Trigger |
|---|---|---|---|
| `build-android.yml` | `ubuntu-latest` | `flutter build apk --release` | PR + push to main |
| `build-linux.yml` | `ubuntu-latest` | `flutter build linux` **+ a headless smoke test** | PR + push to main |
| `build-windows.yml` | `windows-latest` (2x minutes) | `flutter build windows` | PR (paths-filtered) + push to main |
| `build-ios.yml` | `macos-latest` (**10x minutes**) | `flutter build ios --no-codesign` | PR (paths-filtered) only |
| `build-macos.yml` | `macos-latest` (**10x minutes**) | `flutter build macos` | PR (paths-filtered) only |
| `warm-macos-cache.yml` | `macos-latest` | **nothing** — it only fills a cache | push to main (paths-filtered) + twice weekly |

**Android builds release only, and the asset assertion reads the release APK.**
A debug assemble ran first until the efficiency pass; it proved nothing release
does not, and cost ~80s on every green run to save ~80s on a red one. The
release step still deliberately omits `--no-pub`: `flutter pub get` leaves a
dev-inclusive `GeneratedPluginRegistrant.java` naming `IntegrationTestPlugin`,
and only a pub-enabled build regenerates the release one. See
`design/cicd_plan.md` §5.7.

**The macOS-runner jobs are deliberately not on `push`.** `design/cicd_plan.md`
§8 records an earlier plan exceeding the free Actions tier 3x on macOS minutes
alone; path filters plus `cancel-in-progress` are what keep that from
recurring. Note a `paths` filter matches the **whole PR diff, not the newest
push**, so a docs-only commit on a PR that already touched `ios/` still re-runs
the job — `concurrency` is the per-push control, not `paths`.

**That decision is exactly why `warm-macos-cache.yml` has to exist.** An
Actions cache is readable only from the branch that wrote it and from the
default branch, so a workflow that never runs on `main` never warms its own
cache: both macOS jobs logged `Cache not found` on every run they had ever
made and re-downloaded 2.1 GB of SDK each time. The warm job runs on `main`,
builds nothing, and writes the caches the two consumers read. Its
`flutter-version` **must** stay identical to theirs — a differing pin warms a
key nothing reads, and the job still goes green. The same scoping rule is why
`build-android.yml` restores the Gradle cache always but saves it only on
`main`. See `design/cicd_plan.md` §5.4.

These are not redundant with `analyze`. Every one of the five found a defect
that analysed clean and compiled clean on every *other* platform: a `jcenter()`
call Gradle 9 removed, a model declared in `pubspec.yaml` but absent from the
iOS `.app`, and library names that were simply wrong on macOS and Windows. See
`design/m6_platform_handoff.md` §"What compiling on real runners found".

All five carry a docs filter too: `build-android.yml`, `build-linux.yml` and
`build-windows.yml`'s `push` trigger via `paths-ignore`, the three
macOS/Windows `pull_request` triggers via `paths` include-lists that never
matched Markdown anyway. A docs PR compiles nothing.

**A green build job means the target assembles. It does not mean the app runs** —
only web and Linux have ever been launched.

`build-linux.yml` does go further than a compile: `tool/linux_smoke_test.sh`
launches the built binary under `xvfb` and asserts it is alive, that the
database file was created, and that the log has no fatal line. That last check
needs `main` to *log* a startup failure, because all three Linux startup bugs
were caught by `main`'s own `try/catch` and rendered as `StartupFailureApp` —
the process stays alive and quiet, so a naive liveness check calls a dead app
healthy.
