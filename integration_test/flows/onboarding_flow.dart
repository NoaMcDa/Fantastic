import 'package:fantastic/features/onboarding/data/providers.dart';
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
    await tapAt(tester, find.byKey(const Key('onboarding_cta')));

    // Screen 3 — the goal.
    expect(find.text('מה המטרה שלכם?'), findsOneWidget);
    await tapAt(tester, find.byKey(const Key('goal_weightLoss')));
    await tapAt(tester, find.byKey(const Key('onboarding_cta')));

    // Screen 4 — the targets Mifflin-St Jeor produced for those answers.
    // Asserted as exact numbers, not as "non-zero": the whole point of the
    // flow is that the arithmetic reached the screen intact.
    expect(find.text('היעדים שלכם'), findsOneWidget);
    expect(fieldText(tester, 'fat_target_field'), '149');
    expect(fieldText(tester, 'carbs_target_field'), '20');
    expect(fieldText(tester, 'protein_target_field'), '64');
    await tapAt(tester, find.byKey(const Key('onboarding_cta')));

    // The dashboard.
    expect(find.byType(NavigationBar), findsOneWidget);

    // And the streak seeded at day zero, phase 1.
    expect(find.text('שלב ההסתגלות'), findsOneWidget);

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
    expect(find.textContaining('/149ג׳'), findsOneWidget);

    // One meal, and the card switches from zeros to logged values against the
    // same targets — 149, not `MacroTargets.defaults`.
    await tapAt(tester, find.byKey(const Key('add_meal_fab')));
    await enterInto(tester, 'meal_name_field', 'ביצה קשה');
    await enterInto(tester, 'fat_field', '5');
    await enterInto(tester, 'carbs_field', '1');
    await enterInto(tester, 'protein_field', '6');
    await tapAt(tester, find.byKey(const Key('save_meal_button')));
    expect(find.textContaining('/149ג׳'), findsOneWidget);
    expect(find.textContaining('/64ג׳'), findsOneWidget);

    // The profile really is on disk, not just in a provider.
    final stored = await app.container
        .read(userProfileRepositoryProvider)
        .load();
    expect(stored, isNotNull);
    expect(stored!.targets.fatG, 149);
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
