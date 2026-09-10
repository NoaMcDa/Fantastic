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

Milestones are numbered sequentially. Each milestone may only begin when all blocking issues of the previous milestone are merged and green on CI.

| Milestone | Label | North Star |
|---|---|---|
| M0 | `epic:m0-foundation` | Project skeleton, dependencies, routing, Isar wiring, test infra — the scaffold everything else builds on |
| M1 | `epic:m1-domain-data` | All domain models, repository interfaces, Isar schemas, mappers, and contract tests — no UI, no services |
| M2 | `epic:m2-macro-tracker` | Daily meal logging, macro aggregation, keto ratio, and the dashboard/diary UI |
| M3 | `epic:m3-adaptation` | Adaptation phase state machine, streak engine, push notifications, and phase UI |
| M4 | `epic:m4-onboarding` | Personalised onboarding flow, macro target calculation, streak seeding |
| M5 | `epic:m5-symptom-diary` | Lightweight daily symptom check-in and diary view |
| M6 | `epic:m6-keto-lens` | Hebrew OCR pipeline, ingredient classifier, camera UI, result sheet |
| M7 | `epic:m7-polish` | Empty states, error handling, loading skeletons, app icon, permissions |
| M8 | `epic:m8-ci-integration` | Integration test suite, GitHub Actions CI workflow, coverage gate |
| v1.1+ | `epic:post-mvp` | All deferred capabilities (see §1.3) |

### Scope Discipline

**In-scope** for a milestone means: required to satisfy the milestone's North Star and no more.

**Adding scope** to an open milestone is prohibited. If new work is discovered mid-milestone, open a new issue, assign it to the correct milestone (or `post-mvp`), and continue. Never silently expand an existing issue.

**Partial implementations are forbidden.** Every merged PR in a milestone must leave the codebase in a state where `flutter analyze`, `dart format --check`, and `flutter test` all pass. A half-wired feature that requires a subsequent PR to compile is a milestone scope violation.

### MVP Boundary

The MVP consists of milestones M0 through M8. The boundary is hard.

The following capabilities are **explicitly out of scope for MVP** and must be labelled `epic:post-mvp`:

| Capability | Rationale |
|---|---|
| Biomarker logging (ketones, glucose, weight) | Not critical to first-week retention |
| Apple Health / HealthKit integration | Requires entitlement review; v1.1 |
| Restaurant directory | Requires manual content curation |
| Menu analyzer (camera → dish extraction) | Second ML pipeline; complexity deferred |
| Recipe converter | Non-critical to core loop |
| iCloud backup / sync | Offline-first is sufficient for v1 |
| Food database / barcode lookup | Manual entry covers MVP |
| Social / community features | Post-retention problem |
| App Store submission | Follows M8 completion |

Any issue that touches post-MVP scope must carry the `epic:post-mvp` label and must not be referenced as a dependency by any MVP milestone issue.

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
| `epic:m0-foundation` | Project scaffold, deps, routing, Isar init, test infra |
| `epic:m1-domain-data` | Domain models, repository interfaces, Isar schemas, contract tests |
| `epic:m2-macro-tracker` | Meal logging, macro tracking, dashboard, diary UI |
| `epic:m3-adaptation` | Streak engine, phase state machine, notifications, phase UI |
| `epic:m4-onboarding` | Onboarding flow, macro target calculation, first-launch gate |
| `epic:m5-symptom-diary` | Symptom check-in strip and diary section |
| `epic:m6-keto-lens` | OCR pipeline, label parser, classifier, camera UI |
| `epic:m7-polish` | Empty states, errors, loading states, icons, permissions |
| `epic:m8-ci-integration` | Integration tests, GitHub Actions CI, coverage gate |
| `epic:post-mvp` | All deferred v1.1+ capabilities |

### Milestone Closure Conditions

A milestone is **closed** when all of the following are true:

1. Every issue assigned to the milestone is in `Closed` state.
2. Every PR linked to a milestone issue is merged into `main`.
3. `flutter analyze` returns zero issues on `main`.
4. `flutter test` returns zero failures on `main`.
5. Domain and application layer coverage is ≥ 80% on `main`.
6. The milestone's Definition of Done checklist (see §3) is fully checked off.
7. A milestone closure comment is posted on the Epic issue summarising what shipped.

A milestone must not be closed with any open issue, regardless of priority. Move unfinished issues to the next milestone or to `epic:post-mvp` before closing.

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

- [ ] <invariant — e.g., "No Isar types may appear in domain/ or presentation/ layers">
- [ ] <invariant — e.g., "All new providers use @riverpod code generation; no manual Provider(...) calls">
- [ ] <invariant — e.g., "Every new repository implementation must pass the shared contract test suite">
- [ ] <invariant — e.g., "No feature reads Isar directly from a widget or service; always via a repository interface">

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