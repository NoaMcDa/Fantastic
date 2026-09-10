import 'package:fantastic/features/adaptation/application/adaptation_phase_service.dart';
import 'package:fantastic/features/adaptation/data/providers.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'streak_providers.g.dart';

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
@riverpod
Stream<StreakState?> streakState(Ref ref) =>
    ref.watch(streakRepositoryProvider).watch();

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
/// a second time, so both read one stream and cannot disagree.
@riverpod
Future<AdaptationPhase> currentPhase(Ref ref) async {
  final service = ref.watch(adaptationPhaseServiceProvider);

  // The error is re-thrown from the AsyncValue rather than left to surface
  // through `await ...future` below, because it never would: when the source
  // stream fails before emitting, its future never completes, and this
  // provider would sit in AsyncLoading for the life of the app. A storage
  // failure would show a spinner that never resolves instead of an error.
  final snapshot = ref.watch(streakStateProvider);
  final error = snapshot.error;
  if (error != null) {
    Error.throwWithStackTrace(error, snapshot.stackTrace ?? StackTrace.current);
  }

  final state = await ref.watch(streakStateProvider.future);
  return service.currentPhase(state ?? StreakState.initial());
}
