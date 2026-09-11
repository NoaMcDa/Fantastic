# Issue Conventions — Fantastic

## 1. Atomicity & Development Rules

### Defining Atomicity

An issue is atomic when it satisfies all four conditions:

1. **Self-contained** — it can be implemented without requiring a simultaneous, unmerged PR in another branch.
2. **Independently mergeable** — merging its PR leaves `main` in a green, buildable, test-passing state.
3. **Singularly focused** — it touches one concern (one model, one service, one widget, one test suite). If the title requires the word "and", split it.
4. **Verifiable** — it has concrete, binary acceptance criteria that a reviewer can check without interpretation.

An issue that requires two PRs to be useful is two issues. An issue whose PR breaks CI until a follow-up is merged is a scope violation — restructure it so every intermediate state is valid.

Every issue must also satisfy two documentation requirements before it can be picked up:

- **Detailed context** — the Background, Objective, and Why Now fields in the template must be filled with enough detail that a developer with no prior context on the feature can start work without asking clarifying questions.
- **Technology declaration** — every external package, API, or non-obvious pattern used must be listed in the Technologies & Approach table. An issue with an empty or vague technology section is not ready for implementation.

### Branch Naming Convention

```
<type>/issue-<number>-<kebab-slug>
```

| Type | When to use |
|---|---|
| `feat` | New behaviour or capability |
| `fix` | Bug fix |
| `test` | Test-only changes (no production code) |
| `refactor` | Restructure without behaviour change |
| `chore` | Dependencies, config, tooling, code generation |
| `docs` | Documentation only |
| `perf` | Performance improvement |

**Examples:**
```
feat/issue-12-hebrew-label-parser
fix/issue-34-grace-period-timezone-reset
test/issue-45-meal-repository-contract-suite
chore/issue-7-add-riverpod-deps
refactor/issue-61-extract-electrolyte-advisor
```

Rules:
- Slug is lowercase kebab-case, max 5 words
- Issue number is always present — no numberless branches
- Branch is created from the latest `main` — never from another feature branch
- One branch per issue, one PR per branch, no exceptions

### Conventional Commit Standard

```
<type>(#<issue-number>): <imperative description in lowercase>

<optional body: what changed and why — omit if obvious from title>

Closes #<issue-number>
```

**Examples:**
```
feat(#12): implement HebrewLabelParser with net carb extraction

Normalises OCR whitespace and handles common ג vs גר mis-reads before
extracting fat, net carbs, and protein per 100g and per serving.

Closes #12
```
```
fix(#34): compare grace period end timestamp in local time

Grace period expiry was evaluated in UTC, causing streaks to persist
1–3 hours past expiry on devices in GMT+2 (Israel Standard Time).

Closes #34
```

Rules:
- Description is imperative mood, lowercase, no trailing period
- Issue number always present in the type scope
- `Closes #<n>` always present in the commit body — this auto-closes the issue on merge
- No `git commit --amend` on pushed commits; open a new commit instead

### Issue Labeling Taxonomy

Every issue must carry exactly **one Type label**, exactly **one Layer label**, and exactly **one Epic label**.

#### Type Labels

| Label | When to use |
|---|---|
| `type:feat` | New production behaviour |
| `type:fix` | Bug fix in existing behaviour |
| `type:test` | Test code only; no production changes |
| `type:refactor` | Internal restructure; no behaviour change |
| `type:chore` | Deps, config, tooling, code generation setup |
| `type:docs` | Documentation files only |
| `type:perf` | Measurable performance improvement |

#### Layer Labels

| Label | When to use |
|---|---|
| `layer:core` | `lib/core/` — constants, theme, utilities |
| `layer:domain` | `domain/` — pure Dart models and repository interfaces |
| `layer:data` | `data/` — sembast stores, record codecs, repository implementations |
| `layer:application` | `application/` — services, use-cases, Riverpod providers |
| `layer:presentation` | `presentation/` — widgets, screens, UI providers |
| `layer:infra` | `main.dart`, routing, platform config, CI |
| `layer:test` | `test/` or `integration_test/` — test infrastructure only |

#### Epic Labels

See `milestone_conventions.md` §2 for the full epic label list — `epic:m0-foundation`
through `epic:m8-ci-integration` for the MVP, `epic:release-v1` for the v1.0 launch,
and `epic:m9-biomarkers` through `epic:m14-backup` for the post-MVP milestones.
**`epic:post-mvp` is retired** (`design/v1_1_split.md`).

---

## 2. Implementation Description Guidelines

