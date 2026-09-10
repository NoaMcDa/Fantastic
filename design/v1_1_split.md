# v1.1 Milestone Split — Assessment & Proposal

**Status:** proposal, not yet executed on GitHub
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

**Recommendation:** capability-named epic labels, matching `epic:login`, plus
an amendment to §1.2 stating explicitly that post-MVP milestones are unordered
peers and the sequential-gating rule does not apply to them.

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

## 5. Work required to execute

1. Create seven GitHub milestones and seven `epic:*` labels.
2. Re-file #103–#128: swap `epic:post-mvp` for the capability label (the
   one-type/one-layer/one-epic rule in `issue_conventions.md` §"Issue Labeling
   Taxonomy" still holds — this is a swap, not an addition) and reassign the
   milestone.
3. Open six Epic tracking issues from the `milestone_conventions.md` §3
   template, one per capability milestone, each with its own North Star,
   scope boundaries, architectural invariants and DoD.
4. Rewrite Epic #13 as an index pointing at the six, or close it with a comment
   recording the split. It should not survive as a scope-bearing issue.
5. Amend `milestone_conventions.md` §1.2 (milestone table), §1.3 (MVP boundary
   wording, which currently routes everything deferred to a single
   `epic:post-mvp`) and §2 (epic label list).
6. Amend `CLAUDE.md`'s "Issue ranges by milestone" and "Epic tracking issues"
   tables, and the label taxonomy count.
7. Retire the `epic:post-mvp` label once nothing carries it.

Not part of the split, but surfaced by it and worth doing in the same pass:

- **The Login epic has no GitHub milestone and no Epic tracking issue.**
  #206–#221 carry `epic:login` and nothing else. It is already the eighth
  post-MVP capability and should be filed the same way as the six above.
- **`CLAUDE.md` does not mention the Login epic at all.** Its issue-range table
  stops at #128 and its label taxonomy lists ten epic labels, not eleven.
- The five stale-content items in §3 should be fixed as each milestone's
  pre-flight pass, in the same form as `m1_preflight.md` / `m2_preflight.md` /
  `m3_preflight.md` — written before the milestone is picked up, not during.
