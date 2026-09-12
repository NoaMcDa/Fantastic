import 'dart:async';

import 'package:fantastic/core/providers/notification_providers.dart';
import 'package:fantastic/core/services/notification_service.dart';
import 'package:fantastic/features/adaptation/data/providers.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:fantastic/features/adaptation/domain/repositories/streak_repository.dart';
import 'package:fantastic/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:fantastic/features/onboarding/application/providers/onboarding_gate.dart';
import 'package:fantastic/features/onboarding/data/providers.dart';
import 'package:fantastic/features/onboarding/domain/models/keto_goal.dart';
import 'package:fantastic/features/onboarding/domain/models/user_profile.dart';
import 'package:fantastic/features/onboarding/domain/repositories/user_profile_repository.dart';
import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen1.dart';
import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen2.dart';
import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen3.dart';
import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen4.dart';
import 'package:fantastic/main.dart';
import 'package:flutter/material.dart';
import 'package:fantastic/features/dashboard/data/providers.dart';
import 'package:fantastic/features/dashboard/domain/repositories/daily_log_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationService extends Mock implements NotificationService {}

/// A repository that keeps its one record in memory.
///
/// Hand-written rather than mocked, and **not** a real sembast database:
/// sembast's futures do not complete inside `testWidgets`' fake-async zone,
/// so a widget test that awaited one would hang rather than fail. This is
/// also more readable than stubbing `load`, `save` and `watch` separately
/// and keeping them consistent with each other by hand.
class _InMemoryProfileRepository implements UserProfileRepository {
  UserProfile? _profile;
  final _changes = StreamController<UserProfile?>.broadcast();

  @override
  Future<UserProfile?> load() async => _profile;

  @override
  Future<UserProfile> save(UserProfile profile) async {
    _profile = profile;
    _changes.add(profile);
    return profile;
  }

  @override
  Stream<UserProfile?> watch() async* {
    yield _profile;
    yield* _changes.stream;
  }

  void dispose() => _changes.close();
}

class _InMemoryStreakRepository implements StreakRepository {
  StreakState? _state;

  @override
  Future<StreakState?> load() async => _state;

  @override
  Future<StreakState> save(StreakState state) async => _state = state;

  @override
  Stream<StreakState?> watch() => Stream.value(_state);
}

/// The whole flow, driven through the real app and the real router — the
/// only test here that would catch a wiring mistake between two screens
/// that both pass their own tests, and the closest thing this suite has to
/// the browser run that closed M3.
/// #303 gave `adaptationPhaseServiceProvider` a second dependency, so a
/// container that overrides only the streak repository now reaches
/// `databaseProvider` and tries to open a real database.
class _MockDailyLogRepository extends Mock implements DailyLogRepository {}

