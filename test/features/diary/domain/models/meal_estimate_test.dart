import 'package:fantastic/features/diary/domain/models/estimate_failure_reason.dart';
import 'package:fantastic/features/diary/domain/models/meal_estimate.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';

void main() {
  group('EstimateSucceeded totals', () {
    test('each macro sums over items', () {
      final estimate = MealEstimateFixture.succeeded();

      // Three different totals, so a getter summing the wrong column fails.
      expect(estimate.fatG, 22);
      expect(estimate.netCarbsG, 9);
      expect(estimate.proteinG, 19);
    });

    test('a single zero-macro item totals 0 rather than erroring', () {
      final estimate = MealEstimateFixture.succeeded(
        withItems: [
          MealEstimateFixture.item(fatG: 0, netCarbsG: 0, proteinG: 0),
        ],
      );

      expect(estimate.fatG, 0);
      expect(estimate.netCarbsG, 0);
      expect(estimate.proteinG, 0);
      expect(estimate.items, hasLength(1));
    });

    // Computed, never stored: a stored copy goes stale against what it was
    // derived from, and the review surface lets the user delete an item.
    test('the totals follow when an item is removed', () {
      final full = MealEstimateFixture.succeeded();

      final trimmed = EstimateSucceeded(items: full.items.sublist(0, 2));

      expect(full.fatG, 22);
      expect(trimmed.fatG, 20);
    });
  });

  group('EstimateSucceeded.isPartial', () {
    test('is false when nothing went unidentified', () {
      expect(MealEstimateFixture.succeeded().isPartial, isFalse);
    });

    test('is true when something did', () {
      expect(MealEstimateFixture.partial().isPartial, isTrue);
    });

    test('unidentified defaults to empty and is never null', () {
      expect(MealEstimateFixture.succeeded().unidentified, isEmpty);
    });
  });

  group('equality', () {
    test('equal-but-not-identical item lists are equal', () {
      final a = MealEstimateFixture.succeeded();
      final b = MealEstimateFixture.succeeded();

      expect(identical(a.items, b.items), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    // A dropped `לחם` turns a 40 g-carb meal into a 2 g one and the day still
    // reads compliant, so this difference has to be visible to `==`.
    test('two estimates differing only in unidentified are not equal', () {
      expect(
        MealEstimateFixture.succeeded(),
        isNot(MealEstimateFixture.partial()),
      );
    });

    test('two failures with different reasons are not equal', () {
      expect(
        MealEstimateFixture.failed(reason: EstimateFailureReason.offline),
        isNot(
          MealEstimateFixture.failed(reason: EstimateFailureReason.rateLimited),
        ),
      );
    });

    test('two failures with the same reason are equal', () {
      expect(
        MealEstimateFixture.failed(reason: EstimateFailureReason.offline),
        MealEstimateFixture.failed(reason: EstimateFailureReason.offline),
      );
    });

    test('a success and a failure are never equal', () {
      final MealEstimate success = MealEstimateFixture.succeeded();
      final MealEstimate failure = MealEstimateFixture.failed();

      expect(success, isNot(failure));
    });
  });

  group('the seal', () {
    /// The property the hierarchy exists for: this compiles with no `default`
    /// clause, so adding a third variant breaks the build rather than falling
    /// through to a blank sheet.
    String describe(MealEstimate estimate) => switch (estimate) {
      EstimateSucceeded(:final items) => 'ok:${items.length}',
      EstimateFailed(:final reason) => 'failed:${reason.name}',
    };

    test('a switch over both variants is exhaustive without a default', () {
      expect(describe(MealEstimateFixture.succeeded()), 'ok:3');
      expect(
        describe(
          MealEstimateFixture.failed(
            reason: EstimateFailureReason.nothingIdentified,
          ),
        ),
        'failed:nothingIdentified',
      );
    });

    test('every failure reason can be constructed and matched', () {
      for (final reason in EstimateFailureReason.values) {
        expect(
          describe(MealEstimateFixture.failed(reason: reason)),
          'failed:${reason.name}',
        );
      }
    });

    // An attempt that identified nothing is a failure, not an empty success —
    // otherwise "no items" and "zero macros" are the same value.
    test('nothingIdentified is a failure reason, not an empty success', () {
      expect(
        EstimateFailureReason.values,
        contains(EstimateFailureReason.nothingIdentified),
      );
    });
  });
}
