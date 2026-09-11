import 'dart:async';

import 'package:fantastic/core/constants/keto_constants.dart';
import 'package:fantastic/features/dashboard/application/providers/daily_log_providers.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:fantastic/features/dashboard/presentation/widgets/macro_summary_card.dart';
import 'package:fantastic/features/diary/presentation/widgets/empty_meals_state.dart';
import 'package:fantastic/features/onboarding/application/providers/user_profile_providers.dart';
import 'package:fantastic/features/onboarding/domain/models/macro_targets.dart';
import 'package:flutter/material.dart';
import 'package:fantastic/features/dashboard/presentation/widgets/macro_summary_card_skeleton.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  final date = DailyLogFixture.defaultDate;

  Future<void> pumpCard(
    WidgetTester tester, {
    DailyLog? log,
    MacroTargets? targets,
  }) => pumpApp(
    tester,
    MacroSummaryCard(date: date),
    overrides: [
      todaysDailyLogProvider(date).overrideWith((ref) async => log),
      // The targets the card measures against come from the onboarding
      // profile now (#73). The defaults are what a user who has not onboarded
      // sees, and what this card hard-coded through M2 and M3.
      macroTargetsProvider.overrideWith(
        (ref) => Stream.value(targets ?? MacroTargets.defaults),
      ),
    ],
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
    // The user has just finished onboarding and agreed to these numbers. They
    // were invisible until the first meal was logged, which made Epic #8's
    // "dashboard macro targets match what onboarding set" observable only from
    // the second screen onwards (#301).
    testWidgets('a day with no log still shows the four targets', (
      tester,
    ) async {
      await pumpCard(tester);
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsNWidgets(4));
      // `MacroTargets.defaults` — 150 g fat / 20 g net carbs / 80 g protein.
      expect(find.textContaining('150'), findsOneWidget);
      expect(find.textContaining('20'), findsWidgets);
      expect(find.textContaining('80'), findsOneWidget);
    });

    testWidgets('a day with no log logs zero against every target', (
      tester,
    ) async {
      await pumpCard(tester);
      await tester.pumpAndSettle();

      for (final bar in tester.widgetList<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      )) {
        expect(bar.value, 0);
      }
    });

    // Both, not one: `EmptyMealsState`'s own doc comment is right that zeroed
    // bars read as "you are failing every target", so the message has to stay
    // and disambiguate them rather than hide the numbers.
    testWidgets('a day with no log still says nothing was logged', (
      tester,
    ) async {
      await pumpCard(tester);
      await tester.pumpAndSettle();

      expect(find.text(EmptyMealsState.headline), findsOneWidget);
    });

    testWidgets('an empty day renders a ratio of 0 without throwing', (
      tester,
    ) async {
      await pumpCard(tester);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('0.0'), findsWidgets);
    });

    // A logged-then-emptied day is a different fact from an unlogged one: the
    // record exists, so the user did log something and then removed it.
    testWidgets('a stored all-zero day shows no nothing-logged message', (
      tester,
    ) async {
      await pumpCard(tester, log: DailyLogFixture.empty());
      await tester.pumpAndSettle();

      expect(find.text(EmptyMealsState.headline), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(4));
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
          macroTargetsProvider.overrideWith(
            (ref) => Stream.value(MacroTargets.defaults),
          ),
        ],
      );
      await tester.pump();

      expect(find.byType(MacroSummaryCardSkeleton), findsOneWidget);
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
          macroTargetsProvider.overrideWith(
            (ref) => Stream.value(MacroTargets.defaults),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('לא ניתן לטעון את הנתונים'), findsOneWidget);
      expect(find.byType(EmptyMealsState), findsNothing);
      // The loading branch has to be *absent*, not merely unasserted:
      // riverpod 3 reports a provider that failed before its first value as
      // AsyncLoading with an error attached, so a card that checked
      // `isLoading` first would spin forever and this test would still pass
      // without the assertion (`design/m3_handoff.md`).
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(MacroSummaryCardSkeleton), findsNothing);
    });

    // Same trap on the other input. A card that only guarded the daily log
    // would spin here forever.
    testWidgets('a failed targets read says so rather than using defaults', (
      tester,
    ) async {
      await pumpApp(
        tester,
        MacroSummaryCard(date: date),
        overrides: [
          todaysDailyLogProvider(date)
              .overrideWith((ref) async => DailyLogFixture.fixture()),
          macroTargetsProvider.overrideWith(
            (ref) => Stream<MacroTargets>.error(Exception('disk gone')),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('לא ניתן לטעון את הנתונים'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(MacroSummaryCardSkeleton), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });

  // Epic #8: "Dashboard macro targets match the values set in onboarding."
  group('personalised targets', () {
    testWidgets('measures the day against the saved profile targets', (
      tester,
    ) async {
      await pumpCard(
        tester,
        log: DailyLogFixture.fixture(totalFatG: 100),
        targets: const MacroTargets(fatG: 200, netCarbsG: 25, proteinG: 90),
      );
      await tester.pumpAndSettle();

      expect(find.text('100/200ג׳'), findsOneWidget);
      expect(bars(tester).first.value, closeTo(0.5, 0.001));
    });

    testWidgets('every macro row follows the profile, not the constants', (
      tester,
    ) async {
      await pumpCard(
        tester,
        log: DailyLogFixture.fixture(),
        targets: const MacroTargets(fatG: 200, netCarbsG: 25, proteinG: 90),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('/200ג׳'), findsOneWidget);
      expect(find.textContaining('/25ג׳'), findsOneWidget);
      expect(find.textContaining('/90ג׳'), findsOneWidget);
      expect(
        find.textContaining(
          '/${KetoConstants.defaultFatTargetG.toStringAsFixed(0)}ג׳',
        ),
        findsNothing,
      );
    });
  });
}
