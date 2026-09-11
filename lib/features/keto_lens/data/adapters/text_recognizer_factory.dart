/// Chooses an OCR implementation for whichever platform this is compiled
/// for.
///
/// The import is resolved at compile time, not with a `kIsWeb` branch: a
/// runtime check would link *both* engines into every target — the wasm core
/// into the iOS app, the FFI bindings into the web bundle — which is the
/// thing a firewall exists to prevent.
///
/// Exactly the shape of `lib/core/database/database_factory.dart`, which
/// `CLAUDE.md`'s layer rules call "the web build's only firewall". This is
/// the second one.
///
/// ## Two arms, not three
///
/// A conditional export can only branch on `dart.library.io`, so it separates
/// "a VM" from "a browser" and no more. That is the right seam anyway, because
/// it is exactly where the *engine* changes:
///
/// ```
/// browser  ->  tesseract_js_text_recognizer.dart      tesseract.js (wasm)
/// VM       ->  tesseract_native_text_recognizer.dart  libtesseract
/// ```
///
/// The finer split — Android and iOS take the plugin, desktop takes FFI —
/// cannot be expressed here and happens at run time inside the VM half, where
/// `Platform` is legal to ask.
///
/// ## What changed, and why the polarity did not
///
/// M6 shipped this as `unavailable` defaulting to `ml_kit_text_recognizer`,
/// because ML Kit is native-only and the browser had no on-device option. It
/// turned out ML Kit could not read Hebrew on *any* platform — its script enum
/// is latin/chinese/devanagiri/japanese/korean — so the engine changed to
/// Tesseract, which happens to reach every target, and the browser stopped
/// being a special case. `design/m6_platform_research.md` has the whole story.
///
/// The default is still the non-VM file. Both halves are real engines now, so
/// nothing unsafe rides on that, but the habit is worth keeping: a target
/// nobody has thought about yet should land on the implementation with no
/// `dart:io` in it.
///
/// Exposes `createTextRecognitionService()`. `textRecognitionServiceProvider`
/// in `data/providers.dart` is the only caller.
///
/// **Note for anything importing this file and a half of it at once:** the
/// analyzer does not resolve a conditional export, sees
/// `createTextRecognitionService` declared twice, and reports
/// `ambiguous_import`. Use `show` on one of the imports; CI gates on
/// `flutter analyze`.
library;

export 'tesseract_js_text_recognizer.dart'
    if (dart.library.io) 'tesseract_native_text_recognizer.dart';
