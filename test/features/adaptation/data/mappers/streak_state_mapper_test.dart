import 'package:fantastic/features/adaptation/data/mappers/streak_state_mapper.dart';
import 'package:fantastic/features/adaptation/data/schemas/isar_streak_state.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';

void main() {
  // The phase is stored as an ordinal, so the two enums' declaration order is
  // load-bearing: reordering or inserting a value in either one silently
  // reinterprets every stored record. These two tests are the only thing
  // standing between that and a corrupted database.
  group('AdaptationPhase ordinal parity', () {
    test('the two enums have the same number of values', () {
      expect(
        AdaptationPhaseIsar.values,
        hasLength(AdaptationPhase.values.length),
      );
    });

    test('every ordinal maps to the same-named value in the mirror enum', () {
      for (final phase in AdaptationPhase.values) {
        expect(
          AdaptationPhaseIsar.values[phase.index].name,
          phase.name,
          reason:
              'AdaptationPhaseIsar drifted from AdaptationPhase at ordinal '
              '${phase.index}. Both are append-only.',
        );
      }
    });
  });

  group('StreakStateMapper round-trip', () {
    test('preserves every field', () {
      final original = StreakStateFixture.inGracePeriod();

      final restored = StreakStateMapper.toDomain(
        StreakStateMapper.toIsar(original),
      );

      expect(restored, original);
    });

    test('every AdaptationPhase value survives', () {
      for (final phase in AdaptationPhase.values) {
        final original = StreakStateFixture.withStreak(10, phase: phase);

        final restored = StreakStateMapper.toDomain(
          StreakStateMapper.toIsar(original),
        );

        expect(restored.phase, phase);
      }
    });

    test('a null gracePeriodEnd round-trips as null', () {
      final restored = StreakStateMapper.toDomain(
        StreakStateMapper.toIsar(StreakStateFixture.withStreak(3)),
      );

      expect(restored.gracePeriodEnd, isNull);
      expect(restored.inGracePeriod, isFalse);
    });

    test('a null lastCompliantDate round-trips as null', () {
      final restored = StreakStateMapper.toDomain(
        StreakStateMapper.toIsar(StreakStateFixture.initial()),
      );

      expect(restored.lastCompliantDate, isNull);
    });

    test('the first-launch state round-trips unchanged', () {
      final restored = StreakStateMapper.toDomain(
        StreakStateMapper.toIsar(StreakStateFixture.initial()),
      );

      expect(restored, StreakStateFixture.initial());
    });
  });

  group('StreakStateMapper.toIsar', () {
    test('always pins id to the singleton row, even for an unsaved state', () {
      expect(
        StreakStateMapper.toIsar(StreakStateFixture.initial()).id,
        StreakStateMapper.singletonId,
      );
      expect(
        StreakStateMapper.toIsar(StreakStateFixture.withStreak(30)).id,
        StreakStateMapper.singletonId,
      );
    });

    test('the singleton row is 0', () {
      expect(StreakStateMapper.singletonId, 0);
    });
  });
}
