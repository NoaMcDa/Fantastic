import 'package:fantastic/core/providers/notification_providers.dart';
import 'package:fantastic/features/onboarding/data/providers.dart';
import 'package:fantastic/features/onboarding/domain/models/user_profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_providers.g.dart';

/// The saved profile, or null when onboarding has never completed.
///
/// A stream for the same reason `macroTargetsProvider` is one: the screen must
/// repaint the moment anything writes, and no caller should have to remember
/// to invalidate. `UserProfileRepository.watch()` fires immediately, so this
/// has a value without a separate `load`.
///
/// **Unmapped, and the null is not collapsed into a default.**
/// `macroTargetsProvider` substitutes `MacroTargets.defaults` for a missing
/// profile, which is right for a dashboard that must show something — and
/// wrong here, where "never onboarded" and "read failed" are two different
/// things the screen has to be able to tell apart. Null is the first-launch
/// sentinel (`UserProfileRepository.load`), not an error.
@riverpod
Stream<UserProfile?> userProfile(Ref ref) =>
    ref.watch(userProfileRepositoryProvider).watch();

/// Whether the OS will currently deliver this app's notifications.
///
/// Never prompts — `NotificationService.isPermissionGranted` is the query
/// counterpart to `requestPermission`, precisely so a settings row can be
/// built on every frame without spending the one prompt iOS allows.
///
/// Invalidated by `NotificationSettingTile` after a successful request, so
/// the row reflects the new answer without a tab switch. Not kept alive: the
/// value changes outside the app whenever the user visits system settings,
/// and a cached answer would be stale exactly when it matters.
@riverpod
Future<bool> notificationPermission(Ref ref) =>
    ref.watch(notificationServiceProvider).isPermissionGranted();
