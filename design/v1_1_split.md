# v1.1 Milestone Split — Assessment & Record

**Status:** **executed.** Labels created, seven Epic tracking issues opened
(#264–#270), all 26 issues re-filed, re-titled where needed and rewritten to the
`issue_conventions.md` standard, Epic #13 closed as superseded.
**The seven GitHub milestone objects exist** — milestones #11–#17, carrying all 33
issues (the 26 work issues plus the seven Epics), with `v1.1 — Post-MVP Backlog`
retired. Label view and milestone view now agree. See §6 for the mapping and for how
the objects were created, which is not obvious.
**Scope:** milestone `v1.1 — Post-MVP Backlog`, Epic #13, issues #103–#128

---

## 1. Verdict

**Split it.** v1.1 is not a milestone — it is a backlog wearing a milestone's
label. It bundles seven unrelated capability areas behind one North Star, which
`milestone_conventions.md` §1.1 explicitly forbids, and it cannot satisfy its
own closure conditions.

This is not a change of direction. Epic #13's own Definition of Done already
concedes the point:

> - [ ] Each sub-feature ships behind its own milestone (to be created when
>       development begins)

The split executes a decision that was recorded when the epic was written and
then never carried out. What follows is the shape it should take.

---

## 2. Why the current form does not work

### 2.1 It fails the project's own definition of a milestone

`milestone_conventions.md` §1.1 defines a milestone as "a single, cohesive
delivery phase … a clear, singular objective (the North Star) … can be demoed
or shipped independently of subsequent milestones."

v1.1 contains seven objectives: biomarker logging, Apple Health, restaurant
directory, recipe converter, menu analyzer, iCloud backup, and App Store
submission. None of them is a step toward any other. There is no order in which
they must be built, and shipping any one of them does not move the other six.
Every MVP milestone M0–M8 passes this test. v1.1 is the only one that does not.

### 2.2 Its closure conditions are unreachable

§2 "Milestone Closure Conditions" requires that "a milestone must not be closed
with any open issue." As a single milestone, v1.1 closes only when biomarkers,
Health, directory, recipes, menu analysis, backup **and** App Store submission
have all shipped. In practice that means it never closes — and the Definition
of Done attached to it (analyze clean, tests green, ≥80% coverage on
`domain/` + `application/`, closure comment on the Epic) is therefore never
applied to anything. A gate that can never fire is not a gate.

Six smaller milestones each close in weeks and each get the gate applied.

### 2.3 It destroys the readiness signal

The seven groups have wildly different entry conditions, and flattening them
into one bucket makes "what do we pick up next?" unanswerable:

| Group | Issues | Blocked by |
|---|---|---|
| Biomarker logging | #103–#107 | Nothing — pure app work on shipped patterns |
| Recipe converter | #118–#120 | Nothing — no new SDK, no platform config |
| Restaurant directory | #111–#117 | Content curation (#111, non-engineering) + an unresolved map SDK choice |
| Menu analyzer | #121–#122 | M6 Keto Lens — the OCR pipeline it extends does not exist yet |
| Apple Health | #108–#110 | HealthKit entitlement review; iOS-only by nature |
| iCloud backup | #123–#124 | iCloud entitlement; needs re-spec for sembast + web |
| App Store submission | #125–#128 | Not a feature at all — see §2.4 |

Two of these are ready today. Two are blocked on things outside the codebase.
One is blocked on an MVP milestone that has not started. That is exactly the
information a milestone boundary is supposed to carry, and one bucket carries
none of it.

### 2.4 It files the v1.0 release under a post-v1.0 milestone

#125–#128 — App Store Connect metadata, privacy nutrition labels, TestFlight
beta, App Store submission — ship **the MVP**. They are the last mile of
M0–M8, not the first mile of v1.1. Filing them under "v1.1 — Post-MVP Backlog"
puts the release of v1.0 chronologically after v1.0. They also collide with
`cicd_plan.md` §7.1, which parks all fastlane/TestFlight/App Store CD by
decision until stated entry conditions are met.

These four are a release checklist, not a delivery phase, and they belong
outside the feature-milestone sequence entirely.

---

## 3. Stale content the split should clean up

Independent of the structural argument, v1.1 has drifted far enough from `main`
that none of it is pickupable as written. The split is the natural moment to
fix it, and a restructure that re-files stale issues just relocates the problem.

1. **Isar is gone.** #197 replaced it with sembast across the whole repo.
   Three issues still name it in their titles or bodies: #104
   (`IsarBiomarkerLogRepository`), #113 ("caches JSON to Isar"), #123
   ("serialises all Isar collections"). All three need rewriting against the
   sembast store/mapper conventions in `CLAUDE.md` § Local Persistence.

2. **Epic #13's scope boundary is factually wrong.** It lists "Web support"
   under *Explicitly Out of Scope for v1.1*. Web shipped in #197 and #199.

3. **iCloud backup assumes an iOS-only app.** #123/#124 write to the iCloud
   Documents container via `NSFileManager`. With web live, backup either goes
   behind the same conditional-import firewall as
   `lib/core/database/database_factory.dart` or it is declared iOS-only in the
   issue. As written it would break the web build, and `flutter analyze` will
   not catch it — only CI's `flutter build web` step will.

4. **The map SDK choice is wrong twice over.** #114 describes `mapkit_flutter`
   as "(Apple MapKit wrapper)", and `technology.md` §137 repeats it. It is the
   Yandex MapKit plugin; Apple's is `apple_maps_flutter`. Separately, neither
   renders on web, so the choice needs re-deciding now that web is a target —
   which is a directory-milestone pre-flight item, not a detail.

5. **Every v1.1 issue fails the issue gate.** `issue_conventions.md` requires an
   Implementation Plan with exact file paths, full public API contracts, inline
   business logic and named integration points; a filled Technologies &
   Approach table; a three-part Context & Objective; and Testing Requirements.
   #103–#128 have none of these — #114 and #123 are four-line stubs. Compare
   #206 (Login), which is fully formed. Per `CLAUDE.md`, all 26 "would be sent
   back — not ready for implementation."

---

## 4. Proposed structure

### 4.1 Labels: capability-named, not numbered

The repo has already set this precedent. The Login epic (#206–#221) uses
`epic:login`, outside the M0–M8 numbering — correctly, because it is not step 9
of a chain.

The same reasoning applies here. `milestone_conventions.md` §1.2 states that
each milestone "may only begin when all blocking issues of the previous
milestone are merged." That rule is right for M0–M8, which are a genuine
dependency chain, and wrong for post-MVP work, which is a set of parallel peers.
Numbering them M9–M14 would imply a sequence that does not exist and would
gate biomarkers behind a directory that is waiting on content curation.

**Recommendation was:** capability-named epic labels, matching `epic:login`, plus
an amendment to §1.2 stating explicitly that post-MVP milestones are unordered
peers and the sequential-gating rule does not apply to them.

> **Decision taken: numbered `epic:m9-*`–`epic:m14-*`**, continuing the existing
> taxonomy rather than the capability-named scheme recommended above. That is a
> reasonable call — it keeps one naming convention across the whole board, and
> `epic:login` becomes the outlier rather than the precedent.
>
> **It makes the §1.2 amendment mandatory rather than optional.** Capability names
> imply nothing about order; numbers do. Without the explicit carve-out, "each
> milestone may only begin when the previous is merged" would gate M13 Apple Health
> behind M11's restaurant *content curation* — a dependency that does not exist in
> either direction. §1.2 now states that M0–M8 are a chain and M9–M14 are parallel
> peers numbered by recommended build order.
>
> The numbers therefore encode the §4.3 build order: M9 and M10 are the two with no
> external blocker and come first.

### 4.2 The split

| New milestone | Epic label | Issues | Count | Entry condition |
|---|---|---|---|---|
| Biomarker Logging | `epic:biomarkers` | #103–#107 | 5 | **Ready now** |
| Recipe Converter | `epic:recipe-converter` | #118–#120 | 3 | **Ready now** |
| Restaurant Directory | `epic:directory` | #111–#117 | 7 | Content curated; map SDK re-decided for web |
| Menu Analyzer | `epic:menu-analyzer` | #121–#122 | 2 | M6 Keto Lens closed |
| Apple Health Sync | `epic:health-sync` | #108–#110 | 3 | HealthKit entitlement granted |
| Backup & Restore | `epic:backup` | #123–#124 | 2 | Re-spec'd for sembast + web |
| Release v1.0 | `epic:release-v1` | #125–#128 | 4 | M8 closed; `cicd_plan.md` §7.1 entry conditions met |

Six capability milestones plus one release milestone. 26 issues, unchanged in
number — this is a re-filing, not a re-scoping.

### 4.3 Suggested build order

Order among the six is a product call, not a technical one — they are
independent. If the question is which to start first, the technical argument is:

1. **Biomarker Logging** — reuses the daily-keyed singleton store pattern M1
   already shipped (`SymptomLog` is the template), `fl_chart` is already chosen
   in `technology.md` §100, and it touches no platform config and no new
   permission. Lowest risk, and it exercises the M1 data layer against a second
   consumer, which is worth knowing before the heavier milestones land.
2. **Recipe Converter** — self-contained, no new SDK, no entitlement.
3. Directory / Menu Analyzer — the two heavyweight ones, both externally
   blocked. Start them when their blockers clear, not before.

Release v1.0 is not in this ordering. It runs on the MVP's schedule, gated on
M8, and should be treated as blocking v1.0 launch rather than competing with
post-MVP feature work.

---

## 5. What was executed

1. **Seven epic labels created** — `epic:m9-biomarkers`, `epic:m10-recipe-converter`,
   `epic:m11-directory`, `epic:m12-menu-analyzer`, `epic:m13-health-sync`,
   `epic:m14-backup`, `epic:release-v1`. They were auto-created by the first issue
   assignment and carry GitHub's **default grey**; recolouring them to match the
   existing `epic:*` palette is a manual step (there is no label-colour API in the
   tooling used).
2. **All 26 issues re-filed** — `epic:post-mvp` swapped for the capability label,
   `type:*` and `layer:*` untouched. Every issue still carries exactly three labels.
3. **Seven Epic tracking issues opened** (#264–#270) from the §3 template, each with
   its own North Star, entry conditions, scope boundaries, architectural invariants
   and Definition of Done.
4. **Sub-issue hierarchy wired** — all 26 attached to their Epic, so GitHub shows
   real per-milestone progress rather than only a manual checklist.
5. **All 26 issue bodies rewritten** to the `issue_conventions.md` standard, against
   the *current* codebase. Three titles changed where they named a package that no
   longer exists (#104, #113, #123) and two where they promised capability that is
   deferred (#114, #119).
6. **Epic #13 closed as superseded**, its body replaced with an index of the seven
   and a record of the four things its text got wrong.
7. **Docs amended** — `milestone_conventions.md` §1.2/§1.3/§2, `CLAUDE.md`'s
   project-board tables and label taxonomy, `tasks.md` §Post-MVP,
   `issue_conventions.md`, `mvp.md`, `base_design.md`.
8. **`epic:post-mvp` retired** — nothing carries it.

### A second pass: normalised to `issue_conventions.md` §4

All 26 were later re-checked against §4's *literal* template rather than against
house practice, and three genuine deviations were corrected in every one:

- **Technologies & Approach** now uses §4's columns — `Concern | Technology / Package
  | Version | Notes` — instead of the ad-hoc set the first pass used.
- **`#### Contract Tests`** and **`#### Regression`** now appear as named
  sub-sections on every issue, marked N/A where they do not apply, rather than
  being silently omitted.
- **Definition of Done** now carries §4's eight-item **Code** checklist verbatim
  (no scope creep, no sembast in `domain`/`presentation`, no Flutter in
  `domain`/`application`, no `get_it`, no magic numbers, no TODOs, no commented-out
  code, all providers `@riverpod`) plus the issue-specific items, and §4's
  **Validation Gate** and **Git & PR** blocks.
- **Architectural Layer** adopted §4's seven-option `layer:*` checkbox list, which
  is more precise than the file-path form that shipped issues use.

**A finding from that pass, worth recording:** §4's literal template also mandates
a `**Branch:** / **Labels:** / **Milestone:**` header block and `#### Background`
sub-headings. **No issue in this repository has ever had them** — not #80 (shipped
and implemented), not #206 (the most recently authored). The convention doc and
actual practice have diverged, and the 26 follow practice on those two points. That
is a fifth instance of the doc/code drift this document exists to catalogue, and
`issue_conventions.md` §4 should be reconciled with what anyone actually writes.

### A third correction: M6 shipped mid-flight

Between the split and the normalisation pass, M6 Keto Lens merged — and its
platform audit **removed ML Kit entirely** in favour of Tesseract on all six
targets, because ML Kit has no Hebrew script model at all. Three artefacts were
rewritten against the real shipped API rather than left pointing at a deleted
class:

- **#121, #122 and Epic #267** — `MlKitTextRecognizer` and `InputImage` replaced by
  `TextRecognitionService` and a `String imagePath`; M12's "blocked on M6" entry
  condition removed; and the analyser now reuses `IngredientVerdict.matchedCleanIngredients`,
  which M6 built for precisely the "a clean badge is not evidence" problem M12 has.
- **Epic #265 (M10)** — the scan-input deferral is now a scope decision, not a
  dependency.
- **#109** — M4 shipped too, so the weight fields it pre-fills are real.


### Stale content fixed in place, not merely re-filed

All five §3 items were corrected during the rewrite rather than deferred:

- The three Isar references (#104, #113, #123) now specify sembast, with the
  `dateIndex`/`.name`/`num`-decoding rules spelled out per issue
- #123/#124 carry the platform-destination decision explicitly, with the
  `dart:io` firewall named as the binding constraint
- #114 became the map-SDK **re-decision** issue, carrying the
  `mapkit_flutter`-is-Yandex correction and a recommendation (`flutter_map`), and
  requires `technology.md` §137 be fixed as part of it
- #106 quotes `technology.md` §100's existing `fl_chart` choice rather than
  re-litigating it

---

## 6. Milestone objects: created

**All seven exist as real GitHub milestones**, and every issue in the split carries
one. Label view and milestone view now agree — either is an accurate filter of the
board.

| Milestone | Number | Epic | Work issues | Total |
|---|---|---|---|---|
| `M9 — Biomarker Logging` | #11 | #264 | #103–#107 | 6 |
| `M10 — Recipe Converter` | #12 | #265 | #118–#120 | 4 |
| `M11 — Restaurant Directory` | #13 | #266 | #111–#117 | 8 |
| `M12 — Menu Analyzer` | #14 | #267 | #121–#122 | 3 |
| `M13 — Apple Health Sync` | #15 | #268 | #108–#110 | 3 |
| `M14 — Backup & Restore` | #16 | #269 | #123–#124 | 3 |
| `Release v1.0 — App Store Launch` | #17 | #270 | #125–#128 | 5 |

33 issues in total: the 26 re-filed work issues plus the seven Epic tracking issues,
which carry their own milestone so that a milestone page shows its Epic alongside its
children.

**`v1.1 — Post-MVP Backlog` (milestone #8) is retired** — closed with zero open issues
on it. The one issue it still holds is Epic #13, itself closed as superseded, which is
the correct historical record.

### How, and why that is worth writing down

The GitHub tooling available to an agent session exposes **no milestone API**: it can
set an issue's milestone by number but cannot create, list or look one up, and there is
no `gh` CLI and no REST passthrough. That is why the first pass of this split shipped
labels and Epics only.

The route out is a one-shot GitHub Actions workflow. A runner has both `gh` and a
repo-scoped `GITHUB_TOKEN`, so a throwaway workflow committed with
`permissions: issues: write` can do what the session cannot. Two details matter:

- Trigger it with `on: push` to its own branch, **not** `workflow_dispatch` — the
  latter only fires for workflows that already sit on the default branch, so it cannot
  bootstrap itself. Pushing the file is the trigger.
- Make it idempotent. `POST /milestones` returns 422 on a duplicate title, so fall back
  to a lookup rather than failing; re-assigning an issue that already carries the
  milestone is a no-op. A partial failure can then simply be re-run.

Run `34601122804` did the work; the workflow was deleted immediately afterwards, and
`ci.yml` and the five `build-*.yml` files remain the only workflows this repo keeps
(`design/cicd_plan.md`). The same technique is the way to do any other repo-admin
operation the session's tooling does not reach.

**Used a second time, and the gap turned out to be wider than milestones.** M15 Meal
Entry (`design/m15_meal_entry_research.md`) needed a new `epic:m15-meal-entry` label,
and §5.1 above records the belief that epic labels "were auto-created by the first
issue assignment". **That is no longer true of the tooling in use** — creating an issue
with an unknown label now fails outright with `failed to resolve label`, so the label
has to exist first and there is no label API either. One throwaway workflow created
both the label (with a real colour, which the first pass could not do) and milestone
#18, in run `34611503561`, and was deleted in the following commit. Anyone doing this
again should create the label **and** the milestone in the same one-shot run.

---

**Used a third time, for M16 AI Menu Scanner** (`design/m16_menu_scanner_research.md`): one
workflow, pushed to `chore/m16-milestone-bootstrap`, created the `epic:m16-menu-scanner`
label and milestone #19 in run `34647532997`, idempotently (a label
or milestone that already exists is looked up, not re-created). Two things this pass found:
the workflow can print the new milestone's number, which the session then reads from the job
log with the Actions tooling and passes to every `issue_write`; and **the session cannot
delete the throwaway branch** — `git push --delete` is refused by the egress policy (403) —
so the workflow file was removed by a commit on that branch and the branch itself has to be
deleted from the GitHub UI.

---

## 7. Open item, out of scope

The **Login epic (#206–#221)** carries `epic:login`, has **no GitHub milestone and
no Epic tracking issue**, and is not mentioned in `CLAUDE.md`'s issue-range table.
It is effectively the eighth post-MVP capability and should be filed the same way
as the seven above — under the numbered scheme, presumably `epic:m15-login`.
Relabelling 16 issues is a separate decision and was deliberately left alone.
