import 'package:fantastic/features/onboarding/data/providers.dart';
import 'package:fantastic/features/onboarding/domain/models/activity_level.dart';
import 'package:fantastic/features/onboarding/domain/models/keto_goal.dart';
import 'package:fantastic/features/onboarding/domain/models/macro_targets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

/// F1 (#95) and F2 — the first launch, and the second one.
void main() {
  testWidgets('a first launch walks the flow and lands on seeded targets', (
    tester,
  ) async {
    final app = await bootApp();
    await pumpApp(tester, app);

    // A fresh install opens on the flow, not on the dashboard.
    expect(find.text('ברוכים הבאים ל-Fantastic'), findsOneWidget);
    await tapAt(tester, find.byKey(const Key('onboarding_cta')));

    // Screen 2 — who the user is.
    await tapAt(tester, find.byKey(const Key('sex_male')));
    await enterInto(tester, 'age_field', '30');
    await enterInto(tester, 'weight_field', '80');
    await enterInto(tester, 'height_field', '175');
    // How active an ordinary day is. The flow asked nothing here until #431
    // and multiplied every BMR by the sedentary 1.2.
    await tapAt(tester, find.byKey(const Key('activity_moderate')));
    await tapAt(tester, find.byKey(const Key('onboarding_cta')));

    // Screen 3 — the goals, plural since #431. Two of them, which M4's radio
    // group could not express.
    expect(find.text('מה המטרות שלכם?'), findsOneWidget);
    await tapAt(tester, find.byKey(const Key('goal_weightLoss')));
    await tapAt(tester, find.byKey(const Key('goal_athleticPerformance')));
    await tapAt(tester, find.byKey(const Key('onboarding_cta')));

    // Screen 4 — the targets Mifflin-St Jeor produced for those answers.
    // Asserted as exact numbers, not as "non-zero": the whole point of the
    // flow is that the arithmetic reached the screen intact.
    //
    // BMR 1748.75 at moderate (1.55) is 2710.56 kcal, less the 20% weight-loss
    // deficit is 2168.45. The carb target is 25 rather than 20: moderate
    // starts at 25, athletic performance would add 5, and the weight-loss cap
    // holds it at 25 — which is the two goals interacting, not one of them
    // winning outright.
    expect(find.text('היעדים שלכם'), findsOneWidget);
    expect(fieldText(tester, 'fat_target_field'), '201');
    expect(fieldText(tester, 'carbs_target_field'), '25');
    expect(fieldText(tester, 'protein_target_field'), '64');
    await tapAt(tester, find.byKey(const Key('onboarding_cta')));

    // The dashboard.
    expect(find.byType(NavigationBar), findsOneWidget);

    // **The targets are on screen before anything is logged**, which is what
    // Epic #8's Definition of Done means by "dashboard macro targets match
    // what onboarding set" — and it has only been true from the dashboard's
    // first paint since #301. This flow previously asserted the opposite, on
    // purpose, with a comment explaining that the numbers a user had just
    // agreed to were invisible until their first meal.
    //
    // Both, not one: the nothing-logged message stays, because zeroed bars
    // without it read as "you are failing every target" rather than "there is
    // no data yet".
    expect(find.text('לא נרשמו ארוחות להיום'), findsOneWidget);
    expect(find.textContaining('/201ג׳'), findsOneWidget);

    // And the streak seeded at day zero, phase 1. Below the fold rather than
    // on it since the macro card grew a training-day chip, and a sliver child
    // below the fold has no element at all — so this scrolls rather than
    // asserting on a scroll offset that happens to hold today.
    await scrollDown(tester);
    expect(find.text('שלב ההסתגלות'), findsOneWidget);
    await scrollDown(tester, pixels: -400);

    // One meal, and the card switches from zeros to logged values against the
    // same targets — 201, not `MacroTargets.defaults`.
    await openAddMeal(tester);
    await enterInto(tester, 'meal_name_field', 'ביצה קשה');
    await enterInto(tester, 'fat_field', '5');
    await enterInto(tester, 'carbs_field', '1');
    await enterInto(tester, 'protein_field', '6');
    await tapAt(tester, find.byKey(const Key('save_meal_button')));
    expect(find.textContaining('/201ג׳'), findsOneWidget);
    expect(find.textContaining('/64ג׳'), findsOneWidget);

    // Marking today as a training day raises the fat target and nothing else.
    // Moderate steps up to active: 1748.75 × 0.175 is 306 kcal, less the same
    // 20% deficit is 245, which is 27 g of fat on top of the 201.
    await tapAt(tester, find.byKey(const Key('training_day_chip')));
    expect(find.textContaining('/228ג׳'), findsOneWidget);
    expect(find.textContaining('/25ג׳'), findsOneWidget);
    expect(find.textContaining('/64ג׳'), findsOneWidget);

    // Unmarking puts it back — the flag is stored, not a one-way door.
    await tapAt(tester, find.byKey(const Key('training_day_chip')));
    expect(find.textContaining('/201ג׳'), findsOneWidget);

    // The profile really is on disk, not just in a provider.
    final stored = await app.container
        .read(userProfileRepositoryProvider)
        .load();
    expect(stored, isNotNull);
    expect(stored!.targets.fatG, 201);
    expect(stored.goals, {KetoGoal.weightLoss, KetoGoal.athleticPerformance});
    expect(stored.activityLevel, ActivityLevel.moderate);
  });

  // #262. `design/mvp.md` §4 promised a skippable flow; M4 shipped a gate
  // with no way past it.
  testWidgets('a skipped first launch reaches the dashboard on defaults', (
    tester,
  ) async {
    final app = await bootApp();
    await pumpApp(tester, app);

    expect(find.text('ברוכים הבאים ל-Fantastic'), findsOneWidget);
    await tapAt(tester, find.byKey(const Key('onboarding_skip')));

    // Past the gate, on the generic targets the skip warned about.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      find.textContaining(
        '/${MacroTargets.defaults.fatG.toStringAsFixed(0)}ג׳',
      ),
      findsOneWidget,
    );

    // A skip is a *completed* install, not an ungated one: the record is on
    // disk, so the next launch does not ask again.
    final stored = await app.container
        .read(userProfileRepositoryProvider)
        .load();
    expect(stored, isNotNull);
    expect(stored!.hasBiometrics, isFalse);
    expect(stored.goals, isEmpty);

    await relaunchApp(tester, app);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('ברוכים הבאים ל-Fantastic'), findsNothing);
  });

  testWidgets('the second launch goes straight to the dashboard', (
    tester,
  ) async {
    final first = await bootApp(onboarded: true);
    await pumpApp(tester, first);
    expect(find.byType(NavigationBar), findsOneWidget);

    // Same storage, a new container and a new app — a relaunch, not a
    // rebuild. Epic #8's Definition of Done names this and no child issue
    // covers it; M4's audit found the flow's own last screen bouncing the
    // user back into onboarding forever.
    await relaunchApp(tester, first);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('ברוכים הבאים ל-Fantastic'), findsNothing);
  });
}
