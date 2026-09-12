import 'package:flutter/material.dart';

/// The shell every onboarding screen shares.
///
/// The flow is deliberately outside the router's `ShellRoute`, so there is no
/// tab bar and no shared chrome to inherit — this is what gives the four
/// screens one set of margins, one progress indicator and one CTA position
/// instead of four slightly different ones.
///
/// [step] is 1-based and drives the dots; [onNext] being null disables the
/// CTA, which is how screen 3 blocks progress until a goal is chosen.
///
/// [secondaryAction] renders **below** the CTA, which is the only place a
/// skip belongs: an affordance that looks like the primary action gets
/// tapped by accident, and skipping is not undoable while there is no
/// profile-editing screen (#262).
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    required this.step,
    required this.title,
    required this.ctaLabel,
    required this.child,
    this.onNext,
    this.secondaryAction,
    super.key,
  });

  /// How many screens the flow has. Mirrors `kOnboardingStepCount`, kept
  /// local so `presentation/` does not reach into the router for a number it
  /// only draws.
  static const int stepCount = 4;

  final int step;

  /// Shown in the app bar. Screen 1 passes an empty string — a welcome
  /// screen with a title bar reads like a settings page.
  final String title;

  final String ctaLabel;
  final Widget child;
  final VoidCallback? onNext;

  /// Shown under the CTA. Null on every screen but the first.
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title.isEmpty
          ? null
          : AppBar(title: Text(title), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: child),
              const SizedBox(height: 16),
              _StepDots(step: step),
              const SizedBox(height: 16),
              SizedBox(
                // The Apple HIG minimum, and comfortably above it: this is
                // the only control on the screen.
                height: 52,
                child: FilledButton(
                  // One key for all four screens' CTAs. The labels differ
                  // per screen and two of them change mid-interaction
                  // ('שומר...' while screen 4 saves), so a flow test that
                  // taps them by text is one copy edit from breaking.
                  key: const Key('onboarding_cta'),
                  onPressed: onNext,
                  child: Text(ctaLabel),
                ),
              ),
              if (secondaryAction != null) ...[
                const SizedBox(height: 8),
                secondaryAction!,
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Four dots, the current one filled.
///
/// A `Row` of dots rather than a `LinearProgressIndicator`: a bar has a
/// direction and would have to be mirrored for RTL, while a symmetric run of
/// dots reads the same either way. The row still lays out right-to-left
/// inside the RTL `Directionality`, which is what puts step 1 on the right.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= OnboardingScaffold.stepCount; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              width: i == step ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == step
                    ? colors.primary
                    : colors.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
      ],
    );
  }
}