void main() {
  late _InMemoryProfileRepository profiles;
  late _InMemoryStreakRepository streaks;
  late _MockNotificationService notifications;

  setUpAll(() => initializeDateFormatting('he'));

  setUp(() {
    profiles = _InMemoryProfileRepository();
    streaks = _InMemoryStreakRepository();
    notifications = _MockNotificationService();
    when(notifications.requestPermission).thenAnswer((_) async => true);
    addTearDown(profiles.dispose);
  });

  /// `pumpAndSettle` with a short deadline.
  ///
  /// **The original reason is gone, and the bound is kept anyway.** This was
  /// written because the dashboard drew an indeterminate
  /// `CircularProgressIndicator` while its providers loaded, and an
  /// indeterminate spinner animates forever — so a provider that never
  /// resolved did not fail this suite, it hung it for ten minutes per call.
  /// #88 replaced those with static skeletons, and an unbounded
  /// `pumpAndSettle()` now completes this suite in about four seconds.
  ///
  /// The deadline stays because the other half of the hazard did not move:
  /// riverpod 3 retries a failed provider on an exponential backoff, so
  /// frames keep being scheduled over a broken store for as long as the
  /// backoff runs. `design/m8_preflight.md` bounds every settle in the e2e
  /// harness for that reason alone.
  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );

  /// A cold start, in `main`'s own order: build the container, seed the
  /// gate from what is already stored, *then* run the app. Pumping a bare
  /// `ProviderScope` instead would leave the gate at its default and make
  /// every launch look like a first launch.
  Future<ProviderContainer> coldStart(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        userProfileRepositoryProvider.overrideWithValue(profiles),
        streakRepositoryProvider.overrideWithValue(streaks),
        dailyLogRepositoryProvider.overrideWithValue(_MockDailyLogRepository()),
        notificationServiceProvider.overrideWithValue(notifications),
        // The dashboard's own data providers are deliberately left
        // unoverridden: they fail to reach a database and render their
        // failure states, which is fine here. This test is about the flow
        // reaching the dashboard at all; that the card then measures
        // against the saved targets is `macro_summary_card_test`'s job.
      ],
    );
    addTearDown(container.dispose);
    await seedOnboardingGate(container);

    // Tear the previous tree down first. A second `pumpWidget` of the same
    // widget type updates the existing elements rather than replacing them,
    // and updating a live router and a live ProviderScope onto a different
    // container trips a framework assertion. A relaunch has to be a
    // relaunch.
    await tester.pumpWidget(const SizedBox.shrink());

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FantasticApp(),
      ),
    );
    await settle(tester);
    return container;
  }

  Future<void> tap(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await settle(tester);
  }

  /// Scrolls [finder] into view, then taps it.
  ///
  /// Screen 2 grew an activity selector, so the "כבר בקטו?" switch and the
  /// date tile under it now sit below the default test viewport. Both are
  /// built — the `Column` builds eagerly — but a tap does not reach a widget
  /// outside the viewport.
  Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await settle(tester);
    await tester.tap(finder);
    await settle(tester);
  }

  Future<void> fillAboutYou(WidgetTester tester) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'גיל'), '40');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'משקל (ק״ג)'),
      '80',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'גובה (ס״מ)'),
      '180',
    );
    await tester.pump();
  }

  testWidgets('a first launch walks the whole flow and lands on a '
      'personalised dashboard', (tester) async {
    final container = await coldStart(tester);

    // The gate sent the initial route into the flow; nothing navigated.
    expect(find.byType(OnboardingScreen1), findsOneWidget);

    await tap(tester, 'בואו נתחיל');
    expect(find.byType(OnboardingScreen2), findsOneWidget);

    await fillAboutYou(tester);
    await tap(tester, 'זכר');
    await tap(tester, 'הבא');
    expect(find.byType(OnboardingScreen3), findsOneWidget);

    await tap(tester, 'ירידה במשקל');
    await tap(tester, 'הבא');
    expect(find.byType(OnboardingScreen4), findsOneWidget);

    // Male, 80 kg, 180 cm, 40, weight loss: BMR 1730, TDEE 2076, less the
    // 20% deficit is 1660.8; 64 g of protein and 20 g of carbs leave 147 g
    // of fat.
    expect(find.text('147'), findsOneWidget);
    expect(find.text('64'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'שומן יומי (גרם)'),
      '200',
    );
    await tap(tester, 'התחל את המסע');

    // Epic #8: onboarding is shown exactly once, and the dashboard shows
    // what it set.
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(container.read(onboardingGateProvider), isTrue);

    final profile = await profiles.load();
    expect(profile, isNotNull);
    expect(profile!.goals, {KetoGoal.weightLoss});
    expect(profile.targets.fatG, 200);
    expect(profile.weightKg, 80);
    expect(profile.age, 40);
  });

  // The bug #74 as written would ship: the flag is stored, the user is sent
  // to the dashboard, and every launch after that bounces them back in.
  testWidgets('a second launch skips onboarding entirely', (tester) async {
    var container = await coldStart(tester);

    await tap(tester, 'בואו נתחיל');
    await fillAboutYou(tester);
    await tap(tester, 'הבא');
    await tap(tester, 'ביצועים ספורטיביים');
    await tap(tester, 'הבא');
    await tap(tester, 'התחל את המסע');
    expect(find.byType(DashboardScreen), findsOneWidget);

    // A cold start against the same store.
    container = await coldStart(tester);

    expect(container.read(onboardingGateProvider), isTrue);
    expect(find.byType(OnboardingScreen1), findsNothing);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('notification permission is requested once, at the end', (
    tester,
  ) async {
    await coldStart(tester);
    verifyNever(notifications.requestPermission);

    await tap(tester, 'בואו נתחיל');
    await fillAboutYou(tester);
    await tap(tester, 'הבא');
    await tap(tester, 'ירידה במשקל');
    await tap(tester, 'הבא');
    verifyNever(notifications.requestPermission);

    await tap(tester, 'התחל את המסע');

    verify(notifications.requestPermission).called(1);
  });

  // A user who says they are already on keto keeps the days they banked —
  // Epic #8's "streak seeded correctly from past start date", which no
  // child issue asked for.
  testWidgets('a start date entered in the flow seeds the streak', (
    tester,
  ) async {
    final container = await coldStart(tester);

    await tap(tester, 'בואו נתחיל');
    await fillAboutYou(tester);
    await scrollAndTap(tester, find.byType(SwitchListTile));
    await scrollAndTap(tester, find.text('בחרו תאריך'));
    // The picker opens on today, the only date always selectable. "Started
    // today" banks nothing by design, so the assertion below is that the
    // date reached the profile and the null streak sentinel survived.
    await tap(tester, 'אישור');
    await tap(tester, 'הבא');
    await tap(tester, 'בריאות מטבולית');
    await tap(tester, 'הבא');
    await tap(tester, 'התחל את המסע');

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect((await profiles.load())!.ketoStartDate, isNotNull);
    // A StreakState.initial() write here would destroy the "never had a
    // compliant day" sentinel (`design/m4_preflight.md` §1.3).
    expect(await container.read(streakRepositoryProvider).load(), isNull);
  });
}
