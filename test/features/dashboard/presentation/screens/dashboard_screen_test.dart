import 'dart:async';

import 'package:fantastic/features/adaptation/data/providers.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:fantastic/features/adaptation/presentation/widgets/phase_badge_widget.dart';
import 'package:fantastic/features/adaptation/domain/repositories/streak_repository.dart';
import 'package:fantastic/features/dashboard/application/providers/daily_log_providers.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:fantastic/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:fantastic/features/dashboard/presentation/widgets/electrolytes_card.dart';
import 'package:fantastic/features/dashboard/presentation/widgets/macro_summary_card.dart';
import 'package:fantastic/features/diary/application/meal_logging_service.dart';
import 'package:fantastic/features/diary/application/providers/meal_providers.dart';
import 'package:fantastic/features/diary/application/providers/symptom_providers.dart';
import 'package:fantastic/features/diary/domain/models/meal_entry.dart';
import 'package:fantastic/features/diary/domain/models/symptom_log.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_bottom_sheet.dart';
import 'package:fantastic/features/diary/presentation/widgets/meal_list_section.dart';
import 'package:fantastic/features/onboarding/application/providers/user_profile_providers.dart';
import 'package:fantastic/features/onboarding/domain/models/macro_targets.dart';
import 'package:fantastic/features/diary/presentation/widgets/symptom_check_in_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../fixtures/fixtures.dart';

class _MockMealLoggingService extends Mock implements MealLoggingService {}

class _MockStreakRepository extends Mock implements StreakRepository {}

