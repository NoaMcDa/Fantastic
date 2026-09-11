# M6 platform research — Keto Lens on every target

**Status:** research only. No code changed. Nothing here has been measured on a device.

**Question asked:** what would it take to run M6 (Keto Lens) on every platform Flutter targets?

**Answer, in one line:** it is not primarily a porting problem. The OCR engine M6 ships cannot read
Hebrew on the one platform M6 supports, and the only engine that can read Hebrew happens to run
everywhere — so "make the lens work" and "make the lens work on five more platforms" are the same
change.

Read `design/m6_preflight.md` and `design/m6_handoff.md` first; this document assumes both.

---

## Part 0 — The finding, stated first

### ML Kit has no Hebrew script model

Verified in the resolved package, not inferred.
`/root/.pub-cache/hosted/pub.dev/google_mlkit_text_recognition-0.13.1/lib/src/text_recognizer.dart:38`:

```dart
/// Configurations for [TextRecognizer] for different languages.
enum TextRecognitionScript {
  latin,
  chinese,
  devanagiri,
  japanese,
  korean,
}
```

Five scripts. Hebrew is not one of them, and there is no sixth to select. `MlKitTextRecognizer`
(`lib/features/keto_lens/data/adapters/ml_kit_text_recognizer.dart:31`) calls the bare
`TextRecognizer()`, whose constructor defaults to `latin`. **The shipped iOS build asks a Latin
recogniser to read Hebrew.**

### This was noticed, and filed in the wrong place

`design/m6_preflight.md` §2.3 records it exactly right, as a parenthetical inside a correction about
a redundant constructor argument:

> #80's `TextRecognizer(script: TextRecognitionScript.latin)` is correct but redundant. There is
> **no Hebrew script option** — the enum is `latin, chinese, devanagiri, japanese, korean` — so #80's
> note that Hebrew rides on the Latin recogniser is right.

"Hebrew rides on the Latin recogniser" was treated as a property of the design. It is the central
risk of the feature. This document promotes it.

### What a real label most likely does today

Traced through the shipped pipeline. **This is a prediction from code, not an observation** — see
Part 8.

1. The Latin recogniser is handed a photo of Hebrew glyphs. Latin-script models are not
   script-detecting; they emit their best Latin-alphabet guess at whatever shapes they find.
2. `HebrewLabelParser` matches per-line on Hebrew keywords — `RegExp('פחמימ')` at
   `hebrew_label_parser.dart:37`, and the equivalents for `שומן`/`שומנים` and `חלבון`/`חלבונים`.
   None of them can match Latin output.
3. `ParsedLabel` comes back with no macros and no ingredients.
4. `ScanOrchestrator` (`scan_orchestrator.dart:50-87`) hits
   `!label.hasMacros && label.ingredients.isEmpty` and returns
   `ScanFailed(ScanFailureReason.notALabel)`.
5. `ScanResultSheet` renders "turn the product over" and offers a retry.

So the failure mode is **safe, not silent-wrong** — the sealed `ScanResult` doing precisely the job it
was introduced for. A user is never told a product is clean keto because the app could not read the
label. But the feature does not work, and every retry produces the same answer.

Digits are the one partial exception: Latin-script models read Arabic numerals, so the *numbers* on a
label may well survive. They arrive without the Hebrew keyword that says which macro they belong to,
which the parser requires (`hebrew_label_parser.dart:237` — a macro keyword *and* a digit). Numbers
without labels are not usable.

### Two claims in `design/technology.md` §1 are wrong

That section is the decision record for choosing ML Kit. Both load-bearing sentences are false:

| `technology.md` says | Actually |
|---|---|
| *"Zero network dependency, **Hebrew is a first-class supported script**, fast inference (<1s on iPhone 12+)"* (line 23) | Hebrew is not a supported script at all. Inference speed is unmeasured — there is no device. |
| Tesseract: *"Hebrew model must be bundled manually (**~50MB**)"* (line 17) | `heb.traineddata` is **961 KB** in `tessdata_fast` and **3.5 MB** in `tessdata_best`. Off by roughly 50×, and this is part of why Tesseract was dismissed. |

