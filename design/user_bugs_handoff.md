# First user bug reports — handoff

The first two defects reported by someone actually *using* the app rather than
auditing it, and what they exposed about a suite that was green while both were
live.

Both reports were correct. Neither was a misunderstanding of the UI, and
neither was caught by 1220 passing tests, a 99.58% coverage gate, ten e2e
flows, or six per-platform build jobs.

| # | Report | Root cause | PR |
|---|---|---|---|
| 1 | "I cannot add meal yet — there's no plus button" | The Diary tab had no add-meal affordance at all | [#295](https://github.com/NoaMcDa/Fantastic/pull/295) |
| 2 | "The scan didn't read the labels although I gave it a good picture" | Four independent engine-configuration defects | [#297](https://github.com/NoaMcDa/Fantastic/pull/297) |

---

## Bug 1 — the diary tab could not log a meal

### What was wrong

`DiaryScreen` — the tab a user opens to work on a **day** — had no add-meal
affordance. Its empty state read:

```
לא נרשמו ארוחות להיום
הקש על + כדי להוסיף ארוחה
```

*Tap + to add a meal.* The only `+` on that screen was
`log_symptoms_button`, which logs **symptoms**. The app instructed the user to
tap a button it did not provide.

`AddMealBottomSheet.show` had exactly two call sites in the whole app —
`dashboard_screen.dart` and the Keto Lens scan sheet. The sheet's own doc
comment had always described its `date` parameter as *"today from the
dashboard, the selected day from the diary"*. The diary caller was designed in
M2 and never built.

### What was NOT wrong, and why that mattered

The dashboard FAB was fine: unconditional, outside every `AsyncValue`,
unchanged since #49. This was not assumed — the release build was run on both
targets this project has ever run (Linux under Xvfb, web in headless
Chromium) and the gold `+` was observed rendering correctly on each. The
more serious hypothesis — a FAB present in source but clipped, off-screen or
behind the nav bar at real window geometry — was explicitly checked and ruled
out before any code changed.

That distinction decided the fix. Had the dashboard FAB been broken, adding a
diary FAB would have papered over it.

### What shipped

- **`AddMealFab`** (`lib/features/diary/presentation/widgets/add_meal_fab.dart`)
  — one widget, used by both screens, so the places a meal can be logged from
  cannot drift apart again. It owns no state and reads no provider.
- Its accent colour is **stated, not inherited**. It renders gold today only
  because `ColorScheme.dark`'s `primaryContainer` falls back to `primary`,
  which `AppTheme` happens to set to the accent, and the M3 FAB default reads
  `primaryContainer`. The one control the whole tracker depends on should not
  lose its contrast to an unrelated colour-scheme change.
- **`AddMealFab.bodyClearance`** — a FAB floats *over* the body rather than
  displacing it, so every host has to clear it by hand. The constant lives
  next to the button whose height it derives from.
- **Distinct keys per host**: `add_meal_fab` on the dashboard,
  `add_meal_fab_diary` on the diary. The tab shell keeps the outgoing screen
  mounted during a transition, so a shared key matches twice mid-transition
  and makes any cross-tab finder ambiguous — an ambiguous finder is a test
  that looks like it passes.

### The second defect underneath it

`MealListSection` used a loading-first `AsyncValue.when`, so over a dead store
it **spun forever** while two sibling sections reported the failure correctly
(`design/m8_preflight.md` Part 10 defect 2, now closed). It sits under both
add-meal entry points, so the affordance being reachable in the error state
depended on it.

The fix is the rule M3 and M5 already recorded and this code had not adopted:
**`hasError` before `hasValue`**, because riverpod 3's retry state is an
`AsyncLoading` *carrying* an error.

Worth knowing for the next such test: the first attempt at the regression test
**passed against the unfixed code**, because `AsyncValue.when` defaults
`skipLoadingOnRefresh: true`, so an `invalidate`-driven reload renders the
error anyway. The state that actually breaks it is the one
`ProviderElement.triggerRetry` produces, where `isReloading` is true and
`skipLoadingOnReload` defaults to `false`. A test that arms riverpod's real
retry is the only one that proves anything here.

---

## Bug 2 — the scan read nothing

Full engine detail is in `design/m6_platform_handoff.md`
§"The scan that read nothing" and §"Engine output is not stable across
Tesseract versions". Summary only here.

**The pipeline was innocent.** `HebrewLabelParser`, `HebrewTextNormaliser`,
`IngredientClassifier` and `ScanOrchestrator` all behaved correctly: with no
macros and no ingredients, the orchestrator refused to invent a verdict and
returned `ScanFailed(notALabel)`. The sealed result did exactly its job.

Four independent causes in the engine configuration the three adapters share.
**Fixing any three still failed:**

1. `psm 6` flattens a bordered two-column table — six of nine rows lost.
2. The Hebrew model cannot read an isolated column of Latin digits: `heb`
   alone returned 218/9/2/43/9/308 where the label printed
   238/10.9/41.2/7/3.3/368.
3. Tesseract *estimated* 631 dpi on a file declaring none and downscaled
   internally on the guess.
4. **Colour input drops every digit.** At identical size and interpolation:
   RGBA 0/6 values, RGB with alpha flattened 0/6, single-channel greyscale
   6/6. Flattening alpha is not enough — the buffer must genuinely be one
   channel.

Then macOS CI found a fifth, of a different kind: Tesseract **5.5.3** reads
`חזלבונים` where **5.3.4** reads `חלבונים`, so protein was silently lost on a
Mac while every other macro looked right. `HebrewLabelParser` now absorbs one
corrupted letter per keyword, narrowly bounded so it cannot mis-assign a row.

That change surfaced a **pre-existing defect nobody reported**: real labels
print `טראנס` and the disqualifier matched only `טרנס`, so the trans-fat row
was never actually excluded from total fat — only line order was keeping it
out.

---

## What these reports proved about the test suite

The suite was green while both bugs were live. Three distinct blind spots, all
now closed:

1. **The e2e suite asserted the affordance it knew about.** `meal_logging_flow`
   tapped `add_meal_fab` on Home and never asked whether a meal could be logged
   from the Diary tab. An entire tab shipped with no add affordance and a green
   suite. *A flow that exercises one route to a capability is not a test that
   the capability is reachable.*

2. **A test skipped exactly where the bug lived.**
   `tesseract_ffi_recognizer_test` skips when libtesseract is absent, which is
   CI — so a green run proved nothing about the native OCR path, and a
   regression that dropped every digit off a label would have merged unnoticed.
   The skip now prints a loud banner, and `scaling_text_recognizer_test` is the
   pure-Dart companion that asserts the prepared *buffer* with no engine at
   all.

3. **The fixture recorded a pipeline that does not exist.**
   `tool/capture_ocr_fixtures.sh` resized with Pillow/LANCZOS while the app
   resizes with `package:image`, so the committed fixture held an *easier*
   image than the app actually submits — hiding a spurious character that
   silently dropped protein. The script now shells out to
   `tool/prepare_for_ocr.dart`, which **is** the app's own `prepare()`.

---

## Conventions inherited

1. **Never write an add-meal FAB inline.** Use `AddMealFab`, and clear a
   scrolling body with `AddMealFab.bodyClearance`.
2. **Give each host screen its own FAB key.** The tab shell keeps the outgoing
   screen mounted; a shared key makes cross-tab finders ambiguous.
3. **An empty state that names an affordance must be on a screen that has it.**
   Both empty states said "tap +"; only one screen had a +. When you write
   copy that points at a control, assert the control is there.
4. **The only way to log a meal must not sit behind a provider's async state.**
   There are tests for the dashboard FAB with every read *failed* and every
   read *in flight*.
5. **`hasError` before `hasValue`** — riverpod 3's retry state is an
   `AsyncLoading` carrying an error. A test that proves this must arm the real
   retry, not call `invalidate`.
6. **Never assert on raw OCR text — assert what the pipeline parsed.** Engine
   output differs by Tesseract version; parsed macros are stable and are what
   the user depends on.
7. **A test that skips where the bug lives must say so loudly.** A silent skip
   reads identically to a pass.
8. **A tool that generates a fixture must call the app's own code path**, or
   the fixture certifies a pipeline that does not ship.

---

## What is verified

- Both PRs green on all seven checks: the `verify` gate, `e2e flows`, and all
  six per-platform builds. 1249 tests, coverage 498/499 = 99.80%.
- The dashboard `+` renders on Linux and web — observed, not inferred.
- The diary `+` is covered by widget tests on an empty day, against today and
  against a selected past day, and asserted not to reuse the dashboard key.
- **The fixed diary tab was driven in a browser**, not just unit-tested: a web
  release build of `main` was run through a genuine first launch (empty
  IndexedDB, full onboarding) in headless Chromium, and the `+` renders
  bottom-left above the nav bar — the correct corner under RTL — and opens the
  `הוספת ארוחה` sheet when tapped. This closes the gap this document originally
  recorded as open: the screenshots that established the *root cause* were
  taken on `origin/main` before any edit, and for a while nothing had confirmed
  the fix in a running app.
- The `MealListSection` fix was proven to fail without the change by reverting
  the file, re-running, and restoring it.
- The scan reads the user's actual label correctly on Tesseract **5.3.4**
  (locally) and **5.5.3** (macOS CI).

## What is NOT verified

- **No camera has ever been used.** The committed label is screenshot quality —
  a flat crop, not a photograph off a curved bag under shop lighting. No
  accuracy figure is claimed; **#256 and Epic #10 stay open.**
- **The browser OCR path has never executed.** Web canvas greyscaling is
  reasoned from the native measurement; `flutter build web` proves it compiles.
- **Mobile has never executed at all.** Whether `flutter_tesseract_ocr`
  forwards `user_defined_dpi` or silently drops an unknown key is
  **unconfirmed, and is the single most likely place the scan fix fails on a
  real device.**
- The interpolation and target width were swept on **5.3.4 only**, against
  **one** label, and sit on a narrow ridge rather than a plateau — at
  neighbouring settings the engine returns a *plausible wrong* fat value.

---

## Known gaps

- **No Diary-tab e2e flow.** The gap that let bug 1 ship is only half closed:
  widget tests cover the new FAB, but no flow drives the real app to the Diary
  tab and logs a meal there.
- `lib/features/profile/` is still a placeholder.
- The scan's engine settings are calibrated on a single image.

## If you pick this up next

1. **Collect real Israeli label photographs.** This is the highest-value work
   available and it needs no app, no device and no code — the entire OCR fix is
   calibrated on one screenshot-quality crop, and the margin is thin. Glare,
   curvature and shop lighting are completely untested.
2. **Confirm the mobile plugin forwards `user_defined_dpi`.** One Android run
   answers it, and it is the likeliest silent failure on a real phone.
3. **Write the Diary-tab e2e flow.**

---

## Two process notes

**The collision.** Two agents were launched with worktree isolation but also
given absolute paths into the main checkout. They followed the paths, both
worked in the same directory, and one's `git checkout -B` switched the branch
out from under the other. Nothing was lost — the two file sets never
overlapped, and nothing had been committed — but it cost a recovery. *If you
hand an agent an absolute path, that is where it will work, whatever isolation
you asked for.*

**The report worth having.** The scan agent's final message flagged, minutes
before a commit, that the native path it had just "fixed" was returning every
row with no numbers — against its own interest in declaring the task done. The
commit message at that moment claimed a working fix. Believing it would have
shipped a green CI over a broken desktop and mobile scanner, because the only
test covering that path silently skips on CI. **An agent that reports a
failure it could have hidden is worth more than one that reports success.**
