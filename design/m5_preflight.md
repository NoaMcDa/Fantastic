# M5 Pre-flight — corrections to the M5 issue text

Read this before picking up any M5 issue (#75–#78).

This is the fifth such file. `m0_handoff.md`, `m1_preflight.md`,
`m2_preflight.md` and `m3_preflight.md` each catalogued what their milestone's
issue text got wrong. `m3_handoff.md` closed with the same standing
instruction its predecessors did: *audit the next milestone's issues against
the shipped code before implementing, and write the preflight from what that
finds.*

That audit is done. **All four issues carry at least one defect.** Two would
compile and ship wrong behaviour; one of those loses user-entered data
silently.

M5's issues were written in the same sitting as M0's through M4's — before any
of it met a build, before Isar was replaced by sembast, and, most importantly
here, **before `SymptomLog` was designed**. They name a field the model does
not have, in a feature directory that does not exist, and they contradict
their own Epic in two places.

**The issues have not been rewritten.** This file is the correction layer.

Audited: **#75–#78, all four, in full, plus Epic #9.**

---

## Part 1 — Defects that compile and ship wrong behaviour

### 1.1 The fifth scale is **mood**, not brain fog — and the compiler only catches half of it

All four issues call the fifth symptom `brainFogScore` and label it
`ערפל מוחי` / `ערפל` (brain fog). The shipped model
(`lib/features/diary/domain/models/symptom_log.dart`) has:

```
energyScore  clarityScore  hungerScore  physicalScore  moodScore
```

`SymptomLog.brainFogScore` does not exist, so `log.brainFogScore` is a
compile error — that half is caught. **The half that is not caught is the
label.** The obvious repair is to rename the accessor and leave the Hebrew
copy alone, which ships a mood score under a brain-fog heading: the user rates
their mood 5 and the diary records `ערפל: 5` — brain fog at its worst.
`SymptomLogFixture` defaults every scale to 3, so no test catches the swap
either (`m1_handoff.md`'s standing warning about all-neutral fixtures).

This is not a new discovery. **M1's #33 was rewritten by #158 for precisely
this**, and its rewrite note says so:

> The original placed this under `lib/features/symptom_diary/`, a directory
> that does not exist, used relative imports, and **listed only four of the
> five symptom scales**.

M5's text never heard. The canonical five scales and their Hebrew labels come
from `ui_ux_design.md` §Symptoms Section and are the ones to use:

| Field | Hebrew | Issue text says |
|---|---|---|
| `energyScore` | אנרגיה | אנרגיה ✓ |
| `clarityScore` | ריכוז | צלילות / צלילות מחשבה |
| `hungerScore` | רעב | רעב ✓ |
| `physicalScore` | תסמינים פיזיים | גוף / תסמינים גופניים |
| `moodScore` | מצב רוח | **ערפל / ערפל מוחי — wrong scale** |

### 1.2 `.when(loading: …)` leaves a permanent placeholder on a failed read

#76 and #78 both render with

```dart
logAsync.when(
  loading: () => const SizedBox(height: 56),
  error: (_, __) => const SizedBox.shrink(),
  data: (log) => ...,
);
```

`m3_handoff.md` records the fact that cost M3 three issues: **riverpod 3
reports a provider that failed before ever producing a value as `AsyncLoading`
with an error attached** — `isLoading` and `hasError` are both true.
`AsyncValue.when` is written loading-first (verified in
`riverpod-3.0.3/lib/src/core/async_value.dart:250`):

```dart
if (isLoading) { ...; if (!skip) return loading(); }
if (hasError && (!hasValue || !skipError)) { return error(...); }
```

so the `error:` branch of both widgets is **dead code on a first-load
failure**, and the widget shows its loading placeholder for the life of the
screen. Check `hasError` before `isLoading`, as `StreakRingWidget` does, and
**make the failure test assert the loading indicator is absent** — otherwise
it passes with the bug present.

> Note for M7: `MealListSection` (M2) has the same latent shape. Its
> loading branch is a spinner and its error branch a Hebrew failure line, so
> a failed meal read spins forever instead of reporting. Out of M5's scope;
> recorded in the handoff's known gaps.

### 1.3 Saving an edit silently erases the user's note

`SymptomLog` has a `notes` field. #77's `_save` constructs a **fresh**
`SymptomLog` from the five sliders only:

```dart
final log = SymptomLog(date: widget.date, energyScore: _energy, ...);
```

No `notes`, no `id`. `SymptomLogRepository.save` is an upsert keyed on the
date, so this overwrites the stored record and the note the user typed
yesterday is gone — with no error, no warning, and nothing on screen that ever
showed the note in the first place.

Epic #9 scopes the note explicitly:

> `SymptomLogSheet` — full 1–5 scale for all 5 symptoms **+ note**

**The sheet gets a note field**, and an edit carries `existing.notes` and
`existing.id` through. Either alone fixes the data loss; both are correct.

### 1.4 #75's validation is unreachable in debug, and its two failure tests cannot be written as specified

#75 asks for `ArgumentError` when a score is outside 1–5, and requires two
tests: "Score of 0 → `ArgumentError` thrown", "Score of 6 → `ArgumentError`".

`SymptomLog`'s constructor already asserts every scale is 1–5. Tests run in
debug, where asserts are live, so `SymptomLog(energyScore: 0, …)` throws
`AssertionError` **at construction** — the service is never reached, and a
test expecting `ArgumentError` fails on the wrong exception before it ever
calls `logSymptoms`.

The validation is still worth having, for the reason the model itself
documents:

> Note that `assert` is compiled out in release builds — deliberate, since the
> scores come from a fixed 1–5 picker — so the data layer does not rely on
> these holding at runtime.

So the service check is the *release-build* enforcement of an invariant that
is only advisory in the model. To test it, the test constructs a subclass that
passes valid values to `super` and overrides one score getter — Dart permits
overriding a field with a getter, and it is the only way to produce the object
a release build could produce. Recorded here so the next reader does not think
the odd-looking test double is an accident.

This also settles the apparent conflict between #75 ("Validation at the
service boundary — domain models trust scores are valid") and Epic #9
("Score validation enforced in domain model constructor, not in UI"). **Both
hold.** The constructor is the authority; the service is the backstop for the
build where the constructor is silent. Neither is in the UI.

---

## Part 2 — Snippets that do not compile

### 2.1 riverpod 3 removed the generated `Ref` types

The same defect corrected in M1's #43, M2's #45/#47/#48 and M3's five
occurrences. M5 repeats it twice:

```dart
symptomLoggingService(SymptomLoggingServiceRef ref)   // #75 — WRONG
symptomLog(SymptomLogRef ref, DateTime date)          // #76 — WRONG
```

Both take a bare `Ref`.

### 2.2 `SymptomLog` cannot be constructed the way #77 constructs it

`moodScore` is `required`. #77's `_save` omits it (it passes `brainFogScore`,
§1.1), so the call does not compile even after the field is renamed unless the
name is corrected too.

### 2.3 `Slider` is `double`-valued; #77 wires it to `int`

`_SymptomSliderRow(value: _energy, onChanged: (v) => setState(() => _energy = v))`
with `late int _energy` and a `Slider(min: 1, max: 5, divisions: 4)` underneath
is a type error in both directions: `Slider.value` wants a `double`, and
`Slider.onChanged` hands back a `double` that cannot be assigned to an `int`.

Rather than papering over it with `.toDouble()` / `.round()`, **M5 uses a
segmented 1–5 button row instead of a `Slider`.** Five discrete values on a
44pt-minimum touch target (`CLAUDE.md` §UI) is what the design document
specifies — *"a 1–5 scale selector"*, not a slider — a slider's thumb is
smaller than 44pt, has no visible value, and is the hardest control to
operate one-handed in an app whose whole point is a five-second check-in.

### 2.4 Undeclared identifiers and missing imports

As in M3 §2.8. #76 references `SymptomLogSheet`, `symptomLogProvider`,
`showModalBottomSheet` and `SymptomLog` with no imports at all, and defines
`_SymptomIcon` nowhere. #78 references `SymptomLogSheet` and
`symptomLogProvider` with no imports. #77 defines `_SymptomSliderRow` nowhere.

---

## Part 3 — Things that do not exist

### 3.1 `lib/features/symptom_diary/`

Every file path in all four issues begins
`lib/features/symptom_diary/`. There is no such feature. `CLAUDE.md`'s feature
table assigns symptoms to the diary — *"Diary (meals, symptoms, biomarkers) —
`lib/features/diary/`"* — and that is where the model, the repository
interface, the mapper and the sembast implementation have lived since M1.
M1's #33 rewrite already corrected this exact path.

Corrected paths:

| Issue | Says | Actually |
|---|---|---|
| #75 | `lib/features/symptom_diary/application/symptom_logging_service.dart` | `lib/features/diary/application/symptom_logging_service.dart` |
| #76 | `lib/features/symptom_diary/application/providers/symptom_providers.dart` | `lib/features/diary/application/providers/symptom_providers.dart` |
| #76 | `lib/features/symptom_diary/presentation/widgets/symptom_check_in_strip.dart` | `lib/features/diary/presentation/widgets/symptom_check_in_strip.dart` |
| #77 | `…/symptom_log_sheet.dart` | `lib/features/diary/presentation/widgets/symptom_log_sheet.dart` |
| #78 | `…/symptom_diary_section.dart` | `lib/features/diary/presentation/widgets/symptom_diary_section.dart` |

### 3.2 `putByIndex`, and `IsarSymptomLogRepository` (#42)

#75 explains its upsert as "one-per-day via `putByIndex`" and #76 lists
`IsarSymptomLogRepository (#42)` as a blocker. Isar is gone — see
`design/web_support.md`. The shipped class is `SembastSymptomLogRepository`,
and the upsert is structural rather than index-driven: the record key **is**
`SymptomLogMapper.dateIndex(log.date)`, so a second record for a date is
impossible by construction.

### 3.3 `DiaryDayScreen` has no "placeholder comment"

#78 says it replaces "the placeholder comment in `DiaryDayScreen`". It is a
named private widget, `_SymptomsPlaceholder`, put there by M2 for exactly this
swap, with a doc comment saying so. Deleting the class and dropping
`SymptomDiarySection` into the same slot is a two-line change.
`diary_day_screen_test.dart` asserts on its copy (`'תסמינים — בקרוב'`) — that
assertion is updated, not deleted; the slot must still be asserted.

### 3.4 #75's stated dependency on M4

> **Why Now:** This is the first M5 issue. **All M4 issues must be closed.**

M5 has no dependency on M4, in either direction. Nothing in #75–#78 reads a
user profile, a macro target or an onboarding value. The two milestones are
being implemented concurrently.

---

## Part 4 — Where the issue text would regress shipped work

### 4.1 #77's `_save` has no failure handling

```dart
await ref.read(symptomLoggingServiceProvider).logSymptoms(log);
ref.invalidate(symptomLogProvider(widget.date));
if (mounted) Navigator.of(context).pop();
```

A `PersistenceException` from the repository propagates out of an unawaited
`onPressed` callback, the sheet stays open with no explanation, and — worse
in the ordering above — nothing tells the user the save failed.

M2 settled this. `AddMealBottomSheet._submit` holds `_saving` / `_saveError`,
catches `Object`, keeps the sheet open with the entered values intact and
shows `'השמירה נכשלה, נסו שוב'`, and its comment records why: *"Closing on
failure would discard the entry and tell the user it was saved."* The symptom
sheet follows the same shape. It also guards `mounted` **before**
`ref.invalidate`, not only before `pop` — using a disposed `WidgetRef` throws.

### 4.2 A provider that reads the repository directly, against a service the Epic asks for

#76's `symptomLogProvider` calls
`ref.watch(symptomLogRepositoryProvider).findByDate(date)`. `CLAUDE.md` §State
Management says *"No new provider calls the database directly — always through
a service"*, and Epic #9's scope line is `SymptomLoggingService` **(log,
fetch)** — a fetch #75 never specifies.

