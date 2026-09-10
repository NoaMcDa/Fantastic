import 'package:flutter/material.dart';

/// Placeholder for one screen of the 4-step onboarding flow.
///
/// Holds the `/onboarding/:step` route so the flow is reachable before M4
/// builds the real screens (#69–#72). Renders no navigation of its own — the
/// step is displayed purely so the route is identifiable in a test.
class OnboardingPlaceholder extends StatelessWidget {
  const OnboardingPlaceholder({required this.step, super.key});

  final int step;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('אונבורדינג — שלב $step')));
}
