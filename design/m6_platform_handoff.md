# M6 platform handoff — Keto Lens on six targets

**Status:** code-complete on all six Flutter targets, and **every one of them
now builds on a CI runner of its own OS.**

**Two are verified end to end** — web and Linux, both driven, both scanning
Hebrew. **Four compile and only compile**: Android, iOS, macOS and Windows have
a green build job and nothing more. No window has opened on any of them and no
scan has ever run there. That distinction is the whole point of §"What is
verified", which is the first thing to read.

Getting those four to compile found **one real defect per platform**, none of
them visible to `analyze`, to the test suite, or to the `build web` gate — see
§"What compiling on real runners found".

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
| **macOS** | same FFI adapter | gallery (`image_picker_macos`) | ⚠️ **compiled** on a macOS CI runner (`build-macos.yml`, ad-hoc signed) — never run |
| **Windows** | same FFI adapter | gallery (`image_picker_windows`) | ⚠️ **compiled** on a Windows CI runner (`build-windows.yml`) — never run |
| **Android** | `flutter_tesseract_ocr` (ships prebuilt libs) | `camera`, `image_picker` | ⚠️ **compiled** on a CI runner (`build-android.yml`, debug keystore) — never run |
| **iOS** | `flutter_tesseract_ocr` | `camera`, `image_picker` | ⚠️ **compiled** on a macOS CI runner (`build-ios.yml`, unsigned) — never run |

**"Compiled" is not "works".** Five of the six now have a CI job that builds
them on a real runner of that OS, which means a regression turns a check red.
It does not mean anyone has launched the app: on Android, iOS, macOS and
Windows **no window has ever opened and no scan has ever run**. Only web and
Linux have been driven.

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
- **Every target assembles on a real runner of its own OS**, and both OCR
  libraries open by their shipped names on macOS and Windows — proven by
  `tool/tesseract_dylib_probe.dart` against the app's own candidate list, not
  against a copy of it.
- **The Linux smoke test catches a startup failure**, validated by negative
  control: the `path_provider` fault and a notification-shaped fault were each
  injected and each turned the job red for the right reason. A smoke test
  nobody has watched fail is not a smoke test.
- **`tesseract_ffi_recognizer_test.dart` now actually runs in CI.** It
  self-skips wherever libtesseract is absent and had therefore never once
  executed on a runner; `build-linux.yml` installs Tesseract and treats a
  self-skip as a failure.
- The suite, `analyze` and `format` stay clean, and the `web` and `linux`
  release builds succeed.

**Not verified, and nobody should read this document as claiming otherwise:**

- **Android, iOS, macOS and Windows compile, and only compile.** Each has a CI
  job that builds it on a real runner of that OS — see §"What compiling on real
  runners found" for the five defects that surfaced, one per platform. A green
  check means the target assembles and a regression will turn it red. **It does
  not mean the app runs**: no window has opened, no database has been created
  on any of those four, and `flutter_tesseract_ocr` has still never *executed*
  anywhere. It remains the one dependency here chosen for a capability this
  repo cannot exercise.
- **What the iOS build settled specifically.** `.github/workflows/build-ios.yml`
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

## What compiling on real runners found

Five platform build jobs were added after this document's first draft. Every
single platform this repository created blind carried a defect that **only a
real toolchain of that OS could surface** — none of them were visible to
`flutter analyze`, to `flutter test`, or to the existing `build web` gate.

