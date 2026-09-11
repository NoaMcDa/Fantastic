import 'package:fantastic/features/adaptation/application/streak_calculator.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/fixtures.dart';

void main() {
  /// The instant every test reasons from. Fixed, never `DateTime.now()`.
  final now = DateTime(2026, 9, 10, 14, 30);
  final today = DateTime(2026, 9, 10);

  DateTime daysBefore(int n) =>
      DateTime(today.year, today.month, today.day - n);

  /// A compliant day [n] days before [today].
  DailyLog compliant(int n) =>
      DailyLogFixture.fixture(date: daysBefore(n), totalNetCarbsG: 12);

  /// A breached day [n] days before [today].
  DailyLog breach(int n) =>
      DailyLogFixture.fixture(date: daysBefore(n), totalNetCarbsG: 120);

  group('StreakCalculator.derive', () {
    test('an empty history derives a zero streak', () {
      final result = StreakCalculator.derive(logs: const [], now: now);

      expect(result.streak, 0);
      expect(result.lastCompliantDate, isNull);
    });

    test('counts back over contiguous compliant days', () {
      final result = StreakCalculator.derive(
        logs: [compliant(0), compliant(1), compliant(2)],
        now: now,
      );

      expect(result.streak, 3);
      expect(result.lastCompliantDate, today);
    });

    test('today unlogged does not break the streak', () {
      // Today is winnable until midnight.
      final result = StreakCalculator.derive(
        logs: [compliant(1), compliant(2)],
        now: now,
      );

      expect(result.streak, 2);
      expect(result.lastCompliantDate, daysBefore(1));
    });

    test('yesterday unlogged does break it', () {
      final result = StreakCalculator.derive(
        logs: [compliant(0), compliant(2), compliant(3)],
        now: now,
      );

      expect(result.streak, 1);
      expect(result.lastCompliantDate, today);
    });

    test('a day whose meals were all deleted reads as unlogged', () {
      // An all-zero row is not a zero-carb day.
      final result = StreakCalculator.derive(
        logs: [
          compliant(0),
          DailyLogFixture.empty(date: daysBefore(1)),
        ],
        now: now,
      );

      expect(result.streak, 1);
    });

    test('an ungraced breach stops the walk', () {
      final result = StreakCalculator.derive(
        logs: [compliant(0), breach(1), compliant(2)],
        now: now,
      );

      expect(result.streak, 1);
    });

    test('the graced day is stepped over without counting', () {
      final result = StreakCalculator.derive(
        logs: [breach(0), compliant(1), compliant(2)],
        now: now,
        gracedDate: today,
      );

      // The breach is forgiven but earns nothing: two compliant days behind it.
      expect(result.streak, 2);
      expect(result.lastCompliantDate, daysBefore(1));
    });

    test('only the graced day is forgiven, not every breach', () {
      final result = StreakCalculator.derive(
        logs: [breach(0), breach(1), compliant(2)],
        now: now,
        gracedDate: today,
      );

      expect(result.streak, 0);
      expect(result.lastCompliantDate, isNull);
    });

    test('back-filling a gap restores the streak across it', () {
      // Days 1-5 compliant, day 6 missed, then day 6 back-filled: the walk
      // reads the history as it now stands, so the streak spans the gap.
      final result = StreakCalculator.derive(
        logs: [
          compliant(0),
          compliant(1),
          compliant(2),
          compliant(3),
          compliant(4),
          compliant(5),
        ],
        now: now,
      );

      expect(result.streak, 6);
    });

    test('thirty non-contiguous days do not grant a thirty-day streak', () {
      // The naive-fix guard: an accumulator would have added one per
      // back-filled day. Every other day compliant, the rest missing.
      final logs = <DailyLog>[
        for (var back = 0; back < 60; back += 2) compliant(back),
      ];

      final result = StreakCalculator.derive(logs: logs, now: now);

      expect(result.streak, 1);
    });

    test('order of the log list does not matter', () {
      final ascending = StreakCalculator.derive(
        logs: [compliant(2), compliant(1), compliant(0)],
        now: now,
      );
      final descending = StreakCalculator.derive(
        logs: [compliant(0), compliant(1), compliant(2)],
        now: now,
      );

      expect(ascending.streak, descending.streak);
      expect(ascending.lastCompliantDate, descending.lastCompliantDate);
    });

    test('the walk stops at maxDays even when every day qualifies', () {
      final logs = <DailyLog>[
        for (var back = 0; back < StreakCalculator.maxDays + 30; back++)
          compliant(back),
      ];

      final result = StreakCalculator.derive(logs: logs, now: now);

      expect(result.streak, StreakCalculator.maxDays);
    });

    test('a log time of day does not affect which day it counts as', () {
      final lateEvening = DailyLogFixture.fixture(
        date: DateTime(today.year, today.month, today.day, 23, 59),
        totalNetCarbsG: 12,
      );

      final result = StreakCalculator.derive(logs: [lateEvening], now: now);

      expect(result.streak, 1);
      expect(result.lastCompliantDate, today);
    });

    test('counting back across a month boundary lands on real dates', () {
      final march = DateTime(2026, 3, 2, 9);
      final logs = <DailyLog>[
        DailyLogFixture.fixture(date: DateTime(2026, 3, 2), totalNetCarbsG: 5),
        DailyLogFixture.fixture(date: DateTime(2026, 3, 1), totalNetCarbsG: 5),
        DailyLogFixture.fixture(date: DateTime(2026, 2, 28), totalNetCarbsG: 5),
      ];

      final result = StreakCalculator.derive(logs: logs, now: march);

      expect(result.streak, 3);
    });
  });
}
