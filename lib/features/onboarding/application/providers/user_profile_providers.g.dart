// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The saved profile, or null when onboarding has never completed.
///
/// A stream rather than a one-shot read, for the same reason
/// `streakStateProvider` is one: the dashboard must repaint the moment
/// onboarding writes, and no caller should have to remember to invalidate
/// after a save. `UserProfileRepository.watch()` fires immediately, so this
/// has a value without a separate `load`.
///
/// **The whole profile, not just its targets.** This replaced a
/// `macroTargetsProvider` that mapped the same stream down to
/// [MacroTargets] and substituted [MacroTargets.defaults] for a missing
/// profile. `DailyTargetsService` needs more than the targets — the
/// biometrics behind the BMR, the activity level and the goals — so that
/// provider had no reader left, and one stream answering one question beats
/// two over the same query.
///
/// Deliberately still an `AsyncValue`, and the null is **not** collapsed into
/// a default here: "never onboarded" and "read failed" are different facts,
/// and a card that quietly showed 150 g of fat to someone whose real target is
/// 250 g would be telling them something false that they then act on
/// (`design/m2_handoff.md` convention 5). `dailyTargetsProvider` is where the
/// default stands in for an absent profile; the error propagates and
/// `MacroSummaryCard` says the load failed.

@ProviderFor(onboardedProfile)
const onboardedProfileProvider = OnboardedProfileProvider._();

/// The saved profile, or null when onboarding has never completed.
///
/// A stream rather than a one-shot read, for the same reason
/// `streakStateProvider` is one: the dashboard must repaint the moment
/// onboarding writes, and no caller should have to remember to invalidate
/// after a save. `UserProfileRepository.watch()` fires immediately, so this
/// has a value without a separate `load`.
///
/// **The whole profile, not just its targets.** This replaced a
/// `macroTargetsProvider` that mapped the same stream down to
/// [MacroTargets] and substituted [MacroTargets.defaults] for a missing
/// profile. `DailyTargetsService` needs more than the targets — the
/// biometrics behind the BMR, the activity level and the goals — so that
/// provider had no reader left, and one stream answering one question beats
/// two over the same query.
///
/// Deliberately still an `AsyncValue`, and the null is **not** collapsed into
/// a default here: "never onboarded" and "read failed" are different facts,
/// and a card that quietly showed 150 g of fat to someone whose real target is
/// 250 g would be telling them something false that they then act on
/// (`design/m2_handoff.md` convention 5). `dailyTargetsProvider` is where the
/// default stands in for an absent profile; the error propagates and
/// `MacroSummaryCard` says the load failed.

final class OnboardedProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserProfile?>,
          UserProfile?,
          Stream<UserProfile?>
        >
    with $FutureModifier<UserProfile?>, $StreamProvider<UserProfile?> {
  /// The saved profile, or null when onboarding has never completed.
  ///
  /// A stream rather than a one-shot read, for the same reason
  /// `streakStateProvider` is one: the dashboard must repaint the moment
  /// onboarding writes, and no caller should have to remember to invalidate
  /// after a save. `UserProfileRepository.watch()` fires immediately, so this
  /// has a value without a separate `load`.
  ///
  /// **The whole profile, not just its targets.** This replaced a
  /// `macroTargetsProvider` that mapped the same stream down to
  /// [MacroTargets] and substituted [MacroTargets.defaults] for a missing
  /// profile. `DailyTargetsService` needs more than the targets — the
  /// biometrics behind the BMR, the activity level and the goals — so that
  /// provider had no reader left, and one stream answering one question beats
  /// two over the same query.
  ///
  /// Deliberately still an `AsyncValue`, and the null is **not** collapsed into
  /// a default here: "never onboarded" and "read failed" are different facts,
  /// and a card that quietly showed 150 g of fat to someone whose real target is
  /// 250 g would be telling them something false that they then act on
  /// (`design/m2_handoff.md` convention 5). `dailyTargetsProvider` is where the
  /// default stands in for an absent profile; the error propagates and
  /// `MacroSummaryCard` says the load failed.
  const OnboardedProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardedProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardedProfileHash();

  @$internal
  @override
  $StreamProviderElement<UserProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<UserProfile?> create(Ref ref) {
    return onboardedProfile(ref);
  }
}

String _$onboardedProfileHash() => r'5c30e122351561084cfa97e8d0c8997cd0f6b00a';
