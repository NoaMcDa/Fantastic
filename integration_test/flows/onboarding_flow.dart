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

    // **The targets are not on screen yet, and that is what the app does.**
    // `MacroSummaryCard` renders `EmptyMealsState` whenever the day has no
    // `DailyLog`, so a user who has just agreed to a set of targets sees
    // none of them until the first meal is logged. Epic #8's Definition of
    // Done — "dashboard macro targets match what onboarding set" — is
    // therefore only observable from the second screen onwards. Asserted
    // rather than skipped: if someone later makes the card show targets on
    // an empty day, this line fails and the change is deliberate.
    expect(find.text('לא נרשמו ארוחות להיום'), findsOneWidget);
    expect(find.textContaining('/149ג׳'), findsNothing);

    // One meal, and the numbers onboarding computed drive the card — 149,
    // not `MacroTargets.defaults`. This is the assertion #95 is actually
    // for, and the one its own plan does not make.
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
