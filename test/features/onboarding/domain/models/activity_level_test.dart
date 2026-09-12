import 'package:fantastic/features/onboarding/domain/models/activity_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('multiplier', () {
    // The five standard Mifflin-St Jeor activity factors. Asserted literally
    // rather than derived, because the point of the table is that it is the
    // published one and not a set of numbers this project invented.
    test('every level carries the standard factor', () {
      expect(ActivityLevel.sedentary.multiplier, 1.2);
      expect(ActivityLevel.light.multiplier, 1.375);
      expect(ActivityLevel.moderate.multiplier, 1.55);
      expect(ActivityLevel.active.multiplier, 1.725);
      expect(ActivityLevel.veryActive.multiplier, 1.9);
    });

    test('the factors rise with the tier', () {
      for (var i = 1; i < ActivityLevel.values.length; i++) {
        expect(
          ActivityLevel.values[i].multiplier,
          greaterThan(ActivityLevel.values[i - 1].multiplier),
          reason:
              '${ActivityLevel.values[i].name} is not above '
              '${ActivityLevel.values[i - 1].name}',
        );
      }
    });

    // A profile written before the activity question existed reads as
    // sedentary, and that is only honest while sedentary is the 1.2 those
    // targets were computed with.
    test('sedentary is the 1.2 the flow used to assume for everybody', () {
      expect(ActivityLevel.sedentary.multiplier, 1.2);
    });
  });

  group('onTrainingDay', () {
    test('is one tier up', () {
      expect(ActivityLevel.sedentary.onTrainingDay, ActivityLevel.light);
      expect(ActivityLevel.light.onTrainingDay, ActivityLevel.moderate);
      expect(ActivityLevel.moderate.onTrainingDay, ActivityLevel.active);
      expect(ActivityLevel.active.onTrainingDay, ActivityLevel.veryActive);
    });

    // Total, deliberately: there is no sixth factor to borrow, and inventing
    // one for the top tier would be a number nobody specified.
    test('veryActive is its own training-day tier', () {
      expect(ActivityLevel.veryActive.onTrainingDay, ActivityLevel.veryActive);
    });

    test('never goes down', () {
      for (final level in ActivityLevel.values) {
        expect(
          level.onTrainingDay.multiplier,
          greaterThanOrEqualTo(level.multiplier),
          reason: level.name,
        );
      }
    });
  });
}