| Platform | Defect | Would have shipped as |
|---|---|---|
| **Android** | `flutter_tesseract_ocr`'s `build.gradle` calls `jcenter()`, removed in Gradle 9. The `flutter create` template pinned Gradle 9.3.1, so the plugin's script could not be *evaluated* | The Android build dying in configuration, before compiling a line |
| **iOS** | `assets/tessdata` was declared in `pubspec.yaml` but not added to `Runner.xcodeproj`. The iOS plugin reads `Bundle.main.bundleURL/tessdata`, **not** the Flutter asset bundle | Every scan on every device failing at Tesseract init |
| **macOS** | Every bare dylib leaf name missed. dyld resolves unqualified names against `DYLD_FALLBACK_LIBRARY_PATH`, which excludes `/opt/homebrew`; the real file is `libleptonica.6.dylib`, not the guessed `liblept.5.dylib` | A user with Tesseract correctly installed being told to install Tesseract |
| **Windows** | Every Leptonica DLL candidate was wrong. Chocolatey's tesseract 5.5.3 ships `libleptonica-6.dll` | The same: `isAvailable` is false if *either* library fails |
| **Linux** | Three fatal startup bugs (§"What running it changed" item 4), found by running the app rather than by any test | The app dying on its error screen before the first real frame |

The Android and Linux fixes were to the *toolchain and the app*; the macOS and
Windows fixes were to a **list of library names written by guessing**, which is
the part worth remembering. Those names analysed clean, compiled clean and were
wrong on every entry that mattered. A guess that compiles is indistinguishable
from a fact until something runs it.

### Three traps the runs recorded

- **The shell changes the answer on Windows.** `libtesseract-5.dll` fails with
  error 127 (`ERROR_PROC_NOT_FOUND`) when launched from Git Bash: Git for
  Windows puts its MSYS2 `mingw64\bin` ahead on `PATH` and libtesseract's
  imports bind there. Absolute paths do not help — Dart calls plain
  `LoadLibraryW`. A real user-facing trap, not a CI artefact, and the probe now
  distinguishes 126 (wrong name) from 127 (right name, hostile `PATH`).
- **The Windows notification path silently drops `matchDateTimeComponents`.**
  The "daily" reminder schedules exactly one toast. `main` reschedules on every
  launch, so a user who opens the app stays reminded and one who does not,
  stops.
- **macOS plugins integrate via SwiftPM, not CocoaPods** — so the Podfile
  trouble this document and `cicd_plan.md` §10 both predicted for macOS may
  never arrive. iOS is the opposite: `flutter_tesseract_ocr` is the only plugin
  there still on CocoaPods, and Flutter already warns that non-SPM plugins
  *"will become an error in a future version"*.

### The macOS App Sandbox question is open

`Release.entitlements` sets `com.apple.security.app-sandbox`. The sandbox denies
reads outside the container bar a fixed set of system paths, and `/opt/homebrew`
is not among them — **so the shipped app may be unable to open the dylib CI has
just proved is present.** An attempt to settle it by codesigning a probe with
the app's own entitlements died at `SIGTRAP` (a bare executable has no container
for `libsystem_secinit`), which is inconclusive rather than evidence, so the
step was removed rather than left answering nothing forever.

Settling it needs the real `.app` on a real Mac. The fix, if one is needed, is a
product decision with a distribution consequence — ship unsandboxed and lose the
Mac App Store, bundle libtesseract inside the `.app`, or accept no OCR on macOS
— and wants its own issue. Hardened runtime is a separate second problem:
notarisation enables library validation, which would reject an ad-hoc-signed
Homebrew dylib on its own terms.

---

## The serving-basis fix (#257, PR #281)

The highest-value open defect in the project, and it is closed. An Israeli label
declares its macros **per 100 g**; the parser read the numbers and recorded
nothing about what they were *per*, so a user who scanned a 30 g bar and tapped
through logged the whole 100 g — and the day's macros, the keto ratio, the
streak evaluation and the adaptation phase were all computed from a figure more
than three times too large. M6 shipped a caption asking the user to do the
arithmetic.

**What shipped**

- `ServingBasis {per100g, per100ml, perServing, unknown}` in `domain/models/`,
  with an `isPerHundred` extension so the parser, the sheet and the tests cannot
  disagree about whether `per100ml` scales. It does.
- `ParsedLabel` gains `basis` (**defaulting to `unknown`**) and `servingGrams`.
  The default is the migration promise: every `ParsedLabel` built without a
  basis — every older fixture, and the parser's own never-throws failure path —
  keeps M6's behaviour untouched.
