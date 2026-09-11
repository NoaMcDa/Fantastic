# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Fantastic** is an all-in-one keto companion app built with Flutter, targeting **all six Flutter platforms** — iOS, Android, web, macOS, Windows and Linux. All six build on CI; only **web and Linux have ever been run**. See `design/m6_platform_handoff.md` — the distinction matters, and one real defect per platform surfaced only when a real toolchain touched it. The first two defects reported by a real *user* are in `design/user_bugs_handoff.md`; both were live while the whole suite was green. It features on-device Hebrew label OCR, keto ratio & electrolyte tracking, adaptation phase tracking, restaurant menu analysis, recipe conversion, a biomarker/symptom diary, and a curated Israeli keto directory.

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
| `design/m1_handoff.md` | **M1 handoff** — M1 is code-complete; the ten conventions every later issue inherits; the data-layer decisions M2 needs (unique-index writes, the singleton streak row, enum ordinal storage); typed repository failures; gotchas (`const` canonicalisation in equality tests, all-neutral fixtures hiding cross-wiring, `lcov` with no `LF:` lines — **since expired, see the correction in that file**, `build_runner` completing but never exiting). **Read before picking up M2** |
| `design/m2_preflight.md` | **M2 pre-flight corrections** — riverpod-2 `Ref` types, a `DailyLog.empty` factory that does not exist, and the `DailyLog` dashboard move that M2's text never picked up. Also lists the shipped model fields and repository methods M2 must code against. **Read before picking up any M2 issue** |
| `design/m2_handoff.md` | **M2 handoff** — M2 shipped and the app became usable; the five conventions M3 inherits (the `pump_app` widget-test harness, date-only family keys held in state, parameters over un-overridable providers); **the RTL traps that cost the most time** (a horizontal `ListView` already starts right; `endToStart` drags *rightward*); Flutter/riverpod gotchas (`Dismissible` vs async delete, `AnimatedCrossFade` keeping both children, `Override` unexported by `flutter_riverpod`); coverage at closure; the gaps M3/M4/M5 inherit. **Read before picking up M3** |
| `design/m3_preflight.md` | **M3 pre-flight corrections** — all twelve M3 issues audited. Four defects that compile and ship wrong behaviour: `copyWith(gracePeriodEnd: null)` silently does not clear, the streak increments per *meal* not per day, a fat-only first meal registers as a breach, and the phase boundary is off by one. Plus the canonical phase thresholds (8 and 28), two routes that do not exist, and the two places the issue text would regress M2. **Read before picking up any M3 issue** |
| `design/m3_handoff.md` | **M3 handoff** — M3 is code-complete and was driven end-to-end in a browser; **the riverpod-3 async-error fact that cost three issues** (a provider that fails before producing a value is `AsyncLoading` *with* an error, so `isLoading`-first checks hang forever); the eight conventions M4 inherits (phase thresholds 8/28, never `null` to clear a `StreakState` field, Sunday-first weeks, `TextDirection.ltr` on digit runs); why every notification call is a no-op on web; and the gaps M4/M5/M7 inherit. **Read before picking up M4** |
| `design/m4_preflight.md` | **M4 pre-flight corrections** — all six M4 issues audited. Three defects that compile and ship broken behaviour: the flow's last screen bounces straight back into onboarding forever, an `await ...future` inside a go_router redirect can hang the app on a blank screen, and seeding `StreakState.initial()` destroys the null first-launch sentinel. Plus **why `shared_preferences` is not added** (a `user_profile` sembast store replaces it), the seven symbols no issue defines, the corrected build order (#73 first), and the two Epic #8 DoD items no child issue covers. **Read before picking up any M4 issue** |
| `design/m4_handoff.md` | **M4 handoff** — M4 is code-complete and the app has a first launch. What the audit found (the flow's own last screen bounced the user back into onboarding forever; `await provider.future` inside a go_router redirect can hang the app on a blank screen; why `shared_preferences` was refused). The eight conventions M5–M7 inherit (record-existence as the first-launch flag, a synchronous gate seeded in `main`, one numeric parse for the whole flow, whole-day arithmetic through UTC midnights). Gotchas that cost the most: **a conflicted PR gets no CI run at all**, and **sembast futures never complete inside `testWidgets`**. Epic #8's DoD, two of whose six items had no child issue. **Read before picking up M7** |
| `design/m5_preflight.md` | **M5 pre-flight corrections** — all four M5 issues audited. The fifth symptom scale is **`moodScore` / מצב רוח**, not the brain fog every issue names — a rename alone ships a mood score under a brain-fog label. Also: `.when(loading:)` hides a failed read forever, the save sheet silently erases the user's note, `#75`'s two failure tests cannot be written as specified, the feature directory is `diary/` not `symptom_diary/`, and the build order is #75 → #77 → #76 → #78. **Read before picking up any M5 issue** |
| `design/m5_handoff.md` | **M5 handoff** — M5 is code-complete and was driven end-to-end in a browser, including a page reload and a past-date check. What the audit found (a field the model does not have, whose label the compiler cannot catch; a save that erased the user's note). The eight conventions M6/M7 inherit (one enum owns the five scales; `hasError` before `isLoading`; a failed read and an empty day must not look alike; assert against what is *painted*). Gotchas: `AsyncValue.when` is loading-first, a sliver child below the fold has no element at all, Flutter web's RTL semantics rects are offset from the viewport. **Epic #9's DoD is fully met and the Epic is closed.** Known gaps M7 and v1.1 inherit. **Read before picking up M7** |
| `design/m6_preflight.md` | **M6 pre-flight corrections** — all nine M6 issues audited. **Part 0 settles the ML Kit / web-build question empirically**: `dart:io` compiles for dart2js as throwing stubs, so the naive import does *not* break CI — the hazard is a runtime `MissingPluginException`, and the conditional-export firewall is built anyway (and why). Five defects that compile and ship wrong behaviour, the worst being a failed scan reported as **Clean Keto**; the five reasons #81's Hebrew regexes never match a real Israeli label; `permission_handler` and `image` decisions; a circular dependency graph. **Read before picking up any M6 issue** |
| `design/m6_handoff.md` | **M6 handoff** — Keto Lens shipped; **why the ML Kit / web risk was real but mis-located** (`dart:io` compiles for dart2js as throwing stubs; the hazard is a runtime `MissingPluginException`) and the product decision that follows: **the lens tab cannot scan in a browser and says so**. The nine conventions M7 inherits (one plugin per adapter behind an interface, failure as a sealed value, a clean badge is not evidence); the gotchas that cost the most (**an indeterminate spinner on a tab screen hangs `widget_test.dart`**, clearing a busy flag after awaiting a modal, a stale `build_runner` cache skipping a file silently); and an explicit list of **what is unverified** — there is no camera, device or browser here, so no accuracy claim has been measured. **Read before picking up M7** |
| `design/m6_platform_research.md` | **M6 platform research** — what it would take to run Keto Lens on all six Flutter targets, and **the finding that reframes the question: ML Kit has no Hebrew script model** (the enum is `latin, chinese, devanagiri, japanese, korean`), so the shipped iOS scanner asks a Latin recogniser to read Hebrew and most likely returns `ScanFailed(notALabel)` on every real label. Apple Vision, WinRT OCR, PaddleOCR and EasyOCR have no Hebrew either; **Tesseract + `heb.traineddata` is the only Hebrew-capable engine, and it reaches every target** — so fixing the engine and porting the feature are one change. Measured asset budget, correcting `technology.md`'s "~50 MB" Hebrew model by ~50x (the handoff has the figures that actually shipped), why cloud OCR stays rejected, why desktop's blocker is the camera and not OCR, and **the prerequisite for all of it: a corpus of real Israeli labels, which needs no app and no device**. **Read before any M6 engine or platform work** |
| `design/m6_platform_handoff.md` | **M6 platform handoff** — what shipped when the research was implemented: ML Kit removed, **Tesseract on all six targets**, and **the lens tab now scans in a browser** (0.5 s, zero external requests) — reversing M6's central product decision. The six things only running it revealed: **`preserve_interword_spaces=1` destroys RTL Hebrew spacing** (the research doc had recommended setting it), three fatal Linux startup bugs that all rendered the *database* error screen, `flutter create` dropping `ios`+`web` from `.metadata` again, and a Dart `'''` literal that cannot hold geresh-terminated OCR output. The seven conventions inherited; **one real defect per platform, found only when a real toolchain ran** (`jcenter()` on Android, a model absent from the iOS `.app`, wrong library names on macOS *and* Windows); the **#257 serving-basis fix**; and an explicit verified/not-verified line — all six build on CI, **only web and Linux have ever been run**. **Read before any further platform or OCR work** |
| `design/m7_preflight.md` | **M7 pre-flight + the audit it produced** — all eight M7 issues audited against the code. **Three were already done and are closed** (#90's Isar error screen shipped in M2 as `StartupFailureApp`; #93's Hebrew usage strings shipped in M6; #94's notification work shipped in M3/M4, and its `aps-environment` step is *wrong* — that entitlement is for remote push). **Four were rewritten in place**: #89's `ProviderObserver` snippet does not compile against riverpod 3 and reaches for the `AsyncError` match four milestones learned not to — `providerDidFail` is the hook it wanted; #88 presumes a `lib/core/widgets/` that does not exist and never mentions that **a shimmer is the forever-animation that hangs `pumpAndSettle`**; #91 named two screens that cannot be empty; #92 was iOS-only for a six-platform app and is blocked on artwork nobody has drawn. **Nine issues filed** for defects four handoffs called M7 work without numbering (#301–#311). Part 5 records what was deliberately *not* filed — above all **the accessibility gap**, which no design document mentions. **Read before picking up any M7 issue** |
| `design/backlog_handoff.md` | **Backlog handoff** — what M7 and M8 actually contain after the audit, and the **M8 audit, recorded nowhere else**: six of its seven integration-test issues had already shipped in #273 and nobody had closed them; **#98 (breach → grace → expiry → reset) is the one flow never written**, and it is the whole remaining blocker on M8. Also the three invariants that were wrong in Epic #12 — two of which would have had a reviewer reject correct code, including *"`ScanOrchestrator` is mocked"* when it is not. Carries the M7 build order, the corrections applied to `mvp_handoff.md`, what was deliberately **not** filed (accessibility; release APKs signed with the debug key), and the three issues the owner opened mid-session. **Read before picking up M7 or M8** |
| `design/m8_preflight.md` | **M8 pre-flight + the e2e suite** — all eight M8 issues audited, and **Part 0 settles the "where do e2e tests run?" question empirically**: `flutter test -d flutter-tester integration_test/app_test.dart` drives the real app over a real in-memory sembast database, headless on Linux, in seconds — **no simulator, no macOS runner, no nightly-only compromise**, which retires `cicd_plan.md` §7.1's Phase 3 parking. The seven flow issues carry 24 defects between them (two of five tab labels do not exist; #99 drives sliders the sheet does not have). **Part 10 is what shipped**: the harness, the `e2e flows` CI job, ten flows — and the four defects the suite found on its first runs (the dashboard shows no macro targets until the first meal is logged; `MealListSection` spins forever on a storage failure — **fixed, see `design/user_bugs_handoff.md`**; a dismissed meal is deleted asynchronously; the scan prefill shows `0.17999999999999988` where the sheet showed one decimal). **Read before picking up any M8 issue, and before writing a flow** |
| `design/mvp_handoff.md` | **MVP handoff** — the cross-milestone view. **All five MVP features ship (M0–M6 complete).** The audit pattern that defined the project (the issue text was never right, once, in seven milestones) and the worst defect each audit caught; **the riverpod-3 async-error fact that cost four milestones in four disguises**; the consolidated open-defect list (#257 is the highest-value fix); what has never been verified — no device, no camera, and **nothing has ever read a real Hebrew label**; and the M7 issues that are already done or obsolete — **three, not the four it says**; its M7 and M8 sections are superseded in part by `design/m7_preflight.md` and `design/backlog_handoff.md`, and carry pointers saying so. **Read before M7 or M8** |
| `design/user_bugs_handoff.md` | **First user bug reports** — the first two defects reported by someone *using* the app rather than auditing it, both live while 1220 tests, a 99.58% coverage gate, ten e2e flows and six platform builds were green. **The diary tab could not log a meal** (its empty state said "tap +" and the only + logged symptoms; the dashboard FAB was fine, and that was verified by running the app before anything changed), and **the scan read nothing**. The three green-suite blind spots they exposed: a flow that exercises one route to a capability is not a test that the capability is reachable; a test that skips where the bug lives reads identically to a pass; a fixture-generating tool that does not call the app's own code path certifies a pipeline that does not ship. Eight conventions inherited, and the honest verified/not-verified line — **no camera, no mobile run, one label**. **Read before touching the add-meal affordance or trusting a green suite** |
| `design/v1_1_split.md` | **v1.1 split proposal** — why the single `v1.1 — Post-MVP Backlog` milestone fails the project's own milestone definition, the seven capability groups it should become, the stale content it carries (Isar references after the sembast swap, an iOS-only backup design after web shipped, a mis-identified map SDK), and the work required to execute. **Executed** — labels, seven Epic issues (#264–#270), all 26 issues
re-filed and rewritten, and the seven **GitHub milestones #11–#17** created with all 33 issues
assigned and `v1.1` retired. §6 also records the one-shot Actions workflow that created them — the
agent session's own tooling has no milestone API |
| `design/m15_meal_entry_research.md` | **M15 research & pre-flight** — #312 asked for three ways to add a meal; the audit found **one already ships, half of another already ships, and only the third is a new engine**. Corrects the issue text on four counts ("photo with OCR" conflates a nutrition panel with a plate of food; `MealEntry.imageRef` and `ingredients` have been persisted and contract-tested since M1 and **written by nothing**). Carries the accuracy argument that drives the design — **the daily net-carb budget is 20 g, and the best 2026 vision model's 80.7 kcal calorie error *is* 20 g of carbohydrate**, so an estimate must always be editable and can never silently drive the streak. Records the engine decision (**cloud LLM via OpenRouter, BYOK because the free tier is 50 requests/day per key**, not gated on `epic:login`), why Keto Lens's no-network invariant is untouched, and the offline food table kept on the shelf behind the same interface. **Read before picking up any M15 issue** |
| `design/mvp.md` | MVP scope — 5 must-ship features, build order, success metrics, what is deferred |
| `design/architecture.md` | Layer model, persistence schemas, Riverpod provider hierarchy, OCR pipeline, data flow, routing |
| `design/base_design.md` | SOLID abstractions — repository interfaces, service contracts, domain models, and the **Error Handling Contract** (repositories throw typed exceptions; §"Why not `Result<T>`" records why that pattern was dropped before M1 — do not reintroduce it) |
| `design/tests.md` | Testing strategy — pyramid, unit/widget/integration patterns, fixture conventions, CI gate |
| `design/cicd_plan.md` | **CI/CD plan** — `.github/workflows/ci.yml` runs format, analyze, the full test suite, the coverage gate and the web build on every PR (Phases 0 and 2, shipped). Phase 1 (codegen drift, dependabot) is next. Note §5.3 **[r4]**: the "`lcov.info` has no `LF:` lines" premise expired — every record carries `LF:`/`LH:` on Flutter 3.47.3, and the gate counts `DA:` by choice rather than by necessity. **Integration/nightly-simulator CI and all fastlane/TestFlight/App Store CD are parked by decision — §7.1 has the entry conditions; do not build them early.** Also carries seven corrections to issue #102's YAML. **Read before touching `.github/`** |
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

# Desktop. Linux and Windows need a system Tesseract for the lens to scan;
# without it the tab says so and the rest of the app works normally.
#   sudo apt-get install libtesseract-dev libleptonica-dev   # Debian/Ubuntu
#   brew install tesseract leptonica                          # macOS
flutter build linux --release
flutter build macos --release
flutter build windows --release
flutter build apk --release

# Run all tests (unit + widget). Never picks up integration_test/.
flutter test

# Run the end-to-end flows. `-d flutter-tester` is required, and the
# aggregator file is required — see design/m8_preflight.md Part 0 and §6.1.
flutter test -d flutter-tester integration_test/app_test.dart

# Run tests for a single feature
flutter test test/features/<feature_name>/

# Run a single test file
flutter test test/path/to/test_file.dart

# Run tests with coverage, then apply the same gate CI does
flutter test --coverage
tool/check_coverage.sh coverage/lcov.info 80
tool/check_coverage_files.sh coverage/lcov.info

# Run the browser-only tests (the dart:js_interop binding for web OCR).
# These are @TestOn('browser') and are skipped by a plain `flutter test`.
CHROME_EXECUTABLE=/path/to/chrome flutter test --platform chrome \
  test/features/keto_lens/data/adapters/tesseract_js_text_recognizer_test.dart

# Regenerate the captured real-OCR fixtures. Needs tesseract on PATH and a
# Pillow built with Raqm. Never hand-edit real_ocr_fixture.dart - its whole
# value is that no hand touched it.
./tool/capture_ocr_fixtures.sh

# Analyze code (lint)
flutter analyze

# Format code
dart format .

# Format check only (no writes — used in CI)
dart format --output=none --set-exit-if-changed lib/ test/ integration_test/

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
- **Native-only code stays behind a conditional-export firewall.** There are two, and
  nothing outside them may import what they wrap: `lib/core/database/database_factory.dart`
  (`path_provider`, the io/web sembast factories) and
  `lib/features/keto_lens/data/adapters/text_recognizer_factory.dart` (ML Kit).
  Each exports an `_io` and a `_web` implementation on `dart.library.io`.
  **`dart:io` itself is not the hazard** — M6 established empirically that dart2js
  compiles it as a library of throwing stubs, so a naive import builds cleanly and
  then throws `MissingPluginException` in the browser at run time. `flutter analyze`
  catches neither. See `design/m6_preflight.md` Part 0

### Features
| Feature | Directory |
|---|---|
| Dashboard & macro tracking | `lib/features/dashboard/` |
| Onboarding & user profile | `lib/features/onboarding/` |
| Keto Lens (Hebrew OCR scanner) | `lib/features/keto_lens/` |
| Diary (meals, symptoms, biomarkers) | `lib/features/diary/` |
| Adaptation phase & streak | `lib/features/adaptation/` |
| Restaurant directory | `lib/features/restaurant/` |
| Recipe converter | `lib/features/recipe/` |
| Israeli keto directory | `lib/features/directory/` |

`lib/features/profile/` is still a placeholder — the Profile tab has no screen yet.

**A meal can be logged from the dashboard and from the diary, and both go through
`AddMealFab`** (`lib/features/diary/presentation/widgets/add_meal_fab.dart`) — never a
`FloatingActionButton` written out inline. The diary shipped without one while its own empty
state told the user to tap it; see `design/user_bugs_handoff.md`. Each host passes its own key
(`add_meal_fab`, `add_meal_fab_diary`) because the tab shell keeps the outgoing screen mounted
during a transition, and clears a scrolling body with `AddMealFab.bodyClearance`.

## MVP Scope

**All five MVP features are shipped (M0–M6 complete).** Only M7 (polish) and
M8 (CI & integration) remain inside the MVP boundary — and **M8 is one issue
from closing**: #98 is the single flow of eleven that was never written. M7 is
14 open issues with a build order in `design/backlog_handoff.md` §3 — see
`design/mvp_handoff.md` for the consolidated state, the open defects and what
has never been verified.

The MVP (see `design/mvp.md`) ships exactly these 5 features:
1. **Keto Lens** — Hebrew OCR label scanner with Clean/Caution/Non-Keto badge
2. **Daily Macro Tracker** — manual meal logging, keto ratio, electrolytes, dashboard
3. **Adaptation Phase Tracker & Streak** — 3-phase state machine, streak ring, push notifications
4. **Onboarding** — 4-screen flow, personalised macro targets, streak seeding
5. **Symptom Diary** — lightweight 1–5 daily ratings

Everything else is deferred to its own post-MVP milestone: biomarker logging (M9),
recipe converter (M10), restaurant directory (M11), menu analyzer (M12), Apple
Health (M13), backup & restore (M14). See `design/v1_1_split.md`.

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
| `UserProfile` — sex, age, weight, height, goal, macro targets, keto start date | `user_profile` | `UserProfileMapper.singletonId` |

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

**The database file lives in a different directory on mobile and desktop.**
Mobile keeps the app-documents directory — it is what iOS backs up, and it is
where every existing install already has its data. Desktop uses the
application-support directory, because `path_provider_linux` implements
`getApplicationDocumentsDirectory()` by shelling out to `xdg-user-dir`, which a
minimal system does not have; the call then throws
`MissingPlatformDirectoryException` and the app dies before its first real
frame. Found by running the Linux build — no test calls it.

**The database is opened once, in `main.dart`, and injected.**
`lib/core/database/database_factory.dart` conditionally exports
`database_factory_io.dart` (path_provider + `databaseFactoryIo`) or
`database_factory_web.dart` (`databaseFactoryWeb`, IndexedDB, no path) on
`dart.library.io`. `databaseProvider` is overridden with the result.
`build_runner` is still required, but only for `@riverpod` — sembast has no
generator.

### Numeric input

**`NumericInput.positiveFinite` (`lib/core/utils/numeric_input.dart`) is the one
place a user-typed number becomes a `double`.** `double.tryParse` is not
validation: it accepts `Infinity` and `NaN`, neither of which is null, so a
`tryParse(...) ?? fallback` never fires for either and both propagate into a
`NaN` keto ratio. `OnboardingValidators.positiveFinite` delegates to it. Add a
third caller by calling it, never by copying the guard.

### Error handling

Repositories **throw**; they do not return a `Result<T>`. `lib/core/error/` holds the sealed hierarchy — `RepositoryException` with `EntityNotFoundException` and `PersistenceException` — plus `guardPersistence` / `guardPersistenceStream`, which every repository method wraps its storage call in.

The guard catches `Object`, not `Exception`. sembast's own `DatabaseException` does implement `Exception`, but the guarded body also holds the codec that decodes the stored record, and a bad cast or a missing key there throws an `Error` — which an `on Exception` clause would miss. Wrapping those too is right: a codec that throws on stored data is itself a persistence-integrity failure. Services let these propagate without catching to convert; presentation reads them as `AsyncValue.error`.

## OCR & ML

**Shipped in M6, re-engined for every platform since.** On-device Hebrew text
recognition via **Tesseract** — no network call is made during a scan, and Epic
#10's first architectural invariant forbids adding one.

**ML Kit was removed, and the reason matters: it has no Hebrew script model.**
Its enum is `latin, chinese, devanagiri, japanese, korean`, and the adapter was
calling the bare `TextRecognizer()`, which defaults to `latin`. Apple Vision,
`Windows.Media.Ocr`, PaddleOCR and EasyOCR have no Hebrew either. Tesseract is
the only on-device engine that does — and the only one that reaches every
target, which is why fixing the engine and porting the feature were one change.
See `design/m6_platform_research.md` and `design/m6_platform_handoff.md`.

```
CameraScreen / gallery import
  → TextRecognitionService   (domain interface)
      browser  → TesseractJsTextRecognizer      tesseract.js (wasm), self-hosted
      VM       → ScalingTextRecognizer          greyscale + scale-up, in an isolate
                 wrapping TesseractNativeTextRecognizer, which dispatches on Platform:
                   android/ios → TesseractPluginRecognizer  (flutter_tesseract_ocr)
                   desktop     → TesseractFfiRecognizer     (dart:ffi → libtesseract)
                   otherwise   → UnavailableTextRecognizer  (not wrapped)
  → LabelParser              → HebrewLabelParser + HebrewTextNormaliser
  → IngredientClassifier     → IngredientClassifierImpl
  → ScanResult               (sealed: ScanSucceeded | ScanFailed)
  → ScanResultSheet          → scales by ServingBasis → prefills AddMealBottomSheet
```

The firewall still has **two arms**, because `dart.library.io` is the only thing
a conditional export can ask. The finer android-vs-desktop split happens at run
time inside the VM half, where `Platform` is legal to reach for.

`ScanOrchestrator` (`application/`) composes the three interfaces and never sees
a plugin type — which is what makes it testable in pure Dart.

**A failed scan is `ScanFailed`, never a verdict.** Issue #83 originally
specified reporting a failed scan as `Clean Keto`; a user in a shop would have
been told a product was keto-safe because the app could not read the label. The
sealed result exists so that cannot be expressed.

**The badge reads the panel, not only the ingredient list.** A scan produces
*two* verdicts — `IngredientVerdict` from the tokens and `MacroVerdict` from the
numbers — and `LabelVerdict.combine` reduces them to the one badge shown. Until
#306 the badge was `classifier.classify(label.ingredients)` and nothing else, so
a whole-wheat bread at **34.2 g of net carbs per 100 g rendered a green tick**:
`label.netCarbsG` was in scope on the line above and never reached the verdict.

- **Band edges are computed, never typed.** `ProductVerdictConstants` holds
  portions and a carb budget; `5 g / 100 g` and `5 g / 20 g` *are* the green and
  red solid edges. "Why 25 g per 100 g?" has an answer.
- **The panel checks itself first.** When energy, fat, protein and total carbs
  all parsed, `9·fat + 4·protein + 4·carbs` must land within 25% of the declared
  calories, or the verdict is `indeterminate(energyMismatch)` — a confident band
  computed from a mis-read digit is the deepest risk the feature carries. The
  check is **skipped** when the energy row did not parse.
- **Green is withheld under an assumed basis, and only green.** If figures that
  are really per-serving are read as per-100 g, the error is always *optimistic*
  — a serving is never more than 100 g. Amber and red stay right either way. A
  printed zero is the one exception: zero is zero on every basis.
- **Polyols are subtracted only when they can be attributed** — a declared row,
  a clean sweetener named, no insulin-spiking sweetener named, a non-empty
  ingredient list, and grams that fit the carbohydrate residual. An
  unattributed subtraction is a green tick bought with no evidence.
- **An amber ingredient badge escalates to red** when a flagged *insulin-spiking
  sweetener* meets `moderation` or worse macros. `ui_ux_design.md` defines that
  badge as "sweeteners **in small amount**" — a quantity claim nothing could
  test until the panel could. An unspecified vegetable oil never escalates: that
  caution is about identity, and carbs say nothing about which oil it is.
- **`recognisedNothing` is not evidence**, so it is excluded from the reduction.
  With nothing on either side the sheet shows a neutral chip rather than
  "no problematic ingredients found".

**The lens scans in a browser.** This reverses M6's original decision, which
was correct while the only on-device option was a native-only plugin. Tesseract
compiled to WebAssembly runs in a Web Worker on the user's machine, so the
no-network invariant survives: everything is served from `web/tesseract/`, and
a scan was measured in Chromium at 0.5 s with **zero external requests**. Never
let tesseract.js fall back to its CDN defaults for `workerPath`, `corePath` or
`langPath` — that would both break the invariant and regress the
zero-external-requests property `design/web_support.md` §7 records as verified.

**Scanned macros are scaled, and the parser will not guess what they are per.**
A label declares its values per 100 g; logging them as the serving is what #257
was. `ServingBasis {per100g, per100ml, perServing, unknown}` is parsed from the
label and `ParsedLabel.basis` defaults to `unknown`, which never scales.

- **Exactly one basis marker resolves to that basis; zero or more than one
  resolves to `unknown`.** Many Israeli labels print two columns and flattened
  OCR cannot say which column a number came from — so the sheet asks rather
  than picking one. A plausible wrong number logged silently is the failure
  mode this whole feature is built to avoid.
- **The macro strip shows what will be logged, not what is printed.** The
  number in front of the user when they save is the number that gets saved.
- **An empty or unparseable amount falls back to the printed figures, never to
  zero.** A zero-macro meal saves without complaint and is invisible in the
  day's totals.

**The engine settings are `psm 4`, `heb+eng`, `oem 1` and an explicit
`user_defined_dpi`, and every one of them is set in all three adapters.** A
user scanned a real bordered Israeli panel and got nothing back; the parsers
were innocent and the shared engine configuration was at fault, in four
independent ways at once:

- **`psm 6` flattens a bordered two-column table.** Six of the label's nine rows
  came back as punctuation. `psm 4` keeps each row with its own number.
- **The Hebrew model cannot read an isolated column of Latin digits.** It
  returned 218/9/2/43/9/308 where the label printed 238/10.9/41.2/7/3.3/368,
  and more resolution did not help. `eng.traineddata` ships beside `heb` for
  this — 3.92 MB, and a real trade: on **pointed (niqqud)** Hebrew English
  sometimes wins a word, and a macro degrades to `null`. **Never to `0`, and
  never "recovered" by a second `heb`-only pass** — that fills a safe null from
  a pass known to be unreliable on digits, which is the #257 direction.
- **Tesseract estimates resolution when the file declares none, and estimated
  631 dpi here**, then downscaled internally on the strength of it.
  `user_defined_dpi` stops the guess.
- **Colour costs every digit.** Handed a 4- or 3-channel buffer the engine read
  every Hebrew row and not one number. `ScalingTextRecognizer` converts to
  single-channel greyscale; flattening alpha alone is *not* sufficient.

**A small image is scaled up before recognition** (`OcrImagePrep`,
`ScalingTextRecognizer`, and a canvas in `fantastic_ocr.js`), with hard caps on
edge length and pixel count so no input can provoke an unbounded allocation — a
12 MP phone photo passes through untouched. The chosen kernel and width sit on
a **narrow** plateau; adjacent settings return plausible *wrong* macros. See
`design/m6_platform_handoff.md` §"The scan that read nothing".

**`preserve_interword_spaces` must stay unset.** It reads like the safe choice
and is, for Latin — but on RTL Hebrew it *removes* spaces: `53.8 גרם` comes back
as `53.8גרם`. Measured identically on libtesseract and on the wasm build.

Ingredient rules live in `lib/core/constants/ingredient_rules.dart` in both
Hebrew and English — **never redeclared in a classifier**:
- **Forbidden seed oils:** canola, soybean, corn, sunflower, cottonseed, safflower
- **Insulin-spiking sweeteners:** maltitol, sorbitol, dextrose, maltodextrin, HFCS
- **Clean approvals:** olive oil, avocado oil, coconut oil, butter, ghee, tallow, monk fruit, stevia, allulose, erythritol

Output badges: `Clean Keto` / `Caution / Quantity Dependent` / `Non-Keto`.
Worst badge wins. An unrecognised token is *not* flagged, so
`IngredientVerdict.recognisedNothing` distinguishes "nothing here is bad" from
"nothing here was readable" — without it the UI would put a green tick on an
unreadable label.

**Tesseract has been verified to read Hebrew labels, including one real
photographed label; no label has ever been read *through a camera*.** `test/fixtures/real_ocr_fixture.dart` holds verbatim engine
output captured from labels rendered in the app's own font
(`tool/capture_ocr_fixtures.sh` regenerates it), and
`real_ocr_pipeline_test.dart` asserts what the shipped pipeline does with it.
That closes the gap between "a human imagined this OCR output" and "an engine
produced it". It does not close the gap to glare, curvature and shop lighting —
there is still no camera here, no accuracy percentage is claimed, and issue #256
and Epic #10 stay open. See `design/m6_platform_handoff.md`.

## Keto Business Logic

**Scanned values are per 100 g unless the label says otherwise** — see the OCR
section. Everything below is computed from what was *eaten*, so a scan that is
not scaled to the serving corrupts all of it at once.

**Keto Ratio:** `Fat (g) / (Net Carbs (g) + Protein (g))`  
**Net Carbs:** `Total Carbs (g) − Dietary Fiber (g)`

**Adaptation phases** (streak-driven state machine):
- Phase 1 (Days 1–7): Induction & Keto-Flu Management
- Phase 2 (Days 8–27): Fat-Adapted Transition
- Phase 3 (Days 28+): Deep Ketosis & Long-Term Maintenance

**A compliant day is one with meals logged whose total net carbs are at or below
`KetoConstants.maxCompliantNetCarbsG` (50 g).** Above it the day is a breach and
opens a 24-hour grace period; if a compliant day lands inside that window the
streak resumes, and if not it resets to 0 and the phase returns to Phase 1.

**`DayCompliance.of` is the only definition of a compliant day**
(`lib/features/adaptation/domain/models/day_compliance.dart`). It lived in two
places — the streak evaluation and `StreakCalendarWidget._statusFor` — so the
ring and the month grid could disagree about the same day. Never restate it.

**The keto ratio does not decide compliance.** Until #303 it did (`ketoRatioAvg
>= 2.0`), and because the ratio is `fat / (netCarbs + protein)` protein sat in
the denominator beside carbs: a disciplined 8 g-carb day with 90 g of protein
scored 0.31 and broke the streak, while 100 g of fat with 50 g of carbs and no
protein scored exactly 2.0 and passed. The ratio keeps every other job it has —
the ring arc, the macro card, `DailyLog.ketoRatioAvg`.

**The counter is derived, not accumulated.** `AdaptationPhaseService.recomputeFor`
re-derives the streak on every write by walking back over `DailyLog` from today
(`StreakCalculator.derive`, bounded at 365 days). That is what makes a
retroactive edit correct by construction: **back-filling a forgotten day repairs
the streak across the gap, and pushing a past day's net carbs over the limit
breaks it.** `StreakState` keeps one counter and gains no field — the per-day
record is `DailyLog`, which already exists.

**A skipped day breaks the streak, in all three phases.** The walk stops at an
unlogged day, so the next compliant day starts a new streak at 1 — except today,
which is winnable until midnight and is stepped over without breaking.

**A day whose three macro totals are all zero reads as unlogged**, because
`DailyLog` carries no meal count and the row survives a deleted last meal so
water and electrolytes are not lost. A fat-only day is *not* that: it has zero
net carbs, which is the best possible day.

**The evaluation instant is always the wall clock**, never the meal's timestamp.
The walk counts back from the instant it is given, so a back-dated meal would
otherwise start the walk in the past and today would stop counting.

**A breached day is not a skipped day.** An unexpired grace window survives the
calendar gap it creates — that window is precisely what a breach buys, and the
resume promise above depends on it.

**Phase 3 shares the rule for now and is expected to change**, to something
that depends on what was eaten rather than on whether anything was logged.

Re-derivation runs **on write, not on read**: nothing persists it until the
user's next logged meal, so the ring can show a stale streak until then (the
"streak resets lazily" gap in `design/m3_handoff.md`). Applying it on read
would put `DateTime.now()` inside a provider and make every widget test that
stubs a streak time-dependent.

## Testing

Full testing strategy in `design/tests.md`. Summary:

| Layer | Test type | Tooling | Coverage gate |
|---|---|---|---|
| `domain/` | Unit — no mocks | `dart test` | 100% public methods |
| `application/` | Unit — mock interfaces | `dart test` + `mocktail` | 100% public methods |
| `data/` | Repository contract tests | In-memory sembast | Contract suite |
| `presentation/` | Widget tests | `flutter_test` + provider overrides | Critical paths |
| Full flows | End-to-end | `integration_test` on `flutter-tester`, headless | 14 tests, per PR |

- **CI runs the suite; you do not have to.** Push, open the PR, watch the run, and fix any failure on the same branch — see the Developer Workflow above
- All fixtures live in `test/fixtures/` — never construct domain objects inline in tests
- Repository contract tests must pass for every concrete implementation. Each is a top-level factory-parameterised function — `runXxxRepositoryContractTests(factory, {required breakStore})` — so any future backing store runs against the same cases. That is what enforces Liskov at the test level
- `breakStore` lets a suite make the store fail without knowing what it is; for sembast it closes the database, so the next store access throws a real `DatabaseException` from inside the repository
- Open a test database with `openTestDatabase()` — no schema list, no native binary — and close it with `closeTestDatabase(db)`. `newDatabaseFactoryMemory()` gives each call its own isolated store
- The data-layer suite is now pure Dart: no `dart:io`, no `dart:ffi`, no library to dlopen. That makes `flutter test --platform chrome` possible, though CI does not run it yet
- In a test file that imports both `flutter_test` and `package:sembast/sembast.dart`, **`Finder` is ambiguous** — both packages export one. Prefix the sembast import where you need its `Finder`
- Beware a fixture whose fields all share one value (`SymptomLogFixture` defaults every scale to 3): a mapper that crosses two fields still passes. Use distinct values where a model has several same-typed fields
- **Two suites need something the default run does not have.**
  `tesseract_ffi_recognizer_test.dart` runs a real OCR engine and **skips** when
  libtesseract is absent (as on CI) rather than failing — a red suite people
  learn to ignore is worse than a skip that says what is unchecked. **It now
  prints a loud banner when it skips**, because a silent skip once let a
  regression through that dropped every digit off a label while CI stayed
  green: a green run proves nothing about desktop or mobile OCR.
  `scaling_text_recognizer_test.dart` is the pure-Dart companion that would
  have caught that one — it asserts the *buffer* handed to the engine (single
  channel, target width), which needs no engine and runs everywhere.
  `tesseract_js_text_recognizer_test.dart` is `@TestOn('browser')` and needs
  `--platform chrome`; it covers the `dart:js_interop` boundary, which fails
  silently — a mismatched `extension type` member compiles and then throws in a
  browser only, and neither `analyze` nor `build web` catches it
- **Never assert on raw OCR text — assert what the pipeline parsed.** Tesseract
  5.3.4 and 5.5.3 read the same label differently (`חלבונים` vs `חזלבונים`), so
  a `contains('חלבונים')` assertion passes locally and fails on the macOS
  runner. The parsed macros are stable across both and are what the user
  depends on. `HebrewLabelParser` absorbs **one** corrupted letter per keyword
  for the same reason — narrowly, because a loose matcher that let `שומנים`
  claim the `מתוכם שומן רווי` row would report saturated fat as total fat
- **`CiOcrFixture` is transcribed from a CI log**, not generated, because no
  machine here runs 5.5.3. It is a separate file so that "never hand-edit
  `real_ocr_fixture.dart`" stays an unambiguous rule
- **`RealOcrFixture` is generated, not written.** Every other fixture here was
  written by hand, which `design/m6_handoff.md` warns is "exactly the kind of
  test that passes and then fails on a real label". That one is verbatim
  Tesseract output. Regenerate with `tool/capture_ocr_fixtures.sh`; do not edit
- **Hebrew OCR output cannot go in a `'''` Dart literal.** Grams are abbreviated
  with a geresh, so captured text routinely ends in an apostrophe. Use `"""`
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

All atomic issues are created, labelled and added to project board #2. Epic tracking
issues #4–#12 pin the MVP milestones; #264–#270 pin the post-MVP milestones and the
v1.0 release; **#312 pins M15 Meal Entry**, the first milestone opened from a user's own
request. #13 (v1.1 Post-MVP) is closed — it was split into seven milestones,
recorded in `design/v1_1_split.md`.

**GitHub milestones #11–#18 cover M9–M15 and the release**, and all 33 v1.1-split issues — the 26
work issues plus the seven Epics — are assigned to them. `v1.1 — Post-MVP Backlog`
(milestone #8) is retired. **Filtering by milestone and filtering by `epic:*` label give
the same view**, so either is accurate; the Epics additionally report per-child progress
through the GitHub sub-issue hierarchy.

`design/v1_1_split.md` §6 carries the full mapping and records **how** the milestones
were created — an agent session's GitHub tooling can set an issue's milestone but cannot
create one, so a one-shot Actions workflow did it. Read that before attempting any other
repo-admin operation from a session.

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
| M7 — Polish | `epic:m7-polish` | #88–#94, #151, #301, #302, #304, #305, #307–#311 | 17 — **14 open** |
| M8 — CI & Integration | `epic:m8-ci-integration` | #95–#102, #150, #197, #199 | 11 — **1 open (#98)** |
| Release v1.0 — App Store | `epic:release-v1` | #125–#128 | 4 |
| M9 — Biomarker Logging | `epic:m9-biomarkers` | #103–#107 | 5 |
| M10 — Recipe Converter | `epic:m10-recipe-converter` | #118–#120 | 3 |
| M11 — Restaurant Directory | `epic:m11-directory` | #111–#117 | 7 |
| M12 — Menu Analyzer | `epic:m12-menu-analyzer` | #121–#122 | 2 |
| M13 — Apple Health Sync | `epic:m13-health-sync` | #108–#110 | 3 |
| M14 — Backup & Restore | `epic:m14-backup` | #123–#124 | 2 |
| M15 — Meal Entry | `epic:m15-meal-entry` | #315–#326 | 12 |
| Login — accounts & identity | `epic:login` | #206–#226 | 16 |

**M9–M15 are numbered by recommended build order, not by dependency** — they are
parallel peers and `milestone_conventions.md` §1.2's sequential gate applies to
M0–M8 only. **`epic:release-v1` ships the MVP**, so it runs before M9, not after.
`epic:post-mvp` is retired — see `design/v1_1_split.md`.

**M15 is the first milestone opened from a user's own request rather than from the
original plan** — issue #312, rewritten into its Epic. It is also the first to make
an outbound network call, which is a different feature from Keto Lens and **does not
relax the OCR no-network invariant**; see `design/m15_meal_entry_research.md` §4.

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
| ~~v1.1 Post-MVP~~ | ~~#13~~ — closed, split into the seven above |
| Login (unscheduled) | #226 |

### Label taxonomy

**Type labels** (7) — prefix `type:`:
`type:feat` · `type:fix` · `type:test` · `type:refactor` · `type:chore` · `type:docs` · `type:perf`

**Layer labels** (7) — prefix `layer:`:
`layer:core` · `layer:domain` · `layer:data` · `layer:application` · `layer:presentation` · `layer:infra` · `layer:test`

**Epic labels** (18) — prefix `epic:` — see milestone table above. Ten MVP/epic
labels (`epic:m0-foundation`–`epic:m8-ci-integration`, plus `epic` on tracking
issues), seven post-MVP milestones (`epic:m9-biomarkers`–`epic:m15-meal-entry`),
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

Steps, cheapest first so a formatting slip fails in seconds:
1. `flutter pub get`
2. **`pubspec.lock` unchanged** — fails if `pub get` rewrote the committed lockfile
3. `dart format --output=none --set-exit-if-changed lib/ test/ integration_test/` — zero diffs
4. `flutter analyze --no-pub` — zero issues
5. `flutter test --no-pub --coverage` — zero failures, and writes `coverage/lcov.info`
6. `tool/check_coverage.sh coverage/lcov.info 80` — ≥80% on `domain/` + `application/`
7. `tool/check_coverage_files.sh coverage/lcov.info` — no gated file missing from the report and absent from `tool/coverage_ignore.txt`
8. `flutter build web --release --no-pub --no-web-resources-cdn` — the web target compiles

Step 8 is not redundant with `analyze`: a stray `dart:io` or `path_provider`
import outside `lib/core/database/database_factory_io.dart` analyses clean and
breaks only the web build.

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

A second job in the same workflow, on `ubuntu-latest`, per PR and in parallel
with `verify`:

```bash
flutter test -d flutter-tester integration_test/app_test.dart --no-pub
```

**No simulator, and not nightly** — the nightly-on-an-iOS-simulator scoping
every other document used to state is superseded by `design/m8_preflight.md`
Part 0. The suite drives the real app (real router, real provider graph, real
repositories, real in-memory sembast) headless, in ~35 s.

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
OS, each in its own file so that changing one cannot conflict with another:

| Workflow | Runner | Builds | Trigger |
|---|---|---|---|
| `build-android.yml` | `ubuntu-latest` | `flutter build apk` | PR + push to main |
| `build-linux.yml` | `ubuntu-latest` | `flutter build linux` **+ a headless smoke test** | PR + push to main |
| `build-windows.yml` | `windows-latest` (2x minutes) | `flutter build windows` | PR (paths-filtered) + push to main |
| `build-ios.yml` | `macos-latest` (**10x minutes**) | `flutter build ios --no-codesign` | PR (paths-filtered) only |
| `build-macos.yml` | `macos-latest` (**10x minutes**) | `flutter build macos` | PR (paths-filtered) only |

**The macOS-runner jobs are deliberately not on `push`.** `design/cicd_plan.md`
§8 records an earlier plan exceeding the free Actions tier 3x on macOS minutes
alone; path filters plus `cancel-in-progress` are what keep that from
recurring. Note a `paths` filter matches the **whole PR diff, not the newest
push**, so a docs-only commit on a PR that already touched `ios/` still re-runs
the job — `concurrency` is the per-push control, not `paths`.

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
