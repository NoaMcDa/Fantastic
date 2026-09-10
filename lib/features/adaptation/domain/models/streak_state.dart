import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:meta/meta.dart';

/// The single record driving the adaptation phase state machine.
///
/// Per `CLAUDE.md`: the streak increments on compliant days; a breach opens a
/// 24-hour grace period; a compliant day logged inside that window resumes the
/// streak, and otherwise it resets to 0 and the phase returns to Phase 1.
///
/// That is why [gracePeriodEnd] exists alongside [inGracePeriod] — a boolean
/// alone cannot tell the service whether the window has closed.
///
/// Pure domain: no Flutter, no persistence package, no Riverpod. There is no
/// `id` field; the
/// record is a singleton and the data layer pins it to a fixed row.
@immutable
class StreakState {
  const StreakState({
    this.currentStreak = 0,
    this.highestStreak = 0,
    this.phase = AdaptationPhase.induction,
    this.lastCompliantDate,
    this.inGracePeriod = false,
    this.gracePeriodEnd,
  });

  /// The state a brand-new user starts from, and the state a lapsed streak
  /// resets to. Seeded by onboarding (#73) and by grace-period expiry.
  factory StreakState.initial() => const StreakState();

  final int currentStreak;
  final int highestStreak;
  final AdaptationPhase phase;

  /// Last day counted as compliant. Null before the first compliant day.
  final DateTime? lastCompliantDate;

  final bool inGracePeriod;

  /// When the 24-hour grace period expires. Null unless [inGracePeriod].
  final DateTime? gracePeriodEnd;

  /// Copy with overrides.
  ///
  /// [clearLastCompliantDate] and [clearGracePeriodEnd] exist because a plain
  /// `value ?? this.value` cannot express "set this back to null" — which is
  /// exactly what the service needs when a grace period ends or a streak
  /// resets. Passing a value and its clear flag together clears the field.
  StreakState copyWith({
    int? currentStreak,
    int? highestStreak,
    AdaptationPhase? phase,
    DateTime? lastCompliantDate,
    bool clearLastCompliantDate = false,
    bool? inGracePeriod,
    DateTime? gracePeriodEnd,
    bool clearGracePeriodEnd = false,
  }) => StreakState(
    currentStreak: currentStreak ?? this.currentStreak,
    highestStreak: highestStreak ?? this.highestStreak,
    phase: phase ?? this.phase,
    lastCompliantDate: clearLastCompliantDate
        ? null
        : lastCompliantDate ?? this.lastCompliantDate,
    inGracePeriod: inGracePeriod ?? this.inGracePeriod,
    gracePeriodEnd: clearGracePeriodEnd
        ? null
        : gracePeriodEnd ?? this.gracePeriodEnd,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreakState &&
          other.currentStreak == currentStreak &&
          other.highestStreak == highestStreak &&
          other.phase == phase &&
          other.lastCompliantDate == lastCompliantDate &&
          other.inGracePeriod == inGracePeriod &&
          other.gracePeriodEnd == gracePeriodEnd;

  @override
  int get hashCode => Object.hash(
    currentStreak,
    highestStreak,
    phase,
    lastCompliantDate,
    inGracePeriod,
    gracePeriodEnd,
  );
}
