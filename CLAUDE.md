# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Fantastic** is an all-in-one keto companion app built with Flutter, targeting iOS. It features on-device Hebrew label OCR, keto ratio & electrolyte tracking, adaptation phase tracking, restaurant menu analysis, recipe conversion, a biomarker/symptom diary, and a curated Israeli keto directory.

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
| `design/mvp.md` | MVP scope — 5 must-ship features, build order, success metrics, what is deferred |
| `design/architecture.md` | Layer model, Isar schemas, Riverpod provider hierarchy, OCR pipeline, data flow, routing |
| `design/base_design.md` | SOLID abstractions — repository interfaces, service contracts, domain models, and the **Error Handling Contract** (repositories throw typed exceptions; §"Why not `Result<T>`" records why that pattern was dropped before M1 — do not reintroduce it) |
| `design/tests.md` | Testing strategy — pyramid, unit/widget/integration patterns, fixture conventions, CI gate |
| `design/cicd_plan.md` | **CI/CD plan** — `.github/workflows/ci.yml` runs format, analyze and the full test suite on every PR (Phase 0, shipped). Phase 1 (codegen drift, dependabot) and Phase 2 (the `DA:`-counting coverage gate — `lcov.info` has no `LF:` lines) are next. **Integration/nightly-simulator CI and all fastlane/TestFlight/App Store CD are parked by decision — §7.1 has the entry conditions; do not build them early.** Also carries seven corrections to issue #102's YAML. **Read before touching `.github/`** |
| `design/technology.md` | Per-feature technology evaluation and full pubspec.yaml dependency list |
| `design/ui_ux_design.md` | Full RTL/Hebrew UI spec for all screens — colour palette, tab structure, page layouts |
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
- **domain/** — Pure Dart models and repository interfaces (no Flutter/Isar dependencies)
- **data/** — Isar schema implementations of domain repositories

Shared code (constants, utilities, theming) lives in `lib/core/`.

### Layer Rules — Non-Negotiable
- No Isar types in `domain/` or `presentation/`
- No Flutter imports in `application/` or `domain/`
- No widget reads Isar directly — always through a repository interface
- No new provider calls Isar directly — always through a service
- **No Isar error escapes `data/`** — every repository method wraps its storage call in `guardPersistence`, so failures leave as `PersistenceException`. A layer above catching an `IsarError` is the same leak as importing one

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

Providers are defined in `application/` (services) or `presentation/` (UI state). The one exception is repository wiring, which lives in each feature's `data/providers.dart` — a provider there returns the **domain interface**, never the Isar class, so consumers cannot reach past the abstraction. Never define a provider in `domain/`.

**riverpod 3, not 2.** Annotated functions take a bare `Ref` — the generated `XxxRef` types were removed. `isarProvider` is synchronous, so `ref.watch(isarProvider)` yields an `Isar` directly with no `.requireValue`. riverpod 3 also wraps an error thrown by a provider's create function in an internal, non-exported `ProviderException`, so a test asserting on it must match `toString()` rather than the type.

## Local Persistence

**The package is `isar_community` ^3.3.2, not `isar`.** `import 'package:isar/isar.dart'` does not resolve — the original pins `analyzer <6.0.0` and cannot co-resolve with `riverpod_generator`. `isar_community_flutter_libs` must stay pinned to the same version.

Offline-first NoSQL storage. Key schemas (all in `data/` layers):
- `MealEntry` — macros, ingredients, timestamp, image reference
- `DailyLog` — net carbs, fats, protein, water, electrolytes (Na/K/Mg)
- `SymptomLog` — energy, mental clarity, hunger, physical symptoms (1–5 scales)
- `BiomarkerLog` — blood/breath ketones, fasting glucose, body weight
- `StreakState` — current streak, highest streak, adaptation phase enum, grace period state
- `RecipeEntry` — converted keto recipes

Every collection must be appended to `appIsarSchemas` in `lib/core/database/isar_provider.dart` — the single registration point, which `main.dart` opens at startup — **and** given a registration assertion in `test/core/database/isar_provider_test.dart`.

Each schema has a mapper in `data/mappers/`: an `abstract final class XxxMapper` with static `toIsar(domain)` / `toDomain(schema)` and a public `dateIndex(DateTime)` encoding `year * 10000 + month * 100 + day`. `dateIndex` is public because the repository builds its queries with it and must use the same encoding the schema was written with.

A `@Index(unique: true)` on `dateIndex` changes how you write: a plain `put` violates the index and **throws** rather than replacing. Use the generated by-index accessors (`putByDateIndex`, `getByDateIndex`, `deleteByDateIndex`) for one-record-per-day collections.

Always run `build_runner build` after modifying any file annotated with `@collection`.

### Error handling

Repositories **throw**; they do not return a `Result<T>`. `lib/core/error/` holds the sealed hierarchy — `RepositoryException` with `EntityNotFoundException` and `PersistenceException` — plus `guardPersistence` / `guardPersistenceStream`, which every repository method wraps its storage call in.

The guard catches `Object`, not `Exception`, because **`IsarError extends Error`**. An `on Exception` clause silently misses every storage failure. Services let these propagate without catching to convert; presentation reads them as `AsyncValue.error`.

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

- **CI runs the suite; you do not have to.** Push, open the PR, watch the run, and fix any failure on the same branch — see the Developer Workflow above
- All fixtures live in `test/fixtures/` — never construct domain objects inline in tests
- Repository contract tests must pass for every concrete implementation. Each is a top-level factory-parameterised function — `runXxxRepositoryContractTests(factory, {required breakStore})` — so any future backing store runs against the same cases. That is what enforces Liskov at the test level
- `breakStore` lets a suite make the store fail without knowing what it is; for Isar it closes the instance, producing a real `IsarError` from inside the repository
- Open a test instance with `openTestIsar([IsarXxxSchema])` — the schema list is required and must not be empty — and close it with `closeTestIsar(isar)`
- Beware a fixture whose fields all share one value (`SymptomLogFixture` defaults every scale to 3): a mapper that crosses two fields still passes. Use distinct values where a model has several same-typed fields
- CI gate: 80% line coverage on `application/` and `domain/` layers

## UI & Localisation

- RTL throughout — `Directionality(textDirection: TextDirection.rtl)` at app root
- Hebrew is the primary locale; English secondary
- All directional icons (arrows, chevrons) are mirrored for RTL
- Minimum touch target: 44×44pt (Apple HIG)
- Dark-mode first colour palette — see `design/ui_ux_design.md` for full token list
- Accent colour: `#F5A623` (keto gold)

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

Two things CI checks but does not generate, because it builds what you committed:
**generated `.g.dart` files** (run `build_runner` and commit) and **`pubspec.lock`**
(run `flutter pub get` and commit).

Coverage is not enforced by the workflow today. The 80% target on `application/`
and `domain/` (`design/tests.md`) remains a review expectation until a coverage
step is added.

Integration tests (`integration_test/`) are scoped to run nightly on an iOS
simulator, not per-PR. That directory does not exist yet (#150).
