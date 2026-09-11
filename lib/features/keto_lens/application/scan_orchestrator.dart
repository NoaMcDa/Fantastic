import 'package:fantastic/features/keto_lens/data/providers.dart';
import 'package:fantastic/features/keto_lens/domain/models/scan_result.dart';
import 'package:fantastic/features/keto_lens/domain/services/ingredient_classifier.dart';
import 'package:fantastic/features/keto_lens/domain/services/label_parser.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scan_orchestrator.g.dart';

/// Runs the scan pipeline: recognise → parse → classify.
///
/// Depends on three **domain interfaces** and nothing else. #83's snippet
/// imported `google_mlkit_text_recognition` for `InputImage` and the
/// concrete `MlKitTextRecognizer`, both of which contradict its own
/// Technologies table ("Domain interfaces — no concrete imports") and
/// `CLAUDE.md`'s layer rules. The image is addressed by file path, which is
/// what lets this whole class — and its tests — run without a plugin.
///
/// ## Never throws, but never lies either
///
/// #83 caught everything and returned a `cleanKeto` verdict, reasoning that
/// *"users see a clean verdict for unrecognisable labels rather than an
/// error screen"*. That is the most dangerous defect the M6 audit found: the
/// user is in a shop holding a product, and the app has just called it clean
/// keto **because it could not read the label**.
///
/// Not throwing is right; the failure has to be visible in the value. That
/// is what [ScanResult] being sealed is for. `design/m6_preflight.md` §1.1.
class ScanOrchestrator {
  const ScanOrchestrator({
    required this.recognizer,
    required this.parser,
    required this.classifier,
  });

  // Public rather than private, for the reason `MealLoggingService` records:
  // Dart forbids a named parameter starting with an underscore, so a
  // `_recognizer` field cannot use an initializing formal and trips
  // `prefer_initializing_formals`. They are interfaces; nothing leaks.
  final TextRecognitionService recognizer;
  final LabelParser parser;
  final IngredientClassifier classifier;

  /// Scans the image at [imagePath].
  ///
  /// Returns [ScanSucceeded] only when OCR produced text that parsed into
  /// something label-shaped. Every other outcome is a [ScanFailed] naming
  /// what went wrong, so the sheet can say something true and decide
  /// whether a retry is worth offering.
  Future<ScanResult> scan(String imagePath) async {
    // Asked before the attempt, not after it fails: on web this is a
    // compile-time fact, and the UI should never have offered the scan.
    if (!recognizer.isAvailable) {
      return const ScanFailed(reason: ScanFailureReason.unavailable);
    }

    final String rawText;
    try {
      rawText = await recognizer.recognise(imagePath);
    } on Object {
      // `Object`, not `Exception`, for the reason `guardPersistence` gives:
      // a platform channel can deliver an `Error`, and a scan that crashes
      // the screen is worse than a scan that failed.
      return const ScanFailed(reason: ScanFailureReason.recognitionFailed);
    }

    if (rawText.trim().isEmpty) {
      // Pointed at something blank, or too blurred to resolve a glyph.
      return const ScanFailed(reason: ScanFailureReason.noTextFound);
    }

    // `parse` is contractually incapable of throwing, so this needs no
    // guard — and a guard here would hide a regression in that contract.
    final label = parser.parse(rawText);

    if (!label.hasMacros && label.ingredients.isEmpty) {
      // Text, but nothing label-shaped in it: usually the front of the
      // pack rather than the back. This is the case #83 would have shown
      // as a green tick.
      return ScanFailed(reason: ScanFailureReason.notALabel, rawText: rawText);
    }

    return ScanSucceeded(
      label: label,
      verdict: classifier.classify(label.ingredients),
    );
  }
}

@riverpod
ScanOrchestrator scanOrchestrator(Ref ref) => ScanOrchestrator(
  recognizer: ref.watch(textRecognitionServiceProvider),
  parser: ref.watch(labelParserProvider),
  classifier: ref.watch(ingredientClassifierProvider),
);
