import 'package:fantastic/features/onboarding/domain/models/user_profile.dart';

/// Persistence contract for the singleton [UserProfile].
///
/// Exactly one record exists, so there are no collection queries and [save]
/// is always an upsert of that one row — the same shape as
/// `StreakRepository`.
///
/// Methods return plain futures and throw on failure — see
/// `design/base_design.md` §Error Handling Contract.
abstract interface class UserProfileRepository {
  /// Returns the persisted profile, or null if onboarding has never been
  /// completed.
  ///
  /// **Null is the first-launch sentinel**, not an error: it is what the
  /// onboarding gate reads at startup, and it is why there is no separate
  /// `hasCompletedOnboarding` flag.
  Future<UserProfile?> load();

  /// Upserts the single record. Returns the saved copy.
  Future<UserProfile> save(UserProfile profile);

  /// Emits the current profile on subscription and again on every write.
  ///
  /// Emits null while no record exists, matching [load]. Implementations must
  /// fire immediately, so `macroTargetsProvider` has a value without a
  /// separate [load] and the dashboard repaints the moment onboarding writes.
  Stream<UserProfile?> watch();
}
