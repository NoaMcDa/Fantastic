import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';

/// Converts between [StreakState] and its sembast record shape.
///
/// Called only by `SembastStreakRepository` — never from `domain/` or
/// `presentation/`, which must not see a persistence shape at all.
///
/// There is exactly one record, at [singletonId], so this codec takes no key.
abstract final class StreakStateMapper {
  /// The record every streak write is pinned to. There is exactly one.
  static const int singletonId = 0;

  static Map<String, Object?> toRecord(StreakState state) => {
    'currentStreak': state.currentStreak,
    'highestStreak': state.highestStreak,
    // Stored by `name`, not by ordinal. Isar required an ordinal; sembast does
    // not, and a stored ordinal silently remaps every persisted row the day a
    // value is inserted into the middle of `AdaptationPhase`.
    'phase': state.phase.name,
    'inGracePeriod': state.inGracePeriod,
    'gracePeriodEnd': state.gracePeriodEnd?.millisecondsSinceEpoch,
    'lastCompliantDate': state.lastCompliantDate?.millisecondsSinceEpoch,
  };

  static StreakState fromRecord(Map<String, Object?> record) => StreakState(
    currentStreak: record['currentStreak']! as int,
    highestStreak: record['highestStreak']! as int,
    phase: AdaptationPhase.values.byName(record['phase']! as String),
    inGracePeriod: record['inGracePeriod']! as bool,
    gracePeriodEnd: _dateOrNull(record['gracePeriodEnd']),
    lastCompliantDate: _dateOrNull(record['lastCompliantDate']),
  );

  static DateTime? _dateOrNull(Object? millis) => millis == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(millis as int);
}
