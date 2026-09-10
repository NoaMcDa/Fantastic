# PR Conventions — Fantastic

## 1. What a Pull Request Is

A PR is the unit of review and the unit of merge. It corresponds 1:1 to one
atomic issue (see `design/issue_conventions.md` §1 for the atomicity
definition) — or, for the narrow exceptions in §7, to one self-contained
documentation or process change.

A PR must, at every point in its life:

1. **Build on the latest `main`** — branched from `main`, not from another
   feature branch, unless it is an explicitly declared stacked PR (§7).
2. **Leave `main` green if merged as-is** — `flutter analyze`, `dart format
   --check`, and `flutter test` all pass on the merge result.
3. **Do one thing** — bundling unrelated changes is a scope violation, not
   a convenience. If a PR's diff touches two concerns, split it.
4. **Be reviewable in isolation** — a reviewer with no other context can
   understand *what* changed and *why* from the title, description, and
   diff alone.

A draft PR (marked draft in GitHub) is the only form of "work in progress"
this repo allows to exist as a PR. It signals "not ready for review" —
CI may be red, the checklist may be incomplete. Marking a PR ready for
review is a commitment that every gate in §4 passes.

---

## 2. Branch & Base Rules

Branch naming follows `design/issue_conventions.md` §1 exactly:
`<type>/issue-<number>-<kebab-slug>`. This document does not repeat that
table — see it there.

**Base branch is `main`** for every PR, with one exception:

### Stacked PRs

A PR may target another open feature branch instead of `main` only when
its content is genuinely dependent on that branch's unmerged work (e.g. a
docs PR describing a feature branch that hasn't landed yet). When this
happens:

- The PR description's **Base branch** section (see §5 template) states
  the dependency explicitly and names the branch it depends on.
- The PR is retargeted to `main` (via `gh pr edit --base main`, or closed
  and reopened against `main`) as soon as the parent branch merges — a
  stacked PR must never be merged while still pointed at a branch other
  than `main`. If the parent branch merges before the stacked PR does,
  retarget it in the same session that notices — an unretargeted stacked
  PR against an already-merged branch will not land in `main` when merged.
- Stacked PRs are rare by design. Prefer waiting for the parent PR to
  merge and branching from `main` afterward; reach for a stacked PR only
  when the dependent work cannot usefully wait.

---

## 3. Title Convention

The PR title is the same string as the primary commit's Conventional
Commit title (`design/issue_conventions.md` §1):

```
<type>(#<issue-number>): <imperative description in lowercase>
```

For the narrow no-issue exception in §7, drop the issue-number scope:
`docs: <imperative description in lowercase>`.

The title becomes the squash-merge commit message (§6) — write it as a
standalone changelog entry, not as shorthand that only makes sense next
to the diff.

---

## 4. CI Is the Validation Gate

**Do not run the gate locally before opening a PR.** `.github/workflows/ci.yml`
runs it on every pull request against `main`, on a pinned Flutter 3.47.3:

| CI step | Must show |
|---|---|
| `pubspec.lock` freshness | `flutter pub get` does not rewrite the committed lockfile |
| `dart format --output=none --set-exit-if-changed lib/ test/` | Zero diffs |
| `flutter analyze --no-pub` | Zero issues |
| `flutter test --no-pub` | Zero failures |

Open the PR, then **watch the run to completion** (`gh pr checks <n> --watch`).
A PR whose CI has not finished is not ready for review, and a green local
terminal is not a substitute — only the run on the PR counts.

**Two things CI cannot do for you**, because it checks out what you committed
rather than regenerating it:

- **Generated files.** If any `@collection` or `@riverpod` annotation changed,
  run `timeout 120 dart run build_runner build --verbose` and commit the
  `.g.dart` output. Judge it by `git status`, not the exit code — build_runner
  never exits, so `timeout`'s 124 is expected.
- **`pubspec.lock`.** Run `flutter pub get` and commit the result whenever
  `pubspec.yaml` changes, or the lockfile step fails.

### A red run is fixed in the same PR

