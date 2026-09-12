import 'package:fantastic/core/constants/goal_copy.dart';
import 'package:fantastic/features/onboarding/domain/models/keto_goal.dart';
import 'package:fantastic/features/onboarding/domain/models/onboarding_data.dart';
import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen3.dart';
import 'package:fantastic/features/onboarding/presentation/widgets/goal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_onboarding.dart';

void main() {
  final partial = UserProfileFixture.partial(
    age: 41,
    weightKg: 91.2,
    ketoStartDate: UserProfileFixture.defaultKetoStartDate,
  );

  Future<void> pumpScreen(WidgetTester tester) =>
      pumpOnboarding(tester, OnboardingScreen3(partial: partial));

  List<GoalCard> cards(WidgetTester tester) =>
      tester.widgetList<GoalCard>(find.byType(GoalCard)).toList();

  FilledButton cta(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets('renders one card per goal, with its Hebrew copy', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(cards(tester), hasLength(KetoGoal.values.length));
    for (final goal in KetoGoal.values) {
      expect(find.text(GoalCopy.titles[goal]!), findsOneWidget);
      expect(find.text(GoalCopy.subtitles[goal]!), findsOneWidget);
    }
  });

  // There is no sensible default goal, and pre-selecting one would record a
  // preference the user never expressed.
  testWidgets('starts with nothing selected and the CTA disabled', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(cards(tester).any((card) => card.selected), isFalse);
    expect(cta(tester).onPressed, isNull);
  });

  testWidgets('tapping a card selects it and enables the CTA', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text(GoalCopy.titles[KetoGoal.weightLoss]!));
    await tester.pumpAndSettle();

    expect(cta(tester).onPressed, isNotNull);
  });

  // The point of #431's fourth bullet: the three reasons people start keto
  // are not exclusive, and the radio group made somebody who wanted two drop
  // one.
  testWidgets('a second choice adds to the first', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text(GoalCopy.titles[KetoGoal.weightLoss]!));
    await tester.pumpAndSettle();
    await tester.tap(find.text(GoalCopy.titles[KetoGoal.metabolicHealth]!));
    await tester.pumpAndSettle();

    expect(cards(tester).where((card) => card.selected), hasLength(2));
    expect(cta(tester).onPressed, isNotNull);
  });

  testWidgets('every goal can be chosen at once', (tester) async {
    await pumpScreen(tester);

    for (final goal in KetoGoal.values) {
      await tester.tap(find.text(GoalCopy.titles[goal]!));
      await tester.pumpAndSettle();
    }

    expect(
      cards(tester).where((card) => card.selected),
      hasLength(KetoGoal.values.length),
    );
  });

  // A toggle now, unlike the radio group it replaces.
  testWidgets('tapping a selected card deselects it', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text(GoalCopy.titles[KetoGoal.weightLoss]!));
    await tester.pumpAndSettle();
    await tester.tap(find.text(GoalCopy.titles[KetoGoal.metabolicHealth]!));
    await tester.pumpAndSettle();
    await tester.tap(find.text(GoalCopy.titles[KetoGoal.weightLoss]!));
    await tester.pumpAndSettle();

    expect(cards(tester).where((card) => card.selected), hasLength(1));
    expect(
      cards(tester).where((card) => card.selected).single.title,
      GoalCopy.titles[KetoGoal.metabolicHealth],
    );
  });

  // Deselecting the last one must disable the CTA rather than let an empty
  // set reach `OnboardingData`, which asserts against it.
  testWidgets('deselecting the last goal disables the CTA', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text(GoalCopy.titles[KetoGoal.weightLoss]!));
    await tester.pumpAndSettle();
    expect(cta(tester).onPressed, isNotNull);

    await tester.tap(find.text(GoalCopy.titles[KetoGoal.weightLoss]!));
    await tester.pumpAndSettle();

    expect(cards(tester).any((card) => card.selected), isFalse);
    expect(cta(tester).onPressed, isNull);
  });

  testWidgets('says that more than one goal may be chosen', (tester) async {
    await pumpScreen(tester);

    expect(find.text(GoalCopy.pickMoreThanOneHint), findsOneWidget);
  });

  testWidgets('a disabled CTA does not navigate', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('הבא'));
    await tester.pumpAndSettle();

    expect(lastPushedLocation, isNull);
  });

  group('navigation', () {
    testWidgets('carries the completed data to step 4', (tester) async {
      await pumpScreen(tester);

      await tester.tap(
        find.text(GoalCopy.titles[KetoGoal.athleticPerformance]!),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('הבא'));
      await tester.pumpAndSettle();

      expect(lastPushedLocation, '/onboarding/4');
      final data = lastPushedExtra! as OnboardingData;
      expect(data.goals, {KetoGoal.athleticPerformance});
    });

    testWidgets('carries every chosen goal to step 4', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text(GoalCopy.titles[KetoGoal.weightLoss]!));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(GoalCopy.titles[KetoGoal.athleticPerformance]!),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('הבא'));
      await tester.pumpAndSettle();

      expect((lastPushedExtra! as OnboardingData).goals, {
        KetoGoal.weightLoss,
        KetoGoal.athleticPerformance,
      });
    });

    // Screen 2's answers must survive the hop, including the start date the
    // streak seed depends on.
    testWidgets('every screen-2 answer survives', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text(GoalCopy.titles[KetoGoal.weightLoss]!));
      await tester.pumpAndSettle();
      await tester.tap(find.text('הבא'));
      await tester.pumpAndSettle();

      final data = lastPushedExtra! as OnboardingData;
      expect(data.age, 41);
      expect(data.weightKg, 91.2);
      expect(data.sex, partial.sex);
      expect(data.ketoStartDate, UserProfileFixture.defaultKetoStartDate);
    });
  });

  testWidgets('lays out without overflowing a short screen', (tester) async {
    tester.view.physicalSize = const Size(360, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpScreen(tester);

    expect(tester.takeException(), isNull);
  });
}
