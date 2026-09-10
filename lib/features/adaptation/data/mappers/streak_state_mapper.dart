import 'package:fantastic/features/adaptation/data/schemas/isar_streak_state.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';

/// Converts between [StreakState] and its Isar persistence shape.
///
/// Called only by `IsarStreakRepository` (#41) — never from `domain/` or
/// `presentation/`, which must not see Isar types at all.
abstract final class StreakStateMapper {
  /// The row every streak record is pinned to. There is exactly one.
  static const int singletonId = 0;

  static IsarStreakState toIsar(StreakState state) => IsarStreakState()
    ..id = singletonId
    ..currentStreak = state.currentStreak
    ..highestStreak = state.highestStreak
    ..phase = AdaptationPhaseIsar.values[state.phase.index]
    ..inGracePeriod = state.inGracePeriod
    ..gracePeriodEnd = state.gracePeriodEnd
    ..lastCompliantDate = state.lastCompliantDate;

  static StreakState toDomain(IsarStreakState schema) => StreakState(
    currentStreak: schema.currentStreak,
    highestStreak: schema.highestStreak,
    phase: AdaptationPhase.values[schema.phase.index],
    inGracePeriod: schema.inGracePeriod,
    gracePeriodEnd: schema.gracePeriodEnd,
    lastCompliantDate: schema.lastCompliantDate,
  );
}
