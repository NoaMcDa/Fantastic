import 'package:fantastic/core/constants/keto_constants.dart';
import 'package:fantastic/features/onboarding/domain/models/activity_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('net-carb target table', () {
    test('every activity level has a default', () {
      for (final level in ActivityLevel.values) {
        expect(
          KetoConstants.netCarbTargetByActivity[level],
          isNotNull,
          reason: 'no net-carb default for ${level.name}',
        );
      }
    });

    // The invariant the whole derivation rests on: the calculator must never
    // propose a target that is itself a streak breach. This is the guard on
    // the *table*, so an edit to the numbers cannot break it silently;
    // `OnboardingService.netCarbTargetFor` clamps the result as well.
    test('every default is inside the compliance band', () {
      for (final entry in KetoConstants.netCarbTargetByActivity.entries) {
        expect(
          entry.value,
          inInclusiveRange(
            KetoConstants.inductionNetCarbsG,
            KetoConstants.maxCompliantNetCarbsG,
          ),
          reason: '${entry.key.name} is outside the band',
        );
      }
    });

    test('a default plus the athletic bonus is still inside the band', () {
      for (final entry in KetoConstants.netCarbTargetByActivity.entries) {
        expect(
          entry.value + KetoConstants.athleticPerformanceNetCarbBonusG,
          inInclusiveRange(
            KetoConstants.inductionNetCarbsG,
            KetoConstants.maxCompliantNetCarbsG,
          ),
          reason: '${entry.key.name} plus the bonus leaves the band',
        );
      }
    });

    test('the weight-loss cap is inside the band', () {
      expect(
        KetoConstants.weightLossNetCarbCapG,
        inInclusiveRange(
          KetoConstants.inductionNetCarbsG,
          KetoConstants.maxCompliantNetCarbsG,
        ),
      );
    });

    test('the defaults never fall as activity rises', () {
      final ordered = [
        for (final level in ActivityLevel.values)
          KetoConstants.netCarbTargetByActivity[level]!,
      ];

      for (var i = 1; i < ordered.length; i++) {
        expect(
          ordered[i],
          greaterThanOrEqualTo(ordered[i - 1]),
          reason: '${ActivityLevel.values[i].name} is below the tier under it',
        );
      }
    });

    // The induction allowance is the floor of the band, and the streak
    // threshold is its ceiling. They are different constants for a reason
    // (#303) and this is where that stays visible.
    test('the floor is the induction allowance and is below the ceiling', () {
      expect(KetoConstants.inductionNetCarbsG, 20.0);
      expect(
        KetoConstants.inductionNetCarbsG,
        lessThan(KetoConstants.maxCompliantNetCarbsG),
      );
    });
  });
}