This is the most important section of any issue. An issue whose Implementation Plan cannot be handed to a developer cold — with no prior context — and result in correct, reviewable code is not ready to be opened.

### Required Level of Detail

The Implementation Plan must answer all five questions for every step:

| Question | What it means in practice |
|---|---|
| **What file?** | Exact path: `lib/features/keto_lens/data/hebrew_label_parser.dart` |
| **What class / function?** | Full public signature with types: `class HebrewLabelParser implements LabelParser` |
| **What does it do?** | The algorithm, rule, or behaviour in plain language — not "parses the label" but the exact steps the code must execute |
| **What are the contracts?** | Preconditions, postconditions, invariants — what the caller can rely on |
| **How does it connect?** | Which existing class consumes it, which provider wires it, which interface it implements |

If any of the five is missing from a step, the step is incomplete.

### API Contract Requirement

Every issue that introduces a new class, method, or provider must include an **API Contract** block showing the complete public interface as a Dart code snippet. This is not optional.

The snippet must show:
- Class name and any implemented interfaces
- All public method signatures with parameter types and return types
- Doc comment on any non-obvious method
- Annotations (`@riverpod`, `@collection`, `@immutable`, etc.)

```dart
// Example — domain model
@immutable
class ParsedLabel {
  final String? productName;
  final double fatG;
  final double netCarbsG;      // already subtracted fiber
  final double proteinG;
  final double fatGPer100;
  final double netCarbsPer100;
  final double proteinPer100;
  final List<String> ingredients;

  const ParsedLabel({...});
  ParsedLabel copyWith({...});
}

// Example — service
class HebrewLabelParser implements LabelParser {
  @override
  bool canParse(String rawText);     // returns true if Hebrew characters detected

  @override
  ParsedLabel parse(String rawText); // throws ParseException if label is unreadable
}
```

### Business Logic Requirement

For any issue that implements rules, calculations, or a state machine, the Implementation Plan must document the exact logic inline — not as a reference to another document, but written out in the issue body so the developer does not need to cross-reference five files.

**Acceptable:**
```
KetoRatioCalculator.calculate():
  - Formula: fat / (netCarbs + protein)
  - Returns 0.0 when denominator is 0 (avoid divide-by-zero)
  - Throws ArgumentError when any input is negative
  - Result rounded to 2 decimal places
```

**Not acceptable:**
```
Implement the keto ratio calculator per the business logic doc.
```

### Integration Points Requirement

Every step that touches an existing file — modifying a provider, registering a schema, wiring a service — must name the exact existing symbol being changed and describe the change:

**Acceptable:**
```
Modify `lib/features/keto_lens/data/providers.dart`:
  - Add `labelParserProvider` returning `HebrewLabelParser` as `LabelParser`
  - Add `ingredientClassifierProvider` returning `IngredientClassifierImpl` as `IngredientClassifier`
  - Both injected into `scanOrchestratorProvider` via constructor
```

**Not acceptable:**
```
Wire the providers.
```

### Step Structure Template

Each step in the Implementation Plan must follow this structure:

```
<N>. <Action verb> `<exact/file/path.dart>`

   **Class / Function:** `<ClassName>` implements `<InterfaceName>`

   **API Contract:**
   ```dart
   <public interface snippet>
   ```

   **Logic / Behaviour:**
   - <Rule or algorithm step 1>
   - <Rule or algorithm step 2>
   - <Edge case handling>

   **Integration:**
   - Consumed by: `<ClassName>` in `<path>`
   - Wired via: `<providerName>` in `<path/providers.dart>`
   - Implements: `<InterfaceName>` from `<path/interface.dart>`
```

---

## 3. Architectural Layer & Code Guardrails

### Layer Boundary Rules

The dependency arrow flows in one direction only:

```
Presentation  →  Application  →  Domain  ←  Data
```

- **Presentation** may import Application providers and Domain models. Never imports Data or the persistence package directly.
- **Application** may import Domain interfaces and models. Never imports Flutter widgets, the persistence package, or Data classes.
- **Domain** imports nothing from the project. Pure Dart only. No Flutter SDK, no persistence package, no Application.
- **Data** imports Domain (implements its interfaces). Never imported by Application or Presentation.

Any PR that introduces a violation of these arrows is rejected, regardless of test coverage.

### Domain Layer Purity

Every class in `domain/` must satisfy all of the following:

- **Pure Dart** — zero imports from `flutter`, `sembast`, `riverpod`, or any data/application layer file
- **Immutable** — all fields are `final`; mutation is expressed via `copyWith`
- **No side effects** — domain models hold data and define interfaces; they do not perform I/O, logging, or network calls
- **Repository interfaces are abstract** — defined with `abstract interface class`; no implementation logic lives in `domain/`
- **Enums over stringly-typed flags** — `AdaptationPhase.induction`, not `'induction'`

