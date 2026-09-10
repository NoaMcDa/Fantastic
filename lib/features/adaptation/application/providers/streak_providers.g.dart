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

/// The adaptation phase the user is currently in.
///
/// Derived, not stored: [AdaptationPhaseService.currentPhase] computes it from
/// the streak length every time, so a record written before a threshold moved
/// cannot pin a user to a stale phase. `StreakState.phase` is a cache of this
/// same computation, never an input to it.
///
/// A first-launch null streak resolves to `StreakState.initial`'s zero streak,
/// which is [AdaptationPhase.induction] — the phase a new user is genuinely
/// in, not a placeholder.
///
/// Chained off [streakStateProvider] rather than subscribing to the repository
/// again: one subscription, one source of truth, and re-emitting on every
/// write comes for free.

@ProviderFor(currentPhase)
const currentPhaseProvider = CurrentPhaseProvider._();

/// The adaptation phase the user is currently in.
///
/// Derived, not stored: [AdaptationPhaseService.currentPhase] computes it from
/// the streak length every time, so a record written before a threshold moved
/// cannot pin a user to a stale phase. `StreakState.phase` is a cache of this
/// same computation, never an input to it.
///
/// A first-launch null streak resolves to `StreakState.initial`'s zero streak,
/// which is [AdaptationPhase.induction] — the phase a new user is genuinely
/// in, not a placeholder.
///
/// Chained off [streakStateProvider] rather than subscribing to the repository
/// again: one subscription, one source of truth, and re-emitting on every
/// write comes for free.

final class CurrentPhaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<AdaptationPhase>,
          AdaptationPhase,
          FutureOr<AdaptationPhase>
        >
    with $FutureModifier<AdaptationPhase>, $FutureProvider<AdaptationPhase> {
  /// The adaptation phase the user is currently in.
  ///
  /// Derived, not stored: [AdaptationPhaseService.currentPhase] computes it from
  /// the streak length every time, so a record written before a threshold moved
  /// cannot pin a user to a stale phase. `StreakState.phase` is a cache of this
  /// same computation, never an input to it.
  ///
  /// A first-launch null streak resolves to `StreakState.initial`'s zero streak,
  /// which is [AdaptationPhase.induction] — the phase a new user is genuinely
  /// in, not a placeholder.
  ///
  /// Chained off [streakStateProvider] rather than subscribing to the repository
  /// again: one subscription, one source of truth, and re-emitting on every
  /// write comes for free.
  const CurrentPhaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentPhaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentPhaseHash();

  @$internal
  @override
  $FutureProviderElement<AdaptationPhase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AdaptationPhase> create(Ref ref) {
    return currentPhase(ref);
  }
}

String _$currentPhaseHash() => r'f816e1b72479e15e94956447ea2d314a7a360d92';
