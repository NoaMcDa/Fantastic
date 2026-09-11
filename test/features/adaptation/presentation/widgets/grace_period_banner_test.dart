import 'package:fantastic/features/adaptation/data/providers.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:fantastic/features/adaptation/domain/repositories/streak_repository.dart';
import 'package:fantastic/features/adaptation/presentation/widgets/grace_period_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

class _MockStreakRepository extends Mock implements StreakRepository {}

void main() {
  late _MockStreakRepository repository;

  setUp(() {
    repository = _MockStreakRepository();
    when(repository.watch).thenAnswer((_) => Stream.value(null));
  });

  Future<void> pumpBanner(WidgetTester tester, {StreakState? streak}) async {
    when(repository.watch).thenAnswer((_) => Stream.value(streak));
    await pumpApp(
      tester,
      const GracePeriodBanner(),
      overrides: [streakRepositoryProvider.overrideWithValue(repository)],
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
        overrides: [streakRepositoryProvider.overrideWithValue(repository)],
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

    // An expired window is not negative time. The reset lands on the next
    // evaluation; until then the banner holds at the floor.
    test('an expired window does not go negative', () {
      expect(describe(const Duration(minutes: -30)), 'פחות מדקה');
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
      overrides: [streakRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.pumpAndSettle();

    // A surviving Timer.periodic fails the test binding at teardown.
    expect(find.byType(GracePeriodBanner), findsNothing);
  });
}