`design/issue_conventions.md:368` carries the same false claim in its Technologies-table *example*
(*"on-device, no network call, Hebrew script supported"*). Worth correcting so it is not copied into
the next issue.

`technology.md` §1's own alternatives table, read again with the enum in hand, points at the answer:
it already lists Tesseract as the option that needs a bundled Hebrew model, and Apple Vision as *"best
Hebrew quality on-device"*. One of those two claims turns out to be true. It is not the Apple one.

---

## Part 1 — On-device Hebrew OCR: the engine survey

The binding constraint is Epic #10's first architectural invariant, restated in `CLAUDE.md`'s OCR
section: **no network call is made during a scan.** Held firm throughout; Part 2 covers why.

| Engine | Hebrew? | iOS | Android | Web | macOS | Win | Linux |
|---|---|---|---|---|---|---|---|
| Google ML Kit Text Recognition v2 | **No** — `latin, chinese, devanagiri, japanese, korean` | ✅ | ✅ | ✗ | ✗ | ✗ | ✗ |
| Apple Vision / Live Text | **No** — Hebrew is absent from Apple's published list (24 languages across 46 locale combinations as of iOS 26). Arabic, Persian and Urdu are absent too | ✅ | ✗ | ✗ | ✅ | ✗ | ✗ |
| `Windows.Media.Ocr` (WinRT) | **Almost certainly not** — verify on a real box, see Part 8 | ✗ | ✗ | ✗ | ✗ | ✅ | ✗ |
| PaddleOCR / EasyOCR / MMOCR via ONNX | **No Hebrew model exists** in any of the three, despite 80–111 languages between them. Needs one trained | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Tesseract 4/5 + `heb.traineddata`** | **Yes** | ✅ | ✅ | ✅ (wasm) | ✅ | ✅ | ✅ |
| Cloud (Cloud Vision / Azure Read / Textract) | Yes, best-in-class | — rejected, Part 2 — | | | | | |

Hebrew is a small enough market that the big on-device vendors have not shipped a model for it. That
is the whole story: this is not a Flutter limitation, and no amount of platform-channel work routes
around it.

**Tesseract is the only engine that is both Hebrew-capable and available on every target.** Worth
sitting with, because it means the platform question answers itself — pick the engine that can read
the language, and portability arrives as a side effect.

### The precedent this repeats

`design/web_support.md` §1 faced the same shape of decision when Isar could not open in a browser:

> That left two options: keep Isar on native and write a second storage backend for web, or replace
> Isar everywhere with one store that runs on both. **The second was chosen — one implementation, one
> set of contract tests, no drift between two backends that have to behave identically.**

`m6_preflight.md` explicitly declined to apply that reasoning to OCR, on the grounds that *"sembast
genuinely runs everywhere; ML Kit provably cannot"* — the difference being that no single OCR engine
was available on both sides. Given the enum above, that premise was wrong in an interesting way: ML
Kit could not serve *either* side, because it cannot read Hebrew anywhere. There is a
runs-everywhere engine, and the same argument now reaches the same conclusion it did for sembast.

---

## Part 2 — Cloud OCR: the rejected option

Recorded so nobody re-derives it. Cloud engines read Hebrew well and would solve accuracy outright.
Rejected on three independent grounds, any one of which is sufficient:

1. **The architectural invariant.** Epic #10 invariant #1 and `CLAUDE.md`'s OCR section both state no
   network call during a scan. `m6_preflight.md` is blunt about the consequence of ignoring it:
   *"Adding one to make web work would break the thing the feature is for."*

