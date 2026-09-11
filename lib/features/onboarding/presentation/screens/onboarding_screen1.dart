import 'package:fantastic/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Step 1 of 4 — the welcome screen.
///
/// No inputs and no state: it says what the app is and starts the flow.
///
/// **There is no image asset.** #69 specifies
/// `assets/images/onboarding_welcome.png`, which does not exist and is not
/// declared in `pubspec.yaml` — `Image.asset` would throw at paint time and
/// take the issue's own widget tests with it. Committing a meaningless
/// placeholder binary instead is worse than not committing one: it cannot be
/// reviewed, it ignores the dark palette, and it is replaced wholesale the
/// day a real illustration exists. The hero is composed from theme colours
/// and Material icons, which is reviewable and responds to the theme.
/// See `design/m4_preflight.md` §2.
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
          const _WelcomeHero(),
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

/// The keto plate `ui_ux_design.md` §1a asks for, drawn rather than shipped.
///
/// Four foods the app's own ingredient rules approve, arranged around an
/// accent-tinted disc.
class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  /// The icons, in the order they are laid out. Kept as data so the test can
  /// assert on the count without naming each one.
  static const List<IconData> icons = [
    Icons.egg_alt_outlined,
    Icons.set_meal_outlined,
    Icons.water_drop_outlined,
    Icons.local_florist_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            colors.primary.withValues(alpha: 0.25),
            colors.surface.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            for (final icon in icons)
              Icon(icon, size: 48, color: colors.primary),
          ],
        ),
      ),
    );
  }
}
