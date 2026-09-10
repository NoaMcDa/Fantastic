// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's single source of truth for streak state.
///
/// A **stream**, not a one-shot load. `StreakRepository.watch` emits the
/// stored record on subscription and again on every write, so the ring, the
/// phase badge and the grace-period banner all refresh the moment
/// `AdaptationPhaseService` saves — no caller has to remember to invalidate
/// this provider after a transition, and none can forget to.
///
/// Emits `null` while no record exists. That is the first-launch sentinel, not
/// an error: consumers render `StreakState.initial`'s zero streak rather than
/// a failure state.

@ProviderFor(streakState)
const streakStateProvider = StreakStateProvider._();

/// The app's single source of truth for streak state.
///
/// A **stream**, not a one-shot load. `StreakRepository.watch` emits the
/// stored record on subscription and again on every write, so the ring, the
/// phase badge and the grace-period banner all refresh the moment
/// `AdaptationPhaseService` saves — no caller has to remember to invalidate
/// this provider after a transition, and none can forget to.
///
/// Emits `null` while no record exists. That is the first-launch sentinel, not
/// an error: consumers render `StreakState.initial`'s zero streak rather than
/// a failure state.

final class StreakStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<StreakState?>,
          StreakState?,
          Stream<StreakState?>
        >
    with $FutureModifier<StreakState?>, $StreamProvider<StreakState?> {
  /// The app's single source of truth for streak state.
  ///
  /// A **stream**, not a one-shot load. `StreakRepository.watch` emits the
  /// stored record on subscription and again on every write, so the ring, the
  /// phase badge and the grace-period banner all refresh the moment
  /// `AdaptationPhaseService` saves — no caller has to remember to invalidate
  /// this provider after a transition, and none can forget to.
  ///
  /// Emits `null` while no record exists. That is the first-launch sentinel, not
  /// an error: consumers render `StreakState.initial`'s zero streak rather than
  /// a failure state.
  const StreakStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'streakStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$streakStateHash();

  @$internal
  @override
  $StreamProviderElement<StreakState?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<StreakState?> create(Ref ref) {
    return streakState(ref);
  }
}

String _$streakStateHash() => r'4e9494aaec2de53b731142bd121ad4d82855669f';
