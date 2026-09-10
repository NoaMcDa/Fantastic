# Developer Workflow — Standard Operating Procedure

Every issue, without exception, follows this workflow from first command to merged PR. No steps are skipped. No shortcuts.

---

## Step 1 — Triage & Branch

Before writing a single line of code, sync with the base branch and create a dedicated branch.

```bash
# Sync base branch
git checkout main
git pull origin main

# Create and check out a dedicated branch
# feat/  → new functionality
# fix/   → bug fix
# chore/ → tooling, deps, config
# refactor/ → code restructure with no behaviour change
# test/  → test-only changes
# docs/  → documentation only

git checkout -b feat/issue-<number>-<short-description>
# Examples:
#   feat/issue-12-keto-lens-scanner
#   fix/issue-34-streak-grace-period-reset
#   chore/issue-7-add-riverpod-deps
```

**Checklist:**
- [ ] On `main` and fully synced before branching
- [ ] Branch name follows `<type>/issue-<number>-<kebab-description>` convention
- [ ] Branch is checked out locally

---

## Step 2 — Understand the Issue Scope

Read the issue in full before touching code.

```bash
# Read the issue
gh issue view <number>

# Check if there are linked issues or PRs
gh issue view <number> --comments
```

Define in your head (or in a comment on the issue):
- What is the **exact behaviour change** required?
- What are the **edge cases** that must be handled?
- What **existing code** is affected?
- What **tests** need to be added or updated?

Only start implementation once all four are answered.

**Checklist:**
- [ ] Issue read in full including comments
- [ ] Scope is understood — no assumptions left unresolved
- [ ] Affected files identified before editing

---

## Step 3 — Implementation

Write code following the architecture defined in `design/architecture.md` and the SOLID abstractions in `design/base_design.md`.

### Rules
- Changes live in the correct layer: domain logic in `domain/`, persistence in `data/`, orchestration in `application/`, UI in `presentation/`
- No Isar types leak into `domain/` or `presentation/`
- No widget imports in `application/` or `domain/`
- No new provider calls raw `Isar` — always go through a repository interface
- No commented-out code committed
- No `TODO` comments committed — open a follow-up issue instead
- No magic numbers — use named constants in `lib/core/constants/`

### During implementation, verify continuously:

```bash
# Check for analysis errors as you work (run often)
flutter analyze

# Format code after every file edit
dart format lib/ test/
```

**Checklist:**
- [ ] Code lives in the correct architectural layer
- [ ] No cross-layer violations (Isar not in domain, Flutter not in application)
- [ ] No magic numbers, no TODOs, no dead code
- [ ] `flutter analyze` returns zero issues on changed files

---

## Step 4 — Test Development

Write tests **before or alongside** implementation — never after. Tests are not optional.

### File naming convention
```
test/features/<feature_name>/<layer>/<class_name>_test.dart
```

### Coverage requirements per layer

| Layer | Required coverage | Test type |
|---|---|---|
| `domain/` | 100% of public methods | Unit — no mocks |
| `application/` | 100% of public methods | Unit — mock domain interfaces with `mocktail` |
| `data/` | Repository contract suite | Integration — real in-memory Isar |
| `presentation/` | Critical widgets and flows | Widget — provider overrides |

### Minimum test cases for every change
1. **Happy path** — the expected, correct outcome
2. **Edge cases** — boundary values, empty collections, zero, null where applicable
3. **Failure path** — invalid input, repository throws, network unavailable
4. **Regression** — if fixing a bug, a test that would have caught the original bug

```bash
# Run only the tests for the feature you're working on (fast feedback loop)
flutter test test/features/<feature_name>/

# Run the full suite before moving on
flutter test
```

**Checklist:**
- [ ] Happy path tested
- [ ] Edge cases tested
- [ ] Failure / error path tested
- [ ] If a bug fix: regression test added that would have caught the original bug
- [ ] All new tests pass
- [ ] No existing tests broken

---

## Step 5 — Validation & Pre-Commit Verification

Nothing is staged until the full validation suite passes locally. Zero tolerance for committing broken code.

```bash
# 1. Static analysis — must return zero issues
flutter analyze

# 2. Format check — must return no diffs
dart format --output=none --set-exit-if-changed lib/ test/

# 3. Full test suite — must return zero failures
flutter test

# 4. Test coverage report — confirm domain + application layers ≥ 80%
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
# Open coverage/html/index.html and verify

# 5. Code generation — if any @collection or @riverpod annotation was changed
timeout 120 dart run build_runner build --verbose
git status --short   # this is the check, NOT the exit code — see below
flutter analyze  # re-run after generation
flutter test     # re-run after generation
```

> **`build_runner` finishes in about a second but never exits.** Exit code 124
> from `timeout` is the expected outcome, not a failure — judge the run by
> whether the `.g.dart` files are correct, not by its exit status. `--verbose`
> is required: without it a redirected run produces an empty log. Never pipe it
> into `tail` or `head`, which cannot print until a pipe closes that never
> does. If it produces nothing at all, check for an orphaned run holding the
> build lock: `ps -eo pid,etime,cmd | grep build_runner`.

