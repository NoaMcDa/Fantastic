import 'package:fantastic/features/adaptation/data/providers.dart';
import 'package:fantastic/features/dashboard/data/providers.dart';
import 'package:fantastic/features/dashboard/domain/repositories/daily_log_repository.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:fantastic/features/adaptation/domain/repositories/streak_repository.dart';
import 'package:fantastic/features/adaptation/presentation/widgets/grace_period_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

class _MockStreakRepository extends Mock implements StreakRepository {}

/// #303 gave `adaptationPhaseServiceProvider` a second dependency, so a
/// container that overrides only the streak repository now reaches
/// `databaseProvider` and tries to open a real database.
class _MockDailyLogRepository extends Mock implements DailyLogRepository {}

void main() {
  late _MockStreakRepository repository;

  setUp(() {
    repository = _MockStreakRepository();
    when(repository.watch).thenAnswer((_) => Stream.value(null));
  });

  /// The instant every clock-seam test reasons from.
  ///
  /// Fixed, so a window placed relative to it cannot drift between the pump
  /// and the assertion — which is what `graceEndingIn`'s spare minute below
  /// exists to work around for the tests that still use the real clock.
  final now = DateTime(2026, 9, 11, 14, 30);

  Future<void> pumpBanner(
    WidgetTester tester, {
    StreakState? streak,
    DateTime? at,
  }) async {
    when(repository.watch).thenAnswer((_) => Stream.value(streak));
    await pumpApp(
      tester,
      GracePeriodBanner(clock: at == null ? DateTime.now : () => at),
      overrides: [
        streakRepositoryProvider.overrideWithValue(repository),
        dailyLogRepositoryProvider.overrideWithValue(_MockDailyLogRepository()),
      ],
    );
    await tester.pumpAndSettle();
  }

  /// A grace period ending [remaining] from now, plus a minute.
  ///
  /// The extra minute is not decoration. The widget computes
  /// `end.difference(DateTime.now())` at paint time, microseconds after this
  /// runs, so an exact six hours truncates to five and the assertion would
  /// chase its own clock.
  StreakState graceEndingIn(Duration remaining) =>
      StreakStateFixture.inGracePeriod(
        gracePeriodEnd: DateTime.now().add(
          remaining + const Duration(minutes: 1),
        ),
      );

  bool bannerShown(WidgetTester tester) =>
      tester.any(find.byIcon(Icons.warning_amber_rounded));

  group('visibility', () {
    testWidgets('shows while inside the grace period', (tester) async {
      await pumpBanner(tester, streak: graceEndingIn(const Duration(hours: 6)));

      expect(bannerShown(tester), isTrue);
    });

    testWidgets('takes no space when not in a grace period', (tester) async {
      await pumpBanner(tester, streak: StreakStateFixture.withStreak(5));

      expect(bannerShown(tester), isFalse);
      expect(tester.getSize(find.byType(GracePeriodBanner)).height, 0);
    });

    testWidgets('takes no space on first launch', (tester) async {
      await pumpBanner(tester);

      expect(tester.getSize(find.byType(GracePeriodBanner)).height, 0);
    });

    // A flag set with no expiry is a corrupt record, not a grace period —
    // there is nothing to count down to, so there is nothing to say.
    testWidgets('stays hidden when the flag has no expiry', (tester) async {
      await pumpBanner(
        tester,
        streak: StreakStateFixture.withStreak(5)
            .copyWith(inGracePeriod: true, clearGracePeriodEnd: true),
      );

      expect(bannerShown(tester), isFalse);
    });

    // A storage failure is the wrong moment to tell someone their streak is
    // about to reset: the claim would be unfounded.
    testWidgets('stays hidden when the state cannot be read', (tester) async {
      when(repository.watch)
          .thenAnswer((_) => Stream.error(Exception('store gone')));

      await pumpApp(
        tester,
        const GracePeriodBanner(),
        overrides: [
          streakRepositoryProvider.overrideWithValue(repository),
          dailyLogRepositoryProvider.overrideWithValue(
            _MockDailyLogRepository(),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(bannerShown(tester), isFalse);
    });
  });

  group('countdown text', () {
    // The issue's `remaining.inHours` alone truncates, so it reads "0 שעות"
    // for the last fifty-nine minutes — the stretch where the number matters
    // most. These cover the handover points.
    String describe(Duration d) => GracePeriodBannerText.describe(d);

    test('a full window reads as 24 hours', () {
      expect(describe(const Duration(hours: 24)), '24 שעות');
    });

    test('several hours read in hours', () {
      expect(describe(const Duration(hours: 6, minutes: 30)), '6 שעות');
    });

    test('one hour is singular', () {
      expect(describe(const Duration(hours: 1, minutes: 5)), 'שעה');
    });

    test('under an hour switches to minutes', () {
      expect(describe(const Duration(minutes: 59)), '59 דקות');
    });

    test('one minute is singular', () {
      expect(describe(const Duration(minutes: 1, seconds: 30)), 'דקה');
    });

    test('under a minute says so rather than showing zero', () {
      expect(describe(const Duration(seconds: 20)), 'פחות מדקה');
    });

    // **This expectation has flipped, and it is the defect #308 fixes.** It
    // used to assert `'פחות מדקה'`, characterising the fall-through that told
    // a user whose window closed half an hour ago that their streak would
    // reset within the minute — and went on telling them so indefinitely,
    // because nothing reconciles until the next write.
    test('a negative duration reads as expired, not as less than a minute', () {
      expect(describe(const Duration(minutes: -30)), 'הסתיימה');
      expect(describe(const Duration(minutes: -30)), isNot('פחות מדקה'));
    });

    // The boundary between the two. `AdaptationPhaseService.hasExpired` is
    // strictly-after for the same reason: the user is given the instant, not
    // denied it — but a duration of exactly zero has none of it left.
    test('exactly zero reads as expired', () {
      expect(describe(Duration.zero), 'הסתיימה');
    });

    // A regression guard on the branch that was always right.
    test('fifty-nine seconds still reads as less than a minute', () {
      expect(describe(const Duration(seconds: 59)), 'פחות מדקה');
    });

    // A clock moved backwards must not promise more time than a grace period
    // can hold.
    test('more than a full window is capped at 24 hours', () {
      expect(describe(const Duration(hours: 40)), '24 שעות');
    });
  });

  testWidgets('renders the remaining time in the banner', (tester) async {
    await pumpBanner(tester, streak: graceEndingIn(const Duration(hours: 6)));

    expect(find.textContaining('6 שעות'), findsOneWidget);
    expect(find.textContaining('הרצף שלך בסכנה'), findsOneWidget);
  });

  // The countdown ticks once a minute while visible. A timer left running
  // while hidden would rebuild a zero-height box for the life of the app,
  // and most days have no grace period at all.
  testWidgets('a hidden banner leaves no timer running', (tester) async {
    await pumpBanner(tester, streak: StreakStateFixture.withStreak(5));

    // pumpAndSettle throws if a periodic timer is still pending.
    await tester.pumpAndSettle();
    expect(bannerShown(tester), isFalse);
  });

  testWidgets('the timer is cancelled on dispose', (tester) async {
    await pumpBanner(tester, streak: graceEndingIn(const Duration(hours: 6)));
    expect(bannerShown(tester), isTrue);

    // Replaced through the same ProviderScope: riverpod rejects a rebuild
    // that changes the number of overrides.
    await pumpApp(
      tester,
      const SizedBox.shrink(),
      overrides: [
        streakRepositoryProvider.overrideWithValue(repository),
        dailyLogRepositoryProvider.overrideWithValue(_MockDailyLogRepository()),
      ],
    );
    await tester.pumpAndSettle();

    // A surviving Timer.periodic fails the test binding at teardown.
    expect(find.byType(GracePeriodBanner), findsNothing);
  });

  group('an expired window', () {
    /// A window that closed [ago] before [now].
    StreakState graceClosed(Duration ago) =>
        StreakStateFixture.inGracePeriod(gracePeriodEnd: now.subtract(ago));

    testWidgets('shows the expired copy when gracePeriodEnd is in the past', (
      tester,
    ) async {
      await pumpBanner(
        tester,
        streak: graceClosed(const Duration(hours: 6)),
        at: now,
      );

      expect(find.byKey(const Key('grace_period_expired')), findsOneWidget);
      expect(find.text(GracePeriodBannerText.expiredNotice), findsOneWidget);
    });

    // The whole defect in one assertion: six hours after the window closed,
    // the banner used to say the streak would reset in under a minute.
    testWidgets('does not claim the streak resets within the minute', (
      tester,
    ) async {
      await pumpBanner(
        tester,
        streak: graceClosed(const Duration(hours: 6)),
        at: now,
      );

      expect(find.textContaining('פחות מדקה'), findsNothing);
      expect(find.textContaining('הרצף שלך בסכנה'), findsNothing);
    });

    // Vanishing is how the user learns nothing — and the ring's number
    // changing later with no explanation is the failure being fixed, not
    // reproduced.
    testWidgets('does not hide itself', (tester) async {
      await pumpBanner(
        tester,
        streak: graceClosed(const Duration(hours: 6)),
        at: now,
      );

      expect(find.byType(SizedBox), findsWidgets);
      expect(
        tester.getSize(find.byKey(const Key('grace_period_expired'))).height,
        greaterThan(0),
      );
    });

    // The expired notice says the same thing every minute, so it must not
    // leave a ticker rebuilding it for the life of the app. `pumpAndSettle`
    // throws if a periodic timer is still pending.
    testWidgets('leaves no timer running', (tester) async {
      await pumpBanner(
        tester,
        streak: graceClosed(const Duration(hours: 6)),
        at: now,
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('grace_period_expired')), findsOneWidget);
    });

    // The legitimate case, and the one a careless fix breaks: a breached day
    // is not a skipped day, and an unexpired window is exactly what the
    // breach bought.
    testWidgets('shows the countdown when gracePeriodEnd is in the future', (
      tester,
    ) async {
      await pumpBanner(
        tester,
        streak: StreakStateFixture.inGracePeriod(
          gracePeriodEnd: now.add(const Duration(hours: 6, minutes: 1)),
        ),
        at: now,
      );

      expect(find.byKey(const Key('grace_period_countdown')), findsOneWidget);
      expect(find.byKey(const Key('grace_period_expired')), findsNothing);
      expect(find.textContaining('6 שעות'), findsOneWidget);
    });

    // `hasExpired` is strictly-after, so the boundary instant is still
    // inside the window — the user is given it, not denied it.
    testWidgets('the exact expiry instant is still inside the window', (
      tester,
    ) async {
      await pumpBanner(
        tester,
        streak: StreakStateFixture.inGracePeriod(gracePeriodEnd: now),
        at: now,
      );

      expect(find.byKey(const Key('grace_period_countdown')), findsOneWidget);
    });

    // `copyWith` cannot clear a `StreakState` field with null, so this pairing
    // should be unreachable. Asserted anyway: a widget cannot enforce an
    // invariant it does not own.
    testWidgets('an open flag with no expiry renders nothing and does not '
        'throw', (tester) async {
      await pumpBanner(
        tester,
        streak: StreakStateFixture.withStreak(5)
            .copyWith(inGracePeriod: true, clearGracePeriodEnd: true),
        at: now,
      );

      expect(find.byKey(const Key('grace_period_expired')), findsNothing);
      expect(find.byKey(const Key('grace_period_countdown')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
