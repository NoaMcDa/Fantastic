import 'package:fantastic/features/adaptation/application/adaptation_phase_service.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:fantastic/features/adaptation/domain/repositories/streak_repository.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:fantastic/features/dashboard/domain/repositories/daily_log_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/fixtures.dart';

class _MockStreakRepository extends Mock implements StreakRepository {}

class _MockDailyLogRepository extends Mock implements DailyLogRepository {}

void main() {
  late _MockStreakRepository repository;
  late _MockDailyLogRepository dailyLogRepository;
  late AdaptationPhaseService service;

  /// The instant every test reasons from. Fixed, never `DateTime.now()` — the
  /// grace-period branches are decided by comparing instants, and a clock read
  /// would make them pass or fail by time of day.
  final now = DateTime(2026, 9, 10, 14, 30);
  final today = DateTime(2026, 9, 10);
  final yesterday = DateTime(2026, 9, 9);

  DateTime daysBefore(int n) =>
      DateTime(today.year, today.month, today.day - n);

  /// A compliant day [n] days before [today]: well under the carb limit.
  DailyLog compliant(int n) =>
      DailyLogFixture.fixture(date: daysBefore(n), totalNetCarbsG: 12);

  /// A breached day [n] days before [today]: well over it.
  DailyLog breach(int n) =>
      DailyLogFixture.fixture(date: daysBefore(n), totalNetCarbsG: 120);

  setUpAll(() => registerFallbackValue(StreakStateFixture.initial()));

  setUp(() {
    repository = _MockStreakRepository();
    dailyLogRepository = _MockDailyLogRepository();
    service = AdaptationPhaseService(
      repository: repository,
      dailyLogRepository: dailyLogRepository,
    );
    // `save` echoes its argument, as the repository contract requires.
    when(() => repository.save(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as StreakState,
    );
    when(dailyLogRepository.findAll).thenAnswer((_) async => const []);
  });

  /// Stubs the stored streak state. Null is the first-launch sentinel.
  void stored(StreakState? state) =>
      when(repository.load).thenAnswer((_) async => state);

  /// Stubs the logged day history.
  void history(List<DailyLog> logs) =>
      when(dailyLogRepository.findAll).thenAnswer((_) async => logs);

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

  group('recomputeFor — the derived counter', () {
    test('a single compliant day is a streak of 1', () async {
      stored(null);
      history([compliant(0)]);

      await service.recomputeFor(today, at: now);

      final state = saved();
      expect(state.currentStreak, 1);
      expect(state.lastCompliantDate, today);
      expect(state.phase, AdaptationPhase.induction);
    });

    test(
      'an empty history derives a zero streak rather than throwing',
      () async {
        stored(StreakStateFixture.withStreak(5));
        history(const []);

        await service.recomputeFor(today, at: now);

        expect(saved().currentStreak, 0);
      },
    );

    test('the phase follows the derived streak', () async {
      stored(null);
      history([for (var back = 0; back < 8; back++) compliant(back)]);

      await service.recomputeFor(today, at: now);

      final state = saved();
      expect(state.currentStreak, 8);
      expect(state.phase, AdaptationPhase.fatAdapted);
    });

    test('the personal best rises with the streak', () async {
      stored(StreakStateFixture.withStreak(1).copyWith(highestStreak: 1));
      history([compliant(0), compliant(1), compliant(2)]);

      await service.recomputeFor(today, at: now);

      expect(saved().highestStreak, 3);
    });

    test('the personal best does not fall when the streak does', () async {
      // A derived streak *can* fall — that is the point — and a personal best
      // that fell with it would be a new defect.
      stored(StreakStateFixture.withStreak(3).copyWith(highestStreak: 30));
      history([compliant(0)]);

      await service.recomputeFor(today, at: now);

      final state = saved();
      expect(state.currentStreak, 1);
      expect(state.highestStreak, 30);
    });

    test('a skipped day still breaks the streak', () async {
      // Clause 2 of the user report, preserved exactly.
      stored(StreakStateFixture.withStreak(5));
      history([compliant(0), compliant(2), compliant(3)]);

      await service.recomputeFor(today, at: now);

      expect(saved().currentStreak, 1);
    });

    test('today logged nothing does not break the streak', () async {
      stored(StreakStateFixture.withStreak(2));
      history([compliant(1), compliant(2)]);

      await service.recomputeFor(today, at: now);

      final state = saved();
      expect(state.currentStreak, 2);
      expect(state.lastCompliantDate, yesterday);
    });

    test('a broken streak returns the phase to induction', () async {
      stored(
        StreakStateFixture.withStreak(30, phase: AdaptationPhase.deepKetosis),
      );
      history(const []);

      await service.recomputeFor(today, at: now);

      final state = saved();
      expect(state.currentStreak, 0);
      expect(state.phase, AdaptationPhase.induction);
    });

    test('a zero streak clears the stale compliant date', () async {
      stored(StreakStateFixture.withStreak(9));
      history(const []);

      await service.recomputeFor(today, at: now);

      expect(saved().lastCompliantDate, isNull);
    });
  });

  group('recomputeFor — retroactive edits', () {
    test(
      'back-filling the missed day restores the streak across the gap',
      () async {
        // Clause 3 of the user report, and the case the old `_isToday` guard
        // dropped on the floor. Days 1-5 compliant, day 6 missed, day 6 then
        // back-filled while today is day 7.
        stored(StreakStateFixture.withStreak(5));
        history([
          compliant(1),
          compliant(2),
          compliant(3),
          compliant(4),
          compliant(5),
          compliant(6),
        ]);

        await service.recomputeFor(daysBefore(1), at: now);

        expect(saved().currentStreak, 6);
      },
    );

    test(
      'back-filling a day over the limit breaks the streak at that day',
      () async {
        stored(StreakStateFixture.withStreak(5));
        history([compliant(0), breach(1), compliant(2), compliant(3)]);

        await service.recomputeFor(daysBefore(1), at: now);

        expect(saved().currentStreak, 1);
      },
    );

    test('deleting the only meal on a past day shortens the streak', () async {
      stored(StreakStateFixture.withStreak(4));
      history([
        compliant(0),
        DailyLogFixture.empty(date: daysBefore(1)),
        compliant(2),
      ]);

      await service.recomputeFor(daysBefore(1), at: now);

      expect(saved().currentStreak, 1);
    });

    test('back-filling thirty non-contiguous days grants no thirty-day streak', () async {
      // The guard against the naive fix — letting `recordCompliantDay` run on a
      // past date would have added one per back-filled day, with no contiguity
      // check, and handed the user Phase 3.
      stored(null);
      history([for (var back = 0; back < 60; back += 2) compliant(back)]);

      await service.recomputeFor(daysBefore(30), at: now);

      final state = saved();
      expect(state.currentStreak, 1);
      expect(state.phase, AdaptationPhase.induction);
    });

    test('a past write cannot move lastCompliantDate backwards', () async {
      stored(StreakStateFixture.withStreak(3));
      history([compliant(0), compliant(1), compliant(2)]);

      await service.recomputeFor(daysBefore(2), at: now);

      // The most recent compliant day, not the one that was edited.
      expect(saved().lastCompliantDate, today);
    });
  });

  group('recomputeFor — the grace window', () {
    test('a breach today opens a window running 24 hours from now', () async {
      stored(StreakStateFixture.withStreak(5));
      history([breach(0), compliant(1), compliant(2)]);

      await service.recomputeFor(today, at: now);

      final state = saved();
      expect(state.inGracePeriod, isTrue);
      expect(state.gracePeriodEnd, now.add(const Duration(hours: 24)));
    });

    test('the streak survives the breach the window is holding', () async {
      stored(StreakStateFixture.withStreak(2));
      history([breach(0), compliant(1), compliant(2)]);

      await service.recomputeFor(today, at: now);

      // Two compliant days behind the forgiven breach.
      expect(saved().currentStreak, 2);
    });

    test('an unexpired window still forgives the breached day', () async {
      // `openWindow()` expires six hours from now, so it opened eighteen hours
      // ago — the breach it is holding is *yesterday's*.
      stored(openWindow());
      history([breach(1), compliant(2), compliant(3)]);

      await service.recomputeFor(today, at: now);

      final state = saved();
      expect(state.currentStreak, 2);
      expect(state.inGracePeriod, isTrue);
    });

    test('an expired one does not', () async {
      stored(closedWindow());
      history([breach(1), compliant(2), compliant(3)]);

      await service.recomputeFor(today, at: now);

      final state = saved();
      expect(state.currentStreak, 0);
      expect(state.inGracePeriod, isFalse);
      expect(state.gracePeriodEnd, isNull);
    });

    test('a compliant day inside the window resumes the streak', () async {
      stored(openWindow());
      history([compliant(0), breach(1), compliant(2), compliant(3)]);

      await service.recomputeFor(today, at: now);

      // Today counts, yesterday's breach is graced and earns nothing, and the
      // two behind it count: three.
      expect(saved().currentStreak, 3);
    });

    test('a second breach on a later day is not forgiven twice', () async {
      stored(openWindow());
      history([breach(0), breach(1), compliant(2)]);

      await service.recomputeFor(today, at: now);

      // The window graces yesterday only; today's breach ends the walk.
      expect(saved().currentStreak, 0);
    });

    test('a breach on a past day opens no window', () async {
      // A grace period is a chance to recover from a breach as it happens.
      // Granting one retroactively writes an already-expired window that arms
      // an immediate reset.
      stored(StreakStateFixture.withStreak(5));
      history([compliant(0), breach(3), compliant(4)]);

      await service.recomputeFor(daysBefore(3), at: now);

      final state = saved();
      expect(state.inGracePeriod, isFalse);
      expect(state.gracePeriodEnd, isNull);
    });

    test('a breach at the exact expiry instant is still inside the window', () async {
      final endsAt = now;
      stored(
        StreakStateFixture.inGracePeriod(gracePeriodEnd: endsAt)
            .copyWith(lastCompliantDate: yesterday),
      );
      history([breach(1), compliant(2)]);

      await service.recomputeFor(today, at: now);

      // The user is given the boundary, not denied it: `isAfter` is strict, so
      // a window ending exactly now is still open and still graces yesterday.
      expect(saved().currentStreak, 1);
    });

    test('a zero streak closes any window still open', () async {
      stored(openWindow());
      history([breach(0), breach(1)]);

      await service.recomputeFor(today, at: now);

      final state = saved();
      expect(state.currentStreak, 0);
      expect(state.inGracePeriod, isFalse);
      expect(state.gracePeriodEnd, isNull);
    });

    test('clears the expiry, not just the flag', () async {
      // `copyWith(gracePeriodEnd: null)` resolves null to the existing value
      // and silently does not clear — `design/m3_handoff.md` convention 2.
      stored(closedWindow());
      history(const []);

      await service.recomputeFor(today, at: now);

      final state = saved();
      expect(state.inGracePeriod, isFalse);
      expect(state.gracePeriodEnd, isNull);
    });
  });

  group('failure', () {
    test('a streak repository failure propagates', () async {
      when(repository.load).thenThrow(Exception('store gone'));

      await expectLater(
        service.recomputeFor(today, at: now),
        throwsA(isA<Exception>()),
      );
    });

    test('a day-log repository failure propagates', () async {
      // Not swallowed to keep a stale streak on screen.
      stored(null);
      when(dailyLogRepository.findAll).thenThrow(Exception('store gone'));

      await expectLater(
        service.recomputeFor(today, at: now),
        throwsA(isA<Exception>()),
      );
    });
  });
}