2. **The permission prompt already promises otherwise, in Hebrew, in shipped code.**
   `ios/Runner/Info.plist:28` and `:30` both end:

   > הניתוח מתבצע כולו על המכשיר והתמונות אינן נשלחות לשום שרת.
   > *(The analysis is performed entirely on the device and the images are not sent to any server.)*

   Swapping in a cloud engine without rewriting that copy makes the permission prompt a false
   statement — and it is the text App Store review reads, alongside the privacy labels.

3. **`design/mvp.md:165`** — *"All 5 core features work offline on an iPhone 12 or newer."* A cloud
   scanner is not an offline feature.

`m6_preflight.md` names the escape hatch precisely, and it is a product decision rather than an
engineering one: revisiting needs *"a different OCR engine and an explicit decision to send label
photos off-device"* — which means new `Info.plist` copy, a privacy-label change, a consent flow, and
an answer for what happens in a supermarket basement with no signal.

**Not recommended.** Tesseract removes the need to have the conversation at all.

---

## Part 3 — Tesseract on each of the six targets

### Candidate bindings

| Binding | Targets | Notes |
|---|---|---|
| `flutter_tesseract_ocr` 0.4.31 | Android, iOS, web (web via tesseract.js) | Closest to off-the-shelf for our three most likely targets. Unverified uploader on pub.dev. Its own README says *"Tesseract is slower than ml_kit"*. iOS needs the `tessdata` folder dragged into Xcode as a folder reference. |
| `flusseract` ^0.1.1 | Android, iOS, macOS, Windows, Linux | FFI; builds libtesseract and its dependencies from source via CMake. ~10 minutes on a cold build. **No web.** |
| `flutter_ocr_native` 0.3.6 | Android, iOS, macOS, Windows, Linux | **Disqualified** — *"English-only extraction — non-Latin scripts auto-filtered."* Useful only as a map of which native engine each platform offers (ML Kit / Vision / WinRT / Tesseract). |
| Own FFI binding | any | Most control, most cost. The project's "one plugin per adapter behind an interface" convention (M6 convention 1) means swapping the binding later is one file, so starting with a published package is not a trap. |

Nothing here is endorsed. The choice depends on Part 9 step 1, and on which targets actually ship.

### Per-target table

| Target | OCR | Camera | Gallery | Platform-folder state |
|---|---|---|---|---|
| **iOS** | Tesseract, replacing ML Kit | `camera` → `camera_avfoundation` ✅ | `image_picker` ✅ | `ios/` exists. **No `Podfile`, no `Pods/` — CocoaPods has never run in this repo**, so no native dependency is integrated yet. Both usage strings already in `Info.plist`. |
| **Android** | Tesseract (ML Kit would also *run*, and would also not read Hebrew) | `camera` → `camera_android_camerax` ✅ | ✅ | **No `android/`.** Needs `flutter create --platforms=android .` — see the `.metadata` trap below. Manifest needs `CAMERA` plus media-read permissions, and Android's runtime-permission model must be re-checked against the decision in `m6_preflight.md` §2.2 (below). |
| **Web** | tesseract.js (wasm) | `camera` → `camera_web` ✅ | `image_picker_for_web` ✅ | `web/` exists. **The target that reverses M6's "cannot scan in a browser" decision.** Detail in Part 4. |
| **macOS** | Tesseract (Vision has no Hebrew) | ✗ | `image_picker_macos` ✅ | No `macos/`. Camera needs entitlements + hardened runtime. |
| **Windows** | Tesseract (WinRT OCR has no Hebrew) | ✗ | `image_picker_windows` ✅ | No `windows/`. |
| **Linux** | Tesseract (system `libtesseract`) | ✗ | `image_picker_linux` ✅ | No `linux/`. |

### The desktop camera is the blocker, not OCR

Verified in `/root/.pub-cache/hosted/pub.dev/camera-0.11.4/pubspec.yaml` — the plugin declares three
platforms and no more:

```yaml
    platforms:
      android:
        default_package: camera_android_camerax
      ios:
        default_package: camera_avfoundation
      web:
        default_package: camera_web
```

