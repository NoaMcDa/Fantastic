import 'package:fantastic/core/widgets/app_illustration.dart';
import 'package:fantastic/features/onboarding/application/onboarding_service.dart';
import 'package:fantastic/features/onboarding/application/providers/onboarding_gate.dart';
import 'package:fantastic/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Step 1 of 4 — the welcome screen, and the one way past the flow.
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
///
/// **The skip is here (#262).** `design/mvp.md` §4 promised onboarding would
/// be "skippable (defaults used if skipped)" and no M4 child issue delivered
/// it, so the gate was absolute: every route sent a fresh install back to
/// step 1 until the whole flow was finished, and somebody who wanted to look
/// around before handing over their weight could not. A skip is an ordinary
/// completion whose answers are defaults — it *writes a profile*, because the
/// gate reads that record's existence — so nothing downstream needs a special
/// case.
class OnboardingScreen1 extends ConsumerStatefulWidget {
  const OnboardingScreen1({super.key});

  /// Deliberately not "דלג": this says the choice can be revisited, which is
  /// the honest framing while the flow is the only place targets are set.
  static const String skipLabel = 'דלג בינתיים';

  /// What a skip costs, said on screen rather than discovered later.
  ///
  /// #262 is explicit that this must not be hidden: the targets will be
  /// generic, and there is nowhere in the app to change them yet — the
  /// profile tab is read-only by design.
  static const String skipCost =
      'נמשיך עם יעדים כלליים. אפשר יהיה למלא פרטים בהמשך.';

  static const String skipFailed = 'הדילוג נכשל, נסו שוב';

  @override
  ConsumerState<OnboardingScreen1> createState() => _OnboardingScreen1State();
}

class _OnboardingScreen1State extends ConsumerState<OnboardingScreen1> {
  bool _skipping = false;
  String? _skipError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OnboardingScaffold(
      step: 1,
      title: '',
      // `ui_ux_design.md` §1a, not the issue's 'התחל' — the UX spec is what
      // the app's Hebrew is written against, and `tasks.md` agrees with it.
      ctaLabel: 'בואו נתחיל',
      onNext: _skipping ? null : () => context.push('/onboarding/2'),
      secondaryAction: _SkipAction(
        skipping: _skipping,
        error: _skipError,
        onSkip: _onSkip,
      ),
      // Centred, but scrollable: the skip block under the CTA took 16px more
      // than a 360x600 screen had, and a fixed `Column` answers that with an
      // overflow stripe. `Center` keeps the hero in the middle when there is
      // room; the scroll view is what happens when there is not — which a
      // large accessibility text scale reaches on any phone.
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
        ),
      ),
    );
  }

  /// The same three steps screen 4's `_onConfirm` takes, in the same order and
  /// for the same reasons: write, then open the gate, then navigate.
  ///
  /// **The gate is opened only after the write succeeds.** Opening it over a
  /// profile that never reached storage would skip onboarding forever on
  /// defaults with nothing stored — the user would land on a dashboard, and
  /// the next cold start would find no record and put them back at step 1
  /// with no way to tell them why.
  Future<void> _onSkip() async {
    setState(() {
      _skipping = true;
      _skipError = null;
    });

    try {
      await ref.read(onboardingServiceProvider).skipOnboarding();
    } on Object catch (_) {
      // Stays on the screen and says so, exactly as screen 4 does for a
      // failed commit. A silent failure would leave the user gated with no
      // explanation.
      if (mounted) {
        setState(() {
          _skipping = false;
          _skipError = OnboardingScreen1.skipFailed;
        });
      }
      return;
    }

    if (!mounted) {
      return;
    }
    ref.read(onboardingGateProvider.notifier).markCompleted();

    if (!mounted) {
      return;
    }
    // `go`, not `push`: there is nothing to come back to.
    context.go('/');
  }
}

/// The skip button, what it costs, and what happened if it failed.
///
/// A `TextButton` under the filled CTA rather than beside it — visually
/// secondary is the requirement, because this choice is not undoable while
/// the profile tab is read-only.
class _SkipAction extends StatelessWidget {
  const _SkipAction({
    required this.skipping,
    required this.error,
    required this.onSkip,
  });

  final bool skipping;
  final String? error;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          key: const Key('onboarding_skip'),
          onPressed: skipping ? null : onSkip,
          child: Text(skipping ? 'שומר...' : OnboardingScreen1.skipLabel),
        ),
        Text(
          OnboardingScreen1.skipCost,
          key: const Key('onboarding_skip_cost'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error!,
            key: const Key('onboarding_skip_error'),
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
