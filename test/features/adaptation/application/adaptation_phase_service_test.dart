import 'package:fantastic/features/adaptation/application/adaptation_phase_service.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:fantastic/features/adaptation/domain/repositories/streak_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/fixtures.dart';

class _MockStreakRepository extends Mock implements StreakRepository {}

void main() {
  late _MockStreakRepository repository;
  late AdaptationPhaseService service;

  /// The instant every test reasons from. Fixed, never `DateTime.now()` — the
  /// grace-period branches are decided by comparing instants, and a clock read
  /// would make them pass or fail by time of day.
  final now = DateTime(2026, 9, 10, 14, 30);
  final today = DateTime(2026, 9, 10);
  final yesterday = DateTime(2026, 9, 9);

  setUpAll(() => registerFallbackValue(StreakStateFixture.initial()));

  setUp(() {
    repository = _MockStreakRepository();
    service = AdaptationPhaseService(repository);
    // `save` echoes its argument, as the repository contract requires.
    when(() => repository.save(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as StreakState,
    );
  });

  /// Stubs the stored state. Null is the first-launch sentinel.
  void stored(StreakState? state) =>
      when(repository.load).thenAnswer((_) async => state);

  /// The state handed to `save`.
  ///
  /// `verify` consumes the recorded call, so this is callable once per test.
  /// Assert on several fields by holding the result, not by calling twice.
  StreakState saved() =>
      verify(() => repository.save(captureAny())).captured.last as StreakState;

  /// A five-day streak whose grace period is still open at [now].
  ///
  /// **The window is stated here, not taken from the fixture.**
  /// `StreakStateFixture.defaultGracePeriodEnd` is 2026-09-10 12:00, two and a
  /// half hours *before* this suite's [now] — so a fixture called
  /// `inGracePeriod` with no argument is in fact an expired one, and a test
  /// that named the open case was silently exercising the closed one.
  StreakState openWindow() => StreakStateFixture.inGracePeriod(
    gracePeriodEnd: now.add(const Duration(hours: 6)),
  ).copyWith(lastCompliantDate: yesterday);

  /// A twelve-day streak whose grace period closed a minute before [now].
  StreakState closedWindow() => StreakStateFixture.inGracePeriod(
    days: 12,
    gracePeriodEnd: now.subtract(const Duration(minutes: 1)),
  ).copyWith(highestStreak: 30, lastCompliantDate: yesterday);

  group('currentPhase', () {
    // The boundaries are the whole of this function, so every one is asserted
    // on both sides. `design/m3_preflight.md` §1.4: 1–7, 8–27, 28+.
    test('a zero streak is induction', () {
      expect(
        service.currentPhase(StreakStateFixture.withStreak(0)),
        AdaptationPhase.induction,
      );
    });

    test('day 1 is induction', () {
      expect(
        service.currentPhase(StreakStateFixture.withStreak(1)),
        AdaptationPhase.induction,
      );
    });

    test('day 7 is still induction', () {
      expect(
        service.currentPhase(StreakStateFixture.withStreak(7)),
        AdaptationPhase.induction,
      );
    });

    test('day 8 is fatAdapted', () {
      expect(
        service.currentPhase(StreakStateFixture.withStreak(8)),
        AdaptationPhase.fatAdapted,
      );
    });

    test('day 27 is still fatAdapted', () {
      expect(
        service.currentPhase(StreakStateFixture.withStreak(27)),
        AdaptationPhase.fatAdapted,
      );
    });

    test('day 28 is deepKetosis', () {
      expect(
        service.currentPhase(StreakStateFixture.withStreak(28)),
        AdaptationPhase.deepKetosis,
      );
    });

    test('day 29 is still deepKetosis', () {
      expect(
        service.currentPhase(StreakStateFixture.withStreak(29)),
        AdaptationPhase.deepKetosis,
      );
    });

    // The stored phase is a cache of this function's output. If it were ever
    // read back as an input, a record written before a threshold changed would
    // pin the user to the old phase forever.
    test('ignores the phase stored on the state', () {
      final lying = StreakStateFixture.withStreak(
        1,
        phase: AdaptationPhase.deepKetosis,
      );

      expect(service.currentPhase(lying), AdaptationPhase.induction);
    });

    test('reads no state and touches the repository', () {
      service.currentPhase(StreakStateFixture.withStreak(3));

      verifyZeroInteractions(repository);
    });
  });

  group('recordCompliantDay', () {
    test('increments the streak', () async {
      stored(StreakStateFixture.withStreak(3, lastCompliantDate: yesterday));

      await service.recordCompliantDay(now);

      expect(saved().currentStreak, 4);
    });

    test('seeds a streak of 1 on first launch', () async {
      stored(null);

      await service.recordCompliantDay(now);

      expect(saved().currentStreak, 1);
    });

    test('advances the phase with the streak', () async {
      stored(StreakStateFixture.withStreak(7, lastCompliantDate: yesterday));

      await service.recordCompliantDay(now);

      expect(saved().phase, AdaptationPhase.fatAdapted);
    });

    test('raises the personal best when the streak passes it', () async {
      stored(StreakStateFixture.withStreak(3, lastCompliantDate: yesterday));

      await service.recordCompliantDay(now);

      expect(saved().highestStreak, 4);
    });

    test('leaves a higher personal best alone', () async {
      stored(
        StreakStateFixture.withStreak(
          3,
          lastCompliantDate: yesterday,
        ).copyWith(highestStreak: 42),
      );

      await service.recordCompliantDay(now);

      expect(saved().highestStreak, 42);
    });

    test('stores the compliant date stripped to midnight', () async {
      stored(StreakStateFixture.withStreak(3, lastCompliantDate: yesterday));

      await service.recordCompliantDay(now);

      expect(saved().lastCompliantDate, today);
    });

    test('closes an open grace period', () async {
      stored(openWindow());

      await service.recordCompliantDay(now);

      expect(saved().inGracePeriod, isFalse);
    });

    // The defect `design/m3_preflight.md` §1.1 exists to prevent:
    // `copyWith(gracePeriodEnd: null)` resolves to the *existing* value, so a
    // service that passed null here would leave the expiry behind. The
    // assertion above on `inGracePeriod` passes either way — only this one
    // fails when the flag is missing.
    test('clears the grace-period expiry, not just the flag', () async {
      stored(openWindow());

      await service.recordCompliantDay(now);

      expect(saved().gracePeriodEnd, isNull);
    });

    test('resuming inside a grace period keeps the streak going', () async {
      stored(openWindow());

      await service.recordCompliantDay(now);

      expect(saved().currentStreak, 6);
    });

    // The reset is lazy: nothing evaluates the state machine while the user
    // logs nothing, so an expired window is first seen on the next
    // evaluation — and that is at least as likely to be a compliant meal as a
    // breach. Checking expiry only in `handleBreach` let a user who breached,
    // sat out the whole 24 hours and then logged a compliant day carry on as
    // if the lapse had never happened.
    group('after the window has closed', () {
      test('the streak restarts at one rather than resuming', () async {
        stored(closedWindow());

        await service.recordCompliantDay(now);

        expect(saved().currentStreak, 1);
      });

      test('the phase returns to induction', () async {
        stored(closedWindow());

        await service.recordCompliantDay(now);

        expect(saved().phase, AdaptationPhase.induction);
      });

      test('the grace period closes', () async {
        stored(closedWindow());

        await service.recordCompliantDay(now);

        final state = saved();
        expect(state.inGracePeriod, isFalse);
        expect(state.gracePeriodEnd, isNull);
      });

      // A personal best is history, not current state — a lapse must not cost
      // it, here any more than in `handleBreach`.
      test('the personal best survives', () async {
        stored(closedWindow());

        await service.recordCompliantDay(now);

        expect(saved().highestStreak, 30);
      });

      test('the new day is still banked', () async {
        stored(closedWindow());

        await service.recordCompliantDay(now);

        expect(saved().lastCompliantDate, today);
      });

      // Strictly after, matching `handleBreach`: the boundary instant is
      // still inside the window, so the streak resumes rather than restarts.
      test('a compliant day at the exact expiry still resumes', () async {
        final end = now.add(const Duration(hours: 6));
        stored(
          StreakStateFixture.inGracePeriod(
            days: 5,
            gracePeriodEnd: end,
          ).copyWith(lastCompliantDate: yesterday),
        );

        await service.recordCompliantDay(end);

        expect(saved().currentStreak, 6);
      });

      // A malformed record — the flag set with no expiry — has no instant to
      // judge, and guessing would reset a streak on bad data.
      test('an open flag with no expiry does not reset the streak', () async {
        stored(
          StreakStateFixture.withStreak(
            5,
            lastCompliantDate: yesterday,
          ).copyWith(inGracePeriod: true),
        );

        await service.recordCompliantDay(now);

        expect(saved().currentStreak, 6);
      });
    });

    group('idempotence', () {
      // The trigger is per meal (#58). Without the day guard, three meals
      // would leave a three-day streak — §1.2.
      test('a second call for the same day does not increment', () async {
        stored(StreakStateFixture.withStreak(3, lastCompliantDate: today));

        await service.recordCompliantDay(now);

        verifyNever(() => repository.save(any()));
      });

      test(
        'returns the stored state unchanged for a day already banked',
        () async {
          final current = StreakStateFixture.withStreak(
            3,
            lastCompliantDate: today,
          );
          stored(current);

          expect(await service.recordCompliantDay(now), current);
        },
      );

      test(
        'a different time on the same day still does not increment',
        () async {
          stored(StreakStateFixture.withStreak(3, lastCompliantDate: today));

          await service.recordCompliantDay(DateTime(2026, 9, 10, 22, 5));

          verifyNever(() => repository.save(any()));
        },
      );

      test('the next day does increment', () async {
        stored(StreakStateFixture.withStreak(3, lastCompliantDate: today));

        await service.recordCompliantDay(DateTime(2026, 9, 11, 8));

        expect(saved().currentStreak, 4);
      });
    });
  });

  // The rule nothing else in the app can apply: every other transition is
  // driven by a meal being logged, so without this a compliant day in January
  // and another in March read as a two-day streak.
  group('reconcile — a skipped day breaks the streak', () {
    final twoDaysAgo = DateTime(2026, 9, 8);

    test('a last compliant day of today is intact', () {
      final state = StreakStateFixture.withStreak(6, lastCompliantDate: today);

      expect(service.reconcile(state, now).currentStreak, 6);
    });

    // Today is still winnable until midnight, so yesterday is not a skip.
    test('a last compliant day of yesterday is intact', () {
      final state = StreakStateFixture.withStreak(
        6,
        lastCompliantDate: yesterday,
      );

      expect(service.reconcile(state, now).currentStreak, 6);
    });

    test('one whole skipped day breaks it', () {
      final state = StreakStateFixture.withStreak(
        6,
        lastCompliantDate: twoDaysAgo,
      );

      expect(service.reconcile(state, now).currentStreak, 0);
    });

    test('a long absence breaks it', () {
      final state = StreakStateFixture.withStreak(
        30,
        lastCompliantDate: DateTime(2026, 7, 1),
      );

      expect(service.reconcile(state, now).currentStreak, 0);
    });

    test('breaking returns the phase to induction', () {
      final state = StreakStateFixture.withStreak(
        30,
        phase: AdaptationPhase.deepKetosis,
        lastCompliantDate: twoDaysAgo,
      );

      expect(service.reconcile(state, now).phase, AdaptationPhase.induction);
    });

    // A personal best is history, not current state.
    test('breaking keeps the personal best', () {
      final state = StreakStateFixture.withStreak(
        6,
        lastCompliantDate: twoDaysAgo,
      ).copyWith(highestStreak: 30);

      expect(service.reconcile(state, now).highestStreak, 30);
    });

    test('breaking clears the stale compliant date', () {
      final state = StreakStateFixture.withStreak(
        6,
        lastCompliantDate: twoDaysAgo,
      );

      expect(service.reconcile(state, now).lastCompliantDate, isNull);
    });

    test('a user who has never banked a day is left alone', () {
      expect(service.reconcile(StreakStateFixture.initial(), now), isNotNull);
      expect(
        service.reconcile(StreakStateFixture.initial(), now).currentStreak,
        0,
      );
    });

    // A breached day is not a skipped day. The 24-hour window is exactly what
    // a breach buys, and `CLAUDE.md` promises the streak resumes inside it.
    test('an unexpired grace window survives the gap it created', () {
      final state = StreakStateFixture.inGracePeriod(
        days: 6,
        gracePeriodEnd: now.add(const Duration(hours: 3)),
      ).copyWith(lastCompliantDate: twoDaysAgo);

      expect(service.reconcile(state, now).currentStreak, 6);
    });

    test('an expired grace window does not', () {
      final state = StreakStateFixture.inGracePeriod(
        days: 6,
        gracePeriodEnd: now.subtract(const Duration(minutes: 1)),
      ).copyWith(lastCompliantDate: twoDaysAgo);

      expect(service.reconcile(state, now).currentStreak, 0);
    });

    test('is pure — it reads and writes no state', () {
      service.reconcile(
        StreakStateFixture.withStreak(6, lastCompliantDate: twoDaysAgo),
        now,
      );

      verifyNever(repository.load);
      verifyNever(() => repository.save(any()));
    });
  });

  group('recordCompliantDay after a skipped day', () {
    final twoDaysAgo = DateTime(2026, 9, 8);

    // The whole point, end to end: the streak restarts at 1 rather than
    // resuming at 7.
    test('restarts the streak at 1', () async {
      stored(StreakStateFixture.withStreak(6, lastCompliantDate: twoDaysAgo));

      await service.recordCompliantDay(now);

      expect(saved().currentStreak, 1);
    });

    test('returns the phase to induction', () async {
      stored(
        StreakStateFixture.withStreak(
          30,
          phase: AdaptationPhase.deepKetosis,
          lastCompliantDate: twoDaysAgo,
        ),
      );

      await service.recordCompliantDay(now);

      expect(saved().phase, AdaptationPhase.induction);
    });

    test('keeps the personal best', () async {
      stored(
        StreakStateFixture.withStreak(
          6,
          lastCompliantDate: twoDaysAgo,
        ).copyWith(highestStreak: 30),
      );

      await service.recordCompliantDay(now);

      expect(saved().highestStreak, 30);
    });

    test('banks the new day', () async {
      stored(StreakStateFixture.withStreak(6, lastCompliantDate: twoDaysAgo));

      await service.recordCompliantDay(now);

      expect(saved().lastCompliantDate, today);
    });

    // The 43-day-gap case that started this: three compliant days, a long
    // absence, then one more used to read as a four-day streak.
    test('a compliant day after a long absence is day one', () async {
      stored(
        StreakStateFixture.withStreak(
          3,
          lastCompliantDate: DateTime(2026, 7, 29),
        ),
      );

      await service.recordCompliantDay(now);

      expect(saved().currentStreak, 1);
    });

    // The counterpart that must keep working: a breach, then a compliant day
    // inside the window, still resumes.
    test('resuming inside a grace window still continues the streak', () async {
      stored(
        StreakStateFixture.inGracePeriod(
          days: 6,
          gracePeriodEnd: now.add(const Duration(hours: 3)),
        ).copyWith(lastCompliantDate: twoDaysAgo),
      );

      await service.recordCompliantDay(now);

      expect(saved().currentStreak, 7);
    });
  });

  group('handleBreach', () {
    test('opens a grace period on the first breach', () async {
      stored(StreakStateFixture.withStreak(5, lastCompliantDate: yesterday));

      await service.handleBreach(now);

      expect(saved().inGracePeriod, isTrue);
    });

    test('the window runs 24 hours from the breach', () async {
      stored(StreakStateFixture.withStreak(5, lastCompliantDate: yesterday));

      await service.handleBreach(now);

      expect(saved().gracePeriodEnd, now.add(const Duration(hours: 24)));
    });

    test('the streak survives the first breach', () async {
      stored(StreakStateFixture.withStreak(5, lastCompliantDate: yesterday));

      await service.handleBreach(now);

      expect(saved().currentStreak, 5);
    });

    test('a second breach inside the window changes nothing', () async {
      stored(
        StreakStateFixture.inGracePeriod(
          gracePeriodEnd: now.add(const Duration(hours: 6)),
        ).copyWith(lastCompliantDate: yesterday),
      );

      await service.handleBreach(now);

      verifyNever(() => repository.save(any()));
    });

    // Strictly after, so a breach landing on the exact expiry instant is still
    // inside the window. The user is given the boundary, not denied it.
    test('a breach at the exact expiry is still inside the window', () async {
      final end = now.add(const Duration(hours: 6));
      stored(
        StreakStateFixture.inGracePeriod(gracePeriodEnd: end)
            .copyWith(lastCompliantDate: yesterday),
      );

      await service.handleBreach(end);

      verifyNever(() => repository.save(any()));
    });

    group('after the window expires', () {
      StreakState expired() => closedWindow();

      test('the streak resets to zero', () async {
        stored(expired());

        await service.handleBreach(now);

        expect(saved().currentStreak, 0);
      });

      test('the phase returns to induction', () async {
        stored(expired());

        await service.handleBreach(now);

        expect(saved().phase, AdaptationPhase.induction);
      });

      test('the grace period closes', () async {
        stored(expired());

        await service.handleBreach(now);

        expect(saved().inGracePeriod, isFalse);
      });

      // §1.1 again, on the other branch.
      test('the expiry is cleared, not just the flag', () async {
        stored(expired());

        await service.handleBreach(now);

        expect(saved().gracePeriodEnd, isNull);
      });

      test('the stale compliant date is cleared', () async {
        stored(expired());

        await service.handleBreach(now);

        expect(saved().lastCompliantDate, isNull);
      });

      // A personal best is history, not current state. Wiping it would punish
      // the user twice for one lapse.
      test('the personal best survives', () async {
        stored(expired());

        await service.handleBreach(now);

        expect(saved().highestStreak, 30);
      });
    });

    // §1.3's companion: once a day is banked, a later carb-heavy meal that day
    // must not open a grace period against it.
    test('a day already banked compliant is not breached', () async {
      stored(StreakStateFixture.withStreak(5, lastCompliantDate: today));

      await service.handleBreach(now);

      verifyNever(() => repository.save(any()));
    });

    test('breaching on first launch opens a grace period from zero', () async {
      stored(null);

      await service.handleBreach(now);

      final state = saved();
      expect(state.inGracePeriod, isTrue);
      expect(state.currentStreak, 0);
    });
  });

  group('evaluateToday', () {
    test('a compliant day advances the streak', () async {
      stored(StreakStateFixture.withStreak(3, lastCompliantDate: yesterday));

      await service.evaluateToday(now, compliant: true);

      expect(saved().currentStreak, 4);
    });

    test('a breach opens a grace period instead', () async {
      stored(StreakStateFixture.withStreak(3, lastCompliantDate: yesterday));

      await service.evaluateToday(now, compliant: false);

      final state = saved();
      expect(state.inGracePeriod, isTrue);
      expect(state.currentStreak, 3);
    });

    // The user's whole experience of the lazy reset: they breach, they let
    // the 24 hours run out, and the next thing that touches the state machine
    // is a good meal. Whichever branch that lands on, the lapse must have
    // cost the streak.
    test('either branch notices a window that has closed', () async {
      stored(closedWindow());

      await service.evaluateToday(now, compliant: true);

      expect(saved().currentStreak, 1);
    });
  });

  group('failure', () {
    test(
      'a repository failure propagates rather than being swallowed',
      () async {
        when(repository.load).thenThrow(Exception('store gone'));

        await expectLater(
          service.recordCompliantDay(now),
          throwsA(isA<Exception>()),
        );
      },
    );
  });
}
