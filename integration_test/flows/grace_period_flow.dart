import 'package:fantastic/features/adaptation/application/adaptation_phase_service.dart';
import 'package:fantastic/features/adaptation/data/providers.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:fantastic/features/adaptation/presentation/widgets/grace_period_banner.dart'
    show GracePeriodBanner, GracePeriodBannerText;
import 'package:fantastic/features/adaptation/presentation/widgets/streak_ring_widget.dart';
import 'package:fantastic/features/dashboard/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/fixtures/fixtures.dart';
import '../helpers/app_harness.dart';

/// F8 (#98) — breach → grace window → expiry → reset.
///
/// The 24-hour grace window is the promise the whole adaptation feature is
/// built around and no flow had ever driven it. Two of the unit-level traps
/// `design/m3_handoff.md` records live on this path, and both are of the kind
/// that makes a test pass while exercising the opposite case.
///
/// **No clock is injected and none should be.** `gracePeriodEnd` is a
/// persisted `DateTime`, so an expired window is a seeded timestamp in the
/// past and an open one a timestamp in the future — one `save`, no production
/// seam added to serve a test.
void main() {
  /// Midnight today, the day the app itself reasons in.
  DateTime midnightToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Midnight [n] days before today.
  ///
  /// Built by subtracting from the day-of-month rather than with a
  /// `Duration`, which is a fixed 24 hours and lands on the wrong day across
  /// a daylight-saving change — the same reason `StreakCalculator._dayBefore`
  /// does it this way.
  DateTime daysBefore(int n) {
    final today = midnightToday();
    return DateTime(today.year, today.month, today.day - n);
  }

  /// Writes [days] compliant days ending at [endingDaysBefore].
  ///
  /// **Seeding a `StreakState` alone is not enough and fails silently.** The
  /// streak is *derived* from `DailyLog` history on every write (#303), so a
  /// seeded `currentStreak: 5` with no logs behind it re-derives to 0 on the
  /// next meal — and a reset assertion would then pass for entirely the wrong
  /// reason.
  ///
  /// Macros vary per day rather than repeating one value: a fixture whose
  /// fields all share a value hides a crossed field (`CLAUDE.md` §Testing).
  Future<void> seedCompliantDays(
    AppUnderTest app, {
    required int days,
    required int endingDaysBefore,
  }) async {
    final logs = app.container.read(dailyLogRepositoryProvider);
    for (var i = 0; i < days; i++) {
      final back = endingDaysBefore + i;
      await logs.save(
        DailyLogFixture.fixture(
          date: daysBefore(back),
          // Comfortably inside KetoConstants.maxCompliantNetCarbsG (50).
          totalNetCarbsG: 4 + i.toDouble(),
          totalFatG: 60 + i.toDouble(),
          totalProteinG: 40 + i.toDouble(),
        ),
      );
    }
  }

  /// Writes a day whose net carbs are over the limit.
  Future<void> seedBreachedDay(AppUnderTest app, {required int daysAgo}) async {
    await app.container
        .read(dailyLogRepositoryProvider)
        .save(
          DailyLogFixture.fixture(
            date: daysBefore(daysAgo),
            totalNetCarbsG: 92,
            totalFatG: 30,
            totalProteinG: 25,
          ),
        );
  }

  Future<void> logMeal(
    WidgetTester tester, {
    required String name,
    required String fat,
    required String carbs,
    required String protein,
  }) async {
    await tapAt(tester, find.byKey(const Key('add_meal_fab')));
    await enterInto(tester, 'meal_name_field', name);
    await enterInto(tester, 'fat_field', fat);
    await enterInto(tester, 'carbs_field', carbs);
    await enterInto(tester, 'protein_field', protein);
    await tapAt(tester, find.byKey(const Key('save_meal_button')));
  }

  Future<StreakState> storedStreak(AppUnderTest app) async {
    final state = await app.container.read(streakRepositoryProvider).load();
    return state!;
  }

  /// The number painted inside the ring.
  ///
  /// Scoped to [StreakRingWidget], never a bare `find.text`: a dashboard full
  /// of macro figures has plenty of other `0`s and `1`s, which is what made
  /// #97's original `expect(find.text('0'), findsOneWidget)` unwritable.
  Finder ringShows(String value) => find.descendant(
    of: find.byType(StreakRingWidget),
    matching: find.text(value),
  );

  /// Whether the banner is painting anything.
  ///
  /// **`find.byType(GracePeriodBanner)` cannot answer this.** The banner
  /// returns `SizedBox.shrink()` when there is nothing to warn about, so it is
  /// in the tree either way and `findsOneWidget` on the type passes on a
  /// perfectly healthy streak. Asserting on the text it paints is the only
  /// honest question (`design/m5_handoff.md` — assert against what is
  /// painted).
  Finder bannerText() => find.descendant(
    of: find.byType(GracePeriodBanner),
    matching: find.textContaining('הרצף שלך בסכנה'),
  );

  /// Opens the adaptation tab, which is **the only screen that carries the
  /// banner**.
  ///
  /// Found by writing this flow: `GracePeriodBanner` is mounted once in the
  /// whole app, in `PhaseDetailScreen`. The dashboard — where the user lands,
  /// and where they log the meal that opens the window — never warns them
  /// their streak is at risk. Noted in the PR rather than fixed here; #98
  /// changes no `lib/` file.
  Future<void> openAdaptationTab(WidgetTester tester) =>
      goToTab(tester, 'tab_adaptation');

  Future<void> openHomeTab(WidgetTester tester) => goToTab(tester, 'tab_home');

  testWidgets('a day over the carb limit opens the grace window', (
    tester,
  ) async {
    final app = await bootApp(onboarded: true);
    await seedCompliantDays(app, days: 5, endingDaysBefore: 1);
    await app.container
        .read(streakRepositoryProvider)
        .save(
          StreakStateFixture.withStreak(5, lastCompliantDate: daysBefore(1)),
        );
    await pumpApp(tester, app);

    expect(ringShows('5'), findsOneWidget);
    await openAdaptationTab(tester);
    expect(bannerText(), findsNothing);
    await openHomeTab(tester);

    // 92 g of net carbs — well past the 50 g limit. The keto ratio these
    // macros imply is irrelevant now; #303 made net carbs the whole rule.
    await logMeal(tester, name: 'פיצה', fat: '20', carbs: '92', protein: '25');

    // The streak survives the breach — that is precisely what the window
    // buys. The derivation forgives today and keeps counting the five days
    // behind it.
    expect(ringShows('5'), findsOneWidget);

    await openAdaptationTab(tester);
    expect(bannerText(), findsOneWidget);

    final streak = await storedStreak(app);
    expect(streak.inGracePeriod, isTrue);
    expect(streak.currentStreak, 5);
    expect(streak.gracePeriodEnd, isNotNull);
    expect(
      streak.gracePeriodEnd!.difference(DateTime.now()),
      lessThanOrEqualTo(AdaptationPhaseService.gracePeriod),
    );
    expect(streak.gracePeriodEnd!.isAfter(DateTime.now()), isTrue);
  });

  testWidgets('an expired window drops the streak and returns to phase 1', (
    tester,
  ) async {
    final app = await bootApp(onboarded: true);

    // Ten compliant days, then a breach yesterday. Ten rather than five so
    // the phase has somewhere to fall *from*: at streak 5 the phase is
    // induction before and after, and the reset would be untestable.
    await seedCompliantDays(app, days: 10, endingDaysBefore: 2);
    await seedBreachedDay(app, daysAgo: 1);

    await app.container
        .read(streakRepositoryProvider)
        .save(
          StreakStateFixture.withStreak(
            10,
            phase: AdaptationPhase.fatAdapted,
            lastCompliantDate: daysBefore(2),
          ).copyWith(
            inGracePeriod: true,
            // Closed an hour ago. Explicit, and relative to now:
            // `StreakStateFixture.defaultGracePeriodEnd` is a fixed calendar
            // date, correct for a unit suite that controls its own instant
            // and meaningless here, where the app reads the real clock.
            gracePeriodEnd: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        );
    await pumpApp(tester, app);

    // **Before anything is written.** Reconciliation runs on write, not on
    // read, so the store still says `currentStreak: 10` with an open grace
    // flag — and until #308 the display repeated it: the ring showed a
    // ten-day streak the user had already lost, and the banner counted down
    // "פחות מדקה" to a reset that had happened an hour ago.
    //
    // Nothing here has written; only what is painted has changed.
    expect(ringShows('0'), findsOneWidget);
    await openAdaptationTab(tester);
    expect(bannerText(), findsNothing);
    expect(
      find.text(GracePeriodBannerText.expiredNotice),
      findsOneWidget,
      reason: 'the expired window was not reported on screen',
    );
    final beforeWrite = await storedStreak(app);
    expect(
      beforeWrite.currentStreak,
      10,
      reason: 'the display corrected itself by writing, which it must not do',
    );
    expect(beforeWrite.inGracePeriod, isTrue);
    await openHomeTab(tester);

    await logMeal(
      tester,
      name: 'סלט טונה',
      fat: '35',
      carbs: '6',
      protein: '30',
    );

    // **1, not 0, and this is the most surprising number in the flow.** The
    // meal that triggers reconciliation is itself a compliant day, so the
    // walk counts today and then stops dead at yesterday's breach — which the
    // expired window no longer forgives. The ten-day streak is gone; what is
    // left is today.
    //
    // A literal 0 would require the reconciling write to land on a day that
    // is not compliant, which is a different scenario from this one.
    expect(ringShows('1'), findsOneWidget);

    await openAdaptationTab(tester);
    expect(bannerText(), findsNothing);

    final streak = await storedStreak(app);
    expect(streak.currentStreak, 1);
    expect(streak.phase, AdaptationPhase.induction);
    expect(streak.inGracePeriod, isFalse);
    expect(streak.gracePeriodEnd, isNull);

    // A derived streak may fall; a personal best that fell is a defect.
    // Nothing else tests monotonicity end to end.
    expect(streak.highestStreak, 10);
  });

  testWidgets('a compliant day inside an open window resumes the streak', (
    tester,
  ) async {
    final app = await bootApp(onboarded: true);
    await seedCompliantDays(app, days: 5, endingDaysBefore: 2);
    await seedBreachedDay(app, daysAgo: 1);

    // The window a breach at the **last instant of yesterday** would have
    // opened. Derived, not picked: `AdaptationPhaseService` recovers the one
    // forgiven day as `gracePeriodEnd - gracePeriod`, so a window pinned to a
    // wall-clock offset from now (`now + 12h`, say) forgives *today* whenever
    // the suite runs after midday and yesterday when it runs before — a test
    // that passes or fails on the hour it is run.
    //
    // Anchoring to midnight instead makes the forgiven day yesterday at every
    // hour, and the window stays open until the last microsecond of today.
    final breachedAt = midnightToday().subtract(
      const Duration(microseconds: 1),
    );
    await app.container
        .read(streakRepositoryProvider)
        .save(
          StreakStateFixture.withStreak(
            5,
            lastCompliantDate: daysBefore(2),
          ).copyWith(
            inGracePeriod: true,
            gracePeriodEnd: breachedAt.add(AdaptationPhaseService.gracePeriod),
          ),
        );
    await pumpApp(tester, app);

    await openAdaptationTab(tester);
    expect(bannerText(), findsOneWidget);
    await openHomeTab(tester);

    await logMeal(
      tester,
      name: 'ביצים בחמאה',
      fat: '40',
      carbs: '3',
      protein: '18',
    );

    // Six: today, plus the five days behind the breach the open window is
    // holding forgiven. This is the promise — a breach costs the day, not the
    // streak, as long as the user comes back inside 24 hours.
    expect(ringShows('6'), findsOneWidget);

    final streak = await storedStreak(app);
    expect(streak.currentStreak, 6);
    expect(streak.highestStreak, 6);
    expect(streak.phase, AdaptationPhase.induction);

    // **The window stays open, and the banner with it.** That is not an
    // oversight: the derivation re-runs on every write, and it only reaches 6
    // because `gracePeriodEnd` is still on the record forgiving yesterday.
    // Closing the window the moment the user recovered would silently drop
    // the streak back to 1 on their very next meal of the same day.
    //
    // What is arguably wrong is the *wording* — the banner says the streak is
    // in danger when it has just been secured for today. That is display, not
    // state, and it is #308's territory; this assertion is here so whoever
    // picks #308 up knows a flow is watching this exact behaviour and can see
    // at a glance which half they are changing.
    expect(streak.inGracePeriod, isTrue);
    await openAdaptationTab(tester);
    expect(bannerText(), findsOneWidget);
  });
}
