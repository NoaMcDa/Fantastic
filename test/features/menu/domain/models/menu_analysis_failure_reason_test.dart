import 'package:fantastic/features/menu/domain/models/menu_analysis_failure_reason.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MenuAnalysisFailureReason', () {
    test('has exactly eleven values', () {
      // Nine from the original set, plus #408's two PDF-only reasons
      // (pdfUnreadable, pdfNeedsOcr).
      expect(MenuAnalysisFailureReason.values, hasLength(11));
    });

    test('isRetryable is true for exactly offline and badResponse', () {
      final retryable = MenuAnalysisFailureReason.values
          .where((reason) => reason.isRetryable)
          .toSet();

      expect(retryable, {
        MenuAnalysisFailureReason.offline,
        MenuAnalysisFailureReason.badResponse,
      });
    });

    test('every other reason is not retryable', () {
      for (final reason in MenuAnalysisFailureReason.values) {
        if (reason == MenuAnalysisFailureReason.offline ||
            reason == MenuAnalysisFailureReason.badResponse) {
          continue;
        }
        expect(reason.isRetryable, isFalse, reason: reason.name);
      }
    });
  });
}
