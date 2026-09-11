import 'dart:io';

import 'package:fantastic/features/keto_lens/data/adapters/tesseract_ffi_recognizer.dart';
import 'package:fantastic/features/keto_lens/data/adapters/tesseract_plugin_recognizer.dart';
import 'package:fantastic/features/keto_lens/data/adapters/unavailable_text_recognizer.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';

/// The VM half of the OCR firewall — picks the binding for the running OS.
///
/// A conditional export can only branch on what a *compiler* knows, which is
/// `dart.library.io` and nothing finer: it cannot tell Linux from Android,
/// because both are VM targets built by the same front end. So the platform
/// split that the firewall cannot express happens here instead, at run time,
/// on `Platform` — which is sound precisely because every branch below is
/// already inside `dart:io` territory.
///
/// | Platform | Binding | Library |
/// |---|---|---|
/// | Android, iOS | [TesseractPluginRecognizer] | shipped by the plugin |
/// | Linux, macOS, Windows | [TesseractFfiRecognizer] | the system's libtesseract |
/// | anything else | [UnavailableTextRecognizer] | none |
///
/// The fallback is not dead code. `Platform` has values this project has never
/// built for, and a scanner that says "not here" beats one that throws an
/// unhandled error on a target nobody anticipated — the same safe-by-default
/// polarity the firewall itself uses.
TextRecognitionService createTextRecognitionService() {
  if (Platform.isAndroid || Platform.isIOS) {
    return const TesseractPluginRecognizer();
  }
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    return const TesseractFfiRecognizer();
  }
  return const UnavailableTextRecognizer();
}