There is no first-party desktop implementation and no published roadmap for one. `camera_windows`
exists but is incomplete; `camera_desktop` and `flutter_lite_camera` are third-party.

**Recommendation: desktop ships gallery-import-only.** The architecture already supports this for
free — `camera_screen.dart:360` `scanFile(String path)` is a single funnel, called from
`_capture()` at line 319 and `_pickFromGallery()` at line 346. Two callers, not two code paths, and
`image_picker` already resolves a platform package for all three desktop targets (visible in
`pubspec.lock`). A desktop lens screen is the existing screen with the viewfinder branch disabled —
which is a state the screen can already render, since `_MessageState` takes a nullable
`onPickFromGallery`.

### `permission_handler` on Android

`m6_preflight.md` §2.2 refused `permission_handler` because `CameraController.initialize()` already
triggers the iOS prompt and reports refusal as a `CameraException` code, which
`camera_controller_session.dart:110-115` maps to `CameraProblem`. That reasoning is **iOS-shaped**.
Android's permission model differs (a permanently-denied state is reached by two refusals, not by a
settings toggle), so the error-code mapping must be re-verified on Android before assuming the
decision carries. It may well hold; it has not been checked.

### The `.metadata` trap

`design/web_support.md:96-98`, from the change that added web support:

> **`flutter create --platforms=web .` silently drops other platforms from `.metadata`.** It deleted
> the `ios` block; it was restored by hand. Diff `.metadata` deliberately after ever running
> `flutter create`.

This repo has already lost a platform block this way once. `.metadata`'s `migration.platforms` today
lists exactly `root`, `ios`, `web`. Adding four platform folders is four more chances to lose them —
run `flutter create` once per platform, and diff `.metadata` after each.

---

## Part 4 — The web target in detail

The highest-value section, because web is where M6 currently says no, needs no new platform folder,
and — uniquely among the five candidate targets — **can be driven end to end in the development
environment this project actually has.**

### Components

- **tesseract.js 7.0.0** — npm latest, 1.41 MB unpacked.
- **tesseract.js-core 6.1.2** — the wasm builds.

### Everything must be self-hosted

tesseract.js defaults to fetching its core from a CDN and its language data from
`tessdata.projectnaptha.com`. Both are network calls at scan time, which the invariant forbids —
and worse, they would regress a property `web_support.md` §7 records as verified: the app currently
makes **zero external requests**.

Set all three paths to local assets under `web/`:

```js
const worker = await createWorker('heb', 1, {
  workerPath: '/tesseract/worker.min.js',
  corePath:   '/tesseract/',          // a directory — the library picks the right build
  langPath:   '/tesseract',           // fetches <langPath>/heb.traineddata.gz
});
```

This is the same reasoning that already produced `--no-web-resources-cdn` for CanvasKit
(`web_support.md` §5): bundle it, or the app does not boot offline.

### Measured asset sizes

All figures fetched from source, not estimated.

| File | Bytes | |
|---|---:|---|
| `tessdata_fast/heb.traineddata` | 961,404 | **0.92 MB** |
| `tessdata_best/heb.traineddata` | 3,704,077 | 3.53 MB |
| `tessdata/heb.traineddata` (standard) | 5,413,459 | 5.16 MB |
| `tessdata_fast/script/Hebrew.traineddata` | 4,866,337 | 4.64 MB |
| `tessdata_fast/eng.traineddata` | 4,113,088 | 3.92 MB |
| `tesseract-core-simd-lstm.wasm` | — | 2.74 MB (+ 0.12 MB JS loader) |
| `tesseract-core-lstm.wasm` (no SIMD) | — | 2.74 MB |
| `tesseract-core-simd.wasm` (full, not LSTM-only) | — | 3.31 MB |

**A fully offline Hebrew scanner in a browser is ≈ 3.8 MB of assets** — the SIMD LSTM core plus the
fast Hebrew model. Roughly 6.6 MB if the non-SIMD core ships as a fallback.

