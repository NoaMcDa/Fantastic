# M6 Pre-flight — corrections to the M6 issue text

Read this before picking up any M6 issue (#79–#87).

This is the fifth such file. `m0_handoff.md` catalogued seven things the M0
issue text got wrong; `m1_preflight.md`, `m2_preflight.md` and
`m3_preflight.md` did the same for their milestones. Every one of them found
the same thing: **the issue text was written in one sitting before any code
existed, and every issue in the milestone carried at least one defect.**

M6's nine issues are the oldest-written and most speculative text in the
project — they describe a camera, an OCR engine and a Hebrew grammar, none of
which anyone had touched. All nine were audited in full against the shipped
code and against the real package APIs unpacked in `~/.pub-cache`.

**All nine carry at least one defect. Five would compile and ship wrong
behaviour.** One of those — the scan-failure fallback — tells the user a label
is *Clean Keto* when OCR failed, which is the worst possible direction for a
food-safety feature to fail in.

**The issues have not been rewritten.** This file is the correction layer.

Audited: **#79–#87, all nine, in full**, plus Epic #10.

---

## Part 0 — The web-build question, settled empirically

The single biggest risk going into M6 was that
`google_mlkit_text_recognition` is a **native-only plugin** (its pubspec
declares `android` and `ios` and nothing else) while CI step 6 —
`flutter build web --release --no-pub --no-web-resources-cdn` — is a hard gate
on every PR. `design/web_support.md` §4 says a stray `dart:io` import
"analyses clean and breaks only the web build". ML Kit's own Dart code
contains exactly such an import:

```
google_mlkit_commons-0.8.1/lib/src/input_image.dart:1:import 'dart:io';
```

The expectation was therefore that adding ML Kit would break the web build and
block the milestone. **It does not.** This was tested, not reasoned about.

### What was actually run

On a throwaway branch, with `google_mlkit_text_recognition: ^0.13.0`,
`camera: ^0.11.0`, `image_picker: ^1.1.0` and `image: ^4.2.0` added to
`pubspec.yaml`:

| Spike | Setup | `flutter analyze` | `flutter build web --release --no-pub --no-web-resources-cdn` |
|---|---|---|---|
| Baseline | `main` as-is | clean | ✅ built |
| **A — naive** | a file importing `google_mlkit_text_recognition` directly, reachable from `main.dart` | clean | ✅ **built** (48.8 s) |
| **B — firewall** | conditional export, ML Kit behind `dart.library.io` | clean | ✅ built (49.1 s) |

### Why the naive case survives

Because `dart:io` **is** available to dart2js — as a library of throwing stubs.
`dart-sdk/lib/libraries.json` lists it under `_dart2js_common`:

```json
"io": {
  "uri": "io/io.dart",
  "patches": "_internal/js_runtime/lib/io_patch.dart",
  "support_conditional_import": false
}
```

and `io_patch.dart` is wall-to-wall `throw UnsupportedError(...)`. So:

- **`import 'dart:io'` compiles for web.** It is `path_provider` — a plugin
  with no web implementation, throwing `MissingPluginException` out of `main()`
  — that broke the browser before, not `dart:io` itself. `web_support.md` §1
  names both causes; only the first one is a *compile* failure, and it is
  package-level, not language-level.
- **`dart.library.io` is still `false` for dart2js** (`support_conditional_import: false`),
  so the conditional-export pattern works exactly as it does for the database
  factory.
- The ML Kit method channels compile to a web bundle that would throw
  `MissingPluginException` **at run time**, on first use, in the browser only.

So the risk was real but mis-located: it is a **runtime** hazard, not a build
gate. CI would have stayed green and the lens tab would have thrown a raw
platform exception in the browser.

### The decision

**Build the firewall anyway.** Three reasons, none of them the CI gate:

1. **A runtime `MissingPluginException` is not a user-facing error state.**
   The browser deserves a deliberate, explanatory screen, not a red exception.
2. **`InputImage` is a plugin type and must not reach `application/`.** #83
   puts it in the `ScanOrchestrator` signature; see §1.3. Removing it from the
   pipeline's type surface is what makes the orchestrator testable in pure Dart
   and, incidentally, what makes the firewall possible at all.
3. **The next version of the package may not be so forgiving.** 0.17.1 is
   already published. A future release that reaches for a genuinely
   unavailable API turns a green gate red with no warning, and the firewall
   costs two files.

**Shape** — copied from `lib/core/database/database_factory.dart`, which
`CLAUDE.md` calls "the web build's only firewall":

```
domain/services/text_recognition_service.dart   interface, String in / String out
data/adapters/text_recognizer_factory.dart      conditional export
data/adapters/ml_kit_text_recognizer.dart       dart.library.io — imports ML Kit
data/adapters/unavailable_text_recognizer.dart  default — imports nothing native
```

Defaulting to the *unavailable* file and switching to ML Kit on
`dart.library.io` — not the other way round — is the same choice
`database_factory.dart` makes and for the same reason: every non-VM target,
including ones that do not exist yet, gets the safe half.

### The product consequence, stated plainly

**Keto Lens cannot scan in a browser.** There is no on-device Hebrew OCR for
Flutter web: ML Kit's web story is the JS `@google-cloud/vision` API, which is
a network call, and `CLAUDE.md`'s OCR section and Epic #10's first
architectural invariant both say *no network call is made during scan*. Adding
one to make web work would break the thing the feature is for.

So on web the lens tab renders an explanatory state — the camera and gallery
controls are not offered, and the copy says the scanner needs the iOS app. The
rest of the app is unaffected; this is one tab of five. **Flagged for the
user:** if browser scanning ever becomes a requirement, it needs a different
OCR engine and an explicit decision to send label photos off-device.

### Other packages, checked

| Package | Web? | Verdict |
|---|---|---|
| `camera` ^0.11.0 → 0.11.4 | yes — `camera_web` is a declared default_package | keep |
| `image_picker` ^1.1.0 → 1.2.3 | yes — `image_picker_for_web` | keep |
| `image` ^4.2.0 → 4.9.2 | pure Dart | **drop — see §2.1** |
| `permission_handler` | named by #85, **absent from #79** | **do not add — see §2.2** |

Resolution itself is clean: `flutter pub get` added 24 packages with no
conflict against riverpod 3.0.3 / sembast 3.8.10.

---

## Part 1 — Defects that compile and ship wrong behaviour

### 1.1 A failed scan is reported as **Clean Keto** (#83)

The worst defect in the milestone, and the only one that is actively unsafe.

`ScanOrchestrator.scan` in #83 wraps the whole pipeline in `catch (_)` and
returns:

```dart
return ScanResult(
  label: ParsedLabel(),
  verdict: const IngredientVerdict(badge: VerdictBadge.cleanKeto),
);
```

Its own justification says so out loud: *"users see a clean verdict for
unrecognisable labels rather than an error screen."* That is backwards. The
user is standing in a supermarket holding a product, and the app has just told
them it is clean keto **because it could not read the label**. There is no
signal in `ScanResult` that distinguishes this from a genuine clean verdict:
`ParsedLabel().hasMacros` is false and `flaggedIngredients` is empty, which is
also what a real clean-but-macro-less label looks like.

The same shape appears once more: **#82's classifier returns `cleanKeto` for
an ingredient list of entirely unrecognised tokens.** That one is deliberate
and is documented on the shipped interface (`IngredientClassifier`: *"An
unrecognised token is not flagged — the verdict describes what was found, not
what was understood"*), so it stays — but it means the badge over-claims by
construction and the UI copy has to carry the caveat. See §4.1.

**Correction.** `ScanResult` needs a third state. Model it as a sealed result
or an explicit `ScanFailure` field; do not encode failure as a clean verdict.
The result sheet renders a distinct "לא הצלחנו לקרוא את התווית" state with a
retry, and **no badge at all**. The orchestrator still never throws — that part
of the contract is right.

### 1.2 The parser's regexes do not match a real Israeli label (#81)

#81's five regexes are the substance of the milestone and every one of them is
too narrow. Each of the following makes the whole label parse as all-nulls.

**(a) `שומן` is singular; Israeli labels say `שומנים`.** The pattern is
`RegExp(r'שומן\s+(\d+(?:\.\d+)?)\s*ג')`. Against `שומנים 12 גרם` the literal
`שומן` matches the first four letters, then `\s+` demands whitespace and finds
`י`. No match. `חלבון` has the same problem (`חלבונים`), and `סיב` /
`סיבים` / `סיבים תזונתיים` all occur.

**(b) `\s+` requires whitespace; OCR routinely drops it.** The issue's *own*
happy-path fixture is `שומן 12גר` — which the regex does match, because the
space is before the digits — but `שומן12גר`, which OCR produces from a tight
two-column table, does not. Use `\s*`.

**(c) Israeli labels use a decimal comma.** `12,5 גרם` is normal on an Israeli
label. `(\d+(?:\.\d+)?)` captures only `12`, silently losing the fraction —
and `double.tryParse('12,5')` returns `null` if the comma is captured. Normalise
`,` between digits to `.` before parsing.

**(d) Niqqud and cantillation are not stripped.** Real packaging carries
vowel points. `שֻׁמָּן` is `ש U+05BB ו…` — a different code-point sequence from
`שומן`, and no literal match will ever fire. Strip `U+0591–U+05C7` before
matching. This is not exotic; it is most religious-market and children's
packaging in Israel.

**(e) `ג׳` is required by #81's own test list and absent from #81's own
regex.** Test case 6 says *"OCR mis-read `ג׳` instead of `גר` — regex should
also match (add `ג׳` variant to regex)"*. The snippet's `\s*ג` happens to match
the `ג` of `ג׳` by accident, so that test passes for the wrong reason. Worse,
there are three distinct characters in play — `׳` (U+05F3 HEBREW PUNCTUATION
GERESH), `'` (U+0027 APOSTROPHE) and `’` (U+2019) — and ML Kit emits whichever
the font suggests. Normalise all three to one before matching.

**(f) Hebrew letter prefixes.** `ו/ה/ב/ל/מ/ש/כ` attach directly to the noun:
an ingredient list reads `שמן קנולה ושמן סויה`, and `ומלטודקסטרין` is one
token. The classifier's `contains` (§1.4) survives some of this by luck; the
parser's anchored keyword matches do not.

**(g) `dotAll: true` on the ingredients regex swallows the nutrition table.**
`RegExp(r'רכיבים[:\s]+(.+)', dotAll: true)` captures everything to the end of
the OCR output. On a label where the ingredient list is printed *above* the
nutrition table — the common layout — every macro line ends up as an
"ingredient", and each one is then handed to the classifier. Bound the capture
at a blank line or a known table header, or split on lines and stop at the
first line that looks like a macro row.

**None of this is caught by a test written from the issue's own fixtures**,
because those fixtures are the clean singular ASCII-digit form. Test against
realistic strings — plural, prefixed, comma-decimal, niqqud-bearing — or the
suite is theatre.

### 1.3 `InputImage` in the application layer is a layer violation (#83)

#83 is labelled `layer:application` and its first import is

```dart
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
```

followed by `import '../../data/adapters/ml_kit_text_recognizer.dart';` — a
concrete data-layer class. Both contradict `CLAUDE.md`'s non-negotiable layer
rules and the issue's own Technologies table, which promises *"Domain
interfaces — no concrete imports"*. It also makes the firewall impossible: an
`InputImage` in the orchestrator's signature drags ML Kit into every caller.

**Correction.** The pipeline's boundary type is a **file path `String`**.
`TextRecognitionService.recognise(String imagePath)` lives in `domain/`; the
adapter is the only thing that ever constructs an `InputImage`. The
orchestrator then depends on three domain interfaces and nothing else, and its
whole test suite runs with three `mocktail` mocks and no plugin.

### 1.4 The classifier hard-codes a second copy of the rule lists (#82)

`CLAUDE.md` names `lib/core/constants/ingredient_rules.dart` as the spec and
says **"that file already exists, read it before writing a second copy"**.
#82's snippet declares `static const _nonKeto` and `static const _caution`
inside the classifier, duplicating it. The shipped `IngredientClassifier`
interface already says implementations *"read them rather than redeclaring
them, so the forbidden and clean sets have one source of truth"*.

`IngredientRules` today is English-only. The fix is to **extend that file** with
the Hebrew synonyms, not to keep them in the classifier. #82's DoD line "Both
Hebrew and English variants in rule sets" is right about the requirement and
wrong about the location.

Also: #82's DoD says *"all three rule sets"* and its snippet declares two —
there is no clean set, even though `IngredientRules` ships
`cleanApprovedFats` and `cleanSweeteners`.

### 1.5 `AddMealBottomSheet` has no `prefill`, and `MealPrefill` does not exist (#84)

#84's `_addToDiary` calls

```dart
AddMealBottomSheet(date: date, prefill: MealPrefill(...))
```

The shipped widget is
`AddMealBottomSheet({required this.date, super.key})` — one parameter — and
there is no `MealPrefill` type anywhere in the repo. This does not compile.

Also, the shipped sheet owns its own presentation through a static
`AddMealBottomSheet.show(context, date: date)` *"so the sheet owns how it is
presented: `isScrollControlled` is required for the keyboard-avoidance below to
have anywhere to expand into."* #84's hand-rolled `showModalBottomSheet` omits
`isScrollControlled`, so the pre-filled form would be hidden behind the
keyboard.

**Correction.** Adding prefill support means editing an M2 file
(`lib/features/diary/presentation/widgets/add_meal_bottom_sheet.dart`) — add
optional `initialFatG` / `initialNetCarbsG` / `initialProteinG` / `initialName`
parameters threaded through `show`, defaulting to the current behaviour, and
keep `isScrollControlled`. Do not introduce a `MealPrefill` value object for
four doubles.

---

## Part 2 — Dependencies the issue text gets wrong

### 2.1 `image` is never used by any M6 issue — do not add it

#79 adds `image: ^4.2.0` "for image pre-processing (cropping, grayscaling)".
**No other M6 issue imports it, calls it, or mentions pre-processing.** #85
sends `takePicture()`'s file straight to `InputImage.fromFilePath`; #87 does
the same with the picker's `XFile.path`. Adding it buys an unused ~2.6 MB Dart dependency and `depend_on_referenced_packages` will not complain
because nothing imports it at all.

Add it when something crops. Recorded here so nobody reads its absence as an
oversight.

### 2.2 `permission_handler` is required by #85 and missing from #79

#85's import block and its permission-denied branch both use
`permission_handler` (`Permission.camera.request()`, `openAppSettings`), and
#79 — the issue whose entire job is the dependency list — does not list it.
Taken literally, #85 does not compile.

**Do not add it.** The `camera` plugin already surfaces the permission result:
`controller.initialize()` triggers the iOS prompt and throws a
`CameraException` with `code == 'CameraAccessDenied'` (and
`'CameraAccessDeniedWithoutPrompt'`, `'CameraAccessRestricted'`) when refused.
Catching that is one `on CameraException` clause and adds no native-only
plugin — which matters, because `permission_handler` is another plugin with no
first-party web implementation and the lens tab is the one screen that has to
degrade cleanly in a browser. `openAppSettings` is the only thing genuinely
lost; the denied state points the user at iOS Settings in copy instead.

### 2.3 Version and API notes

- `google_mlkit_text_recognition: ^0.13.0` resolves to **0.13.1**; **0.17.1**
  is published. 0.13.1 is kept: it is what the issue asked for, it resolves
  cleanly, and nothing in M6 needs a newer API.
- `TextRecognizer`'s constructor is **named-parameter**
  (`TextRecognizer({this.script = TextRecognitionScript.latin})`), and `latin`
  is already the default. #80's `TextRecognizer(script: TextRecognitionScript.latin)`
  is correct but redundant. There is **no Hebrew script option** — the enum is
  `latin, chinese, devanagiri, japanese, korean` — so #80's note that Hebrew
  rides on the Latin recogniser is right.
- `RecognizedText` exposes **`.text`**, the full recognised string. #80's
  `result.blocks.map((b) => b.text).join('\n')` re-derives it. Either is fine;
  `.text` is one call and is what the plugin guarantees.
- `CameraController(description, resolutionPreset, {...})` — #85's positional
  form is correct for `camera` 0.11.4.
- `InputImage.fromFilePath(String)` exists and is the only factory M6 needs.
  `InputImage.fromFile(File)` is the one that pulls in `dart:io`.

---

## Part 3 — Dependency graph errors in the issue text

The M6 "Upstream Dependencies" blocks are internally inconsistent. Three are
wrong and one is circular.

| Issue | Claim | Reality |
|---|---|---|
| #84 | "Blocked by: Build CameraScreen (**#84**)" | **Self-reference.** CameraScreen is **#85**. |
| #86 | "Blocked by: Build ScanResultSheet (#84)" | Backwards — **#84 uses #86**, not the reverse. #86 has no blockers beyond the shipped `VerdictBadge` enum. |
| #85 | shows `ScanResultSheet` (#84) | and #84 claims to be blocked by #85 — **a cycle**. |
| #81, #82 | "Blocked by: #34, #30" | Both shipped in M1. `LabelParser`, `IngredientClassifier`, `ParsedLabel`, `IngredientVerdict` and `VerdictBadge` all exist under `lib/features/keto_lens/domain/`. **Neither is blocked by anything**, and neither needs #79 — they are pure Dart. |

**Working order** (pure-Dart first, per the milestone's own risk profile):

```
#81 parser → #82 classifier → #79 deps → #80 recogniser + firewall
  → #83 orchestrator → #86 badge → #84 result sheet → #85 camera screen
  → #87 gallery
```

`#81` and `#82` before `#79` is deliberate: they are the only parts of this
milestone that can be fully verified in this environment, and they need no
packages at all.

---

## Part 4 — Smaller corrections

### 4.1 The badge over-claims, and the copy must not (#84, #86)

Following from §1.1: a label whose every ingredient is unrecognised earns
`cleanKeto`. The shipped interface documents this on purpose, so the widget
carries the honesty instead of the classifier. **`'קטו נקי ✓'` asserts more
than the pipeline knows.** Prefer copy that reports what was found — and when
`flaggedIngredients` is empty *and* nothing matched a clean rule either, the
sheet should say so rather than show a green tick. Recorded as a known gap
either way; a confidence signal on `IngredientVerdict` is a post-MVP change.

### 4.2 Raw hex instead of `AppTheme` (#86)

#86's `_colors` map is `0xFF10B981` / `0xFFF59E0B` / `0xFFEF4444`, and its own
DoD says *"Colours stored as named constants (not inline hex)"* — the snippet
fails its own gate. `AppTheme` already ships `success 0xFF30D158`,
`caution 0xFFFFD60A`, `danger 0xFFFF453A`, and M3's `PhaseBadgeWidget` set the
precedent of drawing from the palette *"so the badge tracks the palette every
other widget uses"*. Use `AppTheme`.

Same for #84, which writes `TextStyle(color: Colors.red)` for the flagged
header.

### 4.3 Every digit run needs `TextDirection.ltr` (#84)

M3's handoff convention 6, and three widgets needed it there. #84's macro row —
`'שומן: ${label.fatG?.toStringAsFixed(1)}ג פחמימות: …'` — is a Hebrew string
with three embedded numbers inside an RTL `Directionality`. Rendered as one
`Text`, the digit runs reorder. Split the macro strip into per-macro widgets
with `textDirection: TextDirection.ltr` on the numeral, exactly as
`MacroSummaryCard` does.

### 4.4 Relative imports fail the lint (#81, #82, #83, #84, #86)

Every snippet in M6 uses `import '../../domain/models/parsed_label.dart';`.
`analysis_options.yaml` enables **`always_use_package_imports`**. All of them
must be `package:fantastic/...`. Same class of error as `m1_preflight.md`
found.

`require_trailing_commas` and `prefer_final_locals` are also on and several
snippets violate both.

### 4.5 `riverpod 3`, and providers return the interface

No M6 snippet names an `XxxRef`, so M6 escapes the trap that cost M1 and M2 —
but the provider guidance is still thin. Per `CLAUDE.md`: annotated functions
take a bare `Ref`; a `data/providers.dart` provider returns the **domain
interface**, never the concrete class. So `textRecognitionServiceProvider`
returns `TextRecognitionService`, not `MlKitTextRecognizer`, and
`labelParserProvider` returns `LabelParser`. #80's DoD names
`mlKitTextRecognizerProvider`, which leaks the implementation into the name.

### 4.6 Failure-state widget tests must assert the loading indicator is absent

M3's most expensive lesson, and M6 is the milestone it matters most to: a
camera screen is almost entirely loading and error states. **riverpod 3 reports
a provider that failed before producing a value as `AsyncLoading` *with* an
error** — `isLoading` and `hasError` are both true, the runtime type is
`AsyncLoading`, and matching `AsyncError()` in a `switch` never fires. Check
`hasError` **first**, and make every failure test assert
`find.byType(CircularProgressIndicator)` is `findsNothing`, or the test passes
with the bug present.

`CameraScreen`'s own state machine has the same shape without riverpod: #85's
`build` checks `_permissionDenied` before `_controller == null`, which is the
correct order. Keep it, and add the third state the issue omits —
**initialisation failed for a reason other than permission** (no camera on the
device, `CameraException` on `initialize`). #85's `if (cameras.isEmpty) return;`
leaves the screen on a spinner forever.

### 4.7 `_capture` swallows the failure it is most likely to hit (#85, #87)

`_capture`'s `try { … } finally { … }` has no `catch`. `takePicture()` throws
`CameraException` routinely (disposed controller, another capture in flight,
low storage). The `finally` clears `_scanning`, then the exception propagates
out of an async callback into the zone — an unhandled error, no user feedback,
and the screen simply does nothing. Catch it and surface a message.

### 4.8 `Info.plist` — the second usage string is ungrammatical (#79)

> `Fantastic מגישה גישה לגלריה לייבוא תמונות תוויות לניתוח`

`מגישה גישה` is "serves access". It should read `מבקשת גישה` ("requests
access"). App Store review reads these strings; a garbled one is a rejection
risk. Also check whether `ios/Runner/Info.plist` is even in the repo before
planning to edit it.

### 4.9 Epic #10's invariants that no child issue implements

- **"`CameraScreen` — live viewfinder, crop overlay, **torch toggle**, gallery
  fallback."** No child issue specifies a torch toggle. #85 lists viewfinder,
  overlay and capture; #87 adds gallery.
- **"OCR pipeline tested against real Hebrew label OCR fixtures (min. 5)."**
  No child issue creates any fixtures. `test/fixtures/` has none for M6 and
  `design/tests.md` forbids constructing domain objects inline. Build them.
- **"Hebrew OCR correctly classifies ≥ 80% of tested Israeli products."**
  Unmeasurable here — see Part 5.

---

## Part 5 — What cannot be verified in this environment

Stated up front so no one reads a green CI run as more than it is.

**There is no camera, no iOS device, no simulator and no macOS host.** The
following are therefore shipped unverified, and no test in this repository can
change that:

- that ML Kit recognises Hebrew text on a real label at all;
- the accuracy figure in Epic #10's Definition of Done;
- that `CameraPreview` renders, that the crop overlay lands where the label is,
  or that `takePicture()` produces an image ML Kit can read;
- that the iOS permission prompt appears with the `Info.plist` strings;
- that the gallery picker returns a usable path.

What **can** be verified, and must be covered thoroughly because it is the only
safety net: the parser, the classifier, the rule lists, the orchestrator's
wiring and fallback, and every widget's rendering under `pumpApp`. The parser
and classifier should be at or near 100%.

`design/m6_handoff.md` restates this at closure.
