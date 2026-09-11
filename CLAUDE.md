# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Fantastic** is an all-in-one keto companion app built with Flutter, targeting iOS and the web. It features on-device Hebrew label OCR, keto ratio & electrolyte tracking, adaptation phase tracking, restaurant menu analysis, recipe conversion, a biomarker/symptom diary, and a curated Israeli keto directory.

## Design Documents

All design decisions are documented in `design/`. Read these before making architectural or product decisions.

| File | Contents |
|---|---|
| `design/tasks.md` | **Master task list** — all work broken into atomic subtasks, ordered by priority and dependency |
| `design/developing_rules.md` | **Mandatory developer workflow SOP** — follow this for every issue without exception |
| `design/issue_conventions.md` | **Issue authoring standard** — atomicity rules, branch/commit naming, label taxonomy, implementation description guidelines (API contracts, business logic, integration points), issue template, quality gates |
| `design/pr_conventions.md` | **PR standard** — branch/base rules, title & description templates, validation gate, review & merge rules (squash), stacked/docs-only PR exceptions |
| `design/milestone_conventions.md` | **Milestone/Epic standard** — scope discipline, MVP boundary, epic template, closure conditions, label taxonomy |
| `design/m0_handoff.md` | **M0 closing handoff** — what shipped, seven corrections the M0 issue text got wrong (read before trusting a closed issue), known failing tests, environment setup notes, loose ends, M1 starting points |
| `design/m1_preflight.md` | **M1 pre-flight corrections** — eight things the M1 issue text (#25–#43) gets wrong: wrong Isar package, lint-failing imports, a non-compiling `Isar.open` snippet, repository cross-references off by two, a feature directory that does not exist. **Read before picking up any M1 issue** |
| `design/m1_handoff.md` | **M1 handoff** — M1 is code-complete; the ten conventions every later issue inherits; the data-layer decisions M2 needs (unique-index writes, the singleton streak row, enum ordinal storage); typed repository failures; gotchas (`const` canonicalisation in equality tests, all-neutral fixtures hiding cross-wiring, `lcov` with no `LF:` lines, `build_runner` completing but never exiting). **Read before picking up M2** |
| `design/m2_preflight.md` | **M2 pre-flight corrections** — riverpod-2 `Ref` types, a `DailyLog.empty` factory that does not exist, and the `DailyLog` dashboard move that M2's text never picked up. Also lists the shipped model fields and repository methods M2 must code against. **Read before picking up any M2 issue** |
| `design/m2_handoff.md` | **M2 handoff** — M2 shipped and the app became usable; the five conventions M3 inherits (the `pump_app` widget-test harness, date-only family keys held in state, parameters over un-overridable providers); **the RTL traps that cost the most time** (a horizontal `ListView` already starts right; `endToStart` drags *rightward*); Flutter/riverpod gotchas (`Dismissible` vs async delete, `AnimatedCrossFade` keeping both children, `Override` unexported by `flutter_riverpod`); coverage at closure; the gaps M3/M4/M5 inherit. **Read before picking up M3** |
| `design/m3_preflight.md` | **M3 pre-flight corrections** — all twelve M3 issues audited. Four defects that compile and ship wrong behaviour: `copyWith(gracePeriodEnd: null)` silently does not clear, the streak increments per *meal* not per day, a fat-only first meal registers as a breach, and the phase boundary is off by one. Plus the canonical phase thresholds (8 and 28), two routes that do not exist, and the two places the issue text would regress M2. **Read before picking up any M3 issue** |
| `design/m3_handoff.md` | **M3 handoff** — M3 is code-complete and was driven end-to-end in a browser; **the riverpod-3 async-error fact that cost three issues** (a provider that fails before producing a value is `AsyncLoading` *with* an error, so `isLoading`-first checks hang forever); the eight conventions M4 inherits (phase thresholds 8/28, never `null` to clear a `StreakState` field, Sunday-first weeks, `TextDirection.ltr` on digit runs); why every notification call is a no-op on web; and the gaps M4/M5/M7 inherit. **Read before picking up M4** |
| `design/m4_preflight.md` | **M4 pre-flight corrections** — all six M4 issues audited. Three defects that compile and ship broken behaviour: the flow's last screen bounces straight back into onboarding forever, an `await ...future` inside a go_router redirect can hang the app on a blank screen, and seeding `StreakState.initial()` destroys the null first-launch sentinel. Plus **why `shared_preferences` is not added** (a `user_profile` sembast store replaces it), the seven symbols no issue defines, the corrected build order (#73 first), and the two Epic #8 DoD items no child issue covers. **Read before picking up any M4 issue** |
| `design/m5_preflight.md` | **M5 pre-flight corrections** — all four M5 issues audited. The fifth symptom scale is **`moodScore` / מצב רוח**, not the brain fog every issue names — a rename alone ships a mood score under a brain-fog label. Also: `.when(loading:)` hides a failed read forever, the save sheet silently erases the user's note, `#75`'s two failure tests cannot be written as specified, the feature directory is `diary/` not `symptom_diary/`, and the build order is #75 → #77 → #76 → #78. **Read before picking up any M5 issue** |
| `design/mvp.md` | MVP scope — 5 must-ship features, build order, success metrics, what is deferred |
| `design/architecture.md` | Layer model, persistence schemas, Riverpod provider hierarchy, OCR pipeline, data flow, routing |
| `design/base_design.md` | SOLID abstractions — repository interfaces, service contracts, domain models, and the **Error Handling Contract** (repositories throw typed exceptions; §"Why not `Result<T>`" records why that pattern was dropped before M1 — do not reintroduce it) |
| `design/tests.md` | Testing strategy — pyramid, unit/widget/integration patterns, fixture conventions, CI gate |
| `design/cicd_plan.md` | **CI/CD plan** — `.github/workflows/ci.yml` runs format, analyze and the full test suite on every PR (Phase 0, shipped). Phase 1 (codegen drift, dependabot) and Phase 2 (the `DA:`-counting coverage gate — `lcov.info` has no `LF:` lines) are next. **Integration/nightly-simulator CI and all fastlane/TestFlight/App Store CD are parked by decision — §7.1 has the entry conditions; do not build them early.** Also carries seven corrections to issue #102's YAML. **Read before touching `.github/`** |
| `design/technology.md` | Per-feature technology evaluation and full pubspec.yaml dependency list |
| `design/ui_ux_design.md` | Full RTL/Hebrew UI spec for all screens — colour palette, tab structure, page layouts |
| `design/web_support.md` | **Web support** — why Isar was replaced by sembast, the store/key layout, the conditional-import factory, the CanvasKit and Hebrew-font notes, and the one known gap |
| `design/design_system.md` | **Design system handoff** — link to the interactive component canvas (colour, type, spacing, elevation, icons, buttons, inputs, cards, badges, modals), token decisions not covered by `ui_ux_design.md`, and open questions for product/eng |
| `design/market_search.md` | Competitor analysis and differentiation strategy |

## Issue Authoring Standard

**Every issue must follow `design/issue_conventions.md` before it can be picked up.** Key requirements:

- **Implementation Plan is not optional filler.** Every step must include: exact file path, full public API contract (Dart code snippet with types and annotations), business logic written out inline (no "see design doc"), and named integration points (which provider wires it, which interface it implements, which class consumes it).
- **Technologies & Approach table** must be filled with every external package, version, and the reason it was chosen over alternatives.
- **Context & Objective** must have three sub-fields: Background (full paragraph), Objective (observable outcome), Why Now (one sentence on build-order position).
- An issue missing any of the above is sent back — it is not ready for implementation.

Issue template, label taxonomy, and all quality gates are in `design/issue_conventions.md`.

---

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

# 5. Regenerate what CI cannot generate for itself
#    - if @collection or @riverpod changed:
timeout 120 dart run build_runner build --verbose   # check git status, not exit code
#    - if pubspec.yaml changed:
flutter pub get                                      # commit the updated pubspec.lock

# 6. Commit (stage specific files only — never git add .)
git add <specific files>
git commit -m "feat(#<n>): <description>

Closes #<n>"

# 7. Push and open PR
git push -u origin <branch>
gh pr create --base main --title "..." --body "..."

# 8. Wait for CI, and fix any failure on this same branch
gh pr checks <pr-number> --watch
```

**CI is the validation gate — do not run the suite locally to qualify a push.**
`.github/workflows/ci.yml` runs lockfile freshness, `dart format`,
`flutter analyze` and `flutter test` on every PR, on a pinned Flutter 3.47.3.
Its result is the authority; a green local terminal is not.

**Always wait for the run to finish, and treat a red run as part of the issue
that caused it** — push the fix to the same branch, in the same PR, under the
same issue. Never defer it to a follow-up issue, and never call an issue done
while its PR is red or its run unfinished.

Running `flutter analyze` or `flutter test` while iterating is still fine and
often the quickest way to chase one failing test. It is simply no longer a
required step before pushing.

Branch naming: `feat/issue-<n>-<desc>` · `fix/issue-<n>-<desc>` · `chore/...` · `refactor/...`  
Commit style: Conventional Commits — `feat(#12): add Hebrew OCR scanner`  
PRs always target `main`. Never commit directly to `main`.

## Common Commands

```bash
# Run on iOS simulator
flutter run

# Run in a browser
flutter run -d chrome

# Build for web (release). --no-web-resources-cdn bundles CanvasKit locally
# instead of fetching it from gstatic.com at run time, so the app boots offline.
flutter build web --release --no-web-resources-cdn

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

# Generate code (Riverpod providers — sembast needs no generator)
# The timeout is deliberate: build_runner finishes in ~1s but never exits, so
# exit code 124 is success. Verify with `git status` rather than its exit code.
# --verbose is required — without it a redirected run logs nothing at all.
timeout 120 dart run build_runner build --verbose

# Watch for code generation changes (long-running by design — no timeout)
dart run build_runner watch

# View a GitHub issue
gh issue view <number>

# Create a PR
gh pr create --base main --title "..." --body "..."
```

## Architecture

Feature-first layered architecture. Each feature lives in `lib/features/<feature_name>/` and is divided into four layers:

- **presentation/** — Flutter widgets, screens, and Riverpod UI providers
- **application/** — Use-case services and business logic orchestration (e.g., streak calculation, phase state machine)
- **domain/** — Pure Dart models and repository interfaces (no Flutter or persistence dependencies)
- **data/** — sembast document-store implementations of domain repositories

Shared code (constants, utilities, theming) lives in `lib/core/`.

### Layer Rules — Non-Negotiable
- No sembast types in `domain/` or `presentation/`
- No Flutter imports in `application/` or `domain/`
- No widget reads the database directly — always through a repository interface
- No new provider calls the database directly — always through a service
- **No storage error escapes `data/`** — every repository method wraps its storage call in `guardPersistence`, so failures leave as `PersistenceException`. A layer above catching a `DatabaseException` is the same leak as importing one
- **No `dart:io` and no `path_provider` outside `lib/core/database/database_factory_io.dart`** — that file is the web build's only firewall against them, and `flutter analyze` cannot catch a breach. CI's `flutter build web` step is what does

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
DatabaseProvider → Repository Providers → Service Providers → UI Providers
```

Providers are defined in `application/` (services) or `presentation/` (UI state). The one exception is repository wiring, which lives in each feature's `data/providers.dart` — a provider there returns the **domain interface**, never the sembast class, so consumers cannot reach past the abstraction. Never define a provider in `domain/`.

**riverpod 3, not 2.** Annotated functions take a bare `Ref` — the generated `XxxRef` types were removed. `databaseProvider` is synchronous, so `ref.watch(databaseProvider)` yields a `Database` directly with no `.requireValue`. riverpod 3 also wraps an error thrown by a provider's create function in an internal, non-exported `ProviderException`, so a test asserting on it must match `toString()` rather than the type.

## Local Persistence

**The store is `sembast` ^3.8.10, with `sembast_web` ^2.4.6 for the browser.**
Isar was dropped in the web-support change: `isar_community` 3.3.2's web
`openIsar()` throws unconditionally — the real implementation is commented out
upstream — so it can never open in a browser. sembast is pure Dart and runs the
same repository code on every platform. See `design/web_support.md`.

Offline-first NoSQL document storage. A record is a plain `Map<String, Object?>`
in a named store, addressed by an `int` key.

| Domain model | Store | Key |
|---|---|---|
| `MealEntry` — macros, ingredients, timestamp, image reference | `meals` | sembast auto-increment |
| `DailyLog` — net carbs, fats, protein, water, electrolytes (Na/K/Mg) | `daily_logs` | `dateIndex(date)` |
| `SymptomLog` — energy, clarity, hunger, physical, mood (1–5 scales) | `symptom_logs` | `dateIndex(date)` |
| `StreakState` — current/highest streak, phase, grace-period state | `streak_state` | `StreakStateMapper.singletonId` (0) |

**Keying a one-record-per-day collection on its own date is what makes `save` an
upsert.** Isar needed `@Index(unique: true)` plus the generated `putByDateIndex`
accessors to get that; here `store.record(dateIndex).put(...)` addresses the same
record by construction, and a duplicate is impossible. `DailyLog.id` and
`SymptomLog.id` therefore carry the yyyyMMdd key, not a generated id.

**Store names are declared next to the repository that owns them** (`mealsStore`
in `sembast_meal_repository.dart`, and so on) and enumerated in
`test/core/database/store_names_test.dart`. That test is the successor to the
`appIsarSchemas` registration assertions and is not optional: sembast creates a
store on first write, so two features choosing the same name does not fail — it
silently merges two collections.

Each model has a codec in `data/mappers/`: an `abstract final class XxxMapper`
with static `toRecord(domain)` / `fromRecord(key, record)` and a public
`dateIndex(DateTime)` encoding `year * 10000 + month * 100 + day`. `dateIndex`
is public because the repository builds its keys and filters with it and must
use the same encoding the record was written with.

Record values must be JSON-compatible — `null`, `num`, `String`, `bool`, `List`,
`Map`. Three rules follow, and all three are enforced by the mapper tests:

- **`DateTime` is stored as `millisecondsSinceEpoch`**, never as a `DateTime`
  (sembast rejects it at write time) and never as an ISO string (a lexicographic
  sort is only chronological while every record shares one UTC offset).
- **Enums are stored by `.name`, not by ordinal.** Isar required an ordinal;
  sembast does not, and a stored ordinal silently reinterprets every existing
  record the day a value is inserted mid-enum.
- **Every number is decoded through `num`** — `(record['fatG']! as num).toDouble()`,
  never `as double`. A whole `40.0` comes back from IndexedDB's JSON as an `int`,
  and a direct cast throws.

sembast is schemaless: nothing validates a record on the way in, so a codec
mistake surfaces as a runtime failure on *read*. That is why every `toRecord`
test asserts the emitted map is sembast-legal.

**The database is opened once, in `main.dart`, and injected.**
`lib/core/database/database_factory.dart` conditionally exports
`database_factory_io.dart` (path_provider + `databaseFactoryIo`) or
`database_factory_web.dart` (`databaseFactoryWeb`, IndexedDB, no path) on
`dart.library.io`. `databaseProvider` is overridden with the result.
`build_runner` is still required, but only for `@riverpod` — sembast has no
generator.

### Error handling

Repositories **throw**; they do not return a `Result<T>`. `lib/core/error/` holds the sealed hierarchy — `RepositoryException` with `EntityNotFoundException` and `PersistenceException` — plus `guardPersistence` / `guardPersistenceStream`, which every repository method wraps its storage call in.

The guard catches `Object`, not `Exception`. sembast's own `DatabaseException` does implement `Exception`, but the guarded body also holds the codec that decodes the stored record, and a bad cast or a missing key there throws an `Error` — which an `on Exception` clause would miss. Wrapping those too is right: a codec that throws on stored data is itself a persistence-integrity failure. Services let these propagate without catching to convert; presentation reads them as `AsyncValue.error`.

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
- Phase 2 (Days 8–27): Fat-Adapted Transition
- Phase 3 (Days 28+): Deep Ketosis & Long-Term Maintenance

Streak increments on compliant days. Breach triggers a 24-hour grace period. If a compliant day is logged within the grace period, the streak resumes. If not, the streak resets to 0 and phase returns to Phase 1.

## Testing

Full testing strategy in `design/tests.md`. Summary:

| Layer | Test type | Tooling | Coverage gate |
|---|---|---|---|
| `domain/` | Unit — no mocks | `dart test` | 100% public methods |
| `application/` | Unit — mock interfaces | `dart test` + `mocktail` | 100% public methods |
| `data/` | Repository contract tests | In-memory sembast | Contract suite |
| `presentation/` | Widget tests | `flutter_test` + provider overrides | Critical paths |
| Full flows | Integration | `integration_test` on simulator | 7 key flows |

- **CI runs the suite; you do not have to.** Push, open the PR, watch the run, and fix any failure on the same branch — see the Developer Workflow above
- All fixtures live in `test/fixtures/` — never construct domain objects inline in tests
- Repository contract tests must pass for every concrete implementation. Each is a top-level factory-parameterised function — `runXxxRepositoryContractTests(factory, {required breakStore})` — so any future backing store runs against the same cases. That is what enforces Liskov at the test level
- `breakStore` lets a suite make the store fail without knowing what it is; for sembast it closes the database, so the next store access throws a real `DatabaseException` from inside the repository
- Open a test database with `openTestDatabase()` — no schema list, no native binary — and close it with `closeTestDatabase(db)`. `newDatabaseFactoryMemory()` gives each call its own isolated store
- The data-layer suite is now pure Dart: no `dart:io`, no `dart:ffi`, no library to dlopen. That makes `flutter test --platform chrome` possible, though CI does not run it yet
- In a test file that imports both `flutter_test` and `package:sembast/sembast.dart`, **`Finder` is ambiguous** — both packages export one. Prefix the sembast import where you need its `Finder`
- Beware a fixture whose fields all share one value (`SymptomLogFixture` defaults every scale to 3): a mapper that crosses two fields still passes. Use distinct values where a model has several same-typed fields
- CI gate: 80% line coverage on `application/` and `domain/` layers

## UI & Localisation

- RTL throughout — `Directionality(textDirection: TextDirection.rtl)` at app root
- Hebrew is the primary locale; English secondary
- All directional icons (arrows, chevrons) are mirrored for RTL
- Minimum touch target: 44×44pt (Apple HIG)
- Dark-mode first colour palette — see `design/ui_ux_design.md` for full token list
- Accent colour: `#F5A623` (keto gold)
- **Assistant 400/700 is bundled** (`assets/fonts/`) and named by `AppTheme.fontFamily`. This is not optional polish: CanvasKit ships no Hebrew glyphs, so without a bundled family Flutter web downloads one from Google Fonts on first paint and renders the whole UI as tofu boxes offline. When changing fonts, request the **`hebrew` subset** from Google Fonts — the default subset is Latin-only — and verify coverage against real UI strings

---

## GitHub Project Board

**Repository:** `NoaMcDa/Fantastic` · **Project board:** #2

All 115 atomic issues are created, labelled, milestoned, and added to project board #2. Ten Epic tracking issues (#4–#13) pin the milestone scope.

### Issue ranges by milestone

| Milestone | Label | Issues | Count |
|---|---|---|---|
| M0 — Foundation | `epic:m0-foundation` | #14–#24 | 11 |
| M1 — Domain & Data | `epic:m1-domain-data` | #25–#43, #177 | 20 |
| M2 — Macro Tracker | `epic:m2-macro-tracker` | #44–#56 | 13 |
| M3 — Adaptation & Streak | `epic:m3-adaptation` | #57–#68 | 12 |
| M4 — Onboarding | `epic:m4-onboarding` | #69–#74 | 6 |
| M5 — Symptom Diary | `epic:m5-symptom-diary` | #75–#78 | 4 |
| M6 — Keto Lens | `epic:m6-keto-lens` | #79–#87 | 9 |
| M7 — Polish | `epic:m7-polish` | #88–#94 | 7 |
| M8 — CI & Integration | `epic:m8-ci-integration` | #95–#102 | 8 |
| v1.1 — Post-MVP | `epic:post-mvp` | #103–#128 | 26 |

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
| v1.1 Post-MVP | #13 |

### Label taxonomy

**Type labels** (7) — prefix `type:`:
`type:feat` · `type:fix` · `type:test` · `type:refactor` · `type:chore` · `type:docs` · `type:perf`

**Layer labels** (7) — prefix `layer:`:
`layer:core` · `layer:domain` · `layer:data` · `layer:application` · `layer:presentation` · `layer:infra` · `layer:test`

**Epic labels** (10) — prefix `epic:` — see milestone table above.

Every issue carries exactly **3 labels**: one `type:*`, one `layer:*`, one `epic:*`.

### CI workflow

`.github/workflows/ci.yml` — **the project's validation gate.** Runs on every PR
to `main`, on every push to `main`, and on demand via `workflow_dispatch`. Uses a
pinned Flutter 3.47.3 (the pubspec needs Dart ^3.13.2; older toolchains cannot
resolve it), and cancels a superseded PR run but never one on `main`.

Steps, cheapest first so a formatting slip fails in seconds:
1. `flutter pub get`
2. **`pubspec.lock` unchanged** — fails if `pub get` rewrote the committed lockfile
3. `dart format --output=none --set-exit-if-changed lib/ test/` — zero diffs
4. `flutter analyze --no-pub` — zero issues
5. `flutter test --no-pub` — zero failures
6. `flutter build web --release --no-pub --no-web-resources-cdn` — the web target compiles

Step 6 is not redundant with `analyze`: a stray `dart:io` or `path_provider`
import outside `lib/core/database/database_factory_io.dart` analyses clean and
breaks only the web build.

Two things CI checks but does not generate, because it builds what you committed:
**generated `.g.dart` files** (run `build_runner` and commit) and **`pubspec.lock`**
(run `flutter pub get` and commit).

Coverage is not enforced by the workflow today. The 80% target on `application/`
and `domain/` (`design/tests.md`) remains a review expectation until a coverage
step is added.

Integration tests (`integration_test/`) are scoped to run nightly on an iOS
simulator, not per-PR. That directory does not exist yet (#150).
