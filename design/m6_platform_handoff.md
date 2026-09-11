# M6 platform handoff — Keto Lens on six targets

**Status:** code-complete on all six Flutter targets. **Verified end to end on
two of them** (web and Linux). **iOS compiles** — unsigned, on a macOS CI
runner — but has never been run. Android, macOS and Windows are configured and
analysed and nothing more, because this repository has no Android SDK, no macOS
host and no Windows machine. §"What is verified" is the honest line, and it is
the first thing to read.

Supersedes the *engine* recommendation in `design/m6_platform_research.md`,
which is otherwise still accurate. Three of that document's specifics turned out
to be wrong once an engine actually ran; they are corrected in §"What running it
changed".

---

## What shipped

**Google ML Kit is gone.** Its script enum is
`latin, chinese, devanagiri, japanese, korean` — there is no Hebrew model, and
`MlKitTextRecognizer` was calling the bare `TextRecognizer()`, which defaults to
`latin`. Every platform now runs Tesseract with the Hebrew model, behind the
unchanged `TextRecognitionService` interface.

| Target | Engine | Image source | Built here? |
|---|---|---|---|
| **Web** | tesseract.js 7 (wasm), self-hosted in `web/tesseract/` | `camera_web`, `image_picker_for_web` | ✅ built **and driven in Chromium** |
| **Linux** | `libtesseract` via `dart:ffi` | gallery (`image_picker_linux`) | ✅ built **and run** |
| **macOS** | same FFI adapter | gallery (`image_picker_macos`) | ✗ no macOS host |
| **Windows** | same FFI adapter | gallery (`image_picker_windows`) | ✗ no Windows host |
| **Android** | `flutter_tesseract_ocr` (ships prebuilt libs) | `camera`, `image_picker` | ✗ no Android SDK |
| **iOS** | `flutter_tesseract_ocr` | `camera`, `image_picker` | ⚠️ **compiled** on a macOS CI runner (`build-ios.yml`, unsigned) — never run |

**The lens tab scans in a browser.** That reverses M6's central product
decision — *"Keto Lens cannot scan in a browser, and the tab says so"* — which
was correct when the only on-device option was a native-only plugin. Tesseract
compiled to WebAssembly runs in a Web Worker on the user's machine, so Epic
#10's no-network invariant survives intact. Measured in Chromium against the
built release bundle: **a full Hebrew scan in 0.5 s with zero external
requests.**

### Architecture

The firewall keeps its shape and its safe-by-default polarity. It still has two
arms, because `dart.library.io` is the only thing a conditional export can ask:

```
text_recognizer_factory.dart
  browser → tesseract_js_text_recognizer.dart      tesseract.js, via window.fantasticOcr
  VM      → tesseract_native_text_recognizer.dart  dispatches on Platform:
                                                     android/ios → TesseractPluginRecognizer
                                                     desktop     → TesseractFfiRecognizer
                                                     otherwise   → UnavailableTextRecognizer
```

`UnavailableTextRecognizer` is retained, not deleted. It is the honest answer
for a target nobody has thought about yet, and it is what keeps
`ScanFailureReason.unavailable` meaningful.

**Nothing above `data/` changed.** `HebrewTextNormaliser`, `HebrewLabelParser`,
`IngredientClassifierImpl`, `IngredientRules`, `ScanOrchestrator` and the sealed
`ScanResult` were not touched by any of this — the entire engine swap plus five
new platforms cost one new file per platform family. That is the file-path-`String`
boundary (M6 convention 2) paying for itself, exactly as
`design/web_support.md` §3 said the repository-interface boundary did.

---

## What running it changed

Six things that only showed up because something actually executed. The first
two correct `design/m6_platform_research.md`; the third re-confirms a trap
`design/web_support.md` already documented; the last three are new.

### 1. `preserve_interword_spaces=1` destroys RTL Hebrew spacing

The research doc recommended setting it, from the documentation. It is wrong
for Hebrew, and badly:

| Setting | Output |
|---|---|
| `preserve_interword_spaces=1` | `שומנים 53.8גרם` · `משומשוםמלא` |
| unset (shipped) | `שומנים 53.8 גרם` · `משומשום מלא` |

Measured on **both** engines — libtesseract 5.3.4 over FFI, and the wasm build
in Chromium — with identical results, so it is the engine's RTL handling and
not a binding artefact. All three adapters leave it unset, and
`tesseract_ffi_recognizer_test.dart` has a regression guard.

The general lesson is the project's own, again: a parameter that reads as the
safe choice in English documentation is not necessarily safe in Hebrew.

### 2. The web asset budget is bigger than estimated, and the transfer is not

The research doc costed a browser scanner at ≈3.8 MB from `tesseract.js-core`
6.1.2. tesseract.js 7.0.0 depends on core **7**, which npm's `latest` tag does
not point at, and core 7 requests `relaxedsimd` variants that core 6 does not
ship. Corrected, measured:

