import 'package:fantastic/features/adaptation/data/providers.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/adaptation/presentation/widgets/streak_ring_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

/// F5 (#97) — a compliant day drives the adaptation state machine.
void main() {
  testWidgets('a compliant day takes the streak to 1 and stays in phase 1', (
    tester,
  ) async {
    final app = await bootApp(onboarded: true);
    await pumpApp(tester, app);

    // Day zero.
    expect(
      find.descendant(
        of: find.byType(StreakRingWidget),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );

    // Fat 50, net carbs 2, protein 3 → ratio 10.0, comfortably compliant.
    await tapAt(tester, find.byKey(const Key('add_meal_fab')));
    await enterInto(tester, 'meal_name_field', 'אבוקדו וחמאה');
    await enterInto(tester, 'fat_field', '50');
    await enterInto(tester, 'carbs_field', '2');
    await enterInto(tester, 'protein_field', '3');
    await tapAt(tester, find.byKey(const Key('save_meal_button')));

    // Scoped to the ring: a dashboard full of macro numbers has plenty of
    // other `1`s, which is why #97's bare `find.text('1')` cannot work.
    expect(
      find.descendant(
        of: find.byType(StreakRingWidget),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(find.text('שלב ההסתגלות'), findsOneWidget);

    final streak = await app.container.read(streakRepositoryProvider).load();
    expect(streak!.currentStreak, 1);
    expect(streak.phase, AdaptationPhase.induction);
    expect(streak.inGracePeriod, isFalse);
  });

  testWidgets('a second meal on the same day does not increment again', (
    tester,
  ) async {
    final app = await bootApp(onboarded: true);
    await pumpApp(tester, app);

    for (final name in ['ארוחה ראשונה', 'ארוחה שנייה']) {
      await tapAt(tester, find.byKey(const Key('add_meal_fab')));
      await enterInto(tester, 'meal_name_field', name);
      await enterInto(tester, 'fat_field', '40');
      await enterInto(tester, 'carbs_field', '2');
      await enterInto(tester, 'protein_field', '5');
      await tapAt(tester, find.byKey(const Key('save_meal_button')));
    }

    // The streak counts days, not meals — the defect `m3_preflight.md` §1.2
    // caught in the issue text, asserted here through the UI that would
    // show it.
    final streak = await app.container.read(streakRepositoryProvider).load();
    expect(streak!.currentStreak, 1);
    expect(
      find.descendant(
        of: find.byType(StreakRingWidget),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });
}
