import 'dart:async';

import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/adaptation/application/providers/streak_providers.dart';
import 'package:fantastic/features/adaptation/data/providers.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:fantastic/features/adaptation/domain/repositories/streak_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';

class _MockStreakRepository extends Mock implements StreakRepository {}

void main() {
  late _MockStreakRepository repository;

  setUp(() => repository = _MockStreakRepository());

  /// A container whose repository emits what [stream] builds, already
  /// subscribed to.
  ///
  /// A factory rather than a stream instance: an errored provider is rebuilt
  /// on the next read, and `watch()` handing back the same single-subscription
  /// stream twice throws "Stream has already been listened to" — masking the
  /// error the test is actually about.
  ///
  /// The subscription is not optional. `streakStateProvider` auto-disposes,
  /// and `read(provider.future)` alone does not hold it: riverpod 3 tears the
  /// provider down while it is still loading and the future completes with
  /// "disposed during loading state" instead of the value. A `listen` is what
  /// keeps it mounted — and `fireImmediately: true` does not, which is worth
  /// knowing before spending an afternoon on it.
  ProviderContainer containerWith(Stream<StreakState?> Function() stream) {
    when(repository.watch).thenAnswer((_) => stream());
    final container = ProviderContainer(
      overrides: [streakRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(streakStateProvider, (_, _) {});
    return container;
  }

  test('resolves to the state the repository emits', () async {
    final state = StreakStateFixture.withStreak(5);

    final container = containerWith(() => Stream.value(state));

    expect(await container.read(streakStateProvider.future), state);
  });

  // Null is the first-launch sentinel, not a failure — the UI shows a zero
  // streak rather than an error.
  test('resolves to null before the first compliant day', () async {
    final container = containerWith(() => Stream<StreakState?>.value(null));

    expect(await container.read(streakStateProvider.future), isNull);
  });

  // The point of a stream over a one-shot load: a write reaches the UI with
  // nobody having to remember to invalidate the provider.
  test('re-emits on every write, with no invalidation', () async {
    final controller = StreamController<StreakState?>();
    addTearDown(controller.close);
    final container = containerWith(() => controller.stream);

    final seen = <StreakState?>[];
    container.listen(streakStateProvider, (_, next) => next.whenData(seen.add));

    controller
      ..add(null)
      ..add(StreakStateFixture.withStreak(1))
      ..add(StreakStateFixture.withStreak(2));
    await pumpEventQueue();

    expect(seen, [
      null,
      StreakStateFixture.withStreak(1),
      StreakStateFixture.withStreak(2),
    ]);
  });

  test('subscribes to the repository exactly once', () async {
    final container = containerWith(
      () => Stream.value(StreakStateFixture.initial()),
    );

    await container.read(streakStateProvider.future);
    container.read(streakStateProvider);

    verify(repository.watch).called(1);
  });

  // The repository wraps storage failures as PersistenceException, on the
  // stream as well as on a future. The provider must surface that as an error
  // state rather than flattening it into the first-launch null.
  //
  // Asserted on the AsyncValue, not on `.future`: awaiting the future of an
  // errored auto-disposing provider never settles in riverpod 3 — it hangs
  // until the test times out. The same trap cost #47 a test.
  test('surfaces a stream failure as an error, not as null', () async {
    final container = containerWith(
      () => Stream<StreakState?>.error(
        const PersistenceException('watch failed', 'closed'),
      ),
    );
    await pumpEventQueue();

    final value = container.read(streakStateProvider);
    expect(value.hasError, isTrue);
    expect(value.error, isA<PersistenceException>());
    expect(value.value, isNull);
  });
}