| | Deployed | Downloaded by one browser |
|---|---|---|
| Core (3 LSTM variants: plain, SIMD, relaxed-SIMD) | 11.2 MB | 3.7 MB — one variant, feature-detected |
| `heb.traineddata` (tessdata_fast) | 0.92 MB — **shared, not duplicated** | 0.92 MB |
| `tesseract.min.js` + `worker.min.js` | 0.17 MB | 0.17 MB |
| **Total** | **≈12.3 MB** | **≈4.8 MB** |

The model is **not** copied into `web/`. Flutter serves the asset bundle under
`assets/`, so `assets/assets/tessdata/heb.traineddata` — the same file the
desktop FFI half unpacks and the mobile plugin reads — is what tesseract.js
fetches. One model for all six platforms and no second copy to drift. It is
served uncompressed, so `gzip: false` is required: otherwise tesseract.js asks
for `heb.traineddata.gz` and Flutter hands back `index.html` with a 200.

Deploy size and transfer size differ by 3× here, and the transfer figure is the
one that matters to a user in a shop.

### 3. `flutter create` dropped `ios` and `web` from `.metadata`

`design/web_support.md` §5 documented this trap after it bit once. It bit again,
exactly as written, and was caught only because the doc said to look. All seven
platform entries are now listed explicitly. **Diff `.metadata` after every
`flutter create`.**

### 4. Three Linux startup bugs, each fatal, none caught by any test

Found by running the built app and looking at the screen. All three rendered the
*database* error screen, which is its own lesson about attributing a failure to
whatever catches it.

1. **`getApplicationDocumentsDirectory()` throws on Linux.**
   `path_provider_linux` shells out to `xdg-user-dir`, which a minimal system
   does not have. `database_factory_io.dart` now uses
   `getApplicationSupportDirectory()` on desktop — which is the semantically
   correct directory for a database the user never opens by hand, and resolves
   from `XDG_DATA_HOME` with no external binary. **Mobile deliberately still
   uses documents**: changing it there would orphan every existing install's
   data.
2. **`flutter_local_notifications` needs a settings object per platform.** A
   missing one is not a no-op — it throws
   `Invalid argument(s): Linux settings must be set…` out of `initialize`.
3. **`zonedSchedule` is not implemented on Linux** (`UnimplementedError`) and
   throws `UnsupportedError` on web.

The fix for (2) and (3) is a capability, not a platform check:
`NotificationService.supportsScheduling` is false by default and each platform
has to earn a true. And `main` now guards notification setup **separately from
the database** — a reminder is a convenience, a database is the app, and a
reminder failure must never keep a user from logging a meal.

### 5. A Dart `'''` literal cannot hold Hebrew OCR output

Hebrew abbreviates grams with a geresh, so captured text routinely *ends* in an
apostrophe and `'''…גר'''';` does not compile. `test/fixtures/real_ocr_fixture.dart`
uses `"""`, and the generator checks for it.

### 6. `flutter_tesseract_ocr` declares a malformed web entry

Its pubspec says `web: default_package: FlutterTesseractOcrPlugin` — a class
name where a package name belongs. That looked like a threat to CI step 6, so it
was tested rather than reasoned about: **`flutter build web --release` succeeds**
with the package present. The web half of our firewall never imports it, so only
the declaration could have mattered, and it does not.

---

## What is verified

Stated plainly, because the rest of this document is only as good as this
section.

**Verified by running it:**