void main() {
  /// Today at midnight — the same value the screen derives internally.
  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  late _MockMealLoggingService loggingService;
  late _MockStreakRepository streakRepository;

  setUp(() {
    loggingService = _MockMealLoggingService();
    // #63 put StreakRingWidget on the dashboard, so the screen now reaches
    // StreakRepository. Without the override it resolves databaseProvider and
    // tries to open a real store.
    streakRepository = _MockStreakRepository();
    when(streakRepository.watch).thenAnswer((_) => Stream.value(null));
  });

  /// Makes the streak resolve to [streak] for the next pump.
  void streakIs(StreakState? streak) =>
      when(streakRepository.watch).thenAnswer((_) => Stream.value(streak));

  /// The screen is a `Scaffold` in its own right, so it is pumped directly
  /// rather than through `pumpApp`'s wrapper, which would nest two.
  Future<void> pumpDashboard(
    WidgetTester tester, {
    DailyLog? log,
    List<MealEntry> meals = const [],
    SymptomLog? symptoms,
  }) async {
    final date = today();
    final overrides = <Override>[
      todaysDailyLogProvider(date).overrideWith((ref) async => log),
      todaysMealsProvider(date).overrideWith((ref) async => meals),
      mealLoggingServiceProvider.overrideWithValue(loggingService),
      streakRepositoryProvider.overrideWithValue(streakRepository),
      // MacroSummaryCard measures the day against the onboarding profile's
      // targets (#73); without an override it reaches for a database.
      macroTargetsProvider.overrideWith(
        (ref) => Stream.value(MacroTargets.defaults),
      ),
      // #76 put SymptomCheckInStrip on the dashboard, so the screen now
      // reads the day's symptom log too.
      symptomLogProvider(date).overrideWith((ref) async => symptoms),
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

  /// Scrolls until the electrolytes card — the last row — is built.
  ///
  /// #76's symptom strip pushed it past the fold of the default 800x600 test
  /// window. A sliver child below the fold has no element at all, so
  /// `find.byType` cannot see it and `skipOffstage: false` does not help.
  Future<void> revealElectrolytes(WidgetTester tester) =>
      tester.scrollUntilVisible(
        find.byType(ElectrolytesCard),
        200,
        scrollable: find.byType(Scrollable).first,
      );

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

    testWidgets('hosts all four sections', (tester) async {
      await pumpDashboard(tester, log: DailyLogFixture.fixture(date: today()));

      expect(find.byType(MacroSummaryCard), findsOneWidget);
      expect(find.byType(MealListSection), findsOneWidget);
      expect(find.byType(SymptomCheckInStrip), findsOneWidget);

      await revealElectrolytes(tester);
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

    // The affordance must not depend on the data around it. A dashboard whose
    // reads have failed is exactly when a user most needs to be able to log
    // something, and riverpod 3 keeps a failed provider retrying — so a FAB
    // built inside an `AsyncValue` branch would come and go with the backoff.
    testWidgets('is present when every read has failed', (tester) async {
      final date = today();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todaysDailyLogProvider(date)
                .overrideWith((ref) async => throw Exception('disk gone')),
            todaysMealsProvider(date)
                .overrideWith((ref) async => throw Exception('disk gone')),
            symptomLogProvider(date)
                .overrideWith((ref) async => throw Exception('disk gone')),
            macroTargetsProvider.overrideWith(
              (ref) => Stream<MacroTargets>.error(Exception('disk gone')),
            ),
            mealLoggingServiceProvider.overrideWithValue(loggingService),
            streakRepositoryProvider.overrideWithValue(streakRepository),
          ],
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: DashboardScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('add_meal_fab')), findsOneWidget);
    });

    testWidgets('is present while every read is still in flight', (
      tester,
    ) async {
      final date = today();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todaysDailyLogProvider(date)
                .overrideWith((ref) => Completer<DailyLog?>().future),
            todaysMealsProvider(date)
                .overrideWith((ref) => Completer<List<MealEntry>>().future),
            symptomLogProvider(date)
                .overrideWith((ref) => Completer<SymptomLog?>().future),
            macroTargetsProvider.overrideWith(
              (ref) => const Stream<MacroTargets>.empty(),
            ),
            mealLoggingServiceProvider.overrideWithValue(loggingService),
            streakRepositoryProvider.overrideWithValue(streakRepository),
          ],
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: DashboardScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('add_meal_fab')), findsOneWidget);
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
      final symptoms = tester.widget<SymptomCheckInStrip>(
        find.byType(SymptomCheckInStrip),
      );

      await revealElectrolytes(tester);
      final electrolytes = tester.widget<ElectrolytesCard>(
        find.byType(ElectrolytesCard),
      );

      expect(macro.date, meals.date);
      expect(meals.date, electrolytes.date);
      expect(electrolytes.date, symptoms.date);
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

    // Scrolled to the end first: since #63 added the streak ring the page is
    // taller than the test viewport, and a sliver does not build children it
    // has not laid out. Asserting without scrolling would fail because the
    // spacer is off-screen, not because it is missing.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

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

  // #64 completed the dashboard's adaptation row and closed the last gap
  // m2_handoff.md recorded.
  group('adaptation', () {
    testWidgets('shows the phase badge', (tester) async {
      await pumpDashboard(tester, log: DailyLogFixture.fixture(date: today()));

      expect(find.byType(PhaseBadgeWidget), findsOneWidget);
    });

    // M2 shipped ElectrolytesCard with `phase` defaulting to induction and a
    // comment saying M3 would pass the real value. This is that assertion:
    // the targets now follow the user's actual phase, so a fat-adapted user
    // stops being held to induction's higher sodium figure.
    testWidgets('passes the live phase to the electrolytes card', (
      tester,
    ) async {
      streakIs(StreakStateFixture.withStreak(12));

      await pumpDashboard(tester, log: DailyLogFixture.fixture(date: today()));
      await revealElectrolytes(tester);

      expect(
        tester.widget<ElectrolytesCard>(find.byType(ElectrolytesCard)).phase,
        AdaptationPhase.fatAdapted,
      );
    });

    // Induction is the safe default: highest targets, so it over-warns
    // rather than under-warns while the real phase is unknown.
    testWidgets('falls back to induction before the phase resolves', (
      tester,
    ) async {
      await pumpDashboard(tester, log: DailyLogFixture.fixture(date: today()));
      await revealElectrolytes(tester);

      expect(
        tester.widget<ElectrolytesCard>(find.byType(ElectrolytesCard)).phase,
        AdaptationPhase.induction,
      );
    });
  });
}
