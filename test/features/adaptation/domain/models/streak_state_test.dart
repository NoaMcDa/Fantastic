import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixed so every case is deterministic — never DateTime.now().
final _compliantDate = DateTime(2026, 9, 9);
final _graceEnd = DateTime(2026, 9, 10, 12);

void main() {
  group('AdaptationPhase', () {
    test(
      'declares induction, fatAdapted, deepKetosis in that ordinal order',
      () {
        // Ordinal order is persisted by #37 as an @enumerated value. Reordering
        // these silently reinterprets every stored record.
        expect(AdaptationPhase.values, [
          AdaptationPhase.induction,
          AdaptationPhase.fatAdapted,
          AdaptationPhase.deepKetosis,
        ]);
        expect(AdaptationPhase.induction.index, 0);
        expect(AdaptationPhase.fatAdapted.index, 1);
        expect(AdaptationPhase.deepKetosis.index, 2);
      },
    );

    test('has exactly three phases', () {
      expect(AdaptationPhase.values.length, 3);
    });
  });

  group('StreakState.initial', () {
    test('is a zero streak in the induction phase', () {
      final state = StreakState.initial();

      expect(state.currentStreak, 0);
      expect(state.highestStreak, 0);
      expect(state.phase, AdaptationPhase.induction);
    });

    test('has no grace period and no compliant day yet', () {
      final state = StreakState.initial();

      expect(state.inGracePeriod, isFalse);
      expect(state.gracePeriodEnd, isNull);
      expect(state.lastCompliantDate, isNull);
    });

    test('equals a default-constructed instance', () {
      expect(StreakState.initial(), const StreakState());
    });
  });

  group('StreakState.copyWith', () {
    test('returns a new instance, not the same reference', () {
      final original = StreakState.initial();
      final copy = original.copyWith(currentStreak: 5);

      expect(identical(original, copy), isFalse);
      expect(copy.currentStreak, 5);
    });

    test('leaves untouched fields unchanged', () {
      final copy = StreakState(
        currentStreak: 3,
        highestStreak: 9,
        phase: AdaptationPhase.fatAdapted,
        lastCompliantDate: _compliantDate,
      ).copyWith(currentStreak: 4);

      expect(copy.highestStreak, 9);
      expect(copy.phase, AdaptationPhase.fatAdapted);
      expect(copy.lastCompliantDate, _compliantDate);
    });

    test('with no arguments returns an equal instance', () {
      final original = StreakState(currentStreak: 2, gracePeriodEnd: _graceEnd);

      expect(original.copyWith(), original);
    });

    test('overrides every non-nullable field', () {
      final copy = StreakState.initial().copyWith(
        currentStreak: 7,
        highestStreak: 12,
        phase: AdaptationPhase.deepKetosis,
        inGracePeriod: true,
      );

      expect(copy.currentStreak, 7);
      expect(copy.highestStreak, 12);
      expect(copy.phase, AdaptationPhase.deepKetosis);
      expect(copy.inGracePeriod, isTrue);
    });

    test('sets gracePeriodEnd when a value is given', () {
      final copy = StreakState.initial().copyWith(gracePeriodEnd: _graceEnd);

      expect(copy.gracePeriodEnd, _graceEnd);
    });

    test('clears gracePeriodEnd back to null', () {
      // A plain `value ?? this.value` cannot express this, and the service
      // needs it when a grace period ends.
      final inGrace = StreakState(
        inGracePeriod: true,
        gracePeriodEnd: _graceEnd,
      );

      final cleared = inGrace.copyWith(
        inGracePeriod: false,
        clearGracePeriodEnd: true,
      );

      expect(cleared.gracePeriodEnd, isNull);
      expect(cleared.inGracePeriod, isFalse);
    });

    test('clears lastCompliantDate back to null', () {
      final withDate = StreakState(lastCompliantDate: _compliantDate);

      expect(
        withDate.copyWith(clearLastCompliantDate: true).lastCompliantDate,
        isNull,
      );
    });

    test('a clear flag wins over a value passed alongside it', () {
      final cleared = StreakState(gracePeriodEnd: _graceEnd)
          .copyWith(gracePeriodEnd: DateTime(2030), clearGracePeriodEnd: true);

      expect(cleared.gracePeriodEnd, isNull);
    });

    test('clearing one nullable does not clear the other', () {
      final both = StreakState(
        lastCompliantDate: _compliantDate,
        gracePeriodEnd: _graceEnd,
      );

      final cleared = both.copyWith(clearGracePeriodEnd: true);

      expect(cleared.gracePeriodEnd, isNull);
      expect(cleared.lastCompliantDate, _compliantDate);
    });
  });

  group('StreakState equality', () {
    test('two instances with identical field values are equal', () {
      expect(StreakState.initial(), StreakState.initial());
      expect(StreakState.initial().hashCode, StreakState.initial().hashCode);
    });

    test('two instances differing only in phase are not equal', () {
      expect(
        StreakState.initial(),
        isNot(const StreakState(phase: AdaptationPhase.deepKetosis)),
      );
    });

    test('two instances differing only in gracePeriodEnd are not equal', () {
      expect(
        StreakState(gracePeriodEnd: _graceEnd),
        isNot(StreakState.initial()),
      );
    });

    test('two instances differing only in currentStreak are not equal', () {
      expect(
        const StreakState(currentStreak: 1),
        isNot(const StreakState(currentStreak: 2)),
      );
    });
  });
}
