# M5 Handoff — Symptom Diary

M5 is code-complete. All four issues (#75–#78) are merged, CI is green on
`main`, and the feature was **driven end to end in a real browser** — the
check M3 introduced as part of closing a milestone.

M5 is the smallest milestone in the MVP: one service, one enum, three widgets.
This file records what it shipped, what the pre-flight audit found, and the
handful of things M6 and M7 inherit.

---

## What shipped

| Issue | What |
|---|---|
| #75 | `SymptomLoggingService` — validated upsert plus the day's fetch; `symptomLogProvider(date)` |
| #77 | `SymptomLogSheet` — five 1–5 selectors, a note, and a save that survives failing |
| #76 | `SymptomCheckInStrip` — the dashboard's five-cell check-in |
| #78 | `SymptomDiarySection` — the diary's read-only record, filling M2's reserved slot |

Plus `SymptomScale` — the enum all three widgets iterate — and
`SymptomLogFixture.varied()`.

**804 tests. `domain/` 100%, `application/` 100% line coverage**, excluding
generated files. Every M5 source file is at 100%.

---

## Verified in a browser, not only in tests

Built with the CI flags, served locally, driven with Chromium at 430×900.
What the run actually proved:

- The strip paints on the dashboard with all five Hebrew labels —
  **אנרגיה / ריכוז / רעב / גוף / מצב רוח** — and **no `ערפל` anywhere in the
  app**. **No console errors at all**, on any screen, at any point.
- Tapping the מצב רוח cell opened the sheet **with the mood row highlighted**,
  which is Epic #9's "pre-focused sheet".
- Scoring the five rows 1, 2, 3, 4, 5 top to bottom and saving left the strip
  reading `אנרגיה 1 · ריכוז 2 · רעב 3 · גוף 4 · מצב רוח 5`. **Each score
  landed in its own scale** — the one thing no fixture-based test could have
  told us on its own, because `SymptomLogFixture` defaults every scale to 3.
- **It still read the same after a full page reload.** That is the only proof
  the record reached IndexedDB rather than living in the tab.
- The diary tab showed the five chips with their own values, the note
  `כאב ראש קל` rendered back, and an `עריכה` button.
- **Selecting the previous day showed `לא הוקלטו תסמינים`, and selecting
  today brought the note back.** The per-date keying is real, not just
  asserted.

A screenshot of the sheet, the strip and the diary section is what caught the
one piece of polish below.

---

## What the pre-flight audit found

`design/m5_preflight.md` (#235) audited all four issues before a line was
written. All four carried at least one defect; two would have compiled and
shipped wrong behaviour. The three worth remembering:

**1. Every issue named a field the model does not have — and the compiler
only catches half of that.** All four called the fifth scale `brainFogScore`
and labelled it `ערפל מוחי`. The shipped field is `moodScore`. The accessor is
a compile error; **the label is not**, so the obvious repair ships a mood
score under a brain-fog heading, and `SymptomLogFixture`'s all-3s defaults
mean no test notices. M1's #33 was rewritten by #158 for this exact mistake
and M5's text never heard.

**2. `.when(loading:)` is a permanent placeholder on a failed read.** Both
widget issues used it. `AsyncValue.when` is written loading-first
(`riverpod-3.0.3/lib/src/core/async_value.dart:250`) and riverpod 3 reports a
provider that failed before producing a value as `AsyncLoading` *with* an
error, so the `error:` branch is dead code. This is the same fact that cost M3
three issues, arriving in a third disguise.

**3. The sheet silently erased the user's note.** #77 rebuilt the log from
five sliders with no `notes` and no `id`, and `save` upserts on the date. No
error, no warning, and nothing on screen had ever shown the note.

Also found: `#75`'s two failure-path tests cannot be written as specified (the
domain constructor asserts before the service is reached); `Slider` is
`double`-valued and #77 wired it to `int`; the feature directory
`lib/features/symptom_diary/` has never existed; and Epic #9 requires a
pre-focused sheet that #76's text explicitly refuses.

---

## Conventions M6 and M7 inherit

1. **The five scales live in one enum.** `SymptomScale`
   (`lib/features/diary/presentation/symptom_scale.dart`) owns the label, the
   short label, the icon, and `scoreIn(log)`; `buildSymptomLog` is the mirror
   write path. Nothing reads `log.energyScore` directly in presentation. This
   is not tidying — the issue text's fifth-scale mistake is only writable
   where each widget keeps its own list, and a round-trip test between the two
   directions is what keeps them honest.
2. **`hasError` before `isLoading`, every time**, and **the failure test
   asserts the loading indicator is absent**. Inherited from M3 and now
   applied in three more widgets. `AsyncValue.when` is banned wherever a
   failure has to be visible.
3. **A failed read and an empty day must not look alike.** Both M5 widgets say
   which one it is. They mean opposite things.
4. **A failed read does not block the write.** The strip stays tappable when
   the fetch failed: logging the day is still the most useful thing available.
5. **A save sheet catches, stays open, keeps the input, and says so** —
   `AddMealBottomSheet`'s shape from M2, now in a second sheet. `mounted`
   guards `ref.invalidate` as well as `Navigator.pop`; a disposed `WidgetRef`
   throws.
6. **Use `SymptomLogFixture.varied()` (1/2/3/4/5) in any test that asserts a
   value reaches the right place**, and assert against what is *painted* — the
   strip test counts filled dots rather than reading the provider's value. A
   widget wired to the wrong field passes the second kind of assertion.
7. **Digit runs still need `TextDirection.ltr`.** M3's convention 6, applied
   to every score.
8. **Five items in a row beat a horizontal scroller.** `Expanded` cells fit
   320pt, and the RTL scroll trap `m2_handoff.md` records never arises.

---

## Gotchas worth keeping

- **`AsyncValue.when` is loading-first.** Worth stating as its own fact rather
  than as a corollary: `when` cannot express "show the error even though a
  reload is in flight" without `skipLoadingOnReload`, and for a *first* load
  it cannot express it at all. Read the flags.
- **`SymptomLog.copyWith` cannot clear `notes`** (`notes ?? this.notes`) — the
  same shape as `StreakState`'s trap (`m3_preflight.md` §1.1) without the
  escape flag. Nothing in M5 needs it: the sheet builds a fresh log through
  `buildSymptomLog`, so an emptied note stores as `null` correctly. Anything
  later that clears a note through `copyWith` needs the flag first.
- **A sliver child below the fold has no element at all.** #76's strip pushed
  `ElectrolytesCard` past the fold of the default 800×600 test window and four
  dashboard tests started failing with "Found 0 widgets".
  `skipOffstage: false` does not help — the element was never created. The fix
  is to scroll (`dashboard_screen_test.dart`'s `revealElectrolytes`).
- **A widget test that pops the sheet needs a real modal route.** Pumping the
  sheet directly and then popping removes the root route. `AddMealBottomSheet`
  settled this in M2; the dismissal test opens through `.show`.
- **`verify` consumes the recorded calls.** M3's note, hit again: the
  retry-after-failure test saves twice, so the capture helper takes `.last`,
  not `.single`.
- **A synchronous throw from a `Future`-returning method needs
  `expect(() => …)`, not `expectLater(future, …)`.** `logSymptoms` validates
  before it builds the future — deliberately, so a rejected log never reaches
  the store — which means the call throws rather than returning a rejected
  future.
- **Flutter web's RTL semantics rectangles are offset from the real viewport**
  — the tab bar reports x = 344…774 inside a 430px window. Coordinate clicks
  miss. `flt-semantics` nodes are real DOM elements and Flutter listens for
  `click` on them, so `element.click()` from `page.evaluate` works and
  `page.mouse.click(x, y)` does not. This cost the first browser run.
- **`browser.newContext()` is a fresh IndexedDB.** A "the data vanished"
  result between two playwright runs is the profile, not the app.

---

## Where validation actually lives

Worth writing down because two documents appear to disagree and do not.

- **`SymptomLog`'s constructor asserts every score is 1–5.** It is the
  authority, and Epic #9's invariant ("enforced in domain model constructor,
  not in UI") is about this.
- **`SymptomLoggingService` throws `ArgumentError` for the same range.** Not
  redundant: asserts are compiled out in release, and the model's own doc
  comment says the data layer must not rely on them holding at runtime. The
  service is that runtime guarantee.
- **In debug the service check is unreachable**, so its tests construct a
  subclass that overrides one score getter. That is the only way to produce
  the object a release build can produce, and the odd-looking test double in
  `symptom_logging_service_test.dart` is deliberate.
- **The UI cannot produce an out-of-range score at all** — the selector
  renders exactly `minScore`…`maxScore` buttons, and a test asserts those
  bounds match the model's.

---

## Epic #9's Definition of Done: met

Unlike Epic #7, every item holds and **Epic #9 is closed**.

- All four child issues closed, all four PRs merged, CI green.
- `flutter analyze` — zero issues. `flutter test` — 804 passing.
- **"Tapping a strip icon opens the correct pre-focused sheet."** Implemented
  against the Epic rather than against #76's text, which refuses it, and
  confirmed in the browser.
- **"Saved symptoms appear in diary view for the correct date."** Confirmed in
  the browser, including that the previous day shows its own empty state.
- Architectural invariants: the service depends only on the repository
  interface, and validation is in the domain constructor, not the UI.
- Scope: the note Epic #9 asks for (`+ note`) is implemented, displayed and
  editable, though #77's own text omitted it. The fetch half of
  "`SymptomLoggingService` (log, fetch)" is implemented, though #75's own text
  omitted that too.

---

## Known gaps M6, M7 and v1.1 inherit

- **A logged day cannot be un-logged.** `SymptomLogRepository.deleteByDate`
  exists and is contract-tested, and nothing calls it. The sheet can only
  overwrite. Deliberate for the MVP — an accidental delete of a five-second
  entry is worse than a wrong score you can re-tap — but it means the
  repository method joins `EntityNotFoundException` and
  `SymptomLogRepository.findAll` on the list of tested code with no caller.
- **`findAll` has no caller either.** It exists for the symptom trend charts
  Epic #9 puts in post-MVP.
- **There is no symptom check-in reminder.** `ui_ux_design.md` §Notifications
  lists one; M3 shipped only the 20:00 streak reminder, and nothing in
  #75–#78 asked for a second. Worth its own issue, and it inherits M3's
  standing blocker: notification delivery is unverifiable here, and every
  notification call is a no-op on web.
- **The unselected score buttons are low-contrast on the dark palette.**
  `surfaceContainerHighest` sits very close to the sheet's own surface, so the
  1–5 row reads as five numbers rather than five buttons until one is
  selected. Legible, but it under-signals that they are tappable. M7 polish —
  the browser screenshot is what showed it; no test could.
- **Two M2 widgets still have the §1.2 bug M5's widgets were corrected for.**
  `MealListSection`'s `.when` is loading-first, so a failed meal read spins
  forever instead of showing `לא ניתן לטעון את הארוחות` — visible, and the
  one worth fixing. `ElectrolytesCard` has the same shape, but both its
  branches are `SizedBox.shrink()`, so today the bug has no visible effect;
  it becomes one the moment either branch grows content. Out of M5's scope,
  a line each, and best fixed with eyes on the whole codebase — M7.
- **`ElectrolytesCard` renders nothing at all on a day with no `DailyLog`.**
  Noticed during the browser run and initially mistaken for an M5 regression:
  it is M2's deliberate behaviour (`log == null → SizedBox.shrink()`). It does
  mean a brand-new user's dashboard has no electrolyte guidance on the day
  they most need it — induction, before their first meal is logged. Worth a
  look in M7 alongside M2's standing gap that water and electrolytes have no
  logging flow.
- **Water and electrolytes still have no logging flow**, and **macro targets
  are still the `KetoConstants` defaults**, both inherited from M2 and both
  untouched by M5.
- **The dashboard is getting long.** Macro card, ring, badge, meal list,
  symptom strip, electrolytes — six sections, and the strip pushed the last
  one off a 600pt test viewport. Nothing is broken, but the next addition
  should ask whether the dashboard is still the right home for it.

---

## Next

M5 was the last of the two small milestones. M6 (Keto Lens, #79–#87) and M4
(Onboarding, #69–#74) were in flight alongside this one; M7 (#88–#94) picks up
the polish items above.

**Write the pre-flight first, whichever comes next.** Five milestones, five
audits, and every one has found at least one defect per issue that the
toolchain cannot catch. M5's four issues were the smallest set yet and still
carried a silent data-loss bug and a field that does not exist.
