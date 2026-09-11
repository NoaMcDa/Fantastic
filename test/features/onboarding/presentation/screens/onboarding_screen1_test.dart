import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen1.dart';
import 'package:fantastic/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_onboarding.dart';

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
}
