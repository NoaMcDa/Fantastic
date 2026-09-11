# Milestone Conventions — Fantastic

## 1. Milestone Structure & Scope Discipline

### What a Milestone Is

A Milestone (also called an Epic) represents a single, cohesive delivery phase that produces a shippable, internally consistent slice of the product. It is not a sprint, a time-box, or a loose collection of related work — it is a named vertical increment that:

- Has a clear, singular objective (the North Star)
- Contains only the issues required to reach that objective
- Leaves the codebase in a clean, non-broken state when closed
- Can be demoed or shipped independently of subsequent milestones

Every issue belongs to exactly one milestone. An issue that spans two milestones is not atomic — split it.

### Milestone Sequence

**M0–M8 are a chain.** They are numbered sequentially, and each may only begin when
all blocking issues of the previous milestone are merged and green on CI.

**M9–M15 are not.** They are parallel peers, numbered by *recommended build order*
rather than by dependency, and the sequential gate above does not apply to them.
Applied literally it would block M13 Apple Health behind M11's restaurant content
curation, which is a content task with no code relationship to HealthKit. A
post-MVP milestone begins when **its own entry conditions** — recorded in its Epic
— are met.

The MVP chain still gates everything: a post-MVP milestone may declare a blocking
dependency on an MVP milestone (M12 Menu Analyzer is gated on M6 Keto Lens, whose
OCR pipeline it extends), and §1.4's rule that a dependency may only point at an
*earlier* milestone is unchanged.

| Milestone | Label | North Star |
|---|---|---|
| M0 | `epic:m0-foundation` | Project skeleton, dependencies, routing, database wiring, test infra — the scaffold everything else builds on |
| M1 | `epic:m1-domain-data` | All domain models, repository interfaces, persistence schemas, mappers, and contract tests — no UI, no services |
| M2 | `epic:m2-macro-tracker` | Daily meal logging, macro aggregation, keto ratio, and the dashboard/diary UI |
| M3 | `epic:m3-adaptation` | Adaptation phase state machine, streak engine, push notifications, and phase UI |
| M4 | `epic:m4-onboarding` | Personalised onboarding flow, macro target calculation, streak seeding |
| M5 | `epic:m5-symptom-diary` | Lightweight daily symptom check-in and diary view |
| M6 | `epic:m6-keto-lens` | Hebrew OCR pipeline, ingredient classifier, camera UI, result sheet |
| M7 | `epic:m7-polish` | Empty states, error handling, loading skeletons, app icon, permissions |
| M8 | `epic:m8-ci-integration` | Integration test suite, GitHub Actions CI workflow, coverage gate |
| Release v1.0 | `epic:release-v1` | App Store metadata, privacy labels, TestFlight beta, submission. **Ships the MVP** — runs on M0–M8's schedule, before M9 |
| M9 | `epic:m9-biomarkers` | Ketone, glucose and weight logging with 30-day trends |
| M10 | `epic:m10-recipe-converter` | Hebrew/English keto substitution engine, converter and saved-recipe library |
| M11 | `epic:m11-directory` | Curated Israeli keto venue directory — search, filters, detail and map |
| M12 | `epic:m12-menu-analyzer` | Menu OCR → per-dish keto verdicts and modification tips |
| M13 | `epic:m13-health-sync` | HealthKit body-weight read and macro write, iOS-only behind a platform seam |
| M14 | `epic:m14-backup` | Portable JSON backup export and atomic restore |
| M15 | `epic:m15-meal-entry` | Three ways to add a meal — typed, described, photographed — and a way to correct one, all through the same editable form |

### Scope Discipline

**In-scope** for a milestone means: required to satisfy the milestone's North Star and no more.

**Adding scope** to an open milestone is prohibited. If new work is discovered mid-milestone, open a new issue, assign it to the correct milestone (M9–M15, or a new one if it fits none), and continue. Never silently expand an existing issue.

**Partial implementations are forbidden.** Every merged PR in a milestone must leave the codebase in a state where `flutter analyze`, `dart format --check`, and `flutter test` all pass. A half-wired feature that requires a subsequent PR to compile is a milestone scope violation.

### MVP Boundary

The MVP consists of milestones M0 through M8. The boundary is hard.

The following capabilities are **explicitly out of scope for MVP**. Each now has its
own milestone rather than a shared `epic:post-mvp` bucket — see §1.2 and
`design/v1_1_split.md` for why that bucket was split:

| Capability | Milestone | Rationale for deferral |
|---|---|---|
| Biomarker logging (ketones, glucose, weight) | M9 | Not critical to first-week retention |
| Recipe converter | M10 | Non-critical to core loop |
| Restaurant directory | M11 | Requires manual content curation |
| Menu analyzer (camera → dish extraction) | M12 | Extends M6's OCR pipeline; complexity deferred |
| Apple Health / HealthKit integration | M13 | Requires entitlement review |
| Backup & restore | M14 | Offline-first is sufficient for v1 |
| App Store submission | `epic:release-v1` | **Ships the MVP** — see the note below |
| Food database / barcode lookup | *(unplanned)* | Manual entry covers MVP |
| Social / community features | *(unplanned)* | Post-retention problem |

**App Store submission is not post-MVP work.** It ships v1.0 and runs on M0–M8's
schedule. Filing it as "post-MVP" once put the release of v1.0 chronologically
after v1.0; `epic:release-v1` is deliberately unnumbered and sits before M9.

Any issue outside the MVP must carry the epic label of its milestone, and must not
be referenced as a blocking dependency by any MVP milestone issue.

**The `epic:post-mvp` label is retired.** Nothing carries it. An issue that would
once have gone there now goes to the milestone that owns the capability, or gets a
new milestone opened for it under §3's Epic template.

