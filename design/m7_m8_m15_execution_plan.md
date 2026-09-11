# M7 / M8 / M15 execution plan

**Status:** current. Written at the point where three milestones were open at once
and the question became *what order, and how many people (or agents) can work it*.

**Read with:** `design/developing_rules.md` (the per-issue SOP),
`design/pr_conventions.md` §6 (the merge gate), `design/m7_preflight.md`,
`design/backlog_handoff.md`, `design/m8_preflight.md`,
`design/m15_meal_entry_research.md`.

---

## 1. What is actually open

| Milestone | Open work issues | Epic |
|---|---|---|
| M7 — Polish | **16** — #88, #89, #91, #92, #151, #301–#311 | #11 |
| M8 — CI & Integration | **1** — #98 | #12 |
| M15 — Meal Entry | **14** — #315–#328 | #312 |

**31 issues.** They collapse to **7 waves, average width 4.1, peak 6** — which is
the whole answer to how many workers this can keep busy.

Two of M7's sixteen are not polish. **#303** (the streak breaks on the wrong
condition) and **#306** (a scanned panel earns a green tick without the verdict
reading a number) are rule changes filed from a user's own report, at 10 and 14
implementation steps, and they change behaviour other issues build on.

---

## 2. The recommendation

> **5 concurrent workers on ordinary issues, 1 serialized lane for #303 and #306,
> and 1 lane doing nothing but reviewing.**

| Workers | Verdict |
|---|---|
| 3 | Safe, no conflict management needed, ~2x wall clock. Under-uses waves 0–2 |
| **5** | **The efficient point.** Matches average DAG width, covers the peak-6 waves with one slot of spillover |
| 8+ | Negative returns — past the DAG's width, likely past the Actions concurrent-job ceiling, and piled onto one review gate |

### CI is not the bottleneck

Measured on the last ten code PRs (runs 34603340464, 34604391617, 34605081863):
`ci.yml` completes in **3m30s–4m**. A docs-only PR finishes in ~10 s, because the
`changes` job skips both real jobs (§5.6 of `design/cicd_plan.md`).
`concurrency: group: ci-${{ github.ref }}` is keyed per branch, so **parallel PRs
never cancel each other** — only successive pushes to the same branch do.

### What the bottlenecks actually are

1. **The review gate.** `design/pr_conventions.md` §6: *"At least one review
   approval is required before merge. Never merge your own PR."* Five workers
   finishing together is a serial queue on PRs of 300–900 lines plus tests plus
   doc updates, and every open branch drifts from `main` while it waits.
   **Run a dedicated review lane.** Without one, the approval requirement — not
   the workers — sets throughput. (`design/m6_platform_handoff.md` records six PRs
   already merged with no approval under an explicit merge-on-green instruction.
   That is the alternative, and its cost is that nobody has read those diffs.)
