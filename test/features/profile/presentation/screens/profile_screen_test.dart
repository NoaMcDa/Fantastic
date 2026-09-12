import 'dart:async';

import 'package:fantastic/core/constants/goal_copy.dart';
import 'package:fantastic/core/constants/activity_copy.dart';
import 'package:fantastic/core/constants/profile_copy.dart';
import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/core/utils/app_version.dart';
import 'package:fantastic/features/onboarding/domain/models/activity_level.dart';
import 'package:fantastic/features/onboarding/domain/models/biological_sex.dart';
import 'package:fantastic/features/onboarding/domain/models/keto_goal.dart';
import 'package:fantastic/features/onboarding/domain/models/user_profile.dart';
import 'package:fantastic/features/profile/application/providers/profile_providers.dart';
import 'package:fantastic/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  // The screen is a `ListView` of six sections and it does not fit an
  // 800x600 test window. A `ListView` child below the fold has **no element
  // at all** (`design/m5_handoff.md`), so `find.byKey` on the version row
  // returns zero rather than "off-screen" — a taller viewport is what makes
  // these assertions about the screen rather than about the scroll offset.
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(800, 2400);
    view.devicePixelRatio = 1;
  });

  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher.views.first
        .resetPhysicalSize(),
  );

  /// Pumps the screen over [profile].
  ///
  /// `granted: null` leaves the notification row loading, which is the state
  /// most of these tests do not care about.
  Future<void> pumpScreen(
    WidgetTester tester, {
    UserProfile? profile,
    Object? profileError,
    bool granted = false,
    String version = '9.9.9',
  }) {
    final overrides = <Override>[
      appVersionProvider.overrideWithValue(version),
      notificationPermissionProvider.overrideWith((ref) async => granted),
      if (profileError != null)
        userProfileProvider.overrideWith(
          (ref) => Stream<UserProfile?>.error(profileError),
        )
      else
        userProfileProvider.overrideWith(
          (ref) => Stream<UserProfile?>.value(profile),
        ),
    ];

    return pumpApp(tester, const ProfileScreen(), overrides: overrides);
  }

  /// The text in the trailing half of the row keyed [key].
  String valueOf(WidgetTester tester, String key) => tester
      .widgetList<Text>(
        find.descendant(of: find.byKey(Key(key)), matching: find.byType(Text)),
      )
      // The first is the label; the rest are the value and its unit.
      .skip(1)
      .map((t) => t.data)
      .join(' ');

  group('a saved profile', () {
    testWidgets('renders the saved biometrics', (tester) async {
      // Distinct values throughout: weight and height are both `double` and
      // are exactly the pair a crossed field would hide.
      await pumpScreen(
        tester,
        profile: UserProfileFixture.profile(
          sex: BiologicalSex.male,
          age: 41,
          weightKg: 82.4,
          heightCm: 178,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        valueOf(tester, 'profile_sex'),
        ProfileCopy.sexes[BiologicalSex.male],
      );
      expect(valueOf(tester, 'profile_age'), '41 ${ProfileCopy.years}');
      expect(valueOf(tester, 'profile_weight'), '82.4 ${ProfileCopy.kg}');
      expect(valueOf(tester, 'profile_height'), '178 ${ProfileCopy.cm}');
    });

    // Not the first goal in `GoalCopy.order`: a screen that rendered a
    // hard-coded goal, or the enum's first value, passes against `weightLoss`
    // and fails here.
    testWidgets('renders the goal in the words the user chose', (tester) async {
      await pumpScreen(
        tester,
        profile: UserProfileFixture.profile(
          goals: {KetoGoal.athleticPerformance},
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(GoalCopy.titles[KetoGoal.athleticPerformance]!),
        findsOneWidget,
      );
      expect(find.text(GoalCopy.titles[KetoGoal.weightLoss]!), findsNothing);
    });

    testWidgets('renders the four macro targets', (tester) async {
      await pumpScreen(
        tester,
        profile: UserProfileFixture.profile(
          targets: UserProfileFixture.targets(
            fatG: 155,
            netCarbsG: 22,
            proteinG: 71,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(valueOf(tester, 'profile_target_fat'), '155 ${ProfileCopy.grams}');
      expect(
        valueOf(tester, 'profile_target_net_carbs'),
        '22 ${ProfileCopy.grams}',
      );
      expect(
        valueOf(tester, 'profile_target_protein'),
        '71 ${ProfileCopy.grams}',
      );
      // The protocol constant, not a personal goal — which is why it has no
      // field on `MacroTargets`.
      expect(valueOf(tester, 'profile_keto_ratio'), '2');
    });

    testWidgets('renders the keto start date when one is set', (tester) async {
      await pumpScreen(
        tester,
        profile: UserProfileFixture.profile(
          ketoStartDate: UserProfileFixture.defaultKetoStartDate,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_keto_start_date')), findsOneWidget);
    });

    testWidgets('omits the keto start date row when it is null', (
      tester,
    ) async {
      await pumpScreen(tester, profile: UserProfileFixture.profile());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_keto_start_date')), findsNothing);
    });

    testWidgets('renders the app version', (tester) async {
      await pumpScreen(
        tester,
        profile: UserProfileFixture.profile(),
        version: '4.2.1',
      );
      await tester.pumpAndSettle();

      expect(valueOf(tester, 'profile_app_version'), '4.2.1');
    });

    // The M3 trap: a bare digit run reorders inside an RTL layout.
    testWidgets('renders every number left-to-right inside the RTL layout', (
      tester,
    ) async {
      await pumpScreen(tester, profile: UserProfileFixture.profile());
      await tester.pumpAndSettle();

      const numericRows = [
        'profile_age',
        'profile_weight',
        'profile_height',
        'profile_target_fat',
        'profile_target_net_carbs',
        'profile_target_protein',
        'profile_keto_ratio',
        'profile_app_version',
      ];
      for (final key in numericRows) {
        final value = tester
            .widgetList<Text>(
              find.descendant(
                of: find.byKey(Key(key)),
                matching: find.byType(Text),
              ),
            )
            .elementAt(1);
        expect(
          value.textDirection,
          TextDirection.ltr,
          reason: '$key would reorder',
        );
      }
    });

    testWidgets('says the targets cannot be edited here', (tester) async {
      await pumpScreen(tester, profile: UserProfileFixture.profile());
      await tester.pumpAndSettle();

      // The read-only boundary, on screen rather than only in a doc comment.
      expect(find.text(ProfileCopy.readOnlyNote), findsOneWidget);
    });
  });

  group('failure and absence', () {
    testWidgets('shows the failure message when the profile read fails', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        profileError: const PersistenceException('read failed', 'store closed'),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_load_failed')), findsOneWidget);
      expect(find.text(ProfileCopy.loadFailed), findsOneWidget);
    });

    // The riverpod-3 shape specifically: a stream that errors before its
    // first value is `AsyncLoading` *with* an error attached, so both
    // `isLoading` and `hasError` are true and a loading-first `when` never
    // reaches its error branch. Four milestones paid for this.
    testWidgets('shows the failure message when the provider fails before its '
        'first value', (tester) async {
      await pumpScreen(
        tester,
        profileError: const PersistenceException('read failed', 'store closed'),
      );
      // A single pump, deliberately: not settled, so the tree is still in the
      // state the loading-first bug renders.
      await tester.pump();

      expect(find.byKey(const Key('profile_load_failed')), findsOneWidget);
    });

    testWidgets('does not render a loading indicator when the read has '
        'failed', (tester) async {
      await pumpScreen(
        tester,
        profileError: const PersistenceException('read failed', 'store closed'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    // Distinguishable from a failed read, which is the whole requirement:
    // null is the first-launch sentinel, not an error.
    testWidgets('shows the never-onboarded state when the profile is null', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_not_onboarded')), findsOneWidget);
      expect(find.byKey(const Key('profile_load_failed')), findsNothing);
      expect(find.text(ProfileCopy.notOnboardedTitle), findsOneWidget);
    });

    testWidgets('a failed permission check leaves the rest of the screen '
        'readable', (tester) async {
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: [
          appVersionProvider.overrideWithValue('1.2.3'),
          notificationPermissionProvider.overrideWith(
            (ref) async =>
                throw const PersistenceException('no channel', 'platform'),
          ),
          userProfileProvider.overrideWith(
            (ref) => Stream<UserProfile?>.value(UserProfileFixture.profile()),
          ),
        ],
      );
      await tester.pumpAndSettle();

      // One broken row must not take the tab down.
      expect(find.byKey(const Key('notifications_unknown')), findsOneWidget);
      expect(find.byKey(const Key('profile_target_fat')), findsOneWidget);
      expect(valueOf(tester, 'profile_app_version'), '1.2.3');
    });
  });

  // The hazard #88 and `design/m6_handoff.md` both record: an indeterminate
  // animation on a tab screen makes `pumpAndSettle` never return, and
  // `test/widget_test.dart` visits every tab knowing nothing about what is on
  // it. This is the local guard; the router tests are the wider one.
  testWidgets('settles while still loading — nothing animates forever', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const ProfileScreen(),
      overrides: [
        appVersionProvider.overrideWithValue('1.0.0'),
        notificationPermissionProvider.overrideWith(
          (ref) => Completer<bool>().future,
        ),
        userProfileProvider.overrideWith(
          (ref) => const Stream<UserProfile?>.empty(),
        ),
      ],
    );

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  // #431's fourth bullet: M4 stored one goal, so somebody who wanted two had
  // to drop one — and this tab then read back half of what they said.
  group('goals', () {
    testWidgets('lists every chosen goal', (tester) async {
      await pumpScreen(
        tester,
        profile: UserProfileFixture.profile(
          goals: {KetoGoal.weightLoss, KetoGoal.athleticPerformance},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_goal_weightLoss')), findsOneWidget);
      expect(
        find.byKey(const Key('profile_goal_athleticPerformance')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('profile_goal_metabolicHealth')),
        findsNothing,
      );
    });

    testWidgets('an empty goal set says so', (tester) async {
      await pumpScreen(tester, profile: UserProfile.skipped());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_goals_empty')), findsOneWidget);
      expect(find.text(ProfileCopy.noGoalsChosen), findsOneWidget);
    });
  });

  group('a skipped profile', () {
    // The app genuinely does not know these four. Four rows of dashes, or
    // four invented numbers, would both be worse than saying so.
    testWidgets('says the details were not filled in', (tester) async {
      await pumpScreen(tester, profile: UserProfile.skipped());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('profile_biometrics_missing')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('profile_age')), findsNothing);
      expect(find.byKey(const Key('profile_weight')), findsNothing);
    });

    testWidgets('still shows the default targets', (tester) async {
      await pumpScreen(tester, profile: UserProfile.skipped());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_target_fat')), findsOneWidget);
    });
  });

  testWidgets('shows the activity level in words', (tester) async {
    await pumpScreen(
      tester,
      profile: UserProfileFixture.profile(
        activityLevel: ActivityLevel.veryActive,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_activity_level')), findsOneWidget);
    expect(
      find.text(ActivityCopy.titles[ActivityLevel.veryActive]!),
      findsOneWidget,
    );
  });
}
