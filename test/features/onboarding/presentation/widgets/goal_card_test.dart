import 'package:fantastic/core/constants/goal_copy.dart';
import 'package:fantastic/features/onboarding/domain/models/keto_goal.dart';
import 'package:fantastic/features/onboarding/presentation/widgets/goal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

  // A card in a multi-select group is a checkbox whatever it is drawn as, and
  // saying so is what tells a screen reader that choosing this one does not
  // un-choose the others. It announced `inMutuallyExclusiveGroup` while the
  // group was single-select; that would now describe behaviour the screen no
  // longer has.
  // `SemanticsProperties` comes from `package:flutter/semantics.dart`,
  // which `material.dart` does not re-export.
  SemanticsProperties cardSemantics(WidgetTester tester) => tester
      .widget<Semantics>(
        find
            .descendant(
              of: find.byType(GoalCard),
              matching: find.byType(Semantics),
            )
            .first,
      )
      .properties;

  testWidgets('announces itself as a checked, selected option', (tester) async {
    await pumpCard(tester, selected: true);

    final properties = cardSemantics(tester);
    expect(properties.checked, isTrue);
    expect(properties.selected, isTrue);
    expect(properties.inMutuallyExclusiveGroup, isNot(isTrue));
  });

  testWidgets('an unselected card announces itself unchecked', (tester) async {
    await pumpCard(tester, selected: false);

    final properties = cardSemantics(tester);
    expect(properties.checked, isFalse);
    expect(properties.selected, isFalse);
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
