import 'package:fantastic/features/keto_lens/application/scan_orchestrator.dart';
import 'package:fantastic/features/keto_lens/data/classifiers/ingredient_classifier_impl.dart';
import 'package:fantastic/features/keto_lens/data/parsers/hebrew_label_parser.dart';
import 'package:fantastic/features/keto_lens/domain/models/scan_result.dart';
import 'package:fantastic/features/keto_lens/domain/models/verdict_badge.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/fixtures.dart';

/// The pure-Dart pipeline, driven by text a real OCR engine really produced.
///
/// Every other parser and classifier test in this suite runs on strings a
/// person wrote. That is the failure mode `design/m6_handoff.md` warned about,
/// and this file is the answer to it: [RealOcrFixture] is verbatim Tesseract
/// output, mistakes and all, and these tests assert what the shipped pipeline
/// does with it.
///
/// No engine runs here — the fixtures are captured, so this is a fast unit
/// test that works on any machine and in CI, where Tesseract is not installed.
/// `tesseract_ffi_recognizer_test.dart` is the one that needs a real engine.
void main() {
  /// The real pipeline, with only the recogniser stubbed — the parser and
  /// classifier are the shipped implementations, not fakes. Stubbing the
  /// recogniser is what lets captured output stand in for a live engine.
  ScanOrchestrator orchestratorReturning(String ocrText) => ScanOrchestrator(
    recognizer: _CannedRecognizer(ocrText),
    parser: const HebrewLabelParser(),
    classifier: const IngredientClassifierImpl(),
  );

  group('real OCR output', () {
    test('a cleanly-read tahini label parses every macro', () async {
      final result = await orchestratorReturning(RealOcrFixture.tahini)
          .scan('');

      final success = result as ScanSucceeded;
      // The saturated-fat sub-row uses the same word as the total-fat row,
      // one line below, with its own number. A parser taking the first match
      // reports 7.6 here. That trap survived the round trip through a real
      // engine, which is the point of asserting it again on captured text.
      expect(success.label.fatG, 53.8);
      expect(success.label.netCarbsG, closeTo(10.5 - 9.3, 0.001));
      expect(success.label.proteinG, 26.5);
      expect(success.verdict.badge, VerdictBadge.cleanKeto);
    });

    test('an Israeli decimal comma survives the engine and parses', () async {
      final result = await orchestratorReturning(RealOcrFixture.proteinBar)
          .scan('');

      final success = result as ScanSucceeded;
      // Tesseract returned "22,5" — it did not helpfully normalise the comma,
      // so the parser still has to. `double.tryParse` rejects it outright.
      expect(success.label.fatG, 22.5);
      // Maltitol is in the ingredient line, printed above the table. It is an
      // insulin-spiking sweetener, which `IngredientClassifierImpl` rates
      // amber rather than red — a seed oil is what earns `nonKeto`. That is
      // the shipped severity ladder, not an accident of this fixture.
      expect(success.verdict.badge, VerdictBadge.cautionQuantityDependent);
      expect(success.verdict.flaggedIngredients, isNotEmpty);
    });

    test('a canola wafer is flagged from genuinely recognised text', () async {
      final result = await orchestratorReturning(RealOcrFixture.pointedWafer)
          .scan('');

      final success = result as ScanSucceeded;
      expect(success.verdict.badge, VerdictBadge.nonKeto);
    });

    test('niqqud survives the engine and the normaliser strips it', () async {
      final result = await orchestratorReturning(RealOcrFixture.pointedWafer)
          .scan('');

      // Tesseract returns the vowel points rather than dropping them —
      // `שוּמֶן`, `פחמִימות` — so `HebrewTextNormaliser` is still doing real
      // work on real output, not only on hand-written fixtures. It strips
      // U+0591–U+05C7 and the keywords then match.
      //
      // **Known sensitivity, deliberately not asserted:** the same label
      // rendered smaller came back as `שוּמֶ|` — a final nun read as a pipe —
      // and that row is then lost entirely. Niqqud the normaliser can strip;
      // a wrong letter it cannot. The row going missing is the *safe* failure
      // (fat is null, never 0), but it is a failure, and it is why
      // `design/m6_platform_research.md` Part 6 puts image pre-processing
      // ahead of any further platform work.
      final success = result as ScanSucceeded;
      expect(success.label.fatG, 24);
      expect(success.label.netCarbsG, closeTo(62 - 2, 0.001));
      expect(success.label.proteinG, 6);
    });
  });
}

/// A recogniser that returns one captured string.
///
/// Not a mock: there is nothing to verify about the call, only about what the
/// pipeline does with what comes back.
class _CannedRecognizer implements TextRecognitionService {
  const _CannedRecognizer(this.text);

  final String text;

  @override
  bool get isAvailable => true;

  @override
  Future<String> recognise(String imagePath) async => text;
}