**All five must pass before proceeding. If any fails, fix it — do not skip.**

**Checklist:**
- [ ] `flutter analyze` — zero issues
- [ ] `dart format` — zero diffs
- [ ] `flutter test` — zero failures
- [ ] Coverage gate met (≥ 80% on domain + application)
- [ ] `build_runner` re-run if any generated file was touched, and re-validated

---

## Step 6 — Commit

Stage only the files relevant to this issue. Never use `git add .` or `git add -A`.

```bash
# Stage specific files
git add lib/features/<feature>/<layer>/<file>.dart
git add test/features/<feature>/<layer>/<file>_test.dart
# ... list every file explicitly

# Verify exactly what is staged
git diff --staged

# Commit with a Conventional Commit message referencing the issue
git commit -m "<type>(#<issue-number>): <concise imperative description>

<optional body — what changed and why, if not obvious from the title>

Closes #<issue-number>"
```

### Conventional Commit types

| Type | When to use |
|---|---|
| `feat` | New feature or behaviour |
| `fix` | Bug fix |
| `test` | Adding or fixing tests only |
| `refactor` | Code restructure, no behaviour change |
| `chore` | Deps, config, tooling, code generation |
| `docs` | Documentation only |
| `perf` | Performance improvement |

### Commit message examples
```
feat(#12): add Hebrew OCR label scanner with ingredient classification

Implements the Keto Lens camera screen, MLKit text recogniser adapter,
HebrewLabelParser, and IngredientClassifier. Badges are rendered on the
result sheet and macros are pre-filled on diary add.

Closes #12
```
```
fix(#34): reset streak correctly after grace period expiry

Grace period end timestamp was compared in UTC but stored in local time,
causing streaks to persist 1-3 hours past expiry on devices in GMT+2.

Closes #34
```

**Checklist:**
- [ ] Only issue-relevant files staged
- [ ] `git diff --staged` reviewed — no unintended changes, no debug artifacts
- [ ] Commit message follows Conventional Commits format
- [ ] Issue number referenced in commit message
- [ ] `Closes #<number>` in commit body

---

## Step 7 — Push & Pull Request

```bash
# Push branch to remote
git push -u origin <branch-name>

# Open PR using gh CLI
gh pr create \
  --base main \
  --title "<type>(#<issue-number>): <same as commit title>" \
  --body "$(cat <<'EOF'
## Summary
- <bullet: what changed>
- <bullet: why it changed>
- <bullet: any architectural decisions worth noting>

## Changes
- `lib/features/...` — <what and why>
- `test/features/...` — <what is covered>

## Test Coverage
- [ ] Happy path: <describe>
- [ ] Edge cases: <describe>
- [ ] Failure path: <describe>
- [ ] Regression: <describe if bug fix>

## Validation
- [x] `flutter analyze` — zero issues
- [x] `dart format` — no diffs
- [x] `flutter test` — all passing
- [x] Coverage ≥ 80% on domain + application layers

Closes #<issue-number>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"

# Confirm PR was created and note the URL
gh pr view --web
```

**Checklist:**
- [ ] Branch pushed to remote
- [ ] PR title matches commit title convention
- [ ] PR body has Summary, Changes, Test Coverage, and Validation sections filled
- [ ] `Closes #<issue-number>` present in PR body
- [ ] PR targets `main` (not another feature branch)
- [ ] PR URL confirmed

---

## Quick Reference — Full Command Sequence

```bash
# 1. Branch
git checkout main && git pull origin main
git checkout -b feat/issue-<n>-<desc>

# 2. Read the issue
gh issue view <n>

# 3. Implement (iterate with fast feedback)
flutter analyze
dart format lib/ test/

# 4. Write tests
flutter test test/features/<feature>/

# 5. Validate everything
flutter analyze
dart format --output=none --set-exit-if-changed lib/ test/
flutter test
flutter test --coverage
# if generated files changed:
timeout 120 dart run build_runner build --verbose && flutter test

# 6. Commit
git add <specific files>
git diff --staged
git commit -m "feat(#<n>): <description>

Closes #<n>"

# 7. PR
git push -u origin feat/issue-<n>-<desc>
gh pr create --base main --title "..." --body "..."
```

---

## Non-Negotiables

These rules are never relaxed, regardless of urgency or scope:

1. **Never commit directly to `main`.** Every change goes through a branch and PR.
2. **Never skip tests.** A feature without tests is not done.
3. **Never commit with `flutter analyze` failures.** Fix them first.
4. **Never use `git add .`** — always stage files explicitly.
5. **Never merge your own PR without review** — request at least one reviewer.
6. **Never use `--no-verify`** to bypass hooks.
7. **One issue per branch, one branch per PR.** No bundling unrelated changes.