2. **Three contended files.** `streak_ring_widget.dart` (#88, #305, #308),
   `macro_summary_card.dart` (#88, #301, #305), `add_meal_bottom_sheet.dart`
   (#304, #322, #323, #324, #328). §4 serializes these; going wider than 6 means
   pulling a later issue forward into one of them.
3. **Actions concurrency.** Each code PR fans out to ~6 jobs (`changes`, `verify`,
   `e2e flows`, android, linux, windows). At 4+ concurrent PRs you are at or over
   the standard 20-concurrent-job ceiling and will queue. Jobs are short, so it
   self-drains — worth watching, not worth planning around. *Not verified against
   this account's plan tier.*

---

## 3. The corrections this plan is built on

Found by auditing the issues against the code, in the tradition every preflight in
this directory follows. Applied to the issues themselves; recorded here so the
reasoning survives.

1. **Epic #11's old "suggested order" step 3 was wrong.** It called #304, #305,
   #307, #308 *"independent single-widget fixes, parallelisable"*. **#305 and #308
   both edit `streak_ring_widget.dart`**, and #305 also edits
   `macro_summary_card.dart`, which #301 and #88 both edit. Corrected in place.
2. **#88 is the widest surface in M7**, editing six files —
   `phase_detail_screen.dart`, `streak_ring_widget.dart`, `macro_summary_card.dart`,
   `meal_list_section.dart`, `symptom_diary_section.dart`, `camera_screen.dart`.
   It collides with #301, #302, #305 and #308, so it owns a wave boundary and
   never runs beside one of its consumers.
3. **#98 was unimplementable as written** and has been rewritten. It named
   `IsarStreakRepository` (Isar is gone), a `*_flow_test.dart` filename the runner
   would treat as a second entry point, a **breach defined as a low keto ratio** —
   the rule #303 deletes — and a `DateTimeProvider` production seam that the
   persisted `gracePeriodEnd` makes unnecessary. It also had no concept of seeding
   `DailyLog` history, which after #303 is what the streak is derived from.
4. **Counts were stale.** M7 read "14 open" in three places and is 16; M15 read
   `#315–#326` / 12 issues and is `#315–#328` / 14. `CLAUDE.md`, Epic #11 and
   `design/m15_meal_entry_research.md` corrected.
5. **`lib/core/widgets/` does not exist.** Both #91 and #88 create it — that is why
   they are ordered, and it is a hard gate rather than a preference.

---

## 4. The hard gates

Everything not listed here is free to run in parallel.

| Gate | Why |
|---|---|
| **#91 → #88** | Both create `lib/core/widgets/` |
| **#88 → #301, #302, #305, #308** | #88 rewrites the loading branch in the files all four edit. #301/#302 must *use* the skeleton, not add a spinner |
| **#301 → #305** | Both edit `macro_summary_card.dart` |
| **#308 → #305** | Both edit `streak_ring_widget.dart` |
| **#303 → #308** | #303 replaces `evaluateToday` with `recomputeFor`; #308 reads grace state through it |
| **#303 → #98** | #303 replaces the compliance rule #98 has to breach, and re-bases the existing streak flows |
| **#309 → #310** | The Profile notification toggle cannot be honest without the permission query |
| **#304 → #306** | Both edit `scan_result_sheet.dart`. #306 itself says "whichever merges second rebases" — land the one-file fix first |
| **#304 → #322, #323, #324, #328** | All rebuild around `add_meal_bottom_sheet.dart` |
| **#315 → #325, #327, #328** | `MacroSource` must exist before anything displays or re-sources it |
| **#316, #317 → #318 → #319 → #320** | Epic #312's chain |
| **#317 → #321** · **#322 → #323, #324** · **#320 → #324** · **#327 → #328** | Epic #312 |
| **everything → #326** | e2e flows and doc closure |
| **#151 → #311 → #92** | One platform lane. All three rewrite native asset trees (`ios/`, `macos/`, `android/app/src/main/res/`) |

**#92 is blocked on artwork that does not exist.** It is a product item, not a
worker item. Do not queue it until someone has drawn an icon.

---

## 5. The order

Run it as a **ready-queue of depth 5** — a worker pulls the next unblocked issue
when its PR merges. The waves below show where the width comes from, not a
lockstep schedule.

### The serialized lane

```
#303  judge the streak by net carbs, re-derived from history
  └─ #306  judge the scanned product from what a portion costs
```

While this lane is open, **no other worker may touch**
`lib/features/adaptation/application/`, `lib/features/keto_lens/{domain,data}/`,
`scan_result_sheet.dart`, `verdict_badge_widget.dart`,
`streak_calendar_widget.dart` or `keto_constants.dart`.

> **One accepted overlap.** #315 sets `MealEntry.source` on every write path, which
> includes `meal_logging_service.dart` — the file #303 also rewrites. The regions
> are disjoint (`logMeal`'s construction vs `_evaluateStreak`), so let #315 land
> first and have the #303 branch merge `main` in. A single lane can absorb that;
> five parallel branches could not.

### The waves

| Wave | Issues | Width | Notes |
|---|---|---|---|
| ~~**W0**~~ | ~~#91, #304, #315, #316, #317~~ — **shipped, plus #303** | 5 | All unblockers. #91 creates `lib/core/widgets/`; #304 unblocks #306 *and* the M15 sheet work; #315/#316/#317 are M15's three independent foundations |
| **W1** | #88, #307, #309, #151, #322, #325 | 6 | **Peak.** #88 owns this wave — nothing else in it touches its six files |
| **W2** | #301, #302, #310, #318, #321, #327 | 6 | **Peak.** #318 adds `http`, so it is the only PR in the programme allowed to change `pubspec.lock` while open |
| **W3** | #308, #319, #328, #311 | 4 | #308 before #305 — shared `streak_ring_widget.dart` |
| **W4** | #305, #320, #323, **#98**, #89 | 5 | #89 last by design: the screens that should report their own failures now do. **M8 closes here** |
| **W5** | #324, #92\* | 2 | \*only if artwork exists. **M7 closes here** |
| **W6** | #326 | 1 | e2e flows and doc closure. **M15 closes here** |

**29 issues across 7 waves; the other two are the serialized lane.**

**The tail is the inefficiency, not the head.** W5 and W6 are 2 and 1 wide because
M15's `#320 → #324 → #326` chain is irreducibly serial. Plan to wind down to two
workers there, or spend the spare capacity on work this plan deliberately excludes:
the accessibility gap (`design/m7_preflight.md` §Deferred — three `Semantics` in
all of `lib/`, and no text-scaling handling on a dashboard already known to
overflow), #256, and Epic #10's unmeasured scan accuracy.

---

## 6. What every worker is told

Put this in the opening prompt. It is the set of things that have cost this project
the most time when they were left implicit.

- **Read first:** `CLAUDE.md`, `design/developing_rules.md`,
  `design/issue_conventions.md` §5, `design/pr_conventions.md`, and the milestone's
  own preflight.
- **One issue, one branch off latest `main`, one PR to `main`.** Never stack —
  `pr_conventions.md` §2 calls stacked PRs "rare by design".
- **CI is the validation gate, not a green local terminal.** Watch the run to
  completion; fix every failure on the same branch, in the same PR.
- **`hasError` before `hasValue`. No `AsyncValue.when`, no `is AsyncError` match.**
  riverpod 3 reports a provider that failed before producing a value as
  `AsyncLoading` *with an error attached*. This bug cost four milestones in four
  disguises, and M7 touches more loading branches than any milestone before it.
- **No animation that never ends on a tab screen** — `pumpAndSettle` never returns,
  and the router tests visit every tab. Aimed squarely at #88.
- **Update from `main` by merge, never rebase or force-push** an open PR
  (`issue_conventions.md` §5 rule 7).
- **Doc edits ship in the same PR as their code, and touch only the section the
  issue owns.** `CLAUDE.md` is the most contended file in the repository — two of
  the last ten merges to `main` were conflict resolutions on it.
- **`pubspec.lock` is a global lock.** Only #318 changes it. Any other worker whose
  `flutter pub get` rewrites the lockfile has a bug, not a dependency.
- **Regenerate with `timeout 120 dart run build_runner build --verbose` and check
  `git status`, not the exit code** — it finishes in ~1 s and never exits, so 124
  is success.

---

## 7. Checking it is working

At each wave boundary, on `main`:

```bash
git checkout main && git pull origin main
flutter analyze
flutter test
flutter test --coverage && tool/check_coverage.sh coverage/lcov.info 80
tool/check_coverage_files.sh coverage/lcov.info
flutter test -d flutter-tester integration_test/app_test.dart
```

Per-wave:

- **After W0** — `ls lib/core/widgets/` is non-empty, so #88 is unblocked.
- **After the serialized lane** — `grep -rn "evaluateToday" lib/` returns nothing,
  and the literal `50` appears only in `keto_constants.dart`.
- **After W1** — no `CircularProgressIndicator` left on a tab screen:
  `grep -rn "CircularProgressIndicator" lib/features/*/presentation/`.
- **After W4** — M8 closes; the grace-period flow is in `integration_test/flows/`
  and the `e2e flows` job is green.
- **After W6** — Epic #312's own one-command invariant:
  `grep -rn "OpenRouter" lib/` returns hits in **exactly two files**.

**The throughput check.** After two waves, if PRs are sitting green-and-unmerged
for longer than a worker takes to finish an issue, the review lane is the
bottleneck. Add a second reviewer, not a sixth worker.

---

## 8. Wave 0 shipped — what it cost and what it found

Six issues merged: **#303** (the Opus lane) and all five of wave 0, worked
**serially in one session** rather than by five parallel workers, for the
reason §8.1 gives. Every one landed green on all eight checks.

| Issue | PR | What the audit found in the issue text |
|---|---|---|
| #303 | #330 | Two of the user's three clauses described behaviour the app did not have |
| #91 | #331 | "8 tests" (it has 7); "its existing icon" (it has none); `subtitle` required, which would have meant inventing Hebrew copy inside a refactor |
| #304 | #332 | One defective formatter named; **three existed and two were wrong** |
| #315 | #333 | Cites `evaluateToday`, which #303 had replaced hours earlier |
| #316 | #334 | Accurate. The coverage gate caught two declaration-only files |
| #317 | #335 | Its own amendment moved `resolvedApiKey` out; the **research doc** names the wrong store |

**The issue text was wrong in five of six.** That is the pattern this project
has recorded for seven milestones, holding exactly.

**Two defects were found by tests rather than by reading.** #303's e2e
back-fill flow caught a write path handing the state machine the *meal's*
timestamp instead of the wall clock — days wrong for a back-dated meal, and
invisible to a unit suite that was passing. #304's own regression test showed
the scan sheet's macro strip and its prefill disagreeing by construction.

**The coverage gate paid for itself twice**, catching `estimate_failure_reason.dart`,
`macro_estimator.dart` and `estimation_settings_repository.dart` — all
declaration-only, all silently absent from lcov rather than at 0%.

---

## 8.1 What running wave 0 changed

Recorded the way every other handoff here records what only running it revealed.

### A spawned worker can be no more permissive than the session that spawned it

`create_session` refuses `permission_mode: "auto"` with *"requires the parent
session to be in auto mode (parent is plan)"*. A session in plan mode can
therefore only create children in `default`, and a `default` child **blocks on
its first permission prompt and does no work at all** — five were spawned, all
five sat on an `add_repo` approval, none wrote a line.

Two things follow for anyone running this plan:

- **Spawn workers from a session already in auto mode**, or expect to approve
  every worker's prompts by hand in the web UI.
- **Pass `source_url` and `source_revision`.** Without them the child has no
  repository and immediately asks to attach one, which is what the five were
  blocked on. That prompt is avoidable; the permission ceiling is not.

The fallback is not bad: **one session working the queue serially is viable**,
because the per-issue cost is dominated by the audit and the tests, not by CI.

### The container has no Flutter SDK, and installing it is worth the four minutes

`flutter` and `dart` are absent. `CLAUDE.md` says CI is the validation gate and
that is still true, but blind-pushing a change of any size and iterating through
CI is poor. The pinned 3.47.3 Linux archive downloads from
`storage.googleapis.com` (reachable) in about four minutes:

```bash
curl -sSL -o /tmp/flutter.tar.xz \
  https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.3-stable.tar.xz
tar -xf /tmp/flutter.tar.xz -C /tmp
git config --global --add safe.directory /tmp/flutter/flutter   # "dubious ownership"
export PATH="/tmp/flutter/bin:$PATH"
```

On #303 it caught, locally and in seconds, what would otherwise have been five
or six red CI cycles: a `prefer_initializing_formals` lint that **cannot** be
satisfied with private fields (a named parameter may not start with an
underscore, so the fields became public), six stale `evaluateToday` references,
and eleven widget tests whose containers needed a newly-added provider
dependency overridden.

### Adding a dependency to one `@riverpod` provider ripples into every test container

`adaptationPhaseServiceProvider` gained `dailyLogRepositoryProvider`, and
**every test that overrode only `streakRepositoryProvider` then reached
`databaseProvider` and tried to open a real database** — five files, fifteen
tests. Worth budgeting for whenever a service gains a repository: grep for
`<thatProvider>.overrideWithValue` and expect to touch all of them.

### The e2e flow found what no unit test did

#303's own unit suite passed while `logMeal` still handed the state machine the
**meal's** timestamp as the evaluation instant. That is the same instant for a
meal logged now, and days wrong for a back-dated one: the derivation walks back
from the instant it is given, so back-filling produced a streak of 2 where it
should have been 3. Only the flow that drove the real diary UI caught it —
`design/user_bugs_handoff.md`'s first lesson, earning itself again.

### `app_router.g.dart` was already stale on `main`

`build_runner` regenerates it from an unmodified source file, which means the
committed copy had drifted. **CI cannot catch this** — it builds what you
committed rather than running the generator. Worth a `changes`-style check one
day; `design/cicd_plan.md` Phase 1 already lists codegen drift as next.

---

## 9. What this plan does not claim

In the spirit of every other handoff here.

- **Wave 0's numbers are what one session did, not a rate.** Six issues in one
  sitting says nothing about how long a worker takes; the issues were small and
  the toolchain was warm by the third one.

- **No wall-clock estimate.** Nothing in this repository measures how long an agent
  takes on an issue of this specification density, and a number invented here would
  be quoted back later as if it had been measured.
- **The Actions concurrency ceiling is inferred**, not verified against this
  account's plan tier. It is stated as something to watch.
- **The wave widths are upper bounds on parallelism, not a schedule.** Waves do not
  start together; the ready-queue model is what actually runs.
- **The review-lane recommendation assumes review is a real gate.** If the owner
  chooses to merge on green — as has happened before, and is recorded in
  `design/m6_platform_handoff.md` — throughput rises and the cost is that no human
  has read the diffs. That is a decision, not an oversight, and it belongs to the
  owner either way.
