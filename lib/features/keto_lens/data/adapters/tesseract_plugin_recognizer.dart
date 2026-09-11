import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

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
    args: const {
      // Matches the desktop and web halves exactly. A nutrition panel is a
      // single uniform block; the default hunts for page columns that are
      // not there.
      //
      // `preserve_interword_spaces` is deliberately absent: on RTL Hebrew
      // it removes spaces rather than preserving them. Measured on the FFI
      // and wasm engines; see `design/m6_platform_research.md`.
      'psm': '6',
    },
  );
}
