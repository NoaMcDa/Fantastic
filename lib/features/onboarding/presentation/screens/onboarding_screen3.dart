import 'package:fantastic/core/constants/goal_copy.dart';
import 'package:fantastic/features/onboarding/domain/models/keto_goal.dart';
import 'package:fantastic/features/onboarding/domain/models/onboarding_data.dart';
import 'package:fantastic/features/onboarding/presentation/widgets/goal_card.dart';
import 'package:fantastic/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Step 3 of 4 — what the user wants keto to do for them.
///
/// Single-select, and the CTA stays disabled until something is chosen:
/// there is no sensible default, and pre-selecting one would record a
/// preference the user never expressed.
///
/// Takes the answers from screen 2 and hands the completed [OnboardingData]
/// to screen 4.
class OnboardingScreen3 extends StatefulWidget {
  const OnboardingScreen3({required this.partial, super.key});

  final PartialOnboardingData partial;

  @override
  State<OnboardingScreen3> createState() => _OnboardingScreen3State();
}

class _OnboardingScreen3State extends State<OnboardingScreen3> {
  KetoGoal? _selected;

  static const Map<KetoGoal, IconData> _icons = {
    KetoGoal.weightLoss: Icons.monitor_weight_outlined,
    KetoGoal.metabolicHealth: Icons.favorite_outline,
    KetoGoal.athleticPerformance: Icons.directions_run,
  };

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 3,
      title: 'מה המטרה שלכם?',
      ctaLabel: 'הבא',
      onNext: _selected == null ? null : _onNext,
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        children: [
          for (final goal in GoalCopy.order) ...[
            GoalCard(
              key: Key('goal_${goal.name}'),
              title: GoalCopy.titles[goal]!,
              subtitle: GoalCopy.subtitles[goal]!,
              icon: _icons[goal]!,
              selected: _selected == goal,
              // Selecting is not a toggle: tapping the chosen card again
              // leaves it chosen rather than dropping back to no answer and
              // silently disabling the CTA.
              onTap: () => setState(() => _selected = goal),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  void _onNext() =>
      context.push('/onboarding/4', extra: widget.partial.withGoal(_selected!));
}
