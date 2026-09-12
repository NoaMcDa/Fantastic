import 'package:fantastic/core/constants/goal_copy.dart';
import 'package:fantastic/features/onboarding/domain/models/keto_goal.dart';
import 'package:fantastic/features/onboarding/domain/models/onboarding_data.dart';
import 'package:fantastic/features/onboarding/presentation/widgets/goal_card.dart';
import 'package:fantastic/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Step 3 of 4 — what the user wants keto to do for them.
///
/// **Multi-select, at least one.** The three reasons people start keto are
/// not exclusive: somebody can want to lose weight and train well, and M4's
/// radio group made them drop one — after which the profile tab showed them
/// half of what they said. Two of the three now change the arithmetic, so
/// this is not only a label: weight loss applies the TDEE deficit and
/// athletic performance raises the net-carb target.
///
/// The CTA stays disabled until at least one card is chosen: there is no
/// sensible default, and pre-selecting one would record a preference the user
/// never expressed.
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
  final Set<KetoGoal> _selected = <KetoGoal>{};

  static const Map<KetoGoal, IconData> _icons = {
    KetoGoal.weightLoss: Icons.monitor_weight_outlined,
    KetoGoal.metabolicHealth: Icons.favorite_outline,
    KetoGoal.athleticPerformance: Icons.directions_run,
  };

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 3,
      title: 'מה המטרות שלכם?',
      ctaLabel: 'הבא',
      onNext: _selected.isEmpty ? null : _onNext,
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              GoalCopy.pickMoreThanOneHint,
              key: const Key('goal_multi_select_hint'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final goal in GoalCopy.order) ...[
            GoalCard(
              key: Key('goal_${goal.name}'),
              title: GoalCopy.titles[goal]!,
              subtitle: GoalCopy.subtitles[goal]!,
              icon: _icons[goal]!,
              selected: _selected.contains(goal),
              // A toggle, now that the group is multi-select: tapping a
              // chosen card takes it back out. Deselecting the last one
              // disables the CTA rather than committing an empty set, which
              // [OnboardingData] asserts against anyway.
              onTap: () => setState(
                () => _selected.contains(goal)
                    ? _selected.remove(goal)
                    : _selected.add(goal),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  // A copy, not the live set: this screen keeps mutating `_selected` as the
  // user taps, and `OnboardingData` seals what it is given.
  void _onNext() => context.push(
    '/onboarding/4',
    extra: widget.partial.withGoals(Set.of(_selected)),
  );
}
