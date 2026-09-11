// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(userProfile)
const userProfileProvider = UserProfileProvider._();

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

final class UserProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserProfile?>,
          UserProfile?,
          Stream<UserProfile?>
        >
    with $FutureModifier<UserProfile?>, $StreamProvider<UserProfile?> {
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
  const UserProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userProfileHash();

  @$internal
  @override
  $StreamProviderElement<UserProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<UserProfile?> create(Ref ref) {
    return userProfile(ref);
  }
}

String _$userProfileHash() => r'56c16ca80e32f053ee17e2a75c68806637a4f919';

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

@ProviderFor(notificationPermission)
const notificationPermissionProvider = NotificationPermissionProvider._();

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

final class NotificationPermissionProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
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
  const NotificationPermissionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationPermissionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationPermissionHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return notificationPermission(ref);
  }
}

String _$notificationPermissionHash() =>
    r'd241b49c2281f6ffed7f2e1e4c1e70604af69762';

/// The stored estimation settings.
///
/// A one-shot read rather than a stream, because `EstimationSettingsRepository`
/// exposes no `watch` — it is a settings record read when a settings screen
/// opens, not something the rest of the app reacts to. The section
/// invalidates this after every write.
///
/// **Deliberately an `AsyncValue`.** A settings record that cannot be *read*
/// is not a record that says estimation is off, and rendering an unticked
/// checkbox for a storage failure would invite the user to "fix" something
/// that is not broken.

@ProviderFor(estimationSettings)
const estimationSettingsProvider = EstimationSettingsProvider._();

/// The stored estimation settings.
///
/// A one-shot read rather than a stream, because `EstimationSettingsRepository`
/// exposes no `watch` — it is a settings record read when a settings screen
/// opens, not something the rest of the app reacts to. The section
/// invalidates this after every write.
///
/// **Deliberately an `AsyncValue`.** A settings record that cannot be *read*
/// is not a record that says estimation is off, and rendering an unticked
/// checkbox for a storage failure would invite the user to "fix" something
/// that is not broken.

final class EstimationSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<EstimationSettings>,
          EstimationSettings,
          FutureOr<EstimationSettings>
        >
    with
        $FutureModifier<EstimationSettings>,
        $FutureProvider<EstimationSettings> {
  /// The stored estimation settings.
  ///
  /// A one-shot read rather than a stream, because `EstimationSettingsRepository`
  /// exposes no `watch` — it is a settings record read when a settings screen
  /// opens, not something the rest of the app reacts to. The section
  /// invalidates this after every write.
  ///
  /// **Deliberately an `AsyncValue`.** A settings record that cannot be *read*
  /// is not a record that says estimation is off, and rendering an unticked
  /// checkbox for a storage failure would invite the user to "fix" something
  /// that is not broken.
  const EstimationSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'estimationSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$estimationSettingsHash();

  @$internal
  @override
  $FutureProviderElement<EstimationSettings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<EstimationSettings> create(Ref ref) {
    return estimationSettings(ref);
  }
}

String _$estimationSettingsHash() =>
    r'2b7c672fd6296910d78bd50b39706de03ebc993e';