- `ScanResultSheet`'s success half is now a small `StatefulWidget` with an
  amount field, defaulted to the label's own declared serving where it printed
  one and to 100 otherwise (a no-op scale). **The macro strip shows what will be
  logged, not what is printed**, so the number in front of the user when they
  save is the number that gets saved.

**Three decisions worth not re-litigating**

1. **The parser refuses to guess.** Exactly one basis marker resolves to that
   basis; zero *or more than one* resolves to `unknown`. More-than-one is the
   common and dangerous case — many Israeli labels print two columns and
   flattened OCR cannot say which column a number came from. Picking one would
   produce a plausible, wrong, silently-logged figure, which is the defect the
   issue existed to remove.
2. **An empty or unparseable amount falls back to the printed figures, never
   to zero.** A zero-macro meal saves without complaint and is then invisible in
   the day's totals — the same silent-wrong-number failure in a new place.
3. **`perServing` labels offer no amount field.** The figures already describe
   one serving; a grams box there would invite dividing by 100 a number that was
   never per 100 of anything. If "I ate 2 servings" is wanted, it is a
   multiplier, not this field.

**Two things fixed alongside, because leaving either would have been knowingly
shipping a defect**

- The `Infinity`/`NaN`-safe numeric parse moved from `OnboardingValidators` to
  `core/utils/NumericInput`. This change added the second screen that takes a
  number, and duplicating that guard is precisely the drift its own doc comment
  warned against. `OnboardingValidators.positiveFinite` delegates; no behaviour
  change.
- **`TessdataBundle`'s model unpack is now atomic** (write to a private name,
  then `rename`). The in-process future serialises callers inside one app but
  not across processes, and two parallel test suites sharing the directory
  produced exactly one unreproducible OCR failure — the worst way for a race to
  announce itself.

---

## The scan that read nothing — what the shipped engine settings got wrong

**Added after this handoff was first written.** A user scanned a clean,
well-lit crop of a real Israeli nutrition panel — whole wheat + rye bread, a
bordered two-column table with the numbers in the left column — and Keto Lens
reported `ScanFailed(notALabel)`.

**The pipeline was innocent.** `HebrewLabelParser`, `HebrewTextNormaliser`,
`IngredientClassifier` and `ScanOrchestrator` all behaved correctly, and the
orchestrator correctly refused to invent a verdict. Every macro was `null`
because the engine had returned six of the nine rows as punctuation rubble
(`%- |`, `|`, `היווה`) and misread `100` as `106`. The defect was entirely in
the engine configuration the three adapters share.

**Four independent causes. Fixing any three of them still fails.**

| # | Cause | Evidence |
|---|---|---|
| 1 | `psm 6` flattens a bordered table | six of nine rows lost; `psm 4` keeps each row with its number |
| 2 | `heb` alone cannot read an isolated Latin digit column | returned 218/9/2/43/9/308 for 238/10.9/41.2/7/3.3/368 |
| 3 | Tesseract *estimated* the resolution, at **631 dpi**, and downscaled internally on that basis | declaring `user_defined_dpi` stops the guess |
| 4 | a **colour** buffer makes it drop every digit | 4-channel and 3-channel both read zero numbers; 1-channel greyscale reads all of them |

Cause 3 is the one nobody was looking for, and it is invisible: Tesseract logs
`Estimating resolution as 631` to stderr and then quietly degrades. Cause 4 was
introduced *by the fix for cause 1* and is the more dangerous shape — every
Hebrew row survived, so the output looked healthy while every number was gone.

### What this cost, and what it did not

`eng.traineddata` adds **3.92 MB** to every bundle and to the browser's
same-origin fetch. It is a trade, not a free win: on **pointed (niqqud)**
Hebrew the English model sometimes wins a word it should not, and the
`pointedWafer` fixture now loses its carbohydrate row. That degradation is to
`null` — "not found" — so the sheet asks the user rather than stating a figure.
It is never `0`.

