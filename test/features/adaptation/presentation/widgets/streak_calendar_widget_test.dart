import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/adaptation/presentation/widgets/streak_calendar_widget.dart';
import 'package:fantastic/features/dashboard/data/providers.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:fantastic/features/dashboard/domain/repositories/daily_log_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

class _MockDailyLogRepository extends Mock implements DailyLogRepository {}

void main() {
  late _MockDailyLogRepository repository;

  setUp(() {
    repository = _MockDailyLogRepository();
    when(repository.findAll).thenAnswer((_) async => []);
  });

  /// A month safely in the past, so every day in it counts as elapsed.
  ///
  /// September 2026 starts on a Tuesday and has 30 days — both asserted
  /// below, so a wrong constant fails loudly rather than quietly weakening
  /// the layout tests.
  final month = DateTime(2026, 9);

  Future<void> pumpCalendar(
    WidgetTester tester, {
    List<DailyLog> logs = const [],
    DateTime? forMonth,
  }) async {
    when(repository.findAll).thenAnswer((_) async => logs);
    await pumpApp(
      tester,
      SingleChildScrollView(
        child: StreakCalendarWidget(month: forMonth ?? month),
      ),
      overrides: [dailyLogRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.pumpAndSettle();
  }

  /// The fill colour of the cell showing [day].
  Color cellColour(WidgetTester tester, int day) {
    final box = tester.widget<DecoratedBox>(
      find
          .ancestor(of: find.text('$day'), matching: find.byType(DecoratedBox))
          .first,
    );
    return (box.decoration as BoxDecoration).color!;
  }

  /// A day in [month] whose totals give [ratio], with a real denominator.
  /// A compliant day: comfortably inside the streak's net-carb limit.
  DailyLog compliantDay(int day) => DailyLogFixture.fixture(
    date: DateTime(month.year, month.month, day),
    totalNetCarbsG: 12,
  );

  /// A breached day: comfortably over it.
  DailyLog breachDay(int day) => DailyLogFixture.fixture(
    date: DateTime(month.year, month.month, day),
    totalNetCarbsG: 120,
  );

  group('layout', () {
    testWidgets('draws a cell for every day of the month', (tester) async {
      await pumpCalendar(tester);

      expect(find.text('1'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('31'), findsNothing);
    });

    testWidgets('draws 31 cells in a 31-day month', (tester) async {
      await pumpCalendar(tester, forMonth: DateTime(2026, 8));

      expect(find.text('31'), findsOneWidget);
    });

    testWidgets('handles a leap February', (tester) async {
      await pumpCalendar(tester, forMonth: DateTime(2028, 2));

      expect(find.text('29'), findsOneWidget);
      expect(find.text('30'), findsNothing);
    });

    // Sunday-first, as the Hebrew week runs. The issue offsets by
    // `weekday - 1`, which is Monday-first and shifts every cell by one
    // column in an Israeli calendar.
    testWidgets('the weekday header starts on Sunday', (tester) async {
      await pumpCalendar(tester);

      expect(StreakCalendarWidget.weekdayInitials.first, 'א');
      expect(find.text('א'), findsOneWidget);
      expect(find.text('ש'), findsOneWidget);
    });

    test('a month starting on Sunday needs no leading blanks', () {
      // 1 November 2026 is a Sunday.
      expect(StreakCalendarWidget.leadingBlanks(DateTime(2026, 11)), 0);
    });

    test('a month starting on Tuesday needs two leading blanks', () {
      // 1 September 2026 is a Tuesday: Sunday and Monday come first.
      expect(StreakCalendarWidget.leadingBlanks(month), 2);
    });

    test('a month starting on Saturday needs six leading blanks', () {
      // 1 August 2026 is a Saturday, the last day of the Hebrew week.
      expect(StreakCalendarWidget.leadingBlanks(DateTime(2026, 8)), 6);
    });
  });

  group('day colours', () {
    testWidgets('a day within the carb limit is green', (tester) async {
      await pumpCalendar(tester, logs: [compliantDay(3)]);

      expect(cellColour(tester, 3), AppTheme.success);
    });

    testWidgets('a day over the carb limit is red', (tester) async {
      await pumpCalendar(tester, logs: [breachDay(4)]);

      expect(cellColour(tester, 4), AppTheme.danger);
    });

    // The grid and the ring are now one rule, not two copies of it (#303).
    // This is the case that separates them: 30g fat / 8g carbs / 90g protein
    // is a ratio of 0.31, which the old rule painted red, and 8g of net carbs,
    // which the streak counts as one of its best days.
    testWidgets('the cell follows the carb rule, not the keto ratio', (
      tester,
    ) async {
      await pumpCalendar(
        tester,
        logs: [
          DailyLogFixture.fixture(
            date: DateTime(month.year, month.month, 7),
            totalFatG: 30,
            totalNetCarbsG: 8,
            totalProteinG: 90,
            ketoRatioAvg: 0.31,
          ),
        ],
      );

      expect(cellColour(tester, 7), AppTheme.success);
    });

    testWidgets('a day with no log is neither', (tester) async {
      await pumpCalendar(tester, logs: [compliantDay(3)]);

      expect(cellColour(tester, 5), isNot(AppTheme.success));
      expect(cellColour(tester, 5), isNot(AppTheme.danger));
    });

    // Butter coffee and nothing else. The old rule read `netCarbs + protein
    // == 0` and called this unlogged; under a carb rule zero net carbs is the
    // best day there is, so it is green.
    testWidgets('a fat-only day is compliant, not unlogged', (tester) async {
      await pumpCalendar(
        tester,
        logs: [
          DailyLogFixture.fixture(
            date: DateTime(month.year, month.month, 6),
            totalFatG: 30,
            totalNetCarbsG: 0,
            totalProteinG: 0,
          ),
        ],
      );

      expect(cellColour(tester, 6), AppTheme.success);
    });

    testWidgets('only the logged day is coloured', (tester) async {
      await pumpCalendar(tester, logs: [compliantDay(3)]);

      expect(cellColour(tester, 3), AppTheme.success);
      expect(cellColour(tester, 4), isNot(AppTheme.success));
    });

    // A day that has not happened is not a day the user skipped, so it is
    // drawn fainter than an unlogged past day.
    testWidgets('future days are dimmer than unlogged past days', (
      tester,
    ) async {
      final now = DateTime.now();
      await pumpCalendar(tester, forMonth: DateTime(now.year, now.month));

      final lastDay = DateUtils.getDaysInMonth(now.year, now.month);
      if (now.day >= lastDay) {
        return; // No future day this month to compare against.
      }
      expect(cellColour(tester, lastDay).a, lessThan(cellColour(tester, 1).a));
    });
  });

  // A digit run inside the RTL layout renders reversed without its own
  // direction — '30' would show as '03'.
  testWidgets('day numbers are laid out left-to-right', (tester) async {
    await pumpCalendar(tester);

    expect(
      tester.widget<Text>(find.text('30')).textDirection,
      TextDirection.ltr,
    );
  });

  // One read for the month, not one per day: thirty-one family instances
  // would hit the store thirty-one times to draw one screen and flicker in
  // cell by cell.
  testWidgets('reads the store once for the whole month', (tester) async {
    await pumpCalendar(tester, logs: [compliantDay(3)]);

    verify(repository.findAll).called(1);
  });

  testWidgets('renders without overflowing a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpCalendar(tester);

    expect(tester.takeException(), isNull);
  });
}