### Cross-Milestone Dependency Rules

- A milestone issue may only declare a blocking dependency on an issue in an **earlier** milestone.
- No circular dependencies. No forward references.
- If issue B in M2 depends on issue A in M1, issue A must be merged before issue B can be started. This is enforced by the "Upstream Dependencies" field in the issue template.
- Shared domain models and interfaces (M1) are the only cross-cutting dependencies permitted within the MVP milestones.

---

## 2. Labeling Taxonomy

### Milestone / Epic Labels

One epic label per issue. These map directly to the milestone table above.

| Label | Description |
|---|---|
| `epic:m0-foundation` | Project scaffold, deps, routing, database init, test infra |
| `epic:m1-domain-data` | Domain models, repository interfaces, persistence schemas, contract tests |
| `epic:m2-macro-tracker` | Meal logging, macro tracking, dashboard, diary UI |
| `epic:m3-adaptation` | Streak engine, phase state machine, notifications, phase UI |
| `epic:m4-onboarding` | Onboarding flow, macro target calculation, first-launch gate |
| `epic:m5-symptom-diary` | Symptom check-in strip and diary section |
| `epic:m6-keto-lens` | OCR pipeline, label parser, classifier, camera UI |
| `epic:m7-polish` | Empty states, errors, loading states, icons, permissions |
| `epic:m8-ci-integration` | Integration tests, GitHub Actions CI, coverage gate |
| `epic:release-v1` | App Store metadata, privacy labels, TestFlight beta, submission |
| `epic:m9-biomarkers` | Biomarker model, store, entry sheet, trend chart, diary section |
| `epic:m10-recipe-converter` | Substitution engine, converter screen, saved-recipe library |
| `epic:m11-directory` | Directory data, reader, screen, detail sheet, map |
| `epic:m12-menu-analyzer` | Menu dish extraction, per-dish verdicts, analyser screen |
| `epic:m13-health-sync` | HealthKit seam, body-weight read, macro write |
| `epic:m14-backup` | Backup export, validated atomic restore |
| `epic:m15-meal-entry` | Add-meal mode chooser, macro estimation, provenance, meal editing |
| `epic:login` | Authentication — **not yet milestoned**; see the note below |

`epic:post-mvp` is **retired** — it was split into the seven labels above
(`design/v1_1_split.md`).

`epic:login` (#206–#221) predates this split, carries no GitHub milestone and has no
Epic tracking issue. It is effectively the eighth post-MVP capability and should be
filed like the others — an open item, not a convention.

### Milestone Closure Conditions

A milestone is **closed** when all of the following are true:

1. Every issue assigned to the milestone is in `Closed` state.
2. Every PR linked to a milestone issue is merged into `main`.
3. `flutter analyze` returns zero issues on `main`.
4. `flutter test` returns zero failures on `main`.
5. Domain and application layer coverage is ≥ 80% on `main`.
6. The milestone's Definition of Done checklist (see §3) is fully checked off.
7. A milestone closure comment is posted on the Epic issue summarising what shipped.

A milestone must not be closed with any open issue, regardless of priority. Move
unfinished issues to the milestone that owns the capability before closing — or open
a new milestone for them under §3. There is no catch-all bucket: `epic:post-mvp` was
retired precisely because it became one (`design/v1_1_split.md`).

---

## 3. Formal Milestone Epic Template

Use this template when opening the tracking issue for a new milestone. One Epic issue per milestone, pinned to the repository.

---

```markdown
## [M<N>] <Milestone Title>

**Epic Label:** `epic:m<N>-<slug>`
**Milestone:** M<N> — <Title>

### North Star

<1–2 sentences. What is the single outcome this milestone delivers? Why does it matter to the product?>

---

### Scope Boundaries

#### In Scope (child issues)

- [ ] #<issue-number> — <issue title>
- [ ] #<issue-number> — <issue title>
- [ ] ...

#### Explicitly Out of Scope

> The following will NOT be addressed in this milestone. Any PR touching these areas will be rejected until the relevant future milestone.

- <capability or concern> → deferred to M<N+x> / post-MVP
- <capability or concern> → deferred to M<N+x> / post-MVP

---

### Architectural Invariants

> Rules that every issue in this milestone must respect. Violations are grounds for PR rejection.

- [ ] <invariant — e.g., "No sembast types may appear in domain/ or presentation/ layers">
- [ ] <invariant — e.g., "All new providers use @riverpod code generation; no manual Provider(...) calls">
- [ ] <invariant — e.g., "Every new repository implementation must pass the shared contract test suite">
- [ ] <invariant — e.g., "No feature reads the database directly from a widget or service; always via a repository interface">

---

### Definition of Done

This milestone is complete when all of the following pass on `main`:

- [ ] All child issues closed and their PRs merged
- [ ] `flutter analyze` — zero issues
- [ ] `dart format --output=none --set-exit-if-changed lib/ test/` — zero diffs
- [ ] `flutter test` — zero failures
- [ ] `flutter test --coverage` — domain + application layers ≥ 80% line coverage
- [ ] `timeout 120 dart run build_runner build --verbose` — no conflicts, no errors
- [ ] No TODO comments introduced in this milestone's PRs
- [ ] No magic numbers — all constants in `lib/core/constants/`
- [ ] No cross-layer violations introduced (verified by `flutter analyze` + manual PR review)
- [ ] Milestone closure comment posted summarising shipped capabilities

---

### Progress

<!-- Updated automatically as child issues close -->

| Issue | Title | Status |
|---|---|---|
| #<n> | <title> | Open / In Progress / Closed |
```

---