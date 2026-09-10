import 'dart:async';

import 'package:fantastic/core/constants/keto_constants.dart';
import 'package:fantastic/features/dashboard/application/providers/daily_log_providers.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:fantastic/features/dashboard/presentation/widgets/macro_summary_card.dart';
import 'package:fantastic/features/diary/presentation/widgets/empty_meals_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  final date = DailyLogFixture.defaultDate;

  Future<void> pumpCard(WidgetTester tester, {DailyLog? log}) => pumpApp(
    tester,
    MacroSummaryCard(date: date),
    overrides: [todaysDailyLogProvider(date).overrideWith((ref) async => log)],
  );

  /// Every bar in the card, in render order.
  List<LinearProgressIndicator> bars(WidgetTester tester) => tester
      .widgetList<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
      .toList();

  group('with a logged day', () {
    testWidgets('renders four progress bars', (tester) async {
      await pumpCard(tester, log: DailyLogFixture.fixture());
      await tester.pumpAndSettle();

      expect(bars(tester), hasLength(4));
    });

    testWidgets('labels all four macros in Hebrew', (tester) async {
      await pumpCard(tester, log: DailyLogFixture.fixture());
      await tester.pumpAndSettle();

      expect(find.text('שומן'), findsOneWidget);
      expect(find.text('פחמימות נטו'), findsOneWidget);
      expect(find.text('חלבון'), findsOneWidget);
      expect(find.text('יחס קטו'), findsOneWidget);
    });

    testWidgets('fills each bar to logged over target', (tester) async {
      await pumpCard(
        tester,
        log: DailyLogFixture.fixture(
          totalFatG: KetoConstants.defaultFatTargetG / 2,
        ),
      );
      await tester.pumpAndSettle();

      expect(bars(tester).first.value, closeTo(0.5, 0.001));
    });

    testWidgets('shows the keto ratio of the day totals', (tester) async {
      // 100 / (5 + 20) = 4.0
      await pumpCard(
        tester,
        log: DailyLogFixture.fixture(
          totalFatG: 100,
          totalNetCarbsG: 5,
          totalProteinG: 20,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('4.0'), findsOneWidget);
    });

    testWidgets('shows logged and target figures for each bar', (tester) async {
      await pumpCard(tester, log: DailyLogFixture.fixture(totalFatG: 120));
      await tester.pumpAndSettle();

      expect(
        find.text(
          '120/${KetoConstants.defaultFatTargetG.toStringAsFixed(0)}ג׳',
        ),
        findsOneWidget,
      );
    });
  });

  group('edge cases', () {
    testWidgets('an all-zero day renders four empty bars, not a crash', (
      tester,
    ) async {
      await pumpCard(tester, log: DailyLogFixture.empty());
      await tester.pumpAndSettle();

      expect(bars(tester), hasLength(4));
      expect(bars(tester).every((b) => b.value == 0), isTrue);
      expect(tester.takeException(), isNull);
    });

    // A bar past 100% would paint outside its track.
    testWidgets('over-target clamps the bar to full', (tester) async {
      await pumpCard(
        tester,
        log: DailyLogFixture.fixture(
          totalFatG: KetoConstants.defaultFatTargetG * 3,
        ),
      );
      await tester.pumpAndSettle();

      expect(bars(tester).first.value, 1.0);
    });

    // Clamping the bar must not hide the real number.
    testWidgets('over-target still shows the true figure', (tester) async {
      await pumpCard(tester, log: DailyLogFixture.fixture(totalFatG: 450));
      await tester.pumpAndSettle();

      expect(find.textContaining('450/'), findsOneWidget);
    });

    testWidgets('a ratio above the ideal clamps its bar too', (tester) async {
      await pumpCard(
        tester,
        log: DailyLogFixture.fixture(
          totalFatG: 300,
          totalNetCarbsG: 5,
          totalProteinG: 5,
        ),
      );
      await tester.pumpAndSettle();

      expect(bars(tester).last.value, 1.0);
    });

    testWidgets('a zero-denominator day shows a ratio of 0, not NaN', (
      tester,
    ) async {
      await pumpCard(
        tester,
        log: DailyLogFixture.fixture(
          totalFatG: 50,
          totalNetCarbsG: 0,
          totalProteinG: 0,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('NaN'), findsNothing);
      expect(find.textContaining('Infinity'), findsNothing);
      expect(bars(tester).last.value, 0);
    });

    testWidgets('lays out without overflowing a narrow screen', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpCard(tester, log: DailyLogFixture.fixture());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('non-data states', () {
    testWidgets('a day with no log shows the empty state', (tester) async {
      await pumpCard(tester);
      await tester.pumpAndSettle();

      expect(find.byType(EmptyMealsState), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('shows a spinner while loading', (tester) async {
      await pumpApp(
        tester,
        MacroSummaryCard(date: date),
        overrides: [
          todaysDailyLogProvider(date).overrideWith((ref) async {
            // Never completes — holds the widget in its loading state.
            return Completer<DailyLog?>().future;
          }),
        ],
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // A failed read is not "no meals logged" — conflating them would tell the
    // user something false that they would then act on.
    testWidgets('a failed read says so rather than showing the empty state', (
      tester,
    ) async {
      await pumpApp(
        tester,
        MacroSummaryCard(date: date),
        overrides: [
          todaysDailyLogProvider(date)
              .overrideWith((ref) async => throw Exception('disk gone')),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('לא ניתן לטעון את הנתונים'), findsOneWidget);
      expect(find.byType(EmptyMealsState), findsNothing);
    });
  });
}
