import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// The native half of the OCR firewall — Google ML Kit on-device text
/// recognition.
///
/// **This file is the only place in `lib/` that imports ML Kit**, and it is
/// reached only through the conditional export in
/// `text_recognizer_factory.dart`, on `dart.library.io`. The shape is copied
/// from `lib/core/database/database_factory_io.dart`, which `CLAUDE.md` calls
/// "the web build's only firewall" against `dart:io` and `path_provider`.
///
/// Unlike that case, the web build does not actually *fail* to compile with
/// ML Kit in it — `design/m6_preflight.md` Part 0 proves that with three
/// spike builds. The firewall is here for the other three reasons: a browser
/// gets a deliberate unavailable state instead of a raw
/// `MissingPluginException`, `InputImage` never escapes `data/`, and a future
/// version of the package need not stay so forgiving.
class MlKitTextRecognizer implements TextRecognitionService {
  const MlKitTextRecognizer();

  @override
  bool get isAvailable => true;

  @override
  Future<String> recognise(String imagePath) async {
    // `TextRecognitionScript.latin` is the default and is correct: ML Kit
    // has no Hebrew model. Hebrew is recognised by the Latin script
    // recogniser, and `HebrewLabelParser` does the Hebrew-aware work on the
    // string that comes back.
    final recognizer = TextRecognizer();
    try {
      final result = await recognizer.processImage(
        // The one and only construction of an ML Kit type in this codebase.
        // `fromFilePath` rather than `fromFile`: the latter takes a
        // `dart:io` `File`, and there is no reason to name that type here.
        InputImage.fromFilePath(imagePath),
      );
      // `RecognizedText.text` is the whole recognised string, already
      // assembled by the plugin. #80 rebuilt it from `blocks` by hand, which
      // is the same value with more ways to be wrong.
      return result.text;
    } finally {
      // In a `finally` so the native recogniser is released even when
      // `processImage` throws — it holds a model in memory on the platform
      // side, and a leaked one survives the scan.
      await recognizer.close();
    }
  }
}

/// Builds the recogniser for a platform that has a VM.
///
/// The `dart.library.io` half of `text_recognizer_factory.dart`.
TextRecognitionService createTextRecognitionService() =>
    const MlKitTextRecognizer();