Note `eng.traineddata` is *larger* than `heb.traineddata` in the same repository. If labels need
`heb+eng` (Part 6), English is the expensive half.

> **[r5] Labels do need `heb+eng`, and English is indeed the expensive half.** Both models now
> ship: 0.92 MB Hebrew + 3.92 MB English. The Hebrew model cannot read a column of bare Latin
> digits — on a real panel it returned 218/9/2/43/9/308 where the label printed
> 238/10.9/41.2/7/3.3/368, and more resolution did not help. `tessdata_best/heb` was measured as
> an alternative and is also wrong, *and* drops the geresh in `גר'`, which would break
> serving-basis detection. The browser therefore fetches ~4 MB more, same-origin. What it costs on
> pointed Hebrew is recorded in `TessdataBundle` and in the handoff.

### Decisions this forces

- **SIMD or not.** wasm SIMD needs Chrome ≥ 91, Firefox ≥ 90, **Safari ≥ 16.4**. Shipping only the
  SIMD core saves ~2.9 MB and drops older Safari; tesseract.js picks between builds automatically if
  both are present. Given the product is iOS-first and Israeli, older Safari is not a fringe case —
  decide deliberately rather than by omission.
- **`fast` or `best`.** 0.92 MB vs 3.53 MB for some accuracy. Cannot be decided without Part 7's
  corpus, and is a one-line change once it exists.

### Mechanics

- **Threading.** tesseract.js runs in a Web Worker, so recognition does not block the Flutter
  rasteriser. This matters more than it sounds: `m6_handoff.md` records that *"an indeterminate
  `CircularProgressIndicator` on a tab screen hangs `test/widget_test.dart`"*, and a scan that froze
  the UI thread would make that worse.
- **Interop via `dart:js_interop` + `package:web`, never `dart:html`.** `web_support.md` §2 chose
  `sembast_web` partly to keep `flutter build web --wasm` available; `dart:html` would forfeit it.
- **The image handoff is the one place M6's conventions come under pressure.** Convention 2 says the
  pipeline's boundary type is a file-path `String`. In a browser `image_picker_for_web` returns a
  blob URL, not a filesystem path. **Recommend keeping the convention** — a blob URL is still a
  `String`, and tesseract.js accepts one as an image source — rather than widening the boundary to
  `XFile` and leaking a plugin type into `application/`.

---

## Part 5 — What changes in the code

### What does not change: most of it

> The entire pure-Dart half of the pipeline is already platform-agnostic and covered to near 100%.
> `HebrewTextNormaliser`, `HebrewLabelParser`, `IngredientClassifierImpl`, `IngredientRules`,
> `ScanOrchestrator`, and the sealed `ScanResult` touch no plugin and take and return `String`.

A new platform needs **one new `TextRecognitionService` implementation** and an image source. That is
`web_support.md` §3's finding repeating itself — *"the abstraction was not decoration, and it paid for
itself"* — and it is the direct payoff of M6 convention 2, the file-path-`String` boundary that
`m6_preflight.md` fought #83 to establish.

### The six things that do change

1. **The firewall keeps its shape and its polarity.**
   `lib/features/keto_lens/data/adapters/text_recognizer_factory.dart` is two lines:

   ```dart
   export 'unavailable_text_recognizer.dart'
       if (dart.library.io) 'ml_kit_text_recognizer.dart';
   ```

   The native half becomes a Tesseract binding; the web half becomes a tesseract.js adapter. Still
   two arms, still defaulting to the safe one — so any target without a binding gets the honest
   unavailable state rather than a `MissingPluginException`. Carry the gotcha forward: **the analyzer
   does not resolve conditional exports**, so a file importing both the factory and one half needs
   `show`, or `flutter analyze` reports `ambiguous_import` — and CI gates on it.

