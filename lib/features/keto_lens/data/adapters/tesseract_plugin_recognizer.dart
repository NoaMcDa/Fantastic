import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

import 'package:fantastic/features/keto_lens/data/adapters/ocr_image_prep.dart';
import 'package:fantastic/features/keto_lens/data/adapters/tessdata_bundle.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';

/// The mobile half of the OCR firewall — Hebrew OCR on Android and iOS.
///
/// The desktop half talks to a system libtesseract over FFI, which mobile has
/// no equivalent of: neither platform ships Tesseract, and this repository
/// cannot build a `.so` per ABI or an `.xcframework` for it. `flutter_tesseract_ocr`
/// is the only published binding that carries prebuilt libraries for both, so
/// it is here for the one thing it provides and nothing else.
///
/// It reads its model from the app's `assets/tessdata/` directory, declared in
/// `pubspec.yaml` alongside `assets/tessdata_config.json` — the same asset the
/// desktop half unpacks through [TessdataBundle], so all five native targets
/// recognise against one file.
///
/// **The two platforms find that file differently, and iOS needs project
/// configuration for it.** The Android half copies the declared asset out at
/// run time. The iOS half does not: its plugin reads
/// `Bundle.main.bundleURL/tessdata`, so `assets/tessdata` is *also* added to
/// `ios/Runner.xcodeproj` as a folder reference in Copy Bundle Resources. One
/// model, one source of truth on disk, copied into the `.app` twice — and
/// without the folder reference every scan on a device fails at Tesseract
/// initialisation, with nothing in `flutter analyze` to say so.
/// `.github/workflows/build-ios.yml` asserts it landed.
///
/// **The only file in `lib/` that imports `flutter_tesseract_ocr`.** M6
/// convention 1: one plugin, one adapter, behind an interface. If the binding
/// is ever replaced, this file is the whole change.
///
/// > **Not built or run in this repository.** There is no Android SDK and no
/// > macOS host here, so this adapter is compiled by the analyzer and by
/// > nothing else. See `design/m6_platform_research.md` Part 8.
class TesseractPluginRecognizer implements TextRecognitionService {
  const TesseractPluginRecognizer();

  /// A compile-time fact here, in the sense the interface documents: the
  /// binding ships its own library, so if this build exists at all, OCR runs.
  @override
  bool get isAvailable => true;

  @override
  Future<String> recognise(String imagePath) => FlutterTesseractOcr.extractText(
    imagePath,
    language: TessdataBundle.language,
    args: {
      // Matches the desktop and web halves exactly.
      //
      // `psm 4` — a single column of variable-size text. This was `6`
      // ("a single uniform block") until a user scanned a real Israeli
      // nutrition panel and the app read six of its nine rows as
      // punctuation. A bordered table with its numbers in one column and its
      // Hebrew labels in another is exactly what mode 6 flattens: it returned
      // `%- |` and `|` where `פחמימות (גרם) 41.2` was printed. Mode 4 keeps
      // each row with its own number. Measured on tesseract 5.3.4 against the
      // model this app bundles.
      //
      // `user_defined_dpi` — Tesseract estimates resolution when the file
      // does not declare one, and on that same image it estimated 631 dpi and
      // then downscaled internally on the strength of the guess, which is
      // what destroyed the rows. Declaring a value stops the guess.
      // `OcrImagePrep` has the measurements.
      //
      // `preserve_interword_spaces` is deliberately absent: on RTL Hebrew
      // it removes spaces rather than preserving them. Measured on the FFI
      // and wasm engines; see `design/m6_platform_research.md`.
      'psm': '4',
      'user_defined_dpi': '${OcrImagePrep.assumedDpi}',
    },
  );
}