M2's `todaysMealsProvider` and `todaysDailyLogProvider` do read their
repositories directly, so there is precedent either way. **M5 goes through the
service**, because the Epic asks for the fetch by name and a two-method
service costs nothing: `symptomLogProvider` watches
`symptomLoggingServiceProvider` and calls `symptomsForDate(date)`. Widget tests
then override one provider rather than mocking a repository.

### 4.3 #78's bare `Column` in a screen of cards

`DiaryDayScreen` stacks `MacroSummaryCard`, `MealListSection` and a `Card`
placeholder. #78's snippet is an unwrapped `Column` with a `titleMedium`
heading, which would land as the one section on the screen with no surface
behind it. Wrapped in a `Card` to match — cosmetic, but it is a visible
regression against a screen that currently looks finished.

---

## Part 5 — Contradictions, stale references and copy

### 5.1 Epic #9 requires a pre-focused sheet; #76 explicitly refuses it

Epic #9's Definition of Done:

> Tapping a strip icon opens the correct **pre-focused** sheet

#76's Logic / Behaviour:

> Any icon tap opens the full `SymptomLogSheet` (issue #77) **regardless of
> which symptom was tapped**.

The Epic is the standard an Epic is closed against (`milestone_conventions.md`
§2), so **the Epic wins**: the strip passes the tapped scale to the sheet, and
the sheet marks that row. Implemented as a `SymptomScale` enum shared by the
strip, the sheet and the diary section — one place that knows the five scales,
their Hebrew labels, their icons and how to read each from a `SymptomLog`,
rather than five parallel hand-maintained lists across three widgets (the
mistake §1.1 is made of).

### 5.2 Four scales or five on the dashboard strip

`ui_ux_design.md` §Quick Symptom Check-In Strip lists four —
"energy, hunger, clarity, mood". Its §Symptoms Section lists five. #76 says
five. **Five**, everywhere: the model has five, and a strip that omits
`physicalScore` would make it unreachable from the dashboard.

### 5.3 "Horizontal scrollable row" is an RTL trap, and unnecessary here

`ui_ux_design.md` specifies a horizontal scrollable row.
`m2_handoff.md` warns that a horizontal `ListView` in RTL **already starts at
the right**, and that reversing it or seeding a scroll offset to "fix" that is
how a list ends up backwards. Five items fit a 320pt screen if each is an
`Expanded` cell, so **M5 uses a non-scrolling `Row`** and the trap does not
arise. Recorded rather than silently deviating.

### 5.4 Empty-state copy

`ui_ux_design.md`: `"לא הוקלטו תסמינים להיום"` with a ＋ button. #78:
`'+ רשום תסמינים'`. The design document's line says what happened; the
issue's says what to do. **Both**: the design line as the empty-state text,
the issue's as the button under it. Note the design copy says *"today"* on a
screen that renders any past day — so the text drops `להיום`:
`'לא הוקלטו תסמינים'`.

### 5.5 Digit runs

Every score rendered as a bare numeral (`אנרגיה: 4`, the strip's dots, the
sheet's selected value) is a digit run inside an RTL layout and needs
`textDirection: TextDirection.ltr` — `m3_handoff.md` convention 6. A
single-digit score cannot visibly reverse, but a `1–5` range label or a
`4/5` pair can, and the rule is applied uniformly rather than case by case.

### 5.6 Build order: #77 comes before #76, not after

#77 lists #76 as a blocker and #76 lists #77's sheet as its tap target — a
cycle as written. The real dependency runs one way: the sheet needs the
service and the provider; the strip needs the sheet.

**Build order: #75 → #77 → #76 → #78.**

---

## Part 6 — What M5 must code against

The shipped API, so no issue has to guess.

```dart
// lib/features/diary/domain/models/symptom_log.dart
SymptomLog({required DateTime date,
            required int energyScore, required int clarityScore,
            required int hungerScore, required int physicalScore,
            required int moodScore,
            int? id, String? notes});        // asserts every score is 1–5
SymptomLog copyWith({id, date, energyScore, clarityScore, hungerScore,
                     physicalScore, moodScore, notes});
// NOTE: copyWith cannot clear `notes` — `notes ?? this.notes`. Same shape as
// StreakState's trap (m3_preflight §1.1), without the escape flag. Nothing in
// M5 needs to clear a note; if something later does, it needs the flag.

// lib/features/diary/domain/repositories/symptom_log_repository.dart
Future<SymptomLog>       save(SymptomLog log);   // upsert keyed on the date
Future<SymptomLog?>      findByDate(DateTime date);
Future<List<SymptomLog>> findAll();              // newest first
Future<void>             deleteByDate(DateTime date);

// lib/features/diary/data/providers.dart
symptomLogRepositoryProvider   // returns the interface, already wired

// test/fixtures/symptom_log_fixture.dart
SymptomLogFixture.fixture({id, date, energyScore = 3, clarityScore = 3,
                           hungerScore = 3, physicalScore = 3,
                           moodScore = 3, notes});
SymptomLogFixture.worstDay()   // all 1, notes: 'keto flu'
SymptomLogFixture.bestDay()    // all 5
```

`SymptomLogFixture` defaults **every scale to 3**. A widget that reads
`energyScore` where it means `moodScore` passes every test written against the
default fixture. **Use `fixture(energyScore: 1, clarityScore: 2,
hungerScore: 3, physicalScore: 4, moodScore: 5)` in any test that asserts a
score reaches the right place** — `m1_handoff.md`'s warning, and §1.1 is
exactly the bug it predicts.

Waiting hooks:

- `DiaryDayScreen` renders `_SymptomsPlaceholder` in the slot #78 fills.
- `DashboardScreen` builds a `SliverChildListDelegate`; #76's strip goes after
  `MealListSection`, before `ElectrolytesCard`.
- `pumpApp` (`test/helpers/pump_app.dart`) supplies the RTL `Directionality`,
  the dark theme, a `Scaffold` and a `ProviderScope`. A modal sheet opened in
  a test needs it — `showModalBottomSheet` outside a `ProviderScope` cannot
  build a `ConsumerWidget`.

---

## Summary — before starting M5

1. **The fifth scale is `moodScore` — מצב רוח.** Not brain fog, in the field
   name *or* the label (§1.1).
2. **Everything lives in `lib/features/diary/`**, not `symptom_diary` (§3.1).
3. **Check `hasError` before `isLoading`**, never `.when(loading:…)` on a
   provider whose failure must be visible (§1.2).
4. **Carry `notes` and `id` through an edit** (§1.3).
5. **Build order #75 → #77 → #76 → #78** (§5.6).
6. `flutter analyze` catches §2 and nothing else. CI catches §2 and nothing
   else. Only a test written against the corrected behaviour catches §1.
