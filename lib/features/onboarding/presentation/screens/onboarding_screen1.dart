import 'package:fantastic/core/widgets/app_illustration.dart';
import 'package:fantastic/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Step 1 of 4 — the welcome screen.
///
/// No inputs and no state: it says what the app is and starts the flow.
///
/// **There is still no image asset.** #69 specifies
/// `assets/images/onboarding_welcome.png`, which does not exist and is not
/// declared in `pubspec.yaml` — `Image.asset` would throw at paint time and
/// take the issue's own widget tests with it. Committing a meaningless
/// placeholder binary instead is worse than not committing one: it cannot be
/// reviewed, it ignores the dark palette, and it is replaced wholesale the
/// day a real illustration exists. See `design/m4_preflight.md` §2.
///
/// That day arrived: the hero is [KetoPlateIllustration], drawn rather than
/// shipped, so it keeps every property the argument above asks for. The four
/// Material icons it replaced stood in for the plate `ui_ux_design.md` §1a
/// actually asks for.
class OnboardingScreen1 extends StatelessWidget {
  const OnboardingScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OnboardingScaffold(
      step: 1,
      title: '',
      // `ui_ux_design.md` §1a, not the issue's 'התחל' — the UX spec is what
      // the app's Hebrew is written against, and `tasks.md` agrees with it.
      ctaLabel: 'בואו נתחיל',
      onNext: () => context.push('/onboarding/2'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const KetoPlateIllustration(width: 200),
          const SizedBox(height: 40),
          Text(
            'ברוכים הבאים ל-Fantastic',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'המדריך האולטימטיבי לתזונת קטו ישראלית',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
