# M6 Handoff — Keto Lens, the Hebrew OCR label scanner

M6 is code-complete. All nine issues (#79–#87) are merged, CI is green on
`main`, and the `/lens` tab is a real screen for the first time.

**1076 tests. `domain/` 99.2%, `application/` 90.5% line coverage** — both
well clear of the 80% gate. The parser, the normaliser, the classifier, the
orchestrator, `ScanResult` and every widget are at or near 100%.

**And the one thing that matters most is unverified.** There is no camera, no
iOS device and no simulator in this environment, so nothing here has ever read
a real label. Read §"What is not verified" before trusting any of it.

---

## What shipped

| Issue | What |
|---|---|
| #81 | `HebrewLabelParser` + `HebrewTextNormaliser` — the Hebrew half |
| #82 | `IngredientClassifierImpl`, and `IngredientRules` in both languages |
| #79 | `google_mlkit_text_recognition`, `camera`, `image_picker`, `Info.plist` |
| #80 | `MlKitTextRecognizer` and the **web firewall** |
| #83 | `ScanOrchestrator` and the sealed `ScanResult` |
| #86 | `VerdictBadgeWidget` |
| #84 | `ScanResultSheet`, and `AddMealBottomSheet` prefill |
| #85 | `CameraScreen` — `/lens` is a screen at last; placeholder deleted |
| #87 | Gallery import |

Pure-Dart layers first, deliberately: they are the only parts of this milestone
anything in this environment can actually check, and #81 and #82 needed no
packages at all.

---

## The headline risk, and how it actually resolved

M6 opened with one question: `google_mlkit_text_recognition` is a **native-only
plugin** whose Dart code carries `import 'dart:io'`, and CI step 6 —
`flutter build web --release --no-pub --no-web-resources-cdn` — is a hard gate
on every PR. `design/web_support.md` §4 says a stray `dart:io` "analyses clean
and breaks only the web build". The expectation was that M6 could not start
without breaking the gate for itself and for M4 and M5.

**It does not break it.** Three spike builds on a throwaway branch settled it
before a line of feature code was written (`design/m6_preflight.md` Part 0):
baseline, a naive unconditional ML Kit import, and the firewall — all three
built.

The reason is worth keeping, because it corrects a belief this repo held:
**`dart:io` *is* available to dart2js**, as a library of throwing stubs.
`dart-sdk/lib/libraries.json` lists it under `_dart2js_common` with
`"support_conditional_import": false`, and `io_patch.dart` is wall-to-wall
`throw UnsupportedError(...)`. What broke the browser in the web-support change
was `path_provider` — a *plugin* with no web implementation — not the language
library. Only one of those is a compile failure.

`dart.library.io` is still `false` for dart2js, so the conditional-export
pattern works exactly as it does for the database factory.

**The firewall was built anyway**, for three reasons that have nothing to do
with the gate:

1. A runtime `MissingPluginException` is not a user-facing state. The browser
   gets a deliberate, explanatory screen.
2. `InputImage` is a plugin type and must not reach `application/`. Removing
   it from the pipeline's type surface is what makes `ScanOrchestrator`
   testable in pure Dart — and it is what made the firewall possible at all.
3. 0.17.1 is already published. A future release that reaches for a genuinely
   unavailable API turns a green gate red with no warning, and the firewall is
   two files.

Verified on the built bundle, not assumed:

```
build/web/main.dart.js
  absent   google_mlkit
  absent   vision#startTextRecognizer
  present  plugins.flutter.io/camera     (camera_web exists)
  present  image_picker                  (image_picker_for_web exists)
  present  the lens tab's Hebrew copy    (as \uXXXX escapes)
```

### The product decision, stated plainly

**Keto Lens cannot scan in a browser, and the tab says so.** There is no
on-device Hebrew OCR for Flutter web; the browser-shaped alternative is a
network call, which `CLAUDE.md`'s OCR section and Epic #10's first
architectural invariant both rule out. On web the tab renders
*"הסורק זמין באפליקציה לאייפון"*, offers neither the camera nor the gallery,
and says the rest of the app works normally. **Worth revisiting only if
browser scanning becomes a requirement — it needs a different engine and an
explicit decision to send label photos off-device.**

---

## What the audit found

All nine issues carried at least one defect; five would have compiled and
shipped wrong behaviour. `design/m6_preflight.md` is the full list. The five
worth remembering:

### 1. A failed scan was reported as **Clean Keto**

The worst defect in the project so far. #83's `ScanOrchestrator` caught
everything and returned a `cleanKeto` verdict, reasoning in its own words that
*"users see a clean verdict for unrecognisable labels rather than an error
screen"*. The user is in a shop holding a product, and the app has just called
it clean keto **because it could not read the label**. Nothing in the returned
value distinguished that from a real clean verdict.

Fixed by making `ScanResult` **sealed**: `ScanSucceeded` or `ScanFailed`, so a
`switch` does not compile until the failure is handled. Not throwing was the
right half of the contract; the failure just has to be visible in the value.

### 2. The Hebrew regexes never matched a real label

#81's four regexes are the substance of the milestone and every one was too
narrow. `שומן` is singular where Israeli labels say `שומנים`; `\s+` demands a
space OCR drops; `(\d+(?:\.\d+)?)` cannot read `22,5`; nothing stripped niqqud;
`ג׳` was required by #81's own test list and absent from #81's own regex; and
`dotAll: true` swallowed the nutrition table into the ingredient list.

And one the issue never mentioned: **the saturated-fat row uses the same word
as the total-fat row, one line down, with its own number beside it.** A parser
taking the first match reports 7.6 g of fat for a tahini that has 53.8.

### 3. `InputImage` in the application layer

#83 was labelled `layer:application` and imported `google_mlkit_text_recognition`
and the concrete `MlKitTextRecognizer` — against the layer rules and against
its own Technologies table, which promised "domain interfaces, no concrete
imports".

### 4. `AddMealBottomSheet(prefill:)` does not exist

Neither does `MealPrefill`. #84's add-to-diary path did not compile. And its
hand-rolled `showModalBottomSheet` dropped `isScrollControlled`, which the
shipped sheet documents as required.

### 5. Dependencies named in one issue and absent from another

`permission_handler` is imported by #85 and missing from #79's list — #85 as
written did not compile. `image` is added by #79 and used by nobody.

---

## Conventions M7 and anything later inherits

1. **A plugin lives in exactly one adapter, behind an interface.** Three times
   in this feature: `MlKitTextRecognizer`, `CameraControllerSession`,
   `ImagePickerPhotoPicker`. It is what made a camera screen testable with no
   camera, and it is not optional here.
2. **The scan pipeline's boundary type is a file path `String`.** No plugin
   type above `data/` or `presentation/camera/`.
3. **Failure is a value, not a fallback.** Sealed results over "return
   something harmless-looking". A UI that cannot tell a failure from a success
   will show the success.
4. **A clean badge is not evidence.** `IngredientClassifier` does not flag what
   it does not recognise, so `cleanKeto` also means "no rule matched".
   `IngredientVerdict.recognisedNothing` is how the UI tells those apart, and
   the copy says *"no problematic ingredients were found"* rather than
   *"clean keto"*.
5. **`IngredientRules` is the one source of rule truth**, now in both
   languages. Never a second copy in a classifier.
6. **Normalise Hebrew before matching it.** `HebrewTextNormaliser` — niqqud,
   bidi controls, geresh variants, the decimal comma — and it is applied in the
   classifier as well as the parser, so either works standalone.
7. **Digit runs still need `TextDirection.ltr`**, M3 convention 6, and the
   macro strip needed it again.
8. **Colours from `AppTheme`, and never colour alone.** Each badge carries an
   icon as well as a fill.
9. **Every failure-state test asserts the loading indicator is absent.** M3's
   lesson, and this milestone is mostly failure states.

---

## Gotchas worth keeping

- **An indeterminate `CircularProgressIndicator` on a tab screen hangs
  `test/widget_test.dart`.** `pumpAndSettle` never returns while one animates,
  and the app-level router tests visit every tab knowing nothing about what is
  on it. `CameraScreen`'s opening state is a static icon and a line of text for
  exactly this reason. Two router tests went red before it was found.
- **Clear a busy flag *before* awaiting a modal, not after.** `showModalBottomSheet`
  is awaited until dismissed, so a spinner cleared in a `finally` afterwards
  runs invisibly under the sheet — and `pumpAndSettle` never returns. Three
  tests, same cause.
- **A fake whose methods are plain `async` resolves inside one microtask
  drain**, so an intermediate busy frame never renders and the state looks
  untestable. A `Completer` gate in the fake is what makes it observable.
- **The analyzer does not resolve a conditional export.** It sees
  `createTextRecognitionService` declared by both halves and reports
  `ambiguous_import`; the VM resolves both to one library and the test runs
  regardless. `show` on the import is required for `flutter analyze`, which CI
  gates on.
- **`const Set<Color>` does not compile.** `Color` overrides `==` without a
  primitive equality.
- **`build_runner`'s incremental cache goes stale silently.** Twice it reported
  "1 output" and skipped a file that had genuinely changed, leaving a provider
  ungenerated with no error — and `flutter analyze` cannot catch a provider
  that nothing references yet. `rm -rf .dart_tool/build` fixed both. This is
  *in addition* to M3's "a killed run corrupts it permanently", which also
  happened once, from a `timeout 300` that was too short for a cold build.
  Give a cold `build_runner` 500 s.
- **`library;` must precede `part`.** The generator reports it as a build error
  in its log and then simply produces nothing.
- **A `\u` escape in a bash heredoc is not always literal.** The first draft of
  `HebrewTextNormaliser` ended up with real U+202E and U+2066 characters in its
  source, which `text_direction_code_point_in_literal` caught — correctly,
  since invisible bidi controls in source are how a file comes to read
  differently from how it compiles. Every pattern in that file is now written
  as an escape, and the files were written with Python rather than a heredoc.

---

## What is not verified

**Stated plainly, because a green CI run does not cover any of it.** There is
no camera, no iOS device, no simulator and no macOS host here — and, unlike M2
and M3, **no browser either**, so this is the first milestone since M1 to close
without anyone driving the app.

Unverified:

- **That ML Kit recognises Hebrew on a real label at all.** The adapter is
  tested against a mocked channel; the model has never run.
- **Every accuracy claim.** Epic #10's "≥ 80% of tested Israeli products" is
  unmeasured. The parser is tested against six hand-written fixtures which are
  realistic — plural keywords, a decimal comma, niqqud, a two-column split, a
  saturated-fat sub-row — but they were written by the same person who wrote
  the parser, which is exactly the kind of test that passes and then fails on
  a real label.
- **That `CameraPreview` renders, that the crop guide frames a real nutrition
  table, or that `takePicture()` produces an image ML Kit can read.**
- **That the iOS permission prompt appears with the `Info.plist` strings.**
- **That the torch works**, or that the gallery picker returns a usable path.
- **That the browser tab renders its unavailable state.** The bundle provably
  contains the copy and provably does not contain ML Kit, which is strong
  evidence, but nobody has loaded the page.

Verified thoroughly, because it is the whole safety net: the normaliser, the
parser, the classifier, the rule lists, the orchestrator and every failure
path, the three plugin-free widgets, and the camera screen's entire state
machine against a fake session.

**#256 is the issue that closes this gap**, and Epic #10 stays open until it
does.

---

## Known gaps

- **Scanned macros are per 100 g and are logged as if they were the serving**
  (#257). The parser reads no serving size. The sheet says *"check the serving
  size"* and the fields are editable, but a user who taps straight through logs
  100 g of a 30 g bar — and every number downstream, including the streak, is
  computed from it. The largest correctness gap in the shipped pipeline.
- **The camera and gallery adapters are barely covered** (#258) —
  `CameraControllerSession` 9.8%, `ImagePickerPhotoPicker` 0%. The interesting
  part is the error-code mapping, which is a documented plugin contract that
  nothing checks.
- **An unrecognised ingredient is not flagged, by design**, so a wheat-flour
  wafer earns `cleanKeto`. The UI carries the honesty (`recognisedNothing`), not
  the classifier. A confidence signal on `IngredientVerdict` would be the real
  fix.
- **`unspecifiedVegetableOils` is the one extension to `CLAUDE.md`'s rule
  list.** `שמן צמחי` is a caution rather than a refusal, cancelled by a clean
  plant named in brackets. Deliberate, documented in the file, and worth a
  product opinion.
- **No scan history.** Out of scope per Epic #10, but it means a mis-scan
  cannot be looked at again, which will make #256 harder than it needs to be.
- **`ScanFailed.rawText` is carried and never shown.** It exists so a mis-parse
  is diagnosable; nothing surfaces it yet. A debug affordance would pay for
  itself during #256.
- **Nothing pre-processes the image.** No crop to the guide rectangle, no
  greyscale, no contrast. The guide is drawn but the full frame is sent to OCR,
  so everything else on the pack competes with the table. This is what the
  `image` package would have been for; it was not added because nothing used
  it. Likely the cheapest accuracy win once #256 has a baseline.
- **The lens tab is one of five and is inert on web.** Every other tab works
  there.

---

## Next

`design/tasks.md` has M7 (#88–#94, polish) and M8 (#95–#102, CI). Two things
M6 leaves on the table for them:

- **Write `design/m7_preflight.md` first.** Five milestones in a row have now
  found at least one defect in every issue they audited, and M6's nine were
  the oldest, most speculative text in the project — five of them would have
  shipped wrong behaviour. There is no reason to expect M7's to be better.
- **CI still does not check codegen freshness** (`cicd_plan.md` Phase 1), and
  M6 hit the consequence three times: `app_router.g.dart` regenerates with a
  new hash on a clean build because it is stale on `main`, and it had to be
  reverted by hand on four branches to avoid a pointless conflict with the
  sibling milestones.