2. **`UnavailableTextRecognizer` is retained, not deleted.** It is the honest answer for desktop
   before a binding lands, and it is what keeps `ScanFailureReason.unavailable` meaningful. Deleting
   it because "everything is supported now" would leave the next unsupported target with no state to
   render.

3. **`isAvailable` needs a decision.** Its doc comment
   (`text_recognition_service.dart:27`) says it is *"A compile-time fact, not a permission or a device
   capability — it is the same answer for every launch of a given build."* Tesseract breaks that:
   traineddata must be **loaded**, and loading can fail at runtime (a missing asset, a corrupt copy, a
   browser that blocked the fetch).

   **Recommendation: keep `isAvailable` compile-time** — it answers "can this build ever scan?", which
   remains a compile-time fact — and surface a load failure as a `ScanFailed` value. That is M6
   convention 3: *failure is a value, not a fallback*. Whether it warrants a new
   `ScanFailureReason.modelUnavailable` (retryable, distinct copy: "the scanner is still setting up")
   or folds into the existing `recognitionFailed` is a live design call. Both are defensible; the
   existing enum's doc comments make `recognitionFailed` the cheaper fit, since it already covers
   *"a missing plugin, a corrupt image, a platform error. Worth retrying."*

4. **Warm-up is a new cost.** Tesseract initialisation is expensive in a way ML Kit's was not, and it
   is per-session. Native: run recognition in an isolate so it cannot jank the UI. Web: the worker
   handles it. Either way the camera screen needs a first-scan-is-slower state, and it must not be an
   indeterminate spinner on a tab screen — see the gotcha in Part 4.

5. **Both existing plugin adapters are untouched by an engine swap.**
   `CameraControllerSession` and `ImagePickerPhotoPicker` know nothing about OCR. Desktop adds at most
   a third `CameraSession` implementation behind the interface that already exists.

6. **`ios/Runner/Info.plist` needs nothing.** Both usage strings are present and already promise
   on-device processing — a promise a Tesseract swap keeps and a cloud swap would break.

### Test impact

Small, and mostly favourable. `scan_orchestrator_test.dart` mocks the three domain interfaces and is
unaffected. `camera_screen_test.dart` fakes `TextRecognitionService` and is unaffected.
`ml_kit_text_recognizer_test.dart` — which asserts on the `vision#startTextRecognizer` /
`vision#closeTextRecognizer` MethodChannel wire format — is the one file that goes away with ML Kit,
and its replacement is the same pattern pointed at the new binding's channel.

The firewall's asymmetric coverage stays asymmetric: `text_recognizer_factory_test.dart` can only
observe the VM half. The web half remains verified by CI's `flutter build web` step and a bundle
grep, not by a test — the same honest gap M6 documented.

---

## Part 6 — Accuracy work that is engine-independent

Cheaper than any port, and it helps whichever engine wins.

- ~~**#257 — scanned macros are per 100 g but logged as the serving.**~~ **Fixed in #281** — was the highest-value open
  defect in the project (`mvp_handoff.md`). Independent of everything in this document; fix it
  regardless of which engine ships.

- **Nothing pre-processes the image.** The crop guide is drawn but the full frame goes to OCR, so
  everything else on the packet competes with the nutrition table. `m6_handoff.md` already calls this
  *"likely the cheapest accuracy win."* It matters more with Tesseract than it did with ML Kit:
  **Tesseract is materially more sensitive to input quality** — it has no scene-text detection stage
  of its own, so crop, greyscale, contrast and deskew do work the engine will not do for you. This
  reopens the `image` package decision, which `m6_preflight.md` §2.1 refused on sound grounds
  (*"Add it when something crops"*). Something would now crop.

  > **[r5] Confirmed the hard way, and `image` is now a dependency.** "Materially more sensitive to
  > input quality" turned out to understate it. Two properties of the *input*, with no bearing on
  > the parser, were enough to make a clean label unreadable: it was small (580 px wide), and it was
  > in colour. **Greyscale is not a nicety — handed a 4-channel or even a 3-channel buffer,
  > Tesseract read every Hebrew row of the test label and not one digit.** `OcrImagePrep` and
  > `ScalingTextRecognizer` are the result.

