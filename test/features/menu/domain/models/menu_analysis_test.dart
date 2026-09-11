import 'package:fantastic/features/menu/domain/models/dish_verdict.dart';
import 'package:fantastic/features/menu/domain/models/menu_analysis.dart';
import 'package:fantastic/features/menu/domain/models/menu_analysis_failure_reason.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';

void main() {
  group('MenuAnalysed.withVerdict', () {
    test('returns only dishes with that verdict, in the original order', () {
      final analysis = MenuAnalysisFixture.analysed();

      final green = analysis.withVerdict(DishVerdict.orderAsIs);

      expect(green, hasLength(1));
      expect(green.single.verdict, DishVerdict.orderAsIs);
    });

    test('returns an empty list when nothing matches', () {
      final analysis = MenuAnalysisFixture.analysed(
        withDishes: [AnalysedDishFixture.orderAsIs()],
      );

      expect(analysis.withVerdict(DishVerdict.nonKeto), isEmpty);
    });
  });

  group('MenuAnalysed.isPartial', () {
    test('is false when nothing is unread or unclassified', () {
      expect(MenuAnalysisFixture.clean().isPartial, isFalse);
    });

    test('is true for an unread page alone', () {
      final analysis = MenuAnalysisFixture.analysed(
        unclassified: const [],
        unreadPages: const [3],
      );

      expect(analysis.isPartial, isTrue);
    });

    test('is true for an unclassified name alone', () {
      final analysis = MenuAnalysisFixture.analysed(
        unclassified: const ['מנה לא ידועה'],
        unreadPages: const [],
      );

      expect(analysis.isPartial, isTrue);
    });
  });

  group('MenuAnalysed defaults', () {
    test('pageCount defaults to 0 for pasted text', () {
      const analysis = MenuAnalysed(dishes: []);

      expect(analysis.pageCount, 0);
      expect(analysis.unclassified, isEmpty);
      expect(analysis.unreadPages, isEmpty);
    });
  });

  group('equality', () {
    test('two results with equal-but-not-identical lists are equal', () {
      final a = MenuAnalysisFixture.analysed();
      final b = MenuAnalysisFixture.analysed();

      expect(identical(a.dishes, b.dishes), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('two results differing only in unclassified are not equal', () {
      expect(
        MenuAnalysisFixture.clean(),
        isNot(MenuAnalysisFixture.analysed()),
      );
    });

    test('two failures with different reasons are not equal', () {
      expect(
        MenuAnalysisFixture.failed(reason: MenuAnalysisFailureReason.offline),
        isNot(
          MenuAnalysisFixture.failed(
            reason: MenuAnalysisFailureReason.rateLimited,
          ),
        ),
      );
    });

    test('two failures with the same reason are equal', () {
      expect(
        MenuAnalysisFixture.failed(reason: MenuAnalysisFailureReason.offline),
        MenuAnalysisFixture.failed(reason: MenuAnalysisFailureReason.offline),
      );
    });

    test('a success and a failure are never equal', () {
      final MenuAnalysis success = MenuAnalysisFixture.clean();
      final MenuAnalysis failure = MenuAnalysisFixture.failed();

      expect(success, isNot(failure));
    });
  });

  group('the seal', () {
    /// The property the hierarchy exists for: this compiles with no
    /// `default` clause, so adding a third variant breaks the build rather
    /// than falling through to a blank screen.
    String describe(MenuAnalysis analysis) => switch (analysis) {
      MenuAnalysed(:final dishes) => 'ok:${dishes.length}',
      MenuAnalysisFailed(:final reason) => 'failed:${reason.name}',
    };

    test('a switch over both variants is exhaustive without a default', () {
      expect(describe(MenuAnalysisFixture.clean()), 'ok:3');
      expect(
        describe(
          MenuAnalysisFixture.failed(
            reason: MenuAnalysisFailureReason.noDishesFound,
          ),
        ),
        'failed:noDishesFound',
      );
    });

    test('every failure reason can be constructed and matched', () {
      for (final reason in MenuAnalysisFailureReason.values) {
        expect(
          describe(MenuAnalysisFixture.failed(reason: reason)),
          'failed:${reason.name}',
        );
      }
    });
  });
}
