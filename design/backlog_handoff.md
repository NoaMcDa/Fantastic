# Backlog handoff — M7 and M8 after the audit

What the MVP's two remaining milestones actually contain, as of this session.
Read it with `design/m7_preflight.md`, which carries the M7 evidence in full;
this file adds the M8 audit, which is recorded nowhere else, and says what to
pick up next.

**No production code changed in this session.** Every change is to issues and
to design docs. What follows is a backlog, not a changelog.

---

## 1. Where the MVP stands

| Milestone | Before | After |
|---|---|---|
| **M7 — Polish** | 8 open work issues, 4 of them describing work already done or impossible as written | **14 open**, 3 closed. Four rewritten, nine filed |
| **M8 — CI & Integration** | 8 open work issues, 6 of them already shipped in #273 | **1 open** (#98), 10 closed |

M0–M6 are code-complete. **M8 is one flow away from closing.** M7 is the
larger body of work and is now the honest size it always was.

Both Epics were re-scoped: **#11** (M7) and **#12** (M8) now list what is
actually open, and their architectural invariants have been corrected — see §4.

---

## 2. The M8 audit

Six of the seven integration-test issues had already shipped in **#273**, and
nobody had closed them. The flows self-identify as F1–F11, and matching them to
issue numbers is what settled it:

| Flow | File | Issue | Verdict |
|---|---|---|---|
| F1, F2 | `onboarding_flow.dart` | #95 | Shipped — and asserts the targets as exact numbers (149/20/64), not "non-zero" |
| F3, F4 | `meal_logging_flow.dart` | #96 | Shipped — plus the delete direction, which #96 never asked for |
| F5 | `streak_flow.dart` | #97 | Shipped — plus "two meals on one day does not increment twice" |
| **F6** | — | **#98** | **Never written.** The only gap |
| F7, F8 | `symptom_diary_flow.dart` | #99 | Shipped — plus browsing a past date |
| F9 | `keto_lens_flow.dart` | #101 | Shipped, four tests |
| F10 | `navigation_smoke_flow.dart` | #100 | Shipped |
| F11 | `storage_failure_flow.dart` | — | Shipped; no child issue asked for it |

14 tests across 7 files, headless on `flutter-tester`, ~35 s, on every PR.

**#98 is the whole remaining blocker on M8**, and `milestone_conventions.md` §2
forbids closing a milestone with any open issue. It is not merely unwritten —
it was blocked and the blocker stands: the flow has to move the clock past a
24-hour grace window, and `AdaptationPhaseService` reads `DateTime.now()`
directly. Seeding a `StreakState` whose `gracePeriodEnd` is already past is the
cheaper route, but **`copyWith` cannot clear a `StreakState` field with null**,
and **#308 is changing how an expired grace period is displayed** — whichever
lands second builds on the first rather than assuming the other's behaviour.

### Three things the closed issues asked for that were deliberately not done

Each is a correction, not a shortfall, and each is recorded on the issue it
belongs to so a reader who finds a ticked DoD box against untouched code knows
why:

1. **No simulator.** #95's DoD required "test passes on iOS simulator" and
   "`-d <simulator-id>` from CI". `m8_preflight.md` Part 0 showed
   `flutter test -d flutter-tester` drives the real app headless in seconds.
   That runs on **every PR** instead of nightly — strictly better than the box
   it fails to tick.
2. **No `SharedPreferences`.** #95 opens with `prefs.clear()` to simulate a
   first launch. It is not a dependency — M4 refused it — and the first-launch
   sentinel is *record existence*, not a flag.
3. **No sliders.** #99 drives a control `SymptomLogSheet` has never had; it
   ships score buttons, because a slider thumb is under the 44 pt HIG minimum
   and shows no value.

---

## 3. What M7 contains now

`design/m7_preflight.md` has the evidence for every line of this. In brief:

**Closed — already done (3).** #90 (Isar is gone; `StartupFailureApp` shipped
in M2), #93 (Hebrew usage strings shipped in M6), #94 (notifications shipped in
M3/M4 — **and its `aps-environment` step is wrong**: that entitlement is for
remote push and would break provisioning).

**Rewritten (4).** #88 (a shimmer is the forever-animation that hangs
`pumpAndSettle`, which the original never mentioned), #89 (its `ProviderObserver`
snippet does not compile against riverpod 3, and reaches for the `AsyncError`
match four milestones learned not to), #91 (named two screens that cannot be
empty), #92 (iOS-only for a six-platform app, and blocked on artwork nobody has
drawn).

**Filed (9).** #301 #302 #304 #305 #307 #308 #309 #310 #311 — each named as M7
work by a handoff that never gave it a number, each citing a `file:line`.

**Unchanged (1).** #151.

### Suggested order