**A second `heb`-only pass to recover it was considered and rejected.** It would
fill a safe `null` from a pass measured to be unreliable on digits, turning "the
app asks" into "the app guesses". #257 is why that direction is closed. Do not
reintroduce it.

### The margin is thin, and that is the honest finding

Sweeping interpolation against target width on this label, scored by what the
parser extracts, does not show a broad plateau — it shows a narrow one:

```
           1200  1400  1600  1800  2000  2400
  cubic     ok    -p    -p    -p    xx    fat=0.5
  linear    -p    ok    ok    xx    xx    fat=53.0
  average   ok    -f-p  ok    -c-p  xx    fat=9.0
```

`linear` at 1600 is chosen because it is the only kernel correct at two
*adjacent* widths. Read the right-hand columns as the warning they are: at
other settings the engine returns a **plausible wrong** fat figure — 0.5 is the
saturated-fat sub-row, 53.0 is nothing on the label at all — rather than
failing visibly. This is a 580×498 image at the edge of what the engine can do.
These numbers are evidence that linear/1600 is right *here*, not in general.

### Engine output is not stable across Tesseract versions

**Found by CI, and it is the most transferable lesson in this section.** The
macOS runner installs Tesseract **5.5.3** from brew; the container this was
developed in has **5.3.4**. Given the *same image*, the same `psm 4`,
`heb+eng`, `user_defined_dpi=300` and the same preparation step, the two
engines disagree:

| 5.3.4 | 5.5.3 |
|---|---|
| `חלבונים (גרם) 10.9` | **`חזלבונים`** `(גרם) 10.9` |
| `כלל סיבים תזונתיים (גרם) ] 7` | `... (גרם) § 7` |
| `שומנים (גרם) 3.3` | `3.3 (Da) ‏שומנים‎` |

The parser's `חלבו[נן]` does not match `חזלבונים`, so **on a Mac this label
logged with protein silently missing** — every other macro present, basis
correctly `per100g`, and a hole in the middle of a confident-looking result.

Three consequences, all of them now enforced in code:

1. **Never assert on raw OCR text.** `expect(text, contains('חלבונים'))` is a
   latent cross-platform failure: it pins bytes that legitimately vary by
   engine build. **Assert the parsed result instead** — `fatG`, `netCarbsG`,
   `proteinG`, `basis`. That is both stabler *and* stronger, because it is the
   property a user actually depends on. The one remaining raw-text assertion
   is in `real_ocr_pipeline_test.dart`, and it exists precisely to prove a
   fixture still *contains* the corruption it is there to exercise.
2. **The parser tolerates one corrupted letter per keyword**, and the
   disqualifier tolerates one too. See `HebrewLabelParser._tolerant` for why
   it is that narrow: a matcher loose enough to let `שומנים` claim the
   `מתוכם שומן רווי` row would report saturated fat as total fat, which is far
   worse than the missing protein it fixes. Tolerance is capped at one error,
   never substitutes the first or last letter, and is refused entirely for
   keywords under four letters.
3. **A fixture per engine version.** `test/fixtures/ci_ocr_fixture.dart` holds
   the 5.5.3 capture, kept out of the generated `real_ocr_fixture.dart`
   because it was transcribed from a CI log rather than produced by
   `tool/capture_ocr_fixtures.sh`. The pipeline assertions run against both.

**This also qualifies the interpolation sweep above.** Those numbers were
measured on **5.3.4 only**. The narrow ridge they identify — `linear` at
1600 px — may well sit somewhere else on another engine build, and nothing
here has checked. Treat the table as evidence that the margin is thin, not as
a calibration that transfers.

### Still not verified

The committed fixture image is **screenshot quality** — a clean, flat crop, not
a photograph taken at arm's length off a curved bread bag under supermarket
lighting. There is still **no camera in this repository**, no accuracy figure
is claimed, and **#256 and Epic #10 stay open**. The browser's canvas
preprocessing path has never executed in a real browser, and the mobile plugin
path has never executed at all.

