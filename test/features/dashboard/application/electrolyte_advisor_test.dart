import 'package:fantastic/core/constants/electrolyte_constants.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/dashboard/application/electrolyte_advisor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/fixtures.dart';

void main() {
  const advisor = ElectrolyteAdvisor();

  group('targets by phase', () {
    test('induction targets the phase 1 minimums', () {
      final advice = advisor.advise(
        AdaptationPhase.induction,
        DailyLogFixture.empty(),
      );

      expect(advice.sodiumTargetMg, ElectrolyteConstants.phase1SodiumMinMg);
      expect(
        advice.potassiumTargetMg,
        ElectrolyteConstants.phase1PotassiumMinMg,
      );
      expect(
        advice.magnesiumTargetMg,
        ElectrolyteConstants.phase1MagnesiumMinMg,
      );
    });

    test('induction sodium is higher than later phases', () {
      // Glycogen depletion drives sodium excretion in phase 1; the target drops
      // once the body adapts.
      final induction = advisor.advise(
        AdaptationPhase.induction,
        DailyLogFixture.empty(),
      );
      final adapted = advisor.advise(
        AdaptationPhase.fatAdapted,
        DailyLogFixture.empty(),
      );

      expect(induction.sodiumTargetMg, greaterThan(adapted.sodiumTargetMg));
    });

    test('fatAdapted and deepKetosis share one target set', () {
      // ElectrolyteConstants defines a single phase23 range — the design does
      // not distinguish the two on electrolytes.
      final adapted = advisor.advise(
        AdaptationPhase.fatAdapted,
        DailyLogFixture.empty(),
      );
      final deep = advisor.advise(
        AdaptationPhase.deepKetosis,
        DailyLogFixture.empty(),
      );

      expect(adapted.sodiumTargetMg, deep.sodiumTargetMg);
      expect(adapted.potassiumTargetMg, deep.potassiumTargetMg);
      expect(adapted.magnesiumTargetMg, deep.magnesiumTargetMg);
    });

    test('every phase yields targets above zero', () {
      // A zero target would make "logged nothing" register as met.
      for (final phase in AdaptationPhase.values) {
        final advice = advisor.advise(phase, DailyLogFixture.empty());

        expect(advice.sodiumTargetMg, greaterThan(0), reason: '$phase sodium');
        expect(
          advice.potassiumTargetMg,
          greaterThan(0),
          reason: '$phase potassium',
        );
        expect(
          advice.magnesiumTargetMg,
          greaterThan(0),
          reason: '$phase magnesium',
        );
      }
    });

    test('handles every phase without throwing', () {
      for (final phase in AdaptationPhase.values) {
        expect(
          () => advisor.advise(phase, DailyLogFixture.fixture()),
          returnsNormally,
        );
      }
    });
  });

  group('deficit flags', () {
    test('logging nothing is a deficit in all three', () {
      final advice = advisor.advise(
        AdaptationPhase.induction,
        DailyLogFixture.empty(),
      );

      expect(advice.sodiumDeficit, isTrue);
      expect(advice.potassiumDeficit, isTrue);
      expect(advice.magnesiumDeficit, isTrue);
    });

    test('logging exactly the target is met, not short', () {
      final advice = advisor.advise(
        AdaptationPhase.induction,
        DailyLogFixture.fixture(
          sodiumMg: ElectrolyteConstants.phase1SodiumMinMg,
          potassiumMg: ElectrolyteConstants.phase1PotassiumMinMg,
          magnesiumMg: ElectrolyteConstants.phase1MagnesiumMinMg,
        ),
      );

      expect(advice.sodiumDeficit, isFalse);
      expect(advice.potassiumDeficit, isFalse);
      expect(advice.magnesiumDeficit, isFalse);
    });

    test('one milligram below target is a deficit', () {
      final advice = advisor.advise(
        AdaptationPhase.induction,
        DailyLogFixture.fixture(
          sodiumMg: ElectrolyteConstants.phase1SodiumMinMg - 1,
        ),
      );

      expect(advice.sodiumDeficit, isTrue);
    });

    test('exceeding the target is not a deficit', () {
      final advice = advisor.advise(
        AdaptationPhase.induction,
        DailyLogFixture.fixture(
          sodiumMg: ElectrolyteConstants.phase1SodiumMaxMg,
        ),
      );

      expect(advice.sodiumDeficit, isFalse);
    });

    // Each flag must read its own field. Three distinct states, so a flag
    // wired to the wrong electrolyte cannot pass by coincidence.
    test('each flag tracks its own electrolyte', () {
      final advice = advisor.advise(
        AdaptationPhase.induction,
        DailyLogFixture.fixture(
          sodiumMg: 0,
          potassiumMg: ElectrolyteConstants.phase1PotassiumMinMg,
          magnesiumMg: 0,
        ),
      );

      expect(advice.sodiumDeficit, isTrue);
      expect(advice.potassiumDeficit, isFalse);
      expect(advice.magnesiumDeficit, isTrue);
    });

    test('the same log can be short in one phase and met in another', () {
      // Sodium between the phase 2/3 minimum and the phase 1 minimum.
      final log = DailyLogFixture.fixture(
        sodiumMg: ElectrolyteConstants.phase23SodiumMinMg,
      );

      expect(
        advisor.advise(AdaptationPhase.induction, log).sodiumDeficit,
        isTrue,
      );
      expect(
        advisor.advise(AdaptationPhase.deepKetosis, log).sodiumDeficit,
        isFalse,
      );
    });
  });

  group('hasAnyDeficit', () {
    test('is false when all three are met', () {
      final advice = advisor.advise(
        AdaptationPhase.induction,
        DailyLogFixture.fixture(
          sodiumMg: ElectrolyteConstants.phase1SodiumMinMg,
          potassiumMg: ElectrolyteConstants.phase1PotassiumMinMg,
          magnesiumMg: ElectrolyteConstants.phase1MagnesiumMinMg,
        ),
      );

      expect(advice.hasAnyDeficit, isFalse);
    });

    test('is true when only one is missed', () {
      final advice = advisor.advise(
        AdaptationPhase.induction,
        DailyLogFixture.fixture(
          sodiumMg: ElectrolyteConstants.phase1SodiumMinMg,
          potassiumMg: ElectrolyteConstants.phase1PotassiumMinMg,
          magnesiumMg: 0,
        ),
      );

      expect(advice.hasAnyDeficit, isTrue);
    });

    test('is true when everything is missed', () {
      expect(
        advisor
            .advise(AdaptationPhase.induction, DailyLogFixture.empty())
            .hasAnyDeficit,
        isTrue,
      );
    });
  });

  group('electrolyteAdvisorProvider', () {
    test('resolves to an ElectrolyteAdvisor', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(electrolyteAdvisorProvider),
        isA<ElectrolyteAdvisor>(),
      );
    });

    test('is a const singleton — two reads give the same instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(electrolyteAdvisorProvider),
        same(container.read(electrolyteAdvisorProvider)),
      );
    });
  });
}
