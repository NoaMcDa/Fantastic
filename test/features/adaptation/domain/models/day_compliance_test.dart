import 'package:fantastic/core/constants/keto_constants.dart';
import 'package:fantastic/features/adaptation/domain/models/day_compliance.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';

void main() {
  group('DayCompliance.of', () {
    test('a day with no record at all is unlogged', () {
      expect(DayCompliance.of(null), DayStatus.unlogged);
    });

    test('a day whose three macros are all zero is unlogged', () {
      // What `MealLoggingService` leaves behind when the last meal of a day is
      // deleted: the row survives so water and electrolytes are not lost.
      expect(DayCompliance.of(DailyLogFixture.empty()), DayStatus.unlogged);
    });

    test('a day at exactly the limit is compliant', () {
      final log = DailyLogFixture.fixture(
        totalNetCarbsG: KetoConstants.maxCompliantNetCarbsG,
      );
      expect(DayCompliance.of(log), DayStatus.compliant);
    });

    test('a day one tenth of a gram over the limit is a breach', () {
      final log = DailyLogFixture.fixture(
        totalNetCarbsG: KetoConstants.maxCompliantNetCarbsG + 0.1,
      );
      expect(DayCompliance.of(log), DayStatus.breach);
    });

    test('a high-protein, low-carb day is compliant', () {
      // The regression case. Ratio 30 / (8 + 90) = 0.31, which the old
      // `ketoRatioAvg >= 2.0` rule called a breach — a disciplined 8 g-carb day
      // breaking the streak (#303).
      final log = DailyLogFixture.fixture(
        totalFatG: 30,
        totalNetCarbsG: 8,
        totalProteinG: 90,
        ketoRatioAvg: 0.31,
      );
      expect(DayCompliance.of(log), DayStatus.compliant);
    });

    test('a high-fat day over the carb limit is a breach', () {
      // The inverse regression case. Ratio 100 / (60 + 0) = 1.67 — and at
      // 100 / (50 + 0) the old rule scored exactly 2.0 and passed a 50 g-carb
      // day.
      final log = DailyLogFixture.fixture(
        totalFatG: 100,
        totalNetCarbsG: 60,
        totalProteinG: 0,
        ketoRatioAvg: 1.67,
      );
      expect(DayCompliance.of(log), DayStatus.breach);
    });

    test('a fat-only day is compliant, not unlogged', () {
      // Butter coffee and nothing else. The old calendar rule tested
      // `netCarbs + protein == 0` and called this unlogged; under a carb rule
      // zero net carbs is the best possible day.
      final log = DailyLogFixture.fixture(
        totalFatG: 40,
        totalNetCarbsG: 0,
        totalProteinG: 0,
        ketoRatioAvg: 0,
      );
      expect(DayCompliance.of(log), DayStatus.compliant);
    });

    test('the keto ratio does not participate', () {
      // Same carbs, opposite ratios, same verdict.
      final low = DailyLogFixture.fixture(
        totalNetCarbsG: 10,
        ketoRatioAvg: 0.1,
      );
      final high = DailyLogFixture.fixture(
        totalNetCarbsG: 10,
        ketoRatioAvg: 9.9,
      );
      expect(DayCompliance.of(low), DayStatus.compliant);
      expect(DayCompliance.of(high), DayStatus.compliant);
    });
  });
}