---

## Conventions inherited

1. **One engine, every platform.** The same argument `web_support.md` §1 used to
   replace Isar with sembast rather than maintain two backends. Do not
   reintroduce a per-platform engine without a measured reason.
2. **`preserve_interword_spaces` stays unset.** It is a regression, not a
   tuning knob, on RTL text.
2b. **Every engine parameter is set in all three adapters, or in none.** `psm`,
   the language pair, the OCR engine mode and `user_defined_dpi` each appear in
   the web JS shim, the mobile plugin and the desktop FFI half. A setting
   changed in one place is a platform quietly running a different engine.
2c. **Tesseract gets a single-channel greyscale image, never colour.** Measured:
   colour costs every digit while keeping every Hebrew row. Flattening alpha is
   not sufficient — three-channel fails identically.
2e. **Assert the parsed result, never the raw OCR text.** Engine output varies
   by Tesseract build; the pipeline's output is the only stable contract.
2d. **A fixture is captured through the app's own preparation code**, not through
   a reimplementation of it. `tool/capture_ocr_fixtures.py` shells out to
   `tool/prepare_for_ocr.dart` for exactly this reason: a Pillow reimplementation
   produced an easier image than the app submits, and the fixture recorded a
   pipeline that does not exist.
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

- ~~**#257 — scanned macros are per 100 g, logged as the serving.**~~ **Fixed
  (#281)**, and it was the highest-value open defect in the project. See
  §"The serving-basis fix" above for what shipped and what it deliberately
  refuses to do.
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
- **The macOS App Sandbox may block the dylib.** `Release.entitlements` sets
  `com.apple.security.app-sandbox`; the sandbox denies reads outside the
  container and `/opt/homebrew` is not exempt, so the shipped app may be unable
  to open the library CI proves is present. Unresolved and **not resolvable
  without a Mac** — see §"What compiling on real runners found".
- **`ios/Podfile.lock` is gitignored** by the root `*.lock` rule, so pod
  versions are reproducible only from a CI log. Worth un-ignoring, but it needs
  someone with a Mac to run `pod install` and commit the result.
- **The Windows daily reminder is one-shot.** The Windows notification path
  silently drops `matchDateTimeComponents`. `main` reschedules on every launch,
  so a user who opens the app stays reminded and one who does not, stops.

---

## If you pick this up next

Ordered by value, and the first item has not moved in three handoffs.

1. **Get it on a device, or at least photograph some labels.** Every accuracy
   claim in this project still rests on rendered text, not photographs. #256 and
   Epic #10 cannot close until someone points a camera at an Israeli product.
   `design/m6_platform_research.md` Part 7 describes the corpus; it needs no app
   and no Flutter, just a phone and `tesseract`.
2. **Image pre-processing** — crop to the guide, greyscale, contrast, deskew.
   Cheapest remaining accuracy win, and measurable against that corpus the day
   it exists.
3. **Decide the macOS sandbox question.** It is a product decision with a
   distribution consequence (ship unsandboxed and lose the Mac App Store /
   bundle libtesseract in the `.app` / accept no OCR on macOS), not an
   engineering one, and it wants its own issue.
4. **Audit M7 (#88–#94)** and write `design/m7_preflight.md` before implementing
   any of it — every milestone so far has needed that audit, and every one found
   defects that would have compiled and shipped wrong behaviour.

### Two process notes for whoever reads this next

- **Six PRs (#277–#282, #285) were merged without a review approval**, which
  `design/pr_conventions.md` §6 forbids. It was done on an explicit instruction
  to merge on green. CI green means the target assembles and the suite passes —
  **not that the diff is right**, and no human has read these. Worth a
  retrospective read of the platform workflows in particular.
- **A conflicted PR gets no CI run at all** (`m4_handoff.md` said so; it bit
  twice more here). A green result from before a conflict appeared is stale —
  re-check mergeability before merging, not just the checks.