- **Tesseract reads Hebrew nutrition labels.** This was the project's largest
  open claim (#256, Epic #10) and it is now answered for the first time: the
  tahini, protein-bar and wafer labels all came back with every macro keyword
  and every number intact, including an Israeli decimal comma (`22,5`) and a
  niqqud-pointed label. Degraded renders — rotated, blurred, low contrast — were
  read correctly too.
- **The web app scans in a real browser.** Built release bundle, served over
  HTTP, driven in Chromium: 0.5 s per scan, **zero external network requests**,
  no console errors. ML Kit is provably absent from the bundle.
- **The Linux desktop app builds, boots and renders** — Hebrew, RTL, correct
  theme, onboarding screen, clean startup log.
- **The FFI adapter does real OCR inside `flutter test`**
  (`tesseract_ffi_recognizer_test.dart`, skipped where libtesseract is absent).
- **The `dart:js_interop` binding works in a browser**
  (`tesseract_js_text_recognizer_test.dart`, `flutter test --platform chrome`).
- **The pure-Dart pipeline handles genuine engine output**
  (`real_ocr_pipeline_test.dart`, against `RealOcrFixture`).
- 1110 VM tests and 5 browser tests pass; `analyze` and `format` clean; `web`
  and `linux` release builds succeed.

**Not verified, and nobody should read this document as claiming otherwise:**

- **Android, macOS and Windows have never been built.** No SDK, no host. They
  are compiled by the analyzer and configured by hand. `flutter_tesseract_ocr`
  has still never *executed* anywhere — it is the one dependency here chosen
  for a capability this repo cannot exercise.
- **iOS now compiles, and only compiles.** `.github/workflows/build-ios.yml`
  builds it unsigned on a macOS runner, which is where the `Podfile` this
  repository never had now lives and where CocoaPods now runs. Measured on
  Xcode 26.6 / CocoaPods 1.17.0: pods resolve in 10 s, the Xcode build takes
  109 s, and `Runner.app` comes out at 27.7 MB with `heb.traineddata` in it.
  **No simulator ran, no device ran, no camera opened, no scan happened** —
  everything this section says about OCR accuracy is untouched by a compile.
  Three things that build settled, all of which were guesses before:
  - **SwiftyTesseract 3.1.3 — a 2019 pod — still builds under Xcode 26.6.**
    It is what `flutter_tesseract_ocr` depends on, by an *unversioned*
    `s.dependency`, and 3.1.3 is the newest published version, so the
    unconstrained dependency is currently harmless.
  - **`assets/tessdata` had to be added to `Runner.xcodeproj` as a folder
    reference.** The iOS plugin reads `Bundle.main.bundleURL/tessdata`, not
    the Flutter asset bundle, so the model being declared in `pubspec.yaml`
    was never going to be enough. The workflow asserts both copies are in
    the `.app` — nothing else in the repo could have caught this.
  - **`flutter_tesseract_ocr` is the only plugin here still on CocoaPods.**
    Every other iOS plugin resolves through Swift Package Manager, and the
    build prints *"The following plugins do not support Swift Package Manager
    for ios: flutter_tesseract_ocr. This will become an error in a future
    version of Flutter."* A warning today, a broken iOS build on some future
    Flutter. It is one adapter file behind `TextRecognitionService`
    (M6 convention 1), which is what makes that survivable.
- **Nothing has read a *photograph* of a real Israeli product.** The corpus is
  rendered from the app's own font, which closes the gap between "a human
  imagined this OCR output" and "an engine produced it" — the gap that has
  actually bitten this project — but not the gap to glare, curvature, focus and
  shop lighting. `design/m6_platform_research.md` Part 7 is still outstanding,
  and it is still the highest-value next step.
- **No accuracy percentage is claimed.** Epic #10's "≥ 80% of tested Israeli
  products" remains unmeasured; a rendered corpus cannot measure it.
- **The camera has never been exercised on any platform.** Every scan verified
  here started from a file, not a viewfinder.
- **Desktop ships gallery-import-only.** The `camera` plugin declares
  android/ios/web and nothing else; that is a real product limitation, not an
  environment one.

---

## Conventions inherited

1. **One engine, every platform.** The same argument `web_support.md` §1 used to
   replace Isar with sembast rather than maintain two backends. Do not
   reintroduce a per-platform engine without a measured reason.
2. **`preserve_interword_spaces` stays unset.** It is a regression, not a
   tuning knob, on RTL text.
3. **Capability checks, not platform checks**, for anything a plugin may or may
   not implement — `NotificationService.supportsScheduling` is the pattern.
   False by default; each platform earns a true.
4. **An optional subsystem may not take down startup.** Notifications are
   guarded separately from the database in `main`.
5. **Desktop `isAvailable` is a runtime probe**, and that is a deliberate
   departure from the interface's "compile-time fact" wording: the build
   supports OCR, the installed system may not. It is still stable for the life
   of the process, which is all the UI needs, and it is what lets the lens tab
   say *"install Tesseract"* instead of *"scan failed, try again"*.
6. **Captured fixtures are generated, never hand-edited.**
   `tool/capture_ocr_fixtures.sh` regenerates `RealOcrFixture`; its whole value
   is that no hand touched it.
7. **The engine lives behind `web/tesseract/fantastic_ocr.js` on web.** Dart
   knows three method names and nothing about tesseract.js. Changing engines
   should not touch Dart.

---

## Known gaps

- **#257 — scanned macros are per 100 g, logged as the serving.** Untouched by
  any of this and still the highest-value open defect in the project.
- **No image pre-processing.** The crop guide is drawn; the full frame is sent.
  This matters more with Tesseract than it did with ML Kit — it has no scene-text
  detection stage, so crop, greyscale, contrast and deskew are work the engine
  will not do for you. A smaller render of the niqqud label lost its fat row
  entirely (`שׁוּמָן` → `שוּמֶ|`, a final nun read as a pipe), which is the safe
  failure — fat comes back null, never 0 — but a failure. **Cheapest remaining
  accuracy win**, and it reopens the `image` package decision that
  `m6_preflight.md` §2.1 correctly refused when nothing used it.
- **Warm-up is not paid early.** `TesseractJsTextRecognizer.warmUp()` exists and
  nothing calls it, so the first browser scan of a session pays the model load.
- **Desktop needs a system Tesseract.** Nothing bundles libtesseract; the app
  reports its absence and names the fix, but an installer story does not exist.
- **`tessdata_fast` vs `tessdata_best` is unmeasured** — 0.92 MB against 3.5 MB.
  A one-line change once the photographic corpus exists.
