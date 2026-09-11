import 'package:fantastic/features/dashboard/application/providers/daily_log_providers.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:fantastic/features/dashboard/presentation/widgets/macro_summary_card.dart';
import 'package:fantastic/features/diary/application/meal_logging_service.dart';
import 'package:fantastic/features/diary/application/providers/meal_providers.dart';
import 'package:fantastic/features/diary/domain/models/meal_entry.dart';
import 'package:fantastic/features/diary/presentation/screens/diary_day_screen.dart';
import 'package:fantastic/features/diary/presentation/widgets/empty_meals_state.dart';
import 'package:fantastic/features/diary/presentation/widgets/meal_card.dart';
import 'package:fantastic/features/diary/presentation/widgets/meal_list_section.dart';
import 'package:fantastic/features/onboarding/application/providers/user_profile_providers.dart';
import 'package:fantastic/features/onboarding/domain/models/macro_targets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

class _MockMealLoggingService extends Mock implements MealLoggingService {}

void main() {
  final pastDate = DateTime(2026, 9, 7);
  late _MockMealLoggingService loggingService;

  setUp(() => loggingService = _MockMealLoggingService());

  Future<void> pumpDay(
    WidgetTester tester, {
    required DateTime date,
    DailyLog? log,
    List<MealEntry> meals = const [],
  }) => pumpApp(
    tester,
    DiaryDayScreen(date: date),
    overrides: [
      todaysDailyLogProvider(date).overrideWith((ref) async => log),
      todaysMealsProvider(date).overrideWith((ref) async => meals),
      mealLoggingServiceProvider.overrideWithValue(loggingService),
      // MacroSummaryCard measures the day against the onboarding profile's
      // targets (#73); without an override it reaches for a database.
      macroTargetsProvider.overrideWith(
        (ref) => Stream.value(MacroTargets.defaults),
      ),
    ],
  );

  testWidgets('renders the summary, the meal list and the symptom slot', (
    tester,
  ) async {
    await pumpDay(
      tester,
      date: pastDate,
      log: DailyLogFixture.fixture(date: pastDate),
      meals: [MealEntryFixture.fixture(id: 1, timestamp: pastDate)],
    );
    await tester.pumpAndSettle();

    expect(find.byType(MacroSummaryCard), findsOneWidget);
    expect(find.byType(MealListSection), findsOneWidget);
    expect(find.text('תסמינים — בקרוב'), findsOneWidget);
  });

  testWidgets('a past day with no entries shows the empty state', (
    tester,
  ) async {
    await pumpDay(tester, date: pastDate);
    await tester.pumpAndSettle();

    expect(find.byType(EmptyMealsState), findsOneWidget);
    expect(find.byType(MealCard), findsNothing);
  });

  // The whole point of the date parameter: this screen serves any day, and
  // must read the day it was given rather than today.
  testWidgets('reads the date it was given, not today', (tester) async {
    await pumpDay(
      tester,
      date: pastDate,
      log: DailyLogFixture.fixture(date: pastDate),
      meals: [
        MealEntryFixture.fixture(
          id: 1,
          mealName: 'ארוחה ישנה',
          timestamp: pastDate,
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('ארוחה ישנה'), findsOneWidget);
  });

  testWidgets('passes one date down to both children', (tester) async {
    await pumpDay(
      tester,
      date: pastDate,
      log: DailyLogFixture.fixture(date: pastDate),
    );
    await tester.pumpAndSettle();

    final macro = tester.widget<MacroSummaryCard>(
      find.byType(MacroSummaryCard),
    );
    final meals = tester.widget<MealListSection>(find.byType(MealListSection));

    expect(macro.date, pastDate);
    expect(meals.date, pastDate);
  });

  testWidgets('renders the day meals', (tester) async {
    await pumpDay(
      tester,
      date: pastDate,
      log: DailyLogFixture.fixture(date: pastDate),
      meals: [
        MealEntryFixture.fixture(id: 1, timestamp: pastDate),
        MealEntryFixture.fixture(id: 2, timestamp: pastDate),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byType(MealCard), findsNWidgets(2));
  });

  testWidgets('scrolls rather than overflowing when the day is full', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpDay(
      tester,
      date: pastDate,
      log: DailyLogFixture.fixture(date: pastDate),
      meals: [
        for (var i = 1; i <= 8; i++)
          MealEntryFixture.fixture(id: i, timestamp: pastDate),
      ],
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
