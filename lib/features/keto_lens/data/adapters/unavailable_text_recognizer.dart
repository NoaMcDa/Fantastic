import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';

/// The default half of the OCR firewall — no OCR, cleanly.
///
/// Selected by `text_recognizer_factory.dart` on every target that is not a
/// VM, which today means the browser and tomorrow means whatever else
/// appears. Defaulting to *this* file and switching to ML Kit on
/// `dart.library.io` — rather than the other way round — is the same choice
/// `lib/core/database/database_factory.dart` makes, and for the same reason:
/// a target nobody has thought about yet gets the safe half.
///
/// **Imports nothing native.** That is the entire point of the file.
class UnavailableTextRecognizer implements TextRecognitionService {
  const UnavailableTextRecognizer();

  /// Why OCR cannot run here.
  ///
  /// Surfaced in the exception rather than only logged, so a bug report from
  /// a browser says what happened.
  static const String reason =
      'On-device text recognition needs the iOS app. Google ML Kit is a '
      'native-only plugin, and the browser alternative is a network call, '
      'which the scan pipeline does not make.';

  @override
  bool get isAvailable => false;

  /// Always throws.
  ///
  /// Callers are expected to check [isAvailable] and not offer a scan at
  /// all. Throwing rather than returning an empty string is deliberate: an
  /// empty string is indistinguishable from a blank photo, and would be
  /// rendered as "we read the label and found nothing" instead of "we cannot
  /// read labels here".
  @override
  Future<String> recognise(String imagePath) async =>
      throw const TextRecognitionUnavailableException(reason);
}

/// Builds the recogniser for a platform with no OCR.
///
/// The default half of `text_recognizer_factory.dart`.
TextRecognitionService createTextRecognitionService() =>
    const UnavailableTextRecognizer();
