import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/diary/domain/models/physical_symptom.dart';
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

    test('AnalysedDishFixture.modifiable always carries a modification', () {
      expect(AnalysedDishFixture.modifiable().modification, isNotEmpty);
    });

    test('AnalysedDishFixture.orderAsIs and nonKeto carry no modification', () {
      expect(AnalysedDishFixture.orderAsIs().modification, isNull);
      expect(AnalysedDishFixture.nonKeto().modification, isNull);
    });

    test(
      'MenuAnalysisFixture.clean carries no unclassified or unread page',
      () {
        final analysis = MenuAnalysisFixture.clean();

        expect(analysis.unclassified, isEmpty);
        expect(analysis.unreadPages, isEmpty);
      },
    );
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
    // the right place needs four distinguishable scores.
    test('SymptomLogFixture.varied gives every scale a different score', () {
      final log = SymptomLogFixture.varied();

      expect(
        [log.energyScore, log.clarityScore, log.hungerScore, log.moodScore],
        [1, 2, 3, 4],
      );
    });

    // A widget that renders `PhysicalSymptom.values` instead of
    // `log.symptoms` passes against any fixture holding all eight, and a chip
    // row hardcoded to the first enum value passes against one holding
    // `halitosis`. Neither passes against a single mid-list value.
    test(
      'SymptomLogFixture.varied holds one symptom, neither first nor last',
      () {
        final symptoms = SymptomLogFixture.varied().symptoms;

        expect(symptoms, hasLength(1));
        expect(symptoms.single, isNot(PhysicalSymptom.values.first));
        expect(symptoms.single, isNot(PhysicalSymptom.values.last));
      },
    );

    test('AnalysedDishFixture overrides carry through', () {
      final dish = AnalysedDishFixture.orderAsIs(
        name: 'שם אחר',
        description: 'תיאור אחר',
        why: 'סיבה אחרת',
      );

      expect(dish.name, 'שם אחר');
      expect(dish.description, 'תיאור אחר');
      expect(dish.why, 'סיבה אחרת');
    });

    test('MenuAnalysisFixture.analysed overrides carry through', () {
      final analysis = MenuAnalysisFixture.analysed(
        withDishes: [AnalysedDishFixture.orderAsIs()],
        unclassified: const ['מנה א', 'מנה ב'],
        pageCount: 5,
        unreadPages: const [4, 5],
      );

      expect(analysis.dishes, hasLength(1));
      expect(analysis.unclassified, ['מנה א', 'מנה ב']);
      expect(analysis.pageCount, 5);
      expect(analysis.unreadPages, [4, 5]);
    });

    test('SymptomLogFixture boundary days sit at 1 and 5', () {
      expect(SymptomLogFixture.worstDay().energyScore, 1);
      expect(SymptomLogFixture.worstDay().moodScore, 1);
      expect(SymptomLogFixture.bestDay().energyScore, 5);
      expect(SymptomLogFixture.bestDay().moodScore, 5);
    });

    // The fixture is named for the condition, so it carries the symptoms that
    // constitute it — a worst day with an empty set would be a contradiction.
    test('SymptomLogFixture.worstDay carries the keto-flu symptoms', () {
      expect(SymptomLogFixture.worstDay().symptoms, isNotEmpty);
      expect(SymptomLogFixture.bestDay().symptoms, isEmpty);
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
      expect(
        AnalysedDishFixture.modifiable(),
        AnalysedDishFixture.modifiable(),
      );
      expect(MenuAnalysisFixture.clean(), MenuAnalysisFixture.clean());
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
      expect(AnalysedDishFixture.orderAsIs(), isNotNull);
      expect(MenuAnalysisFixture.analysed(), isNotNull);
    });
  });
}
