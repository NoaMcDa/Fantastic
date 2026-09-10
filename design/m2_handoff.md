# M2 Handoff — the app became usable

> **Superseded in part:** Isar was replaced by **sembast + sembast_web** when web
> support landed — see `design/web_support.md` and `CLAUDE.md` §Local Persistence.
> Everything below is kept as a record of what was true at the time and is not a
> description of the current data layer.

State of M2 as of 2026-09-10, after every issue shipped. Read
`design/m2_preflight.md` for the corrections its issue text needed; this file
records what building it actually taught, and what M3 inherits.

## Status — M2 is merged and closed

All thirteen issues (#44–#56) are closed and all fourteen PRs (#180–#184,
#186–#194) are merged. `main` is green: `dart format`, `flutter analyze` and
`flutter test` all pass in CI.

| Group | Issues | PRs |
|---|---|---|
| Services | #44 `KetoRatioCalculator`, #46 `ElectrolyteAdvisor`, #45 `MealLoggingService` | #180, #181, #182 |
| Date-keyed providers | #47 `todaysDailyLog`, #48 `todaysMeals` | #183, #184 |
| Widgets | #54 empty state, #50 macro card, #51 meal list, #52 electrolytes, #53 add-meal sheet | #186–#190 |
| Screens | #49 dashboard, #56 diary day, #55 diary | #191, #192, #193 |

**482 tests**, up from 316 at the end of M1.

**This is the first milestone the user can actually use.** The FAB opens a form,
saving logs a meal, and the macro bars, meal list and electrolyte gauges all
refresh from it. The dashboard and diary tabs are real screens rather than
placeholders — `DashboardPlaceholder` and `DiaryPlaceholder` are no longer routed.

### Coverage at closure

Measured on `main` (CI has no coverage step — `cicd_plan.md` puts it in Phase 2):

| Scope | Lines | |
|---|---|---|
| `domain/` | 155/155 | 100.0% |
| `application/` | 123/134 | 91.8% |
| **Gate: `domain/` + `application/`** | **278/289** | **96.2%** |
| Whole project | 980/1013 | 96.7% |

No hand-written file in either layer is below 80%. The only sub-80% files are
generated `.g.dart` provider shims.

---

## Conventions M2 established

M3 inherits these. They are not restated in its issue text.

1. **`test/helpers/pump_app.dart` is the widget-test harness.** It wraps the
   widget in the RTL `Directionality`, the dark theme and a `ProviderScope` with
   overrides — the same shell `FantasticApp` gives it at runtime. Pumping a bare
   widget instead tests it under Flutter's LTR light-theme defaults, so an
   RTL-only layout bug or a colour that vanishes on the dark palette passes and
   then fails on device.
2. **A date-keyed family provider must be given a date-only value held in state.**
   `todaysDailyLogProvider` and `todaysMealsProvider` normalise internally, which
   fixes the *query* but not the *cache key* — the family is keyed on the argument
   as given. `provider(DateTime.now())` called in a `build` method allocates a
   fresh provider every frame and refetches forever. Screens resolve one
   midnight-stripped date once (`late final DateTime _date = ...`) and pass it down.
3. **A widget takes what it needs as a parameter, not as a provider it cannot be
   tested without.** `ElectrolytesCard` takes `phase` with a default rather than
   hardcoding `AdaptationPhase.induction` inside `build`; M3 passes the real phase
   in one line, and the card is testable across phases today.
4. **Every public declaration in a file counts, including the `@riverpod` function.**
   Three services shipped with the service tested and its provider not; the
   provider-resolution test is part of the pattern, not an extra.
5. **A failed read is not an empty state.** `MacroSummaryCard` and
   `MealListSection` say the load failed rather than rendering nothing or falling
   through to "no meals logged" — the latter tells the user something false that
   they then act on.

---

## RTL is where the time went

Both of these produce code that looks right, compiles, and behaves backwards.

**A horizontal `ListView` already starts at the right edge under RTL.** #55's
snippet sets `reverse: true` to "put today on the right"; in RTL that moves it to
the left. No `reverse` is correct.

**`DismissDirection.endToStart` travels *rightward* in RTL.** Start is the right
edge, so an end-to-start dismissal is a positive-dx drag. A test dragging the
LTR direction silently asserts nothing — it neither dismisses nor fails
informatively. `meal_list_section_test.dart` names its offsets
`dismissSwipe`/`oppositeSwipe` with the reasoning attached for this reason.

**Reveal side follows from that too.** An `endToStart` dismissal slides the row
toward the start, so the background is revealed at the **end** — the left in RTL.
Use `AlignmentDirectional`/`EdgeInsetsDirectional`, never `Alignment.centerRight`.

**Digit runs need an explicit `TextDirection.ltr`.** `120/150` and `19:30` get
reordered inside an RTL layout otherwise.

---

## Flutter and riverpod gotchas

**`Dismissible` asserts its dismissed child leaves the tree immediately**, but
deleting is asynchronous — the delete and the refetch both have to finish before
the provider's list stops containing the row, and the widget rebuilds long before
that. The issue's snippet throws *"A dismissed Dismissible widget is still part of
the tree"* on the very next build. `MealListSection` keeps a `Set<int>` of
dismissed ids and filters them out, pruning each once the refetch confirms it —
which also stops the row flashing back mid-refetch.

**`AnimatedCrossFade` keeps both children mounted.** A collapsed child still
matches `find.text(...)`. Assert with `.hitTestable()`, or the test passes for the
wrong reason in one direction and fails in the other.

**`Override` is not exported by `flutter_riverpod` 3.0.3**, even though
`ProviderScope.overrides` is typed `List<Override>`. `riverpod_annotation` exports
it and is already a direct dependency — that is why `pump_app.dart` imports it.

**`.future` on an errored auto-disposing provider never settles.** Testing a
provider's error branch by awaiting `.future` hangs until the container is torn
down and then reports *"disposed during loading state"*, masking the real error.
Assert on the `AsyncValue` the UI consumes, or cover the throw where it
originates.

**Dart forbids a named parameter starting with `_`.** A `required Foo foo` +
`_foo` field pairing cannot use an initializing formal and trips
`prefer_initializing_formals`. `MealLoggingService`'s injected collaborators are
public for this reason.

**`double.tryParse` accepts `Infinity` and `NaN`**, and neither is `< 0`. Any
numeric form validator needs `isNaN`/`isInfinite` checks explicitly, or the value
reaches the totals and poisons every figure derived from them.

---

## Known gaps M3 and M4 inherit

- **`ElectrolytesCard` defaults to `AdaptationPhase.induction`.** M3's
  `currentPhaseProvider` (#59) should be passed in at the call site in
  `DashboardScreen` — a one-line change, no edit to the card. Induction is the
  safe default meanwhile: highest targets, so it over-warns rather than
  under-warns.
- **Macro targets are the `KetoConstants` defaults.** M4's onboarding persists
  per-user targets; `MacroSummaryCard` reads the constants until then.
- **The streak ring slot is empty.** `DashboardScreen` has a comment where M3's
  `StreakRingWidget` (#63) goes, between the macro card and the meal list.
- **`DiaryDayScreen`'s symptom slot is a named placeholder widget**, so M5 (#75–#78)
  swaps it without touching the screen's layout.
- **`EntityNotFoundException` still has no throw site** (from M1, #177). M2 did not
  need one either.
- **Water and electrolytes have no logging flow.** `MealLoggingService` deliberately
  preserves them across recalculation, but nothing writes them yet, so the
  electrolyte gauges read zero in practice.

---

## Known blocker

**`flutter run` on an iOS simulator has never been verified** — no macOS host in
this environment. This matters more after M2 than any milestone before it: M2's
deliverable is screens, and no widget test tells you how they look on a device.
Epic #4 remains open on this alone.

---

## Next: M3 (#57–#68)

**No `m3_preflight.md` exists yet.** M1 and M2 each got one because their issue
text was audited first and found wrong — every M2 issue that was audited carried
at least one defect, and three would have compiled and shipped incorrect
behaviour. Audit M3's twelve issues against the shipped code before implementing,
and write the preflight from what that finds.

Two things to check first, since M2 already knows the answers:

- **`StreakRepository.watch()` exists and emits immediately** (`fireImmediately:
  true`). #59's `streakStateProvider` is specified as a stream watching it.
- **`AdaptationPhase` is stored by `.name`, not by ordinal.** This paragraph
  originally said ordinal, via a mirror enum — that was true under Isar. The
  sembast migration changed it, because a stored ordinal silently reinterprets
  every existing record the day a value is inserted mid-enum. `StreakStateMapper`
  writes `.name`; renaming a value is what would orphan stored records, and
  reordering is safe. See `design/m3_preflight.md` §5.4.
