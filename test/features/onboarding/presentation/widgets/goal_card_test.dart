import 'package:fantastic/core/constants/goal_copy.dart';
import 'package:fantastic/features/onboarding/domain/models/keto_goal.dart';
import 'package:fantastic/features/onboarding/presentation/widgets/goal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required bool selected,
    VoidCallback? onTap,
  }) => pumpApp(
    tester,
    GoalCard(
      title: 'ירידה במשקל',
      subtitle: 'שריפת שומן תוך שמירה על מסת שריר',
      icon: Icons.monitor_weight_outlined,
      selected: selected,
      onTap: onTap ?? () {},
    ),
  );

  testWidgets('renders its title, subtitle and icon', (tester) async {
    await pumpCard(tester, selected: false);

    expect(find.text('ירידה במשקל'), findsOneWidget);
    expect(find.text('שריפת שומן תוך שמירה על מסת שריר'), findsOneWidget);
    expect(find.byIcon(Icons.monitor_weight_outlined), findsOneWidget);
  });

  testWidgets('shows a check only when selected', (tester) async {
    await pumpCard(tester, selected: false);
    expect(find.byIcon(Icons.check_circle), findsNothing);

    await pumpCard(tester, selected: true);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('reports the tap', (tester) async {
    var taps = 0;
    await pumpCard(tester, selected: false, onTap: () => taps++);

    await tester.tap(find.byType(GoalCard));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  // Three mutually exclusive cards are a radio group whatever they are drawn
  // as. Without this a screen reader announces three unrelated buttons and
  // never says which one is chosen.
  testWidgets('announces itself as a selected radio option', (tester) async {
    await pumpCard(tester, selected: true);

    final semantics = tester.widget<Semantics>(
      find
          .descendant(
            of: find.byType(GoalCard),
            matching: find.byType(Semantics),
          )
          .first,
    );

    expect(semantics.properties.inMutuallyExclusiveGroup, isTrue);
    expect(semantics.properties.selected, isTrue);
  });

  // A missing entry is a `!` on a null inside the screen, and two goals
  // sharing a title would make the screen's own finders ambiguous.
  group('GoalCopy', () {
    test('every KetoGoal has a title and a subtitle', () {
      for (final goal in KetoGoal.values) {
        expect(GoalCopy.titles[goal], isNotNull, reason: 'title for $goal');
        expect(
          GoalCopy.subtitles[goal],
          isNotNull,
          reason: 'subtitle for $goal',
        );
      }
    });

    test('the display order covers every goal exactly once', () {
      expect(GoalCopy.order.toSet(), KetoGoal.values.toSet());
      expect(GoalCopy.order, hasLength(KetoGoal.values.length));
    });

    test('no two goals share a title', () {
      expect(GoalCopy.titles.values.toSet(), hasLength(GoalCopy.titles.length));
    });
  });
}