1. **#91**, then **#88** — both create `lib/core/widgets/`
2. **#301**, **#302** — the two empty-state defects
3. **#304**, **#305**, **#307**, **#308** — independent, parallelisable
4. **#309**, then **#310** — the toggle cannot be honest without the query
5. **#89** — better last, once the screens that should report failures do
6. **#92**, **#311**, **#151** — platform work; **#92 is blocked on artwork**

---

## 4. Three invariants that were wrong in Epic #12

Worth stating separately, because an invariant is what a reviewer rejects a PR
against, and two of these would have caused a reviewer to reject correct code:

- *"Integration tests use real (ephemeral) Isar"* — Isar was removed in #197.
  The flows run on real **in-memory sembast**.
- *"`ScanOrchestrator` is mocked in the Keto Lens integration test"* — **it is
  not.** Exactly two seams are faked, both already interfaces in `lib/` and both
  at the plugin boundary: `PhotoPicker` (no `image_picker` channel headless) and
  `TextRecognitionService` (its desktop arm is `dart:ffi` against a system
  `libtesseract` CI does not install). The parser, classifier, orchestrator,
  sealed `ScanResult`, sheet, prefill and meal write are shipped code. The test
  is much stronger than the Epic claimed.
- *"CI workflow runs on `macos-latest` for iOS simulator support"* — it runs on
  `ubuntu-latest`. macOS runners cost **10× Actions minutes** and are reserved
  for the iOS and macOS *build* jobs, which are path-filtered and PR-only for
  that reason.

---

## 5. Corrections to `mvp_handoff.md`

That file directs whoever picks the project up next, so its stale lines matter
more than most. Three were corrected in place:

- It said **four** M7 issues were already done. It is **three** — #91 was
  genuinely partial, not done, and is now a rewritten refactor.
- It said `MealListSection` **and** `ElectrolytesCard` still use the
  loading-first `.when`. `MealListSection` was fixed, with a comment citing
  `m8_preflight.md` Part 10 defect 2. **`ElectrolytesCard` is the only one
  left**, and it is #302.
- Its "pick this up next" item 2 said to audit M7 and write
  `design/m7_preflight.md`. Done.

One correction to `m8_preflight.md` is recorded in `m7_preflight.md` rather
than applied: it locates the Android white-splash defect in
`drawable/launch_background.xml`, the file with the word "white" in it. On
API 21+ that file is **shadowed** by `drawable-v21/`, whose
`?android:colorBackground` resolves against the theme — so the cause is
`LaunchTheme`'s parent in `values/styles.xml`, and editing the obvious file
would change nothing on a device. #311 says so.

---

## 6. What was deliberately not filed

`milestone_conventions.md` §1 forbids adding scope to an open milestone, so the
audit's wider findings are recorded in `m7_preflight.md` §Deferred rather than
turned into issues. Two are worth naming here because they are larger than
polish and have no owner at all:

- **Accessibility.** Three `Semantics` in the whole of `lib/`; the 44 pt
  tap-target constant declared twice in two files that do not import each
  other; **zero** text-scaling handling on a dashboard already known to
  overflow at default scale; **zero** uses of `meetsGuideline` anywhere. It is
  not mentioned in a single design document. Worth 2–3 issues and a design
  decision.
- **Release APKs are signed with the debug key.**
  `android/app/build.gradle.kts:53-55` still carries Flutter's template TODO and
  `build-android.yml:135` acknowledges it. This blocks any real Android release
  and belongs with `epic:release-v1`.

---

## 7. Three issues filed by the owner mid-session

**#303, #306 and #312** were opened while this audit ran and were left
untouched. They are product statements rather than authored issues — no labels,
and #303 is on the M7 milestone without one.

**#303 "Fix streak problem"** is the one to read first: it specifies that the
streak should break above 50 g carbs and on a missed day, and that a
retroactive log should restore it. That is a **behaviour specification that
goes beyond what shipped**, and it overlaps #308 without being the same thing —
#308 is about *displaying* an expired grace period honestly, #303 is about what
breaks a streak in the first place. It needs authoring against
`design/issue_conventions.md` before it can be picked up, and the decision it
implies belongs to whoever owns the product rule.

---

## 8. If you pick this up next

1. **#98** — one flow, and M8 closes.
2. **M7, in the order in §3.** Nothing in it is blocked except #92, and #92 is
   blocked on a designer rather than on an engineer.
3. **Author #303, #306 and #312**, or close them into the issues that already
   cover them.
4. **Get it on a device.** Unchanged from `mvp_handoff.md`, and unchanged by
   anything in this session: there is no iOS device, no macOS host and no
   camera here. Epics #4 and #10 cannot close until someone runs it, and every
   iOS claim in every document remains inference.
