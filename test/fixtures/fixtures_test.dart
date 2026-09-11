import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  group('fixture defaults are keto-valid', () {
    test('MealEntryFixture defaults to a ratio of 1.0', () {
      expect(MealEntryFixture.fixture().ketoRatio, closeTo(1.0, 0.0001));
    });

    test('DailyLogFixture defaults to a compliant day', () {
      final log = DailyLogFixture.fixture();

      expect(log.totalFatG, greaterThan(0));
      expect(log.ketoRatioAvg, greaterThan(1));
      expect(log.totalNetCarbsG, lessThan(20));
    });

    test('StreakStateFixture.initial is a fresh induction-phase user', () {
      final state = StreakStateFixture.initial();

      expect(state.currentStreak, 0);
      expect(state.phase, AdaptationPhase.induction);
      expect(state.inGracePeriod, isFalse);
    });

    test('SymptomLogFixture defaults sit mid-scale', () {
      final log = SymptomLogFixture.fixture();

      expect(log.energyScore, 3);
      expect(log.moodScore, 3);
    });
  });

  group('fixtures apply every override', () {
    test('MealEntryFixture overrides carry through', () {
      final meal = MealEntryFixture.fixture(
        id: 4,
        fatG: 50,
        mealName: 'Changed',
        ingredients: const ['ghee'],
        imageRef: 'x.png',
      );

      expect(meal.id, 4);
      expect(meal.fatG, 50);
      expect(meal.mealName, 'Changed');
      expect(meal.ingredients, const ['ghee']);
      expect(meal.imageRef, 'x.png');
    });

    test('DailyLogFixture.empty zeroes every total', () {
      final log = DailyLogFixture.empty();

      expect(log.totalFatG, 0);
      expect(log.waterMl, 0);
      expect(log.ketoRatioAvg, 0);
    });

    test('StreakStateFixture.withStreak sets both streak counters', () {
      final state = StreakStateFixture.withStreak(
        12,
        phase: AdaptationPhase.fatAdapted,
      );

      expect(state.currentStreak, 12);
      expect(state.highestStreak, 12);
      expect(state.phase, AdaptationPhase.fatAdapted);
    });

    test('StreakStateFixture.inGracePeriod opens the window', () {
      final state = StreakStateFixture.inGracePeriod();

      expect(state.inGracePeriod, isTrue);
      expect(state.gracePeriodEnd, isNotNull);
    });

    // The antidote to the all-3s default: a test asserting a score reaches
    // the right place needs five distinguishable scores.
    test('SymptomLogFixture.varied gives every scale a different score', () {
      final log = SymptomLogFixture.varied();

      expect(
        [
          log.energyScore,
          log.clarityScore,
          log.hungerScore,
          log.physicalScore,
          log.moodScore,
        ],
        [1, 2, 3, 4, 5],
      );
    });

    test('SymptomLogFixture boundary days sit at 1 and 5', () {
      expect(SymptomLogFixture.worstDay().energyScore, 1);
      expect(SymptomLogFixture.worstDay().moodScore, 1);
      expect(SymptomLogFixture.bestDay().energyScore, 5);
      expect(SymptomLogFixture.bestDay().moodScore, 5);
    });
  });

  group('fixtures are deterministic', () {
    // The M0 stubs called out fixed timestamps explicitly: a fixture backed by
    // DateTime.now() makes any date-sensitive assertion flake.
    test('two no-argument MealEntry fixtures share a timestamp', () {
      expect(
        MealEntryFixture.fixture().timestamp,
        MealEntryFixture.fixture().timestamp,
      );
    });

    test('two no-argument fixtures are equal', () {
      expect(MealEntryFixture.fixture(), MealEntryFixture.fixture());
      expect(DailyLogFixture.fixture(), DailyLogFixture.fixture());
      expect(StreakStateFixture.initial(), StreakStateFixture.initial());
      expect(SymptomLogFixture.fixture(), SymptomLogFixture.fixture());
    });

    test('no fixture date depends on the current clock', () {
      final now = DateTime.now();

      expect(MealEntryFixture.fixture().timestamp.isBefore(now), isTrue);
      expect(DailyLogFixture.fixture().date.isBefore(now), isTrue);
      expect(SymptomLogFixture.fixture().date.isBefore(now), isTrue);
    });
  });

  group('the barrel exports every fixture', () {
    test('all four are reachable through fixtures.dart alone', () {
      // Reaching these names via the single `fixtures.dart` import is the
      // assertion — a missing export fails at compile time.
      expect(MealEntryFixture.complete(), isNotNull);
      expect(DailyLogFixture.fixture(), isNotNull);
      expect(StreakStateFixture.initial(), isNotNull);
      expect(SymptomLogFixture.bestDay(), isNotNull);
    });
  });
}