```dart
// Correct — pure domain model
@immutable
class MealEntry {
  final Id? id;
  final DateTime timestamp;
  final double fatG;
  final double netCarbsG;
  final double proteinG;
  const MealEntry({...});
  MealEntry copyWith({...}) => ...;
}

// Correct — abstract repository interface
abstract interface class MealRepository {
  Future<MealEntry> save(MealEntry entry);
  Future<MealEntry?> findById(Id id);
  Future<List<MealEntry>> findByDate(DateTime date);
  Future<void> delete(Id id);
}
```

### Data Layer Rules

- sembast `StoreRef`s live exclusively in `data/`, declared beside the repository that owns them
- Every persisted model has a codec in `data/mappers/` (`XxxMapper.toRecord` / `fromRecord`)
- Codecs are the only place where domain ↔ record conversion happens — never in services or widgets
- Schema classes are never passed across layer boundaries — always map to domain model first
- Queries use sembast's `Finder`/`Filter` API; record values stay JSON-compatible (see `CLAUDE.md` §Local Persistence)

### Application Layer Rules

- One service class per use-case group (`MealLoggingService`, `AdaptationPhaseService`, not a god `AppService`)
- Services declare dependencies via constructor injection (domain interfaces, never a `Database`)
- All providers use `@riverpod` code generation — no manual `Provider(...)`, `StateNotifierProvider(...)`, etc.
- Provider wiring lives in `<feature>/application/providers.dart` or `<feature>/data/providers.dart` — nowhere else
- No `get_it`, `injectable`, or any service locator — Riverpod handles all injection

### Code Generation Guidelines

Two generators are in use. `build_runner` runs both after any annotated file
changes:

```bash
timeout 120 dart run build_runner build --verbose
git status --short   # the real check — build_runner never exits, so exit 124
                     # from timeout is expected, not a failure
```

| Annotation | Generator | Output |
|---|---|---|
| `@riverpod` (provider) | `riverpod_generator` | `*.g.dart` provider definitions |

`json_serializable` is **not** a dependency. Earlier drafts of this document
and of `CLAUDE.md` listed `@JsonSerializable` as a third generator; nothing in
the project uses it, and the MVP has no remote DTOs to deserialise. Add it only
alongside a feature that actually needs it.

Persistence needs no generator at all. Note also that the original `isar` / `isar_generator` were replaced in
M0 by the community fork, because they pin `analyzer <6.0.0` and cannot
co-resolve with `riverpod_generator` (see `design/m0_handoff.md` §1).

- Never manually edit `.g.dart` files
- Always commit `.g.dart` files alongside the annotated source file in the same PR
- Commit the regenerated output — CI checks out generated files rather than
  building them, so an uncommitted `.g.dart` fails the run on code that does
  not compile

---

## 4. Formal Atomic Issue Template

Use this template verbatim when opening any implementation issue. Copy the raw Markdown.

---

