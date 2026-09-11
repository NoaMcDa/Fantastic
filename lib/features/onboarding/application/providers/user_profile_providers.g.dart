// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The macro targets the dashboard measures a day against.
///
/// A stream rather than a one-shot read, for the same reason
/// `streakStateProvider` is one: the dashboard must repaint the moment
/// onboarding writes, and no caller should have to remember to invalidate
/// after a save. `UserProfileRepository.watch()` fires immediately, so this
/// has a value without a separate `load`.
///
/// [MacroTargets.defaults] — the `KetoConstants` values `MacroSummaryCard`
/// read directly through M2 and M3 — until a profile exists.
///
/// Deliberately still an `AsyncValue`: a profile that cannot be *read* is not
/// a profile that is *absent*, and a card that quietly showed 150 g of fat to
/// someone whose real target is 250 g would be telling them something false
/// that they then act on (`design/m2_handoff.md` convention 5). The error
/// propagates and `MacroSummaryCard` says the load failed.

@ProviderFor(macroTargets)
const macroTargetsProvider = MacroTargetsProvider._();

/// The macro targets the dashboard measures a day against.
///
/// A stream rather than a one-shot read, for the same reason
/// `streakStateProvider` is one: the dashboard must repaint the moment
/// onboarding writes, and no caller should have to remember to invalidate
/// after a save. `UserProfileRepository.watch()` fires immediately, so this
/// has a value without a separate `load`.
///
/// [MacroTargets.defaults] — the `KetoConstants` values `MacroSummaryCard`
/// read directly through M2 and M3 — until a profile exists.
///
/// Deliberately still an `AsyncValue`: a profile that cannot be *read* is not
/// a profile that is *absent*, and a card that quietly showed 150 g of fat to
/// someone whose real target is 250 g would be telling them something false
/// that they then act on (`design/m2_handoff.md` convention 5). The error
/// propagates and `MacroSummaryCard` says the load failed.

final class MacroTargetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<MacroTargets>,
          MacroTargets,
          Stream<MacroTargets>
        >
    with $FutureModifier<MacroTargets>, $StreamProvider<MacroTargets> {
  /// The macro targets the dashboard measures a day against.
  ///
  /// A stream rather than a one-shot read, for the same reason
  /// `streakStateProvider` is one: the dashboard must repaint the moment
  /// onboarding writes, and no caller should have to remember to invalidate
  /// after a save. `UserProfileRepository.watch()` fires immediately, so this
  /// has a value without a separate `load`.
  ///
  /// [MacroTargets.defaults] — the `KetoConstants` values `MacroSummaryCard`
  /// read directly through M2 and M3 — until a profile exists.
  ///
  /// Deliberately still an `AsyncValue`: a profile that cannot be *read* is not
  /// a profile that is *absent*, and a card that quietly showed 150 g of fat to
  /// someone whose real target is 250 g would be telling them something false
  /// that they then act on (`design/m2_handoff.md` convention 5). The error
  /// propagates and `MacroSummaryCard` says the load failed.
  const MacroTargetsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'macroTargetsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$macroTargetsHash();

  @$internal
  @override
  $StreamProviderElement<MacroTargets> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<MacroTargets> create(Ref ref) {
    return macroTargets(ref);
  }
}

String _$macroTargetsHash() => r'a155b16e9ac10402b002d8fc7e085f4c57520eef';
