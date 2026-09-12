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
import 'package:fantastic/features/onboarding/domain/models/user_profile.dart';
import 'package:fantastic/features/diary/presentation/widgets/symptom_check_in_strip.dart';
import 'package:fantastic/features/adaptation/presentation/widgets/grace_period_banner.dart';
import 'package:flutter/material.dart';
import 'package:fantastic/features/dashboard/data/providers.dart';
import 'package:fantastic/features/dashboard/domain/repositories/daily_log_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

class _MockMealLoggingService extends Mock implements MealLoggingService {}

class _MockStreakRepository extends Mock implements StreakRepository {}

/// #303 gave `adaptationPhaseServiceProvider` a second dependency, so a
/// container that overrides only the streak repository now reaches
/// `databaseProvider` and tries to open a real database.
class _MockDailyLogRepository extends Mock implements DailyLogRepository {}

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
      dailyLogRepositoryProvider.overrideWithValue(_MockDailyLogRepository()),
      // MacroSummaryCard measures the day against the onboarding profile
      // (#73), and against the day's own training flag on top of it (#431);
      // without an override it reaches for a database. Null is a user who has
      // not onboarded, whose targets are the defaults.
      onboardedProfileProvider.overrideWith((ref) => Stream.value(null)),
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
      // The `+` opens the mode chooser now (#322); manual entry is one
      // tile behind it. Asserted on this host separately from the other,
      // because a capability reachable from one screen and not the other
      // is the defect `design/user_bugs_handoff.md` records.
      await tester.tap(find.byKey(const Key('add_meal_mode_manual')));
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
            onboardedProfileProvider.overrideWith(
              (ref) => Stream<UserProfile?>.error(Exception('disk gone')),
            ),
            mealLoggingServiceProvider.overrideWithValue(loggingService),
            streakRepositoryProvider.overrideWithValue(streakRepository),
            dailyLogRepositoryProvider.overrideWithValue(
              _MockDailyLogRepository(),
            ),
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
            onboardedProfileProvider.overrideWith(
              (ref) => const Stream<UserProfile?>.empty(),
            ),
            mealLoggingServiceProvider.overrideWithValue(loggingService),
            streakRepositoryProvider.overrideWithValue(streakRepository),
            dailyLogRepositoryProvider.overrideWithValue(
              _MockDailyLogRepository(),
            ),
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
      // The `+` opens the mode chooser now (#322); manual entry is one
      // tile behind it. Asserted on this host separately from the other,
      // because a capability reachable from one screen and not the other
      // is the defect `design/user_bugs_handoff.md` records.
      await tester.tap(find.byKey(const Key('add_meal_mode_manual')));
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

  // #409: the symptom strip's own suite already pumps it at 320px and
  // passes (`symptom_check_in_strip_test.dart:472`) — it gives the strip
  // the whole viewport. `DashboardScreen` never does: `SliverPadding`'s
  // `EdgeInsets.all(16)`, the `Card`'s own margin and the strip's own
  // internal padding all come out of the width before the strip's header
  // `Row` ever sees it, so only pumping the *whole* screen — this
  // composition, not the strip alone — can catch what the strip's suite
  // cannot see.
  //
  // `pumpApp` (not this file's own `pumpDashboard`) is deliberate: with no
  // repository overrides, every read throws — there is no database in a
  // widget test — which puts the header `Row` in its widest state, the
  // failed-read message rendered next to the title. That is exactly the
  // state #409 was filed against, reproduced verbatim with Flutter
  // 3.47.3's own overflow diagnostic before the fix:
  //
  //   A RenderFlex overflowed by 82 pixels on the right.
  //   ...Row:.../symptom_check_in_strip.dart:53:22
  group('#409 regression — the strip does not overflow once composed', () {
    testWidgets('renders at 320px with no overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpApp(tester, const DashboardScreen());
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
    });

    // A fix that only satisfies 320px and breaks a wider layout is itself a
    // regression — #409's own Testing Requirements calls this out by name.
    // 360/390 are the next two common phone widths up from 320; 1024 is a
    // tablet.
    for (final width in [360.0, 390.0, 1024.0]) {
      testWidgets('renders at ${width.toInt()}px with no overflow', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pumpApp(tester, const DashboardScreen());
        await tester.pump(const Duration(seconds: 1));

        expect(tester.takeException(), isNull);
      });
    }
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

  // #345: the warning that the streak is in danger belongs on the screen
  // where the user logs the meal that endangers it. Until then
  // `GracePeriodBanner` was mounted once in the whole app, on the
  // adaptation tab, and the dashboard said nothing.
  group('the grace-period banner', () {
    testWidgets('is silent and takes no space on a healthy streak', (
      tester,
    ) async {
      when(streakRepository.watch)
          .thenAnswer((_) => Stream.value(StreakStateFixture.withStreak(5)));

      await pumpDashboard(tester);

      // `skipOffstage: false`: the banner is mounted and renders
      // `SizedBox.shrink()`, and a zero-extent sliver child reads as
      // offstage to the default finder — which is precisely the state being
      // asserted here.
      final banner = find.byType(GracePeriodBanner, skipOffstage: false);
      expect(banner, findsOneWidget);
      expect(find.textContaining('הרצף שלך בסכנה'), findsNothing);
      // The whole reason an unconditional placement is safe: on a healthy
      // streak it costs the dashboard nothing at all.
      expect(tester.getSize(banner).height, 0);
    });

    testWidgets('warns on the dashboard while a window is open', (
      tester,
    ) async {
      when(streakRepository.watch).thenAnswer(
        (_) => Stream.value(
          StreakStateFixture.inGracePeriod(
            gracePeriodEnd: DateTime.now().add(const Duration(hours: 6)),
          ),
        ),
      );

      await pumpDashboard(tester);

      expect(find.textContaining('הרצף שלך בסכנה'), findsOneWidget);
      expect(
        tester.getSize(find.byType(GracePeriodBanner)).height,
        greaterThan(0),
      );
    });

    // The banner is full-bleed rather than a child of the padded card list:
    // a full-width alert inset by 16pt reads as another card, and it is not
    // a card.
    testWidgets('spans the full width, outside the list padding', (
      tester,
    ) async {
      when(streakRepository.watch).thenAnswer(
        (_) => Stream.value(
          StreakStateFixture.inGracePeriod(
            gracePeriodEnd: DateTime.now().add(const Duration(hours: 6)),
          ),
        ),
      );

      await pumpDashboard(tester);

      expect(
        tester.getSize(find.byType(GracePeriodBanner)).width,
        tester.getSize(find.byType(Scaffold)).width,
      );
    });
  });
}
