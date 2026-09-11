import 'package:fantastic/features/keto_lens/domain/models/ingredient_verdict.dart';
import 'package:fantastic/features/keto_lens/domain/models/parsed_label.dart';
import 'package:fantastic/features/keto_lens/domain/models/scan_result.dart';
import 'package:fantastic/features/keto_lens/domain/models/verdict_badge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const label = ParsedLabel(fatG: 12);
  const verdict = IngredientVerdict(badge: VerdictBadge.cleanKeto);

  group('ScanResult is sealed', () {
    test('a success and a failure are both ScanResults', () {
      expect(
        const ScanSucceeded(label: label, verdict: verdict),
        isA<ScanResult>(),
      );
      expect(
        const ScanFailed(reason: ScanFailureReason.noTextFound),
        isA<ScanResult>(),
      );
    });

    test('a failure is never a success', () {
      // The whole point: #83 encoded failure as a success carrying a clean
      // verdict, and nothing downstream could tell them apart.
      const ScanResult failure = ScanFailed(
        reason: ScanFailureReason.recognitionFailed,
      );

      expect(failure, isNot(isA<ScanSucceeded>()));
    });

    test('a switch over it is exhaustive without a default arm', () {
      String describe(ScanResult result) => switch (result) {
        ScanSucceeded() => 'ok',
        ScanFailed() => 'failed',
      };

      expect(
        describe(const ScanSucceeded(label: label, verdict: verdict)),
        'ok',
      );
      expect(
        describe(const ScanFailed(reason: ScanFailureReason.unavailable)),
        'failed',
      );
    });
  });

  group('ScanSucceeded equality', () {
    test('two with the same label and verdict are equal', () {
      expect(
        const ScanSucceeded(label: label, verdict: verdict),
        const ScanSucceeded(label: label, verdict: verdict),
      );
      expect(
        const ScanSucceeded(label: label, verdict: verdict).hashCode,
        const ScanSucceeded(label: label, verdict: verdict).hashCode,
      );
    });

    test('differing in the label is not equal', () {
      expect(
        const ScanSucceeded(label: label, verdict: verdict),
        isNot(
          const ScanSucceeded(label: ParsedLabel(fatG: 13), verdict: verdict),
        ),
      );
    });

    test('differing in the verdict is not equal', () {
      expect(
        const ScanSucceeded(label: label, verdict: verdict),
        isNot(
          const ScanSucceeded(
            label: label,
            verdict: IngredientVerdict(badge: VerdictBadge.nonKeto),
          ),
        ),
      );
    });
  });

  group('ScanFailed', () {
    test('rawText defaults to empty', () {
      expect(
        const ScanFailed(reason: ScanFailureReason.unavailable).rawText,
        isEmpty,
      );
    });

    test('two with the same reason and raw text are equal', () {
      expect(
        const ScanFailed(reason: ScanFailureReason.notALabel, rawText: 'x'),
        const ScanFailed(reason: ScanFailureReason.notALabel, rawText: 'x'),
      );
      expect(
        const ScanFailed(
          reason: ScanFailureReason.notALabel,
          rawText: 'x',
        ).hashCode,
        const ScanFailed(
          reason: ScanFailureReason.notALabel,
          rawText: 'x',
        ).hashCode,
      );
    });

    test('differing in the reason is not equal', () {
      expect(
        const ScanFailed(reason: ScanFailureReason.notALabel),
        isNot(const ScanFailed(reason: ScanFailureReason.noTextFound)),
      );
    });

    test('differing in the raw text is not equal', () {
      expect(
        const ScanFailed(reason: ScanFailureReason.notALabel, rawText: 'a'),
        isNot(
          const ScanFailed(reason: ScanFailureReason.notALabel, rawText: 'b'),
        ),
      );
    });

    test('there are four distinct reasons', () {
      // Four because the right thing to tell the user differs for each,
      // and so does whether a retry is worth offering.
      expect(ScanFailureReason.values, hasLength(4));
    });
  });
}
