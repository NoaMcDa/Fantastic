import 'package:fantastic/features/adaptation/data/providers.dart';
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