A CI failure belongs to the issue whose PR is red. Push the fix to the same
branch, wait for the new run, repeat until green. Never open a follow-up issue
for it, never merge around it, and never close the issue while its PR is red.

Coverage is not enforced per-PR by the workflow today. The ≥ 80% target on
`domain/` and `application/` (`design/tests.md`) still stands as a review
expectation; wire it into CI when a coverage step is added.

Documentation-only and design-canvas-only PRs (§7) are exempt from the
Flutter-specific rows (analyze, format, test, coverage, build_runner) —
nothing in `lib/` or `test/` changed for them to apply to.

---

## 5. PR Description Template

```markdown
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
```

Include a **Base branch** section, placed after Summary, only for a
stacked PR (§2):

```markdown
## Base branch

This PR targets `<branch>` (not `main`) because <one-sentence reason>.
Retarget to `main` once `<branch>` merges.
```

### No-issue documentation exception

A documentation-only PR not tied to a tracked issue (§7) uses a reduced
template — no `Test Coverage` section, no `Closes #<n>` line:

```markdown
## Summary
- <bullet: what changed>
- <bullet: why it changed>

## Changes
- `design/...` — <what and why>

## Validation
- [x] Reviewed for consistency with the docs it cross-references
```

---

## 6. Review & Merge Rules

- **At least one review approval** is required before merge. Never merge
  your own PR (`design/issue_conventions.md` §5, rule 5).
- **Resolve every review thread** before merging — an unresolved comment
  is an open question, not a closed one, regardless of whether the
  underlying code changed.
- **Merge strategy: squash and merge.** The PR title (§3) becomes the
  squash commit's message on `main`, keeping `main`'s history one
  Conventional Commit per issue regardless of how many commits the branch
  accumulated during review.
- **Update via merge, not rebase**, when `main` has moved since the branch
  was created — `design/issue_conventions.md` §5 rule 7 prohibits rebasing
  or force-pushing a branch with an open PR. Merge `main` into the branch
  instead.
- **CI must be green** before merging is allowed. `.github/workflows/ci.yml`
  runs `flutter pub get` (asserting `pubspec.lock` is unchanged), `dart format
  --set-exit-if-changed`, `flutter analyze` and `flutter test` on every PR
  targeting `main`. The local validation gate (§4) is now a fast pre-flight,
  not the only enforcement. See `design/cicd_plan.md`.

---

## 7. Special Cases

### Documentation-only PRs without a tracked issue

Process and reference documents under `design/` (this file included) are
sometimes written ahead of, or independent of, a numbered issue — there is
no feature behaviour to gate behind an issue number. For these only:

- Branch name may omit the issue number: `docs/<kebab-slug>`.
- PR title may omit the issue scope: `docs: <description>`.
- Use the reduced template in §5.
- Still: one branch, one PR, one concern. A docs PR that also touches
  `lib/` or `test/` is not a documentation-only PR — split it.

### Design-canvas-only PRs

Changes confined to `design/design-system/` (the `.dc.html` artboards and
`canvas.json`) follow the same documentation-only path: no Flutter
validation gate applies, but every design token or component claim in the
PR description should be checked against the boards it changes before
opening, the same way a code PR is checked against its tests.

### Dependent / stacked PRs

Covered in §2. Flagged here as a special case because it is the one
situation where "base branch is `main`" (§1, rule 1) does not hold, and it
carries a retargeting obligation the PR author must not forget.

---

## 8. Non-Negotiable Rules

`design/issue_conventions.md` §5 ("Non-Negotiable PR Rules") is the
canonical list — read it there. This section adds only the rules specific
to PR review and merge mechanics that list does not cover:

1. **Never merge with an unresolved review thread**, even one the author
   believes is settled — get an explicit resolve or re-approval first.
2. **Never leave a stacked PR merged against a non-`main` base.** Retarget
   before merging, not after.
3. **Never mark a PR ready for review with a red validation gate** (§4).
   Keep it draft until every command in the gate passes.
4. **Never invent a new merge strategy per PR.** Squash and merge (§6) is
   the only sanctioned strategy until this document says otherwise.
