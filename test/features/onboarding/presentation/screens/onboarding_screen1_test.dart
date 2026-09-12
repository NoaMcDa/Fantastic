import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/onboarding/application/onboarding_service.dart';
import 'package:fantastic/features/onboarding/application/providers/onboarding_gate.dart';
import 'package:fantastic/features/onboarding/domain/models/user_profile.dart';
import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen1.dart';
import 'package:fantastic/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_onboarding.dart';

class _MockOnboardingService extends Mock implements OnboardingService {}

void main() {
  testWidgets('renders the Hebrew headline and subtitle', (tester) async {
    await pumpOnboarding(tester, const OnboardingScreen1());

    expect(find.text('ברוכים הבאים ל-Fantastic'), findsOneWidget);
    expect(find.text('המדריך האולטימטיבי לתזונת קטו ישראלית'), findsOneWidget);
  });

  // `ui_ux_design.md` §1a, not the issue's 'התחל'.
  testWidgets('shows the CTA from the UX spec', (tester) async {
    await pumpOnboarding(tester, const OnboardingScreen1());

    expect(find.widgetWithText(FilledButton, 'בואו נתחיל'), findsOneWidget);
  });

  testWidgets('the CTA navigates to step 2', (tester) async {
    await pumpOnboarding(tester, const OnboardingScreen1());

    await tester.tap(find.text('בואו נתחיל'));
    await tester.pumpAndSettle();

    expect(lastPushedLocation, '/onboarding/2');
  });

  // #69 asks for `Image.asset('assets/images/onboarding_welcome.png')`. The
  // file does not exist and `assets/images/` is not declared in the pubspec,
  // so that would throw at paint time and take this suite with it.
  testWidgets('draws its hero rather than loading a missing asset', (
    tester,
  ) async {
    await pumpOnboarding(tester, const OnboardingScreen1());

    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('marks step 1 of 4 in the shared scaffold', (tester) async {
    await pumpOnboarding(tester, const OnboardingScreen1());

    final scaffold = tester.widget<OnboardingScaffold>(
      find.byType(OnboardingScaffold),
    );
    expect(scaffold.step, 1);
    expect(OnboardingScaffold.stepCount, 4);
  });

  // The welcome screen has no back destination and no title — an app bar
  // here would read like a settings page.
  testWidgets('has no app bar', (tester) async {
    await pumpOnboarding(tester, const OnboardingScreen1());

    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('lays out without overflowing a short screen', (tester) async {
    tester.view.physicalSize = const Size(360, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpOnboarding(tester, const OnboardingScreen1());

    expect(tester.takeException(), isNull);
  });

  // #262. `design/mvp.md` §4 promised a skippable flow and M4 shipped an
  // absolute gate; this is the way past it.
  group('skip', () {
    late _MockOnboardingService service;

    setUp(() {
      service = _MockOnboardingService();
      when(service.skipOnboarding)
          .thenAnswer((_) async => UserProfile.skipped());
    });

    Future<void> pumpScreen(WidgetTester tester) => pumpOnboarding(
      tester,
      const OnboardingScreen1(),
      overrides: [onboardingServiceProvider.overrideWithValue(service)],
    );

    ProviderContainer containerOf(WidgetTester tester) =>
        ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp)),
          listen: false,
        );

    testWidgets('offers a skip, visually secondary to the CTA', (tester) async {
      await pumpScreen(tester);

      // A `TextButton`, not a second `FilledButton`: an affordance that looks
      // like the primary action gets tapped by accident, and this one is not
      // undoable while the profile tab is read-only.
      expect(
        find.widgetWithText(TextButton, OnboardingScreen1.skipLabel),
        findsOneWidget,
      );
      expect(find.byType(FilledButton), findsOneWidget);
    });

    // #262 is explicit that what a skip costs must not be hidden.
    testWidgets('says what a skip costs', (tester) async {
      await pumpScreen(tester);

      expect(find.text(OnboardingScreen1.skipCost), findsOneWidget);
    });

    testWidgets('tapping it commits a skipped profile', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('onboarding_skip')));
      await tester.pumpAndSettle();

      verify(service.skipOnboarding).called(1);
    });

    testWidgets('it opens the gate and lands on the dashboard', (tester) async {
      await pumpScreen(tester);
      final container = containerOf(tester);
      expect(container.read(onboardingGateProvider), isFalse);

      await tester.tap(find.byKey(const Key('onboarding_skip')));
      await tester.pumpAndSettle();

      expect(container.read(onboardingGateProvider), isTrue);
      expect(lastPushedLocation, '/');
    });

    // A gate opened over a profile that never reached storage would skip
    // onboarding forever with nothing stored: the user lands on a dashboard,
    // and the next cold start finds no record and puts them back at step 1.
    testWidgets('a failed skip leaves the gate closed and says so', (
      tester,
    ) async {
      when(service.skipOnboarding).thenThrow(
        const PersistenceException('UserProfileRepository.save', 'closed'),
      );
      await pumpScreen(tester);
      final container = containerOf(tester);

      await tester.tap(find.byKey(const Key('onboarding_skip')));
      await tester.pumpAndSettle();

      expect(find.text(OnboardingScreen1.skipFailed), findsOneWidget);
      expect(container.read(onboardingGateProvider), isFalse);
      expect(lastPushedLocation, isNull);
    });

    testWidgets('the CTA still reaches step 2', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('בואו נתחיל'));
      await tester.pumpAndSettle();

      expect(lastPushedLocation, '/onboarding/2');
      verifyNever(service.skipOnboarding);
    });
  });
}
