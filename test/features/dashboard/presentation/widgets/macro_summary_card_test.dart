import 'dart:async';

import 'package:fantastic/core/constants/dashboard_copy.dart';
import 'package:fantastic/core/constants/keto_constants.dart';
import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/core/theme/keto_ratio_palette.dart';
import 'package:fantastic/features/adaptation/presentation/widgets/streak_ring_widget.dart';
import 'package:fantastic/features/dashboard/application/daily_targets_service.dart';
import 'package:fantastic/features/dashboard/application/providers/daily_log_providers.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:fantastic/features/dashboard/presentation/widgets/macro_summary_card.dart';
import 'package:fantastic/features/diary/presentation/widgets/empty_meals_state.dart';
import 'package:fantastic/features/onboarding/application/providers/user_profile_providers.dart';
import 'package:fantastic/features/onboarding/domain/models/macro_targets.dart';
import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/onboarding/domain/models/activity_level.dart';
import 'package:fantastic/features/onboarding/domain/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:fantastic/features/dashboard/presentation/widgets/macro_summary_card_skeleton.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
      // The profile is overridden rather than `dailyTargetsProvider` itself,
      // so these tests still run the real composition the card depends on:
      // profile + day's log → the day's targets. A null profile is a user who
      // has not onboarded, whose targets are the defaults this card
      // hard-coded through M2 and M3 (#73).
      onboardedProfileProvider.overrideWith(
        (ref) => Stream.value(
          targets == null ? null : UserProfileFixture.profile(targets: targets),
        ),
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
          onboardedProfileProvider.overrideWith((ref) => Stream.value(null)),
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
          onboardedProfileProvider.overrideWith((ref) => Stream.value(null)),
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
          onboardedProfileProvider.overrideWith(
            (ref) => Stream<UserProfile?>.error(Exception('disk gone')),
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

  group('the ratio bar is a verdict', () {
    /// A day whose totals give exactly [ratio], with a non-zero denominator.
    ///
    /// Built from macros rather than by setting `ketoRatioAvg`, because the
    /// card recomputes the ratio from the totals.
    DailyLog dayWithRatio(double ratio) => DailyLogFixture.fixture(
      totalFatG: ratio * 20,
      totalNetCarbsG: 5,
      totalProteinG: 15,
    );

    /// The ratio row's bar — the fourth and last.
    LinearProgressIndicator ratioBar(WidgetTester tester) => bars(tester).last;

    testWidgets('green when the ratio meets the target', (tester) async {
      await pumpCard(tester, log: dayWithRatio(2.6));
      await tester.pumpAndSettle();

      expect(ratioBar(tester).color, AppTheme.success);
    });

    testWidgets('amber when the ratio is approaching the target', (
      tester,
    ) async {
      await pumpCard(tester, log: dayWithRatio(1.7));
      await tester.pumpAndSettle();

      expect(ratioBar(tester).color, AppTheme.caution);
    });

    testWidgets('red when the ratio is below the minimum', (tester) async {
      await pumpCard(tester, log: dayWithRatio(0.9));
      await tester.pumpAndSettle();

      expect(ratioBar(tester).color, AppTheme.danger);
    });

    // **The test this issue exists for.** A per-widget assertion would pass
    // while the two still disagreed — which is exactly what happened: the
    // ring had band colours from M3 and the bar had a fixed gold, and every
    // test of each one passed.
    //
    // The two widgets are pumped separately and read against each other, at
    // a ratio in each band.
    //
    // One test per ratio rather than a loop: a second `pumpWidget` of the
    // same widget updates the tree instead of replacing it, so the card kept
    // the previous ratio's colour and the loop compared the wrong pair.
    for (final ratio in [2.6, 1.7, 0.9]) {
      testWidgets('the ratio bar and the streak ring agree at $ratio', (
        tester,
      ) async {
        await pumpCard(tester, log: dayWithRatio(ratio));
        await tester.pumpAndSettle();

        expect(
          ratioBar(tester).color,
          StreakRingPainter.colourFor(ratio),
          reason: 'ring and bar disagree at ratio $ratio',
        );
      });
    }

    testWidgets('the ratio row carries a band icon', (tester) async {
      await pumpCard(tester, log: dayWithRatio(2.6));
      await tester.pumpAndSettle();

      // Colour is never the only signal.
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(
        tester
            .widget<Icon>(find.byIcon(Icons.check_circle_outline))
            .semanticLabel,
        KetoRatioPalette.labelFor(2.6),
      );
    });

    testWidgets('the icon changes with the band', (tester) async {
      await pumpCard(tester, log: dayWithRatio(0.9));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    });

    // The three macro rows keep their fixed hues: those identify fat from
    // carbs from protein, and are not a judgement about progress.
    testWidgets('the fat, carb and protein bars keep their own colours '
        'regardless of progress', (tester) async {
      final scheme = AppTheme.dark.colorScheme;

      await pumpCard(tester, log: dayWithRatio(2.6));
      await tester.pumpAndSettle();

      final rows = bars(tester);
      expect(rows[0].color, scheme.tertiary, reason: 'fat');
      expect(rows[1].color, scheme.error, reason: 'net carbs');
      expect(rows[2].color, scheme.secondary, reason: 'protein');
      // And none of them picked up a band icon: the ratio row's is the only
      // one in the card.
      expect(find.byType(Icon), findsOneWidget);
    });

    // A ratio of 0.0 on an unlogged day is not a bad day — it is no day yet.
    // A red bar on someone's first morning, under a headline saying nothing
    // has been logged, is a verdict on something that has not happened. The
    // issue left this open; this is the answer.
    testWidgets('an unlogged day is neutral, not red', (tester) async {
      await pumpCard(tester);
      await tester.pumpAndSettle();

      expect(
        ratioBar(tester).color,
        AppTheme.dark.colorScheme.onSurfaceVariant,
      );
      expect(ratioBar(tester).color, isNot(AppTheme.danger));
      // And no verdict icon either.
      expect(find.byType(Icon), findsNothing);
    });

    // A *stored* all-zero day is a different fact: the record exists, so the
    // user logged something and emptied it, and a verdict is earned.
    testWidgets('a stored all-zero day is judged, not excused', (tester) async {
      await pumpCard(tester, log: DailyLogFixture.empty(date: date));
      await tester.pumpAndSettle();

      expect(ratioBar(tester).color, AppTheme.danger);
    });
  });

  // #431's second bullet, at the point the user touches it. The chip lives in
  // this card because the target it moves is the bar directly below it.
  group('the training-day chip', () {
    late _MockDailyTargetsService targetsService;

    /// Today, because the chip is deliberately today-only: this card is also
    /// the diary's day view, and a past day's targets are what they were.
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    setUpAll(() => registerFallbackValue(DateTime(2026)));

    setUp(() {
      targetsService = _MockDailyTargetsService();
      when(
        () => targetsService.setTrainingDay(
          any(),
          trained: any(named: 'trained'),
        ),
      ).thenAnswer((_) async {});
    });

    Future<void> pumpToday(
      WidgetTester tester, {
      required UserProfile? profile,
      DailyLog? log,
      DateTime? date,
    }) => pumpApp(
      tester,
      MacroSummaryCard(date: date ?? today),
      overrides: [
        todaysDailyLogProvider(date ?? today).overrideWith((ref) async => log),
        onboardedProfileProvider.overrideWith((ref) => Stream.value(profile)),
        dailyTargetsServiceProvider.overrideWithValue(targetsService),
      ],
    );

    testWidgets('renders for a profile with biometrics', (tester) async {
      await pumpToday(
        tester,
        profile: UserProfileFixture.profile(),
        log: DailyLogFixture.fixture(date: today),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('training_day_chip')), findsOneWidget);
      expect(find.text(DashboardCopy.trainingDay), findsOneWidget);
    });

    testWidgets('is selected on a day already marked', (tester) async {
      await pumpToday(
        tester,
        profile: UserProfileFixture.profile(),
        log: DailyLogFixture.fixture(date: today).copyWith(trainingDay: true),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FilterChip>(find.byKey(const Key('training_day_chip')))
            .selected,
        isTrue,
      );
    });

    testWidgets('tapping it marks the day', (tester) async {
      await pumpToday(
        tester,
        profile: UserProfileFixture.profile(),
        log: DailyLogFixture.fixture(date: today),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('training_day_chip')));
      await tester.pumpAndSettle();

      verify(() => targetsService.setTrainingDay(today, trained: true))
          .called(1);
    });

    testWidgets('tapping a marked day unmarks it', (tester) async {
      await pumpToday(
        tester,
        profile: UserProfileFixture.profile(),
        log: DailyLogFixture.fixture(date: today).copyWith(trainingDay: true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('training_day_chip')));
      await tester.pumpAndSettle();

      verify(() => targetsService.setTrainingDay(today, trained: false))
          .called(1);
    });

    // A tap that did nothing and said nothing is the worst outcome: the user
    // re-taps, and the chip keeps snapping back for no stated reason.
    testWidgets('a failed write says so and leaves the chip alone', (
      tester,
    ) async {
      when(
        () => targetsService.setTrainingDay(
          any(),
          trained: any(named: 'trained'),
        ),
      ).thenThrow(
        const PersistenceException('DailyLogRepository.save', 'closed'),
      );
      await pumpToday(
        tester,
        profile: UserProfileFixture.profile(),
        log: DailyLogFixture.fixture(date: today),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('training_day_chip')));
      await tester.pumpAndSettle();

      expect(find.text(DashboardCopy.trainingDaySaveFailed), findsOneWidget);
      expect(
        tester
            .widget<FilterChip>(find.byKey(const Key('training_day_chip')))
            .selected,
        isFalse,
      );
    });

    // A skipped flow (#262) leaves no BMR, so the chip would move no number.
    testWidgets('is hidden for a profile with no biometrics', (tester) async {
      await pumpToday(
        tester,
        profile: UserProfile.skipped(),
        log: DailyLogFixture.fixture(date: today),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('training_day_chip')), findsNothing);
    });

    testWidgets('is hidden when nobody has onboarded', (tester) async {
      await pumpToday(
        tester,
        profile: null,
        log: DailyLogFixture.fixture(date: today),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('training_day_chip')), findsNothing);
    });

    testWidgets('is hidden on a past day', (tester) async {
      final past = DateTime(2026, 1, 1);
      await pumpToday(
        tester,
        profile: UserProfileFixture.profile(),
        log: DailyLogFixture.fixture(date: past),
        date: past,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('training_day_chip')), findsNothing);
    });

    // The card is the one place the raised target becomes visible.
    testWidgets('a marked day shows the raised fat target', (tester) async {
      final profile = UserProfileFixture.profile(
        activityLevel: ActivityLevel.moderate,
      );
      final marked = DailyLogFixture.fixture(date: today)
          .copyWith(trainingDay: true);

      await pumpToday(tester, profile: profile, log: marked);
      await tester.pumpAndSettle();

      final raised = DailyTargetsService.forDay(profile: profile, log: marked);
      expect(raised.fatG, greaterThan(profile.targets.fatG));
      expect(
        find.textContaining('/${raised.fatG.toStringAsFixed(0)}ג׳'),
        findsOneWidget,
      );
    });
  });
}

class _MockDailyTargetsService extends Mock implements DailyTargetsService {}