- **Page-segmentation tuning.** A nutrition table is a specific layout. `--psm 6` (assume a single
  uniform block) and `--psm 4` (variable-size columns) are the two candidates, with
  `preserve_interword_spaces=1`. `flutter_tesseract_ocr` exposes these through its `args` map.
  Untuned Tesseract on a two-column label is a known weak spot, and `HebrewLabelParser` already
  handles a two-column split — so the parser and the PSM setting must be chosen together.

  > **[r5] Settled, and this bullet called it.** M6 shipped `--psm 6`; a user then scanned a real
  > bordered Israeli panel and six of its nine rows came back as punctuation. **`--psm 4` is now
  > the setting on all three adapters.** `preserve_interword_spaces=1` was *not* adopted — see §1
  > of the handoff, it is a regression on RTL. The "known weak spot" above was exactly right and
  > cost a user a failed scan before it was acted on. See `m6_platform_handoff.md` §"The scan that
  > read nothing".

- **Bidi in the engine's output.** Tesseract emits Hebrew in logical order. `HebrewTextNormaliser`
  already strips U+200E/U+200F and normalises geresh variants and the decimal comma. Verify it
  against **real Tesseract output**, not against the existing fixtures — see Part 7.

- **`heb` alone vs `heb+eng`.** Israeli labels mix Hebrew with Arabic numerals and occasional English
  (`Protein`, brand names, units). Both configurations should be measured; `eng` costs 3.92 MB on top.

---

## Part 7 — Rescoping #256, and the corpus problem

Issue #256 is currently shaped as *measure ML Kit's OCR accuracy*. Given Part 0 that question has a
predictable and uninteresting answer. It should become:

> **Measure candidate engines against a corpus of real Israeli nutrition labels.**

And the corpus is the actual prerequisite — for the engine choice, for the pre-processing work, for
the PSM setting, for `fast`-vs-`best`, and for every accuracy claim in this document.

`m6_handoff.md`'s warning is the trap this whole exercise exists to avoid repeating, and it is worth
quoting rather than paraphrasing:

> The parser is tested against six hand-written fixtures which are realistic — plural keywords, a
> decimal comma, niqqud, a two-column split, a saturated-fat sub-row — but **they were written by the
> same person who wrote the parser, which is exactly the kind of test that passes and then fails on a
> real label.**

**Recommendation:** 20–30 photographed Israeli nutrition labels with hand-transcribed ground truth,
committed as an evaluation fixture set. Vary what actually varies in a shop — matte and glossy,
flat and curved, one column and two, good light and bad, straight-on and at an angle.

The most important property of that corpus: **it needs no Flutter app.** Running Tesseract over a
folder of photos from a command line answers the central question — *can an off-the-shelf Hebrew
model read Israeli packaging at all?* — before a line of Dart is written, and before any decision in
Part 9 has to be made.

---

## Part 8 — What this research could not verify

Stated plainly, per the convention every M-series handoff in this repo follows.

- **No device, no camera, no simulator, no macOS host**, and the browser has not been driven since M5.
  Every accuracy statement here comes from published documentation and measured file sizes. **Nothing
  was run.**

- **Whether Tesseract's `heb` model actually reads printed Israeli packaging.** Modern Hebrew without
  niqqud, on glossy or curved surfaces, under shop lighting, at an angle, often in a condensed
  display face. Unmeasured. **This is the single claim the entire recommendation rests on**, and
  Part 7 step 1 exists to settle it before anything is committed to.

- **The predicted `ScanFailed(notALabel)` behaviour of the shipped iOS build** is a trace through
  code, not an observation. The enum is a fact; the consequence is an inference.

