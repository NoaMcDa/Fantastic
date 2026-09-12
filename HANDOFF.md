# Handoff — 2026-09-10

> Scratch file, untracked. Delete once the next session picks it up.

## Where things stand

All GitHub planning work is **done**. The repo has no application code yet beyond
the Flutter scaffold (`lib/main.dart`, `pubspec.yaml`, `ios/`) that landed in PR #3.

### Completed

- **10 milestones** created (M0–M8 + `v1.1 — Post-MVP Backlog`)
- **10 Epic tracking issues** (#4–#13), one per milestone
- **115 atomic issues** created (#14–#128), each with a full 8-section body per
  `design/issue_conventions.md`, correct milestone, exactly 3 labels
  (`type:*` + `layer:*` + `epic:*`), and added to project board #2
- **24 labels** created: 7 `type:*`, 7 `layer:*`, 10 `epic:*`
- `CLAUDE.md` updated with a **GitHub Project Board** section documenting issue
  ranges per milestone, epic issue numbers, label taxonomy, and CI workflow

Issue ranges: M0 #14–24 · M1 #25–43 · M2 #44–56 · M3 #57–68 · M4 #69–74 ·
M5 #75–78 · M6 #79–87 · M7 #88–94 · M8 #95–102 · post-MVP #103–128

## In flight — pick up here

Branch `chore/update-claude-md-project-board` is committed (`b4abff7`) and pushed
to origin. **The PR was never opened** — that is the next action.

```bash
gh pr create --base main \
  --title "chore: update CLAUDE.md with GitHub project board setup" \
  --body "..."   # Summary / Changes / Validation sections
gh pr merge --squash   # or --merge, repo has used merge commits so far
```

The commit contains a single file change: `CLAUDE.md` (+59 lines, new
"GitHub Project Board" section appended after "UI & Localisation").

## After that

Start M0 implementation. First issue is **#14 — Add all MVP dependencies to
pubspec.yaml**. Follow `design/developing_rules.md` exactly:
branch → read issue → implement → test → full validation gate → commit → PR.

M0 issues in dependency order: #14 (deps) → #15 (build_runner) → #16
(analysis_options) → #20 (constants) → #21 (Isar + isarProvider) → #17
(go_router) → #18 (RTL app root) → #19 (tab bar shell) → #22 (feature dirs) →
#23 (fixtures) → #24 (test_isar helper).

## Gotchas hit this session

- `gh project item-add` intermittently times out on the GraphQL endpoint. Never
  chain it with `gh issue create` using `&&` — a timeout silently skips the
  issue creation. Run them as separate commands.
- Creating issues in parallel/background caused shell parse errors previously.
  Create them strictly sequentially.
- Untracked cruft in the working tree: `.DS_Store`, `design/.DS_Store`, `.idea/`.
  Worth adding to `.gitignore` at some point.
