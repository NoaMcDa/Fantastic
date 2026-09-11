import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/adaptation/data/providers.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:fantastic/features/adaptation/domain/repositories/streak_repository.dart';
import 'package:fantastic/features/adaptation/presentation/widgets/streak_ring_widget.dart';
import 'package:fantastic/features/dashboard/application/providers/daily_log_providers.dart';
import 'package:fantastic/features/dashboard/data/providers.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:fantastic/features/dashboard/domain/repositories/daily_log_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

class _MockStreakRepository extends Mock implements StreakRepository {}

class _MockDailyLogRepository extends Mock implements DailyLogRepository {}

void main() {
  final date = DailyLogFixture.defaultDate;
  late _MockStreakRepository streakRepository;
  late _MockDailyLogRepository dailyLogRepository;

  setUp(() {
    streakRepository = _MockStreakRepository();
    dailyLogRepository = _MockDailyLogRepository();
    when(streakRepository.watch).thenAnswer((_) => Stream.value(null));
    when(() => dailyLogRepository.findByDate(any())).thenAnswer((_) async {
      return null;
    });
  });

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  /// A day whose totals give exactly [ratio], with a non-zero denominator.
  ///
  /// Built from macros rather than by setting `ketoRatioAvg`, because the
  /// widget recomputes the ratio from the totals — writing the stored field
  /// would test nothing.
  DailyLog dayWithRatio(double ratio) => DailyLogFixture.fixture(
    totalFatG: ratio * 20,
    totalNetCarbsG: 5,
    totalProteinG: 15,
  );

  Future<void> pumpRing(
    WidgetTester tester, {
    StreakState? streak,
    DailyLog? log,
  }) async {
    when(streakRepository.watch).thenAnswer((_) => Stream.value(streak));
    when(() => dailyLogRepository.findByDate(any())).thenAnswer((_) async {
      return log;
    });

    await pumpApp(
      tester,
      StreakRingWidget(date: date),
      overrides: [
        streakRepositoryProvider.overrideWithValue(streakRepository),
        dailyLogRepositoryProvider.overrideWithValue(dailyLogRepository),
      ],
    );
    // Settles the providers and the fill animation.
    await tester.pumpAndSettle();
  }

  /// Every [StreakRingPainter] currently mounted.
  ///
  /// Filtered by type rather than by `find.byType(CustomPaint)`: Material
  /// paints scaffolds, ink and scrollbars through `CustomPaint` too, so a
  /// bare type finder matches widgets this test has no opinion about.
  Iterable<StreakRingPainter> painters(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((paint) => paint.painter)
      .whereType<StreakRingPainter>();

  StreakRingPainter painter(WidgetTester tester) => painters(tester).single;

  group('fill', () {
    // The two static rules are asserted directly as well as through a pumped
    // widget: the arc geometry is the one part of this widget a rendered
    // assertion cannot see.
    test('a ratio at the ideal fills the ring', () {
      expect(StreakRingPainter.fillFor(2), 1);
    });

    test('a ratio above the ideal does not overfill', () {
      expect(StreakRingPainter.fillFor(6), 1);
    });

    test('half the ideal is half a ring', () {
      expect(StreakRingPainter.fillFor(1), 0.5);
    });

    test('a zero ratio leaves the ring empty', () {
      expect(StreakRingPainter.fillFor(0), 0);
    });
  });

  group('colour', () {
    // Thresholds are KetoConstants (1.5 / 2.0), not the 1.0 / 2.0 the issue
    // names — see design/m3_preflight.md §2.5.
    test('at the ideal the arc is green', () {
      expect(StreakRingPainter.colourFor(2), AppTheme.success);
    });

    test('above the ideal the arc is still green', () {
      expect(StreakRingPainter.colourFor(4), AppTheme.success);
    });

    test('at the minimum the arc is amber', () {
      expect(StreakRingPainter.colourFor(1.5), AppTheme.caution);
    });

    test('just under the ideal the arc is amber', () {
      expect(StreakRingPainter.colourFor(1.99), AppTheme.caution);
    });

    test('below the minimum the arc is red', () {
      expect(StreakRingPainter.colourFor(1.49), AppTheme.danger);
    });

    test('a zero ratio is red', () {
      expect(StreakRingPainter.colourFor(0), AppTheme.danger);
    });
  });

  group('rendering', () {
    testWidgets('shows the streak day count', (tester) async {
      await pumpRing(tester, streak: StreakStateFixture.withStreak(12));

      expect(find.text('12'), findsOneWidget);
    });

    // First launch: a zero, not a blank and not a crash.
    testWidgets('shows zero when no streak has been recorded', (tester) async {
      await pumpRing(tester);

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('a one-day streak reads in the singular', (tester) async {
      await pumpRing(tester, streak: StreakStateFixture.withStreak(1));

      expect(find.text('יום'), findsOneWidget);
    });

    testWidgets('a longer streak reads in the plural', (tester) async {
      await pumpRing(tester, streak: StreakStateFixture.withStreak(4));

      expect(find.text('ימים'), findsOneWidget);
    });

    // A bare digit run inside an RTL layout renders reversed unless it is
    // given a direction of its own — '12' would show as '21'.
    testWidgets('the day count is laid out left-to-right', (tester) async {
      await pumpRing(tester, streak: StreakStateFixture.withStreak(12));

      expect(
        tester.widget<Text>(find.text('12')).textDirection,
        TextDirection.ltr,
      );
    });

    testWidgets('paints a full green arc for a compliant day', (tester) async {
      await pumpRing(
        tester,
        streak: StreakStateFixture.withStreak(3),
        log: dayWithRatio(2.5),
      );

      expect(painter(tester).fill, 1);
      expect(painter(tester).colour, AppTheme.success);
    });

    testWidgets('paints a part-filled amber arc mid-range', (tester) async {
      await pumpRing(
        tester,
        streak: StreakStateFixture.withStreak(3),
        log: dayWithRatio(1.5),
      );

      expect(painter(tester).fill, closeTo(0.75, 0.0001));
      expect(painter(tester).colour, AppTheme.caution);
    });

    // Nothing logged yet is a ratio of zero, which is red and empty — the
    // same as a genuinely bad day. That is intended: both mean "not in
    // ketosis on today's numbers".
    testWidgets('paints an empty red arc when nothing is logged', (
      tester,
    ) async {
      await pumpRing(tester, streak: StreakStateFixture.withStreak(3));

      expect(painter(tester).fill, 0);
      expect(painter(tester).colour, AppTheme.danger);
    });
  });

  group('loading and failure', () {
    // Both reserve the ring's space rather than collapsing, so the dashboard
    // below does not jump when the data lands.
    testWidgets('reserves its space while loading', (tester) async {
      when(streakRepository.watch).thenAnswer((_) => const Stream.empty());

      await pumpApp(
        tester,
        StreakRingWidget(date: date),
        overrides: [
          streakRepositoryProvider.overrideWithValue(streakRepository),
          dailyLogRepositoryProvider.overrideWithValue(dailyLogRepository),
        ],
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.getSize(find.byType(StreakRingWidget)).width,
        StreakRingWidget.diameter,
      );
    });

    // No error message of its own: MacroSummaryCard directly above already
    // reports a failed read, and two would say the same thing twice.
    testWidgets('renders an empty box of the same size on failure', (
      tester,
    ) async {
      when(streakRepository.watch)
          .thenAnswer((_) => Stream.error(Exception('store gone')));

      await pumpApp(
        tester,
        StreakRingWidget(date: date),
        overrides: [
          streakRepositoryProvider.overrideWithValue(streakRepository),
          dailyLogRepositoryProvider.overrideWithValue(dailyLogRepository),
        ],
      );
      await tester.pumpAndSettle();

      expect(painters(tester), isEmpty);
      // Asserted explicitly, because the loading branch also paints no ring
      // and reserves the same box: without this the test passes while the
      // widget shows a spinner that never stops. riverpod 3 reports a
      // never-resolved failure as AsyncLoading *with* an error, so both
      // branches are reachable from one state.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester.getSize(find.byType(StreakRingWidget)).width,
        StreakRingWidget.diameter,
      );
    });

    // A refresh is `isLoading` with the previous value still attached, and
    // every meal write produces one: `AddMealBottomSheet` invalidates
    // `todaysDailyLogProvider` as soon as the save returns. Checking
    // `isLoading` alone swapped the ring for a spinner on each save and then
    // replayed the sweep from zero.
    testWidgets('keeps the ring painted while it refreshes', (tester) async {
      await pumpRing(
        tester,
        streak: StreakStateFixture.withStreak(4),
        log: dayWithRatio(2),
      );

      ProviderScope.containerOf(
        tester.element(find.byType(StreakRingWidget)),
        listen: false,
      ).invalidate(todaysDailyLogProvider(date));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(painters(tester), isNotEmpty);
    });
  });
}
