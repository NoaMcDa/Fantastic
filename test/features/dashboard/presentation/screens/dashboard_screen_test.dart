import 'package:fantastic/features/dashboard/application/providers/daily_log_providers.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:fantastic/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:fantastic/features/dashboard/presentation/widgets/electrolytes_card.dart';
import 'package:fantastic/features/dashboard/presentation/widgets/macro_summary_card.dart';
import 'package:fantastic/features/diary/application/meal_logging_service.dart';
import 'package:fantastic/features/diary/application/providers/meal_providers.dart';
import 'package:fantastic/features/diary/domain/models/meal_entry.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_bottom_sheet.dart';
import 'package:fantastic/features/diary/presentation/widgets/meal_list_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../fixtures/fixtures.dart';

class _MockMealLoggingService extends Mock implements MealLoggingService {}

void main() {
  /// Today at midnight — the same value the screen derives internally.
  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  late _MockMealLoggingService loggingService;

  setUp(() => loggingService = _MockMealLoggingService());

  /// The screen is a `Scaffold` in its own right, so it is pumped directly
  /// rather than through `pumpApp`'s wrapper, which would nest two.
  Future<void> pumpDashboard(
    WidgetTester tester, {
    DailyLog? log,
    List<MealEntry> meals = const [],
  }) async {
    final date = today();
    final overrides = <Override>[
      todaysDailyLogProvider(date).overrideWith((ref) async => log),
      todaysMealsProvider(date).overrideWith((ref) async => meals),
      mealLoggingServiceProvider.overrideWithValue(loggingService),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: DashboardScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('scaffold', () {
    testWidgets('renders with a logged day', (tester) async {
      await pumpDashboard(tester, log: DailyLogFixture.fixture(date: today()));

      expect(tester.takeException(), isNull);
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('renders when the day has no log', (tester) async {
      await pumpDashboard(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('shows a date in the app bar', (tester) async {
      await pumpDashboard(tester);

      expect(find.byType(SliverAppBar), findsOneWidget);
      // The year is locale-independent, so this holds whether or not Hebrew
      // date symbols were initialised in this test binary.
      expect(find.textContaining('${today().year}'), findsOneWidget);
    });

    testWidgets('hosts all three sections', (tester) async {
      await pumpDashboard(tester, log: DailyLogFixture.fixture(date: today()));

      expect(find.byType(MacroSummaryCard), findsOneWidget);
      expect(find.byType(MealListSection), findsOneWidget);
      expect(find.byType(ElectrolytesCard), findsOneWidget);
    });
  });

  group('add-meal FAB', () {
    testWidgets('is present with its integration-test key', (tester) async {
      await pumpDashboard(tester);

      expect(find.byKey(const Key('add_meal_fab')), findsOneWidget);
    });

    testWidgets('opens the add-meal sheet', (tester) async {
      await pumpDashboard(tester);

      await tester.tap(find.byKey(const Key('add_meal_fab')));
      await tester.pumpAndSettle();

      expect(find.byType(AddMealBottomSheet), findsOneWidget);
    });

    testWidgets('the sheet targets today', (tester) async {
      await pumpDashboard(tester);

      await tester.tap(find.byKey(const Key('add_meal_fab')));
      await tester.pumpAndSettle();

      final sheet = tester.widget<AddMealBottomSheet>(
        find.byType(AddMealBottomSheet),
      );
      expect(sheet.date, today());
    });
  });

  // The date-keyed providers are families keyed on the value passed in. A
  // fresh `DateTime.now()` each build would allocate a new provider every
  // frame and refetch forever, so the screen must hold one stripped date.
  group('date stability', () {
    testWidgets('passes the same date to every child', (tester) async {
      await pumpDashboard(tester, log: DailyLogFixture.fixture(date: today()));

      final macro = tester.widget<MacroSummaryCard>(
        find.byType(MacroSummaryCard),
      );
      final meals = tester.widget<MealListSection>(
        find.byType(MealListSection),
      );
      final electrolytes = tester.widget<ElectrolytesCard>(
        find.byType(ElectrolytesCard),
      );

      expect(macro.date, meals.date);
      expect(meals.date, electrolytes.date);
    });

    testWidgets('the date it passes down is stripped to midnight', (
      tester,
    ) async {
      await pumpDashboard(tester);

      final macro = tester.widget<MacroSummaryCard>(
        find.byType(MacroSummaryCard),
      );
      expect(macro.date.hour, 0);
      expect(macro.date.minute, 0);
      expect(macro.date.second, 0);
    });

    testWidgets('the date does not change across rebuilds', (tester) async {
      await pumpDashboard(tester);

      final first = tester
          .widget<MacroSummaryCard>(find.byType(MacroSummaryCard))
          .date;

      await tester.pump();
      await tester.pump();

      final second = tester
          .widget<MacroSummaryCard>(find.byType(MacroSummaryCard))
          .date;
      expect(second, first);
    });
  });

  testWidgets('leaves room below the last section for the FAB', (tester) async {
    await pumpDashboard(tester, log: DailyLogFixture.fixture(date: today()));

    // Without the spacer the FAB sits over the electrolytes card.
    final spacers = tester.widgetList<SizedBox>(find.byType(SizedBox));
    expect(spacers.any((s) => s.height == 80), isTrue);
  });

  testWidgets('lays out without overflowing a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpDashboard(tester, log: DailyLogFixture.fixture(date: today()));

    expect(tester.takeException(), isNull);
  });
}