- **Windows OCR's Hebrew status** is inferred from Microsoft's published OCR language capabilities.
  Confirm on a real Windows machine with `[Windows.Media.Ocr.OcrEngine]::AvailableRecognizerLanguages`
  or `Get-WindowsCapability -Online -Name 'Language.OCR*'`. It changes nothing — Tesseract is the
  Windows recommendation either way — but the table should not assert what was not checked.

- **Apple Vision's Hebrew status** comes from Apple's published Live Text language list, which is the
  same model family. The authoritative check is
  `VNRecognizeTextRequest.supportedRecognitionLanguages()` on a current device. Worth doing before
  writing Vision off entirely, since `technology.md` §1 claims *"best Hebrew quality on-device"* for
  it and that claim came from somewhere.

- **No new platform target has been built.** No `android/`, `macos/`, `windows/` or `linux/` directory
  was created. CocoaPods has still never run on `ios/`, so even the existing iOS target has not had
  its native dependencies resolved.

- **No binding was trialled.** `flutter_tesseract_ocr`, `flusseract` and the FFI option are described
  from their documentation. None was added to `pubspec.yaml`, and pub resolution against riverpod 3 /
  sembast 3.8.10 was not attempted.

---

## Part 9 — Recommended sequencing

Ordered by value per unit of risk. Each step is shaped to become an issue under
`design/issue_conventions.md`.

1. **Build the label corpus and run Tesseract `heb` over it outside Flutter.**
   The cheapest possible answer to the only question that matters, and it needs no app, no device and
   no platform folder. **Everything below is conditional on this.** If off-the-shelf Tesseract cannot
   read Israeli packaging, the honest next question is whether a keto label scanner is buildable
   on-device at all — which is a product question, and one worth reaching early rather than after a
   port.

2. ~~**Fix #257.**~~ Done (#281). It was independent of all of it, and was corrupting the day's macros, the keto ratio,
   the streak evaluation and the phase.

3. **Swap the iOS recogniser to Tesseract**, behind the unchanged `TextRecognitionService` interface,
   measured against the corpus. Reversible, because it is one adapter behind an interface — which is
   exactly what M6 convention 1 bought.

4. **Web: tesseract.js, fully self-hosted.** Reverses the "cannot scan in a browser" decision, needs
   no new platform folder, and is **the only step that can be verified end to end in this
   environment.** `mvp_handoff.md` is emphatic that the browser check repeatedly caught what the test
   suites missed — *"It found a bug 482 passing tests had missed"* — and M6 is the one milestone that
   shipped without it.

5. **Image pre-processing** — crop to the guide, greyscale, contrast, deskew — measured against the
   same corpus. Likely the largest accuracy gain per line of code once Tesseract is in.

6. **Android**, if it becomes a product target. The largest platform-folder cost and the smallest OCR
   cost, since the binding from step 3 already covers it.

7. **Desktop, gallery-import-only, last.** OCR is solved by step 3; the camera is the blocker and is
   not worth solving for a keto app.

The ordering consequence worth stating plainly: **step 4 delivers a working Hebrew scanner on a
platform where one has never existed, and it is the only step in this document that can be proven
without buying hardware.**

---

## Summary

| | |
|---|---|
| **Root cause** | ML Kit has no Hebrew script model. The engine was chosen on a false premise recorded in `technology.md` §1. |
| **Blast radius** | The shipped iOS scanner most likely cannot read any Hebrew label. It fails safely — `ScanFailed(notALabel)` — but it fails. |
| **The one engine that works** | Tesseract + `heb.traineddata`, which also happens to run on all six Flutter targets. |
| **Cost on web** | ≈ 3.8 MB of self-hosted assets. `technology.md`'s "~50 MB" is off by ~50×. |
| **Cost in code** | One new `TextRecognitionService` per platform family. The parser, classifier, normaliser, orchestrator and sealed result are untouched. |
| **Desktop's real blocker** | The camera, not OCR. Ship gallery-only. |
| **What must happen first** | A corpus of real Israeli labels, and a command-line Tesseract run over it. No app required. |
