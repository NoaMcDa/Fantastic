import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';

/// Persistence contract for the singleton [StreakState].
///
/// Exactly one record exists, so there are no collection queries and [save] is
/// always an upsert of that one row.
///
/// [watch] exists because M3's UI is reactive: `streakStateProvider` (#59) is
/// specified as a stream watching this repository, and the streak ring, phase
/// badge and grace-period banner all rebuild from it.
///
/// Methods return plain futures and throw on failure — see
/// `design/base_design.md` §Error Handling Contract.
abstract interface class StreakRepository {
  /// Returns the persisted state, or null if the user has never completed a
  /// compliant day.
  ///
  /// Null is the first-launch sentinel — callers seed [StreakState.initial]
  /// rather than treating it as an error.
  Future<StreakState?> load();

  /// Upserts the single record. Returns the saved copy.
  Future<StreakState> save(StreakState state);

  /// Emits the current state on subscription and again on every write.
  ///
  /// Emits null while no record exists, matching [load]. Implementations must
  /// fire immediately so a provider has a value without a separate [load].
  Stream<StreakState?> watch();
}
