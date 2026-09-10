import 'package:fantastic/features/adaptation/data/mappers/streak_state_mapper.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';

/// The singleton takes no key, so a round-trip is just the two codec halves.
StreakState _roundTrip(StreakState original) =>
    StreakStateMapper.fromRecord(StreakStateMapper.toRecord(original));

void main() {
  // The phase is stored by `name`, not by ordinal — the mirror enum the Isar
  // schema needed is gone, and with it the ordinal-parity tests that guarded
  // it. What matters now is that every value survives the name round-trip and
  // that an unknown name fails loudly rather than defaulting to phase one.
  group('AdaptationPhase encoding', () {
    test('is stored as the value name, not its ordinal', () {
      final record = StreakStateMapper.toRecord(
        StreakStateFixture.withStreak(10, phase: AdaptationPhase.values.last),
      );

      expect(record['phase'], AdaptationPhase.values.last.name);
      expect(record['phase'], isA<String>());
    });

    test('every value round-trips', () {
      for (final phase in AdaptationPhase.values) {
        expect(
          _roundTrip(StreakStateFixture.withStreak(10, phase: phase)).phase,
          phase,
          reason: 'AdaptationPhase.${phase.name} did not survive the codec',
        );
      }
    });

    test('an unknown stored name throws rather than silently defaulting', () {
      final record = Map<String, Object?>.from(
        StreakStateMapper.toRecord(StreakStateFixture.initial()),
      )..['phase'] = 'notAPhase';

      expect(() => StreakStateMapper.fromRecord(record), throwsArgumentError);
    });
  });

  group('StreakStateMapper round-trip', () {
    test('preserves every field', () {
      final original = StreakStateFixture.inGracePeriod();

      expect(_roundTrip(original), original);
    });

    test('a null gracePeriodEnd round-trips as null', () {
      final restored = _roundTrip(StreakStateFixture.withStreak(3));

      expect(restored.gracePeriodEnd, isNull);
      expect(restored.inGracePeriod, isFalse);
    });

    test('a null lastCompliantDate round-trips as null', () {
      expect(
        _roundTrip(StreakStateFixture.initial()).lastCompliantDate,
        isNull,
      );
    });

    test('the first-launch state round-trips unchanged', () {
      expect(_roundTrip(StreakStateFixture.initial()), StreakState.initial());
    });

    test('both dates round-trip exactly, time of day included', () {
      final original = StreakStateFixture.inGracePeriod();

      final restored = _roundTrip(original);

      expect(
        restored.lastCompliantDate,
        StreakStateFixture.defaultCompliantDate,
      );
      expect(restored.gracePeriodEnd, StreakStateFixture.defaultGracePeriodEnd);
    });
  });

  group('StreakStateMapper.toRecord', () {
    // sembast only validates value types at write time, so a codec that emits
    // a DateTime fails at runtime inside the repository rather than here.
    test('emits only sembast-legal values — no DateTime anywhere', () {
      final record = StreakStateMapper.toRecord(
        StreakStateFixture.inGracePeriod(),
      );

      for (final value in record.values) {
        expect(
          value,
          anyOf(isNull, isA<num>(), isA<String>(), isA<bool>(), isA<List>()),
          reason: 'sembast stores JSON-compatible values only',
        );
      }
    });

    test('writes both dates as epoch milliseconds', () {
      final record = StreakStateMapper.toRecord(
        StreakStateFixture.inGracePeriod(),
      );

      expect(
        record['lastCompliantDate'],
        StreakStateFixture.defaultCompliantDate.millisecondsSinceEpoch,
      );
      expect(
        record['gracePeriodEnd'],
        StreakStateFixture.defaultGracePeriodEnd.millisecondsSinceEpoch,
      );
    });

    test('carries no id — every write is pinned to the singleton key', () {
      expect(
        StreakStateMapper.toRecord(StreakStateFixture.initial()),
        isNot(contains('id')),
      );
    });
  });

  group('StreakStateMapper.singletonId', () {
    test('is 0', () {
      expect(StreakStateMapper.singletonId, 0);
    });
  });
}