```markdown
## <Imperative Title — e.g., "Implement HebrewLabelParser with net carb extraction">

**Branch:** `<type>/issue-<number>-<slug>`
**Labels:** `type:<x>` · `layer:<x>` · `epic:m<N>-<slug>`
**Milestone:** M<N> — <Milestone Title>

---

### Context & Objective

#### Background
<Detailed explanation of the problem or capability. Include: why this exists, what user need or system requirement it addresses, how it fits into the broader feature, and any non-obvious constraints or decisions that shaped the scope. Minimum 1 short paragraph — do not leave this as a one-liner.>

#### Objective
<Precise statement of what will be true when this issue is done. Written as an observable outcome, not as a task list. E.g. "The HebrewLabelParser correctly extracts fat, net carbs, and protein from any Israeli nutritional label captured by the Keto Lens camera, handling the 5 known OCR mis-read patterns documented in design/technology.md.">

#### Why Now
<One sentence: why this issue belongs at this point in the build order. Name the milestone and the specific upstream issues it unblocks.>

---

### Technologies & Approach

> Specify every external package, Flutter/Dart API, or pattern used in this issue. Reference `design/technology.md` for rationale where applicable. This section must be filled — "standard Flutter" is not an acceptable answer.

| Concern | Technology / Package | Version | Notes |
|---|---|---|---|
| <e.g., OCR recognition> | <e.g., `google_mlkit_text_recognition`> | <e.g., ^0.13.0> | <e.g., on-device, no network call, Hebrew script supported> |
| <e.g., State management> | <e.g., `flutter_riverpod` + `@riverpod`> | <e.g., ^2.5.0> | <e.g., code-generated provider, AsyncNotifier pattern> |
| <e.g., Local persistence> | <e.g., `sembast` + `sembast_web`> | <e.g., ^3.8.10> | <e.g., pure-Dart document store, one implementation for iOS and web> |

**Approach summary:**
<1–3 sentences describing the chosen implementation strategy and why alternatives were not selected. E.g. "Using rule-based ingredient matching rather than ML classification because the rule set is deterministic, auditable, and works fully offline. A future issue will add Claude API as an optional fallback for ambiguous ingredients.">

---

### Architectural Layer

Select exactly one:

- [ ] `layer:core` — `lib/core/`
- [ ] `layer:domain` — pure Dart models / repository interfaces
- [ ] `layer:data` — sembast stores, record codecs, repository implementations
- [ ] `layer:application` — services, use-cases, Riverpod providers
- [ ] `layer:presentation` — widgets, screens, UI providers
- [ ] `layer:infra` — routing, platform config, CI
- [ ] `layer:test` — test infrastructure only

---

### Upstream Dependencies

> This issue cannot be started until the following are merged:

- Blocked by #<issue-number> — <title>
- Blocked by #<issue-number> — <title>
- _(none)_ if this issue has no blockers

---

### Implementation Plan

> Every step must follow the full structure defined in §2. File path, API contract, logic/behaviour, and integration point are all required for every step. A step that says only "implement X" is incomplete and the issue will be sent back.

---

**Step 1.** Create `lib/features/<feature>/<layer>/<ClassName>.dart`

   **Class / Function:** `<ClassName>` implements `<InterfaceName>`

   **API Contract:**
   ```dart
   // Paste the complete public interface — all method signatures with types and annotations
   class <ClassName> implements <InterfaceName> {
     const <ClassName>({required <Dependency> dep});

     @override
     <ReturnType> <methodName>(<ParamType> param);
   }
   ```

   **Logic / Behaviour:**
   - <Exact rule or algorithm step — specific enough to code from without guessing>
   - <Edge case: what happens when input is empty / null / zero / out of range>
   - <What exception or Result type is returned on failure and under what condition>

   **Integration:**
   - Implements: `<InterfaceName>` from `lib/features/<feature>/domain/<interface>.dart`
   - Consumed by: `<ServiceClass>` in `lib/features/<feature>/application/<service>.dart`
   - Wired via: `<providerName>` in `lib/features/<feature>/data/providers.dart`

---

**Step 2.** Create `test/features/<feature>/<layer>/<class_name>_test.dart`

   **What to test:** <list the exact test case names — these become the `test('...')` descriptions>
   - `'<method>: <happy path description>'`
   - `'<method>: <edge case description>'`
   - `'<method>: <failure path description>'`

   **Test doubles needed:** `<Mock/Fake class names from mocktail, or "none — pure logic">`

---

**Step 3.** _(if applicable)_ Modify `lib/features/<feature>/<layer>/providers.dart`

   **Change:** Add `<providerName>` that returns `<ConcreteClass>` as `<DomainInterface>`
   ```dart
   @riverpod
   <DomainInterface> <providerName>(Ref ref) {
     final dep = ref.watch(<dependencyProvider>);
     return <ConcreteClass>(dep);
   }
   ```

---

**Step 4.** _(if applicable)_ Run code generation and re-validate
   ```bash
   timeout 120 dart run build_runner build --verbose
   flutter analyze
   flutter test
   ```

---

**Step 5.** Run full validation gate (see §5)

---

### Testing Requirements

#### Happy Path
- [ ] <Describe the primary correct-behaviour test case>
- [ ] <Describe a second happy-path case if applicable>

#### Edge Cases
- [ ] <Boundary value, empty collection, zero, or null scenario>
- [ ] <Second edge case>

#### Error / Failure Handling
- [ ] <What happens when the repository throws?>
- [ ] <What happens with invalid input?>

#### Contract Tests (data layer issues only)
- [ ] Runs `runXxxRepositoryContractTests(factory)` against this implementation
- [ ] All contract cases pass against the in-memory database from `test/helpers/test_database.dart`

#### Regression (fix issues only)
- [ ] A test that would have caught the original bug is added and named to describe the failure mode

---

### Coverage Target

- **Domain / Application layer issues:** 100% public method coverage required
- **Data layer issues:** contract test suite counts as coverage; additional unit tests for mapper edge cases
- **Presentation layer issues:** critical user interactions covered; provider override pattern used

---

### Definition of Done

Every item below must be checked before requesting review:

**Code**
- [ ] Implementation matches the plan above — no scope creep
- [ ] No sembast types in `domain/` or `presentation/`
- [ ] No Flutter imports in `domain/` or `application/`
- [ ] No `get_it` or service locator usage
- [ ] No magic numbers — constants in `lib/core/constants/`
- [ ] No TODO comments
- [ ] No commented-out code
- [ ] All new providers use `@riverpod` code generation

**Validation Gate** (CI is the authority — see `design/pr_conventions.md` §4)
- [ ] Generated `.g.dart` files regenerated and committed, if any `@collection`
      or `@riverpod` annotation changed. CI checks them out, it does not build
      them — judge `build_runner` by `git status`, not its exit code
- [ ] `pubspec.lock` committed, if `pubspec.yaml` changed — CI fails on a stale one
- [ ] **CI run watched to completion on the PR** (`gh pr checks <n> --watch`)
- [ ] **CI green** — every failure fixed on this same branch, in this same PR.
      A red run is part of this issue, never a follow-up
- [ ] Coverage target met for this layer (review expectation; not yet a CI step)

**Git & PR**
- [ ] Branch named `<type>/issue-<number>-<slug>` created from latest `main`
- [ ] Only issue-relevant files staged (`git diff --staged` reviewed)
- [ ] Commit message follows Conventional Commits: `<type>(#<n>): <description>`
- [ ] `Closes #<n>` present in commit body
- [ ] PR targets `main`; title matches commit title
- [ ] PR body contains Summary, Changes, Test Coverage, and Validation sections
- [ ] No direct commit to `main`; no `--no-verify` used
```

---

## 5. Pre-Commit Verification & Workflow Quality Gates

### Required Local Validation Sequence

Run the following commands **in order** before staging any file. All must pass. If any fails, fix it before proceeding — do not stage, do not commit.

```bash
# Step 1 — Static analysis
flutter analyze
# Expected: "No issues found!"
# On failure: fix all reported issues before continuing

# Step 2 — Format check (write-safe; use --output=none to avoid auto-changes slipping into staging)
dart format --output=none --set-exit-if-changed lib/ test/
# Expected: exit code 0, no output
# On failure: run `dart format lib/ test/` to fix, then re-check

# Step 3 — Full test suite
flutter test
# Expected: all tests pass, zero failures
# On failure: fix failing tests before continuing

# Step 4 — Coverage check
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
# Open coverage/html/index.html and verify:
# - domain/ + application/ layers ≥ 80% line coverage
# On failure: add missing tests

# Step 5 — Code generation sync (only if @riverpod or @collection was added/changed)
timeout 120 dart run build_runner build --verbose
# Then re-run steps 1 and 3:
flutter analyze
flutter test
# Both must still pass after generation
```

Do not use `dart format lib/ test/` as your validation step — it silently fixes and exits 0 regardless, hiding the diff. Always use `--output=none --set-exit-if-changed` for the gate. This is §5 — referenced as "full validation gate" in issue Implementation Plans.

### Staging Rules

```bash
# Stage specific files only — never use git add . or git add -A
git add lib/features/<feature>/<layer>/<file>.dart
git add test/features/<feature>/<layer>/<file>_test.dart
# ... one explicit path per file

# Always review exactly what is staged before committing
git diff --staged
# Confirm: no debug artifacts, no .g.dart conflicts, no unrelated changes
```

### Non-Negotiable PR Rules

These rules have no exceptions, regardless of urgency, deadline, or issue severity:

1. **Never commit directly to `main`.** Every change goes through a dedicated branch and PR.
2. **Never use `--no-verify`** to bypass pre-commit hooks. If a hook fails, fix the root cause.
3. **Never skip the validation gate** (§4 above). A PR opened before local tests pass will be closed.
4. **One issue per branch, one branch per PR.** Bundling unrelated changes into one PR is prohibited.
5. **Never merge your own PR** without at least one review approval.
6. **Never use `git add .` or `git add -A`.** Stage files explicitly; review `git diff --staged` before every commit.
7. **Never rebase or force-push a branch that has an open PR** — close the PR, fix on a new branch, reopen.
8. **Never leave `.g.dart` files out of sync** with their annotated source. If a `.g.dart` is stale, `build_runner` must be re-run and the generated file committed in the same PR.
9. **Never reference a post-MVP issue as a blocking dependency** of an MVP milestone issue.
10. **Never open a PR from a branch not created from the latest `main`.** Run `git pull origin main` immediately before branching.
