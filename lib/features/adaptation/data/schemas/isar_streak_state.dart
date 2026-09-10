import 'package:isar_community/isar.dart';

part 'isar_streak_state.g.dart';

/// Isar persistence shape for `StreakState`.
///
/// Unlike the other schemas this is a **singleton**: exactly one streak record
/// exists, pinned to row 0, so `IsarStreakRepository` (#41) always reads and
/// writes that row and duplicates are structurally impossible.
///
/// Field names match the domain model exactly so a rename on either side fails
/// to compile rather than silently dropping data.
@collection
class IsarStreakState {
  /// Fixed singleton id. Never auto-incremented — see the class doc.
  Id id = 0;

  late int currentStreak;
  late int highestStreak;

  @enumerated
  late AdaptationPhaseIsar phase;

  late bool inGracePeriod;

  /// Null unless [inGracePeriod]; null is a normal first-launch state.
  DateTime? gracePeriodEnd;

  /// Null before the user's first compliant day.
  DateTime? lastCompliantDate;
}

/// Data-layer mirror of the domain `AdaptationPhase`.
///
/// Kept separate so the domain enum carries no Isar annotations. Stored by
/// **ordinal**, so this must stay in the same order as the domain enum —
/// inserting or reordering a value silently reinterprets every stored record.
/// Append only; the parity test in
/// `test/features/adaptation/data/mappers/streak_state_mapper_test.dart`
/// fails loudly if the two ever drift.
enum AdaptationPhaseIsar { induction, fatAdapted, deepKetosis }
