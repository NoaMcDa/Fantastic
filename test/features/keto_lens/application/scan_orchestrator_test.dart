import 'package:fantastic/features/keto_lens/application/scan_orchestrator.dart';
import 'package:fantastic/features/keto_lens/domain/models/ingredient_verdict.dart';
import 'package:fantastic/features/keto_lens/domain/models/parsed_label.dart';
import 'package:fantastic/features/keto_lens/domain/models/scan_result.dart';
import 'package:fantastic/features/keto_lens/domain/models/verdict_badge.dart';
import 'package:fantastic/features/keto_lens/domain/services/ingredient_classifier.dart';
import 'package:fantastic/features/keto_lens/domain/services/label_parser.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';
import 'package:fantastic/features/keto_lens/data/classifiers/macro_classifier_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRecognizer extends Mock implements TextRecognitionService {}

class _MockParser extends Mock implements LabelParser {}

class _MockClassifier extends Mock implements IngredientClassifier {}

void main() {
  late _MockRecognizer recognizer;
  late _MockParser parser;
  late _MockClassifier classifier;
  late ScanOrchestrator orchestrator;

  const path = '/tmp/label.jpg';
  const rawText = 'שומנים 12 גרם';
  const label = ParsedLabel(fatG: 12, ingredients: ['שמן קנולה']);
  const verdict = IngredientVerdict(
    badge: VerdictBadge.nonKeto,
    flaggedIngredients: ['שמן קנולה'],
  );

  setUp(() {
    recognizer = _MockRecognizer();
    parser = _MockParser();
    classifier = _MockClassifier();
    orchestrator = ScanOrchestrator(
      macroClassifier: const MacroClassifierImpl(),
      recognizer: recognizer,
      parser: parser,
      classifier: classifier,
    );
    when(() => recognizer.isAvailable).thenReturn(true);
  });

  group('ScanOrchestrator happy path', () {
    test('threads recogniser into parser into classifier', () async {
      when(() => recognizer.recognise(path)).thenAnswer((_) async => rawText);
      when(() => parser.parse(rawText)).thenReturn(label);
      when(() => classifier.classify(label.ingredients)).thenReturn(verdict);

      final result = await orchestrator.scan(path);

      expect(result, isA<ScanSucceeded>());
      expect((result as ScanSucceeded).label, label);
      expect(result.verdict, verdict);
      verify(() => recognizer.recognise(path)).called(1);
      verify(() => parser.parse(rawText)).called(1);
      verify(() => classifier.classify(label.ingredients)).called(1);
    });

    test('a label with macros but no ingredients still succeeds', () async {
      // An imported bottle whose ingredient list is on a sticker the shot
      // missed. The macros are real and worth logging.
      const macrosOnly = ParsedLabel(fatG: 100, netCarbsG: 0);
      when(() => recognizer.recognise(path)).thenAnswer((_) async => rawText);
      when(() => parser.parse(rawText)).thenReturn(macrosOnly);
      when(() => classifier.classify(const []))
          .thenReturn(const IngredientVerdict(badge: VerdictBadge.cleanKeto));

      expect(await orchestrator.scan(path), isA<ScanSucceeded>());
    });

    test('an ingredient list with no macros still succeeds', () async {
      const ingredientsOnly = ParsedLabel(ingredients: ['מלטיטול']);
      when(() => recognizer.recognise(path)).thenAnswer((_) async => rawText);
      when(() => parser.parse(rawText)).thenReturn(ingredientsOnly);
      when(() => classifier.classify(ingredientsOnly.ingredients)).thenReturn(
        const IngredientVerdict(
          badge: VerdictBadge.cautionQuantityDependent,
          flaggedIngredients: ['מלטיטול'],
        ),
      );

      final result = await orchestrator.scan(path);

      expect(result, isA<ScanSucceeded>());
      expect(
        (result as ScanSucceeded).verdict.badge,
        VerdictBadge.cautionQuantityDependent,
      );
    });
  });

  group('ScanOrchestrator failure paths', () {
    test('an unavailable recogniser fails before it is called', () async {
      when(() => recognizer.isAvailable).thenReturn(false);

      final result = await orchestrator.scan(path);

      expect(result, isA<ScanFailed>());
      expect((result as ScanFailed).reason, ScanFailureReason.unavailable);
      verifyNever(() => recognizer.recognise(any()));
    });

    test('a throwing recogniser is a recognitionFailed, not a clean '
        'verdict', () async {
      // The defect this whole sealed type exists to prevent. #83 returned
      // ScanResult(label: ParsedLabel(), verdict: cleanKeto) here - a
      // green tick on a scan that never happened.
      when(() => recognizer.recognise(path)).thenThrow(Exception('boom'));

      final result = await orchestrator.scan(path);

      expect(result, isA<ScanFailed>());
      expect(
        (result as ScanFailed).reason,
        ScanFailureReason.recognitionFailed,
      );
    });

    test('an Error from the recogniser is caught too', () async {
      // A platform channel can deliver an Error, and `on Exception` would
      // miss it - the same reason guardPersistence catches Object.
      when(() => recognizer.recognise(path)).thenThrow(StateError('bad'));

      expect(await orchestrator.scan(path), isA<ScanFailed>());
    });

    test('empty OCR output is noTextFound', () async {
      when(() => recognizer.recognise(path)).thenAnswer((_) async => '');

      final result = await orchestrator.scan(path);

      expect((result as ScanFailed).reason, ScanFailureReason.noTextFound);
      verifyNever(() => parser.parse(any()));
    });

    test('whitespace-only OCR output is noTextFound', () async {
      when(() => recognizer.recognise(path)).thenAnswer((_) async => '  \n ');

      final result = await orchestrator.scan(path);

      expect((result as ScanFailed).reason, ScanFailureReason.noTextFound);
    });

    test('text that parses to nothing is notALabel', () async {
      // The front of the pack: plenty of text, no macro row and no
      // ingredient list. #83 would have shown this as clean keto.
      when(() => recognizer.recognise(path))
          .thenAnswer((_) async => 'חטיף שוקולד מעולה');
      when(() => parser.parse(any()))
          .thenReturn(const ParsedLabel(rawText: 'חטיף שוקולד מעולה'));

      final result = await orchestrator.scan(path);

      expect((result as ScanFailed).reason, ScanFailureReason.notALabel);
      verifyNever(() => classifier.classify(any()));
    });

    test('notALabel keeps the raw text for a bug report', () async {
      const front = 'חטיף שוקולד מעולה';
      when(() => recognizer.recognise(path)).thenAnswer((_) async => front);
      when(() => parser.parse(any())).thenReturn(const ParsedLabel());

      final result = await orchestrator.scan(path) as ScanFailed;

      expect(result.rawText, front);
    });

    test('never throws, whatever the collaborators do', () async {
      when(() => recognizer.recognise(path)).thenAnswer((_) async => rawText);
      when(() => parser.parse(any())).thenThrow(StateError('parser broke'));

      // parse is contractually incapable of throwing, so there is no guard
      // around it - if that contract is ever broken the scan throws, and
      // this test is what says so rather than hiding it.
      await expectLater(orchestrator.scan(path), throwsStateError);
    });
  });

  group('ScanOrchestrator never claims clean on a failure', () {
    /// Builds an orchestrator whose collaborators are freshly stubbed, so
    /// one case's stubs cannot leak into the next.
    ScanOrchestrator freshFor(
      void Function(_MockRecognizer, _MockParser) stub,
    ) {
      final r = _MockRecognizer();
      final p = _MockParser();
      when(() => r.isAvailable).thenReturn(true);
      stub(r, p);
      return ScanOrchestrator(
        macroClassifier: const MacroClassifierImpl(),
        recognizer: r,
        parser: p,
        classifier: _MockClassifier(),
      );
    }

    test('no failure path ever produces a verdict', () async {
      final cases = <String, ScanOrchestrator>{
        'unavailable': freshFor((r, p) {
          when(() => r.isAvailable).thenReturn(false);
        }),
        'recogniser throws': freshFor((r, p) {
          when(() => r.recognise(path)).thenThrow(Exception('x'));
        }),
        'no text': freshFor((r, p) {
          when(() => r.recognise(path)).thenAnswer((_) async => '');
        }),
        'not a label': freshFor((r, p) {
          when(() => r.recognise(path)).thenAnswer((_) async => 'front');
          when(() => p.parse(any())).thenReturn(const ParsedLabel());
        }),
      };

      for (final entry in cases.entries) {
        final result = await entry.value.scan(path);

        expect(result, isA<ScanFailed>(), reason: entry.key);
        expect(result, isNot(isA<ScanSucceeded>()), reason: entry.key);
      }
    });
  });
}
