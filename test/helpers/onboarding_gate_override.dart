import 'package:fantastic/features/onboarding/application/providers/onboarding_gate.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// A gate that reports onboarding as already done.
///
/// `main` seeds the real one from the stored profile before `runApp`; a test
/// that pumps the app has no storage and would otherwise get the default
/// `false`, which sends every route into the onboarding flow. Most router
/// and screen tests are about a *returning* user, so this is what they pass.
class _CompletedOnboardingGate extends OnboardingGate {
  @override
  bool build() => true;
}

/// Override making the app behave as it does for a returning user.
Override completedOnboardingGate() =>
    onboardingGateProvider.overrideWith(_CompletedOnboardingGate.new);
