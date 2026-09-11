import 'package:fantastic/features/onboarding/application/onboarding_service.dart';
import 'package:fantastic/features/onboarding/application/providers/onboarding_gate.dart';
import 'package:fantastic/features/onboarding/domain/models/biological_sex.dart';
import 'package:fantastic/features/onboarding/domain/models/keto_goal.dart';
import 'package:fantastic/features/onboarding/domain/models/macro_targets.dart';
import 'package:fantastic/features/onboarding/domain/models/onboarding_data.dart';
import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen4.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_onboarding.dart';

class _MockOnboardingService extends Mock implements OnboardingService {}

void main() {
  late _MockOnboardingService service;

  final data = UserProfileFixture.data(
    sex: BiologicalSex.male,
    age: 41,
    weightKg: 91.2,
    heightCm: 183,
    goal: KetoGoal.weightLoss,
  );
  final calculated = UserProfileFixture.targets(
    fatG: 147,
    netCarbsG: 20,
    proteinG: 73,
  );

  setUpAll(() {
    registerFallbackValue(UserProfileFixture.data());
    registerFallbackValue(UserProfileFixture.targets());
  });

  setUp(() {
    service = _MockOnboardingService();
    when(() => service.calculateMacroTargets(any())).thenReturn(calculated);
    when(
      () => service.completeOnboarding(
        data: any(named: 'data'),
        targets: any(named: 'targets'),
      ),
    ).thenAnswer((_) async => UserProfileFixture.profile());
  });

  Future<void> pumpScreen(WidgetTester tester) => pumpOnboarding(
    tester,
    OnboardingScreen4(data: data),
    overrides: [onboardingServiceProvider.overrideWithValue(service)],
  );

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.text('התחל את המסע'));
    await tester.pumpAndSettle();
  }

  /// The targets `completeOnboarding` was called with.
  ///
  /// `verify` consumes the recorded call, so this is callable once per test
  /// — hold the result rather than calling it twice.
  ProviderContainer gateOf(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
    listen: false,
  );

  MacroTargets savedTargets() =>
      verify(
            () => service.completeOnboarding(
              data: any(named: 'data'),
              targets: captureAny(named: 'targets'),
            ),
          ).captured.single
          as MacroTargets;

  group('pre-filled targets', () {
    testWidgets('shows the calculated numbers in the three fields', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('147'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      expect(find.text('73'), findsOneWidget);
    });

    testWidgets('calculates from the data it was given', (tester) async {
      await pumpScreen(tester);

      verify(() => service.calculateMacroTargets(data)).called(1);
    });

    // Every digit run inside the RTL layout needs this, or 147 reads as 741.
    testWidgets('lays every field out left to right', (tester) async {
      await pumpScreen(tester);

      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields, hasLength(3));
      for (final field in fields) {
        expect(field.textDirection, TextDirection.ltr);
      }
    });
  });

  group('confirming', () {
    testWidgets('saves the calculated targets untouched', (tester) async {
      await pumpScreen(tester);

      await confirm(tester);

      expect(savedTargets(), calculated);
    });

    testWidgets('saves an edit rather than the calculated value', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'שומן יומי (גרם)'),
        '200',
      );
      await confirm(tester);

      final saved = savedTargets();
      expect(saved.fatG, 200);
      expect(saved.proteinG, 73);
    });

    // Net carbs are calculated as the fixed induction allowance and are
    // editable anyway: #73 calls them "not user-adjustable" and #72 renders
    // them in an editable field.
    testWidgets('an edited net-carb target is saved', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'פחמימות נטו (גרם)'),
        '30',
      );
      await confirm(tester);

      expect(savedTargets().netCarbsG, 30);
    });

    testWidgets('carries the answers through to the service', (tester) async {
      await pumpScreen(tester);

      await confirm(tester);

      final saved =
          verify(
                () => service.completeOnboarding(
                  data: captureAny(named: 'data'),
                  targets: any(named: 'targets'),
                ),
              ).captured.single
              as OnboardingData;
      expect(saved, data);
    });

    testWidgets('navigates to the dashboard once saved', (tester) async {
      await pumpScreen(tester);

      await confirm(tester);

      expect(lastPushedLocation, '/');
    });

    // Without this the router's redirect still believes onboarding is
    // pending and sends the user straight back to step 1 — forever, on
    // every launch. #74 expects the service to invalidate a provider, which
    // it holds no `Ref` to do (`design/m4_preflight.md` §1.1).
    testWidgets('opens the onboarding gate', (tester) async {
      await pumpScreen(tester);
      expect(gateOf(tester).read(onboardingGateProvider), isFalse);

      await confirm(tester);

      expect(gateOf(tester).read(onboardingGateProvider), isTrue);
    });
  });

  group('validation', () {
    // `double.tryParse` returns a value for both of these and neither is
    // null, so #72's `?? _targets.fatG` fallback never fires — and both then
    // divide through every bar on the dashboard.
    testWidgets('Infinity and NaN are refused, not silently defaulted', (
      tester,
    ) async {
      await pumpScreen(tester);

      for (final poison in ['Infinity', 'NaN']) {
        await tester.enterText(
          find.widgetWithText(TextFormField, 'שומן יומי (גרם)'),
          poison,
        );
        await confirm(tester);
      }

      verifyNever(
        () => service.completeOnboarding(
          data: any(named: 'data'),
          targets: any(named: 'targets'),
        ),
      );
      expect(lastPushedLocation, isNull);
    });

    testWidgets('a zero target is refused', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'חלבון (גרם)'),
        '0',
      );
      await confirm(tester);

      expect(find.text('יש להזין מספר גדול מאפס'), findsOneWidget);
      expect(lastPushedLocation, isNull);
    });

    testWidgets('an emptied field is refused', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'שומן יומי (גרם)'),
        '',
      );
      await confirm(tester);

      expect(lastPushedLocation, isNull);
    });
  });

  group('when the save fails', () {
    setUp(() {
      when(
        () => service.completeOnboarding(
          data: any(named: 'data'),
          targets: any(named: 'targets'),
        ),
      ).thenThrow(Exception('disk gone'));
    });

    // Navigating to a dashboard that would immediately send the user back
    // here — because the profile never reached storage — is the worst of
    // both outcomes.
    testWidgets('stays on the screen and says so', (tester) async {
      await pumpScreen(tester);

      await confirm(tester);

      expect(find.text('השמירה נכשלה, נסו שוב'), findsOneWidget);
      expect(lastPushedLocation, isNull);
      expect(find.byType(OnboardingScreen4), findsOneWidget);
    });

    // A gate opened on a profile that never reached storage would skip
    // onboarding on the next launch and leave the user on the defaults.
    testWidgets('leaves the onboarding gate closed', (tester) async {
      await pumpScreen(tester);

      await confirm(tester);

      expect(gateOf(tester).read(onboardingGateProvider), isFalse);
    });

    testWidgets('keeps the edited numbers and allows a retry', (tester) async {
      await pumpScreen(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'שומן יומי (גרם)'),
        '200',
      );

      await confirm(tester);

      expect(find.text('200'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    });
  });

  testWidgets('lays out without overflowing a short screen', (tester) async {
    tester.view.physicalSize = const Size(360, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpScreen(tester);

    expect(tester.takeException(), isNull);
  });
}
