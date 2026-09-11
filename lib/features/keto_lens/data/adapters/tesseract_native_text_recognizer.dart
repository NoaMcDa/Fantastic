import 'dart:io';

import 'package:fantastic/features/keto_lens/data/adapters/scaling_text_recognizer.dart';
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
/// The first two are wrapped in [ScalingTextRecognizer]; see below.
///
/// The fallback is not dead code. `Platform` has values this project has never
/// built for, and a scanner that says "not here" beats one that throws an
/// unhandled error on a target nobody anticipated — the same safe-by-default
/// polarity the firewall itself uses.
///
/// ## Both real bindings are wrapped, the fallback is not
///
/// [ScalingTextRecognizer] normalises the image's size before recognition —
/// the fix for a 580x498 crop of a real nutrition panel that Tesseract could
/// not read. It belongs here rather than inside either binding because both
/// bindings need it and they share no code: one is a method channel, the
/// other is FFI. Wrapping once is what makes all five native targets apply
/// one rule.
///
/// [UnavailableTextRecognizer] is deliberately left bare. Resizing an image
/// for an engine that does not exist is work with no possible payoff, and
/// wrapping it would mean a platform with no OCR still paid for a decode.
TextRecognitionService createTextRecognitionService() {
  if (Platform.isAndroid || Platform.isIOS) {
    return const ScalingTextRecognizer(TesseractPluginRecognizer());
  }
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    return const ScalingTextRecognizer(TesseractFfiRecognizer());
  }
  return const UnavailableTextRecognizer();
}
