import 'package:fantastic/features/diary/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

/// F7 (#99) — five scales logged from the dashboard, read back in the diary.
///
/// **Every score is distinct.** M5's audit found four issues naming a field
/// the model has never had, and an all-3s fixture that would have hidden a
/// mood score under a brain-fog label. Five identical scores here would
/// prove nothing about which scale went where.
const Map<String, int> _scores = {
  'energy': 5,
  'clarity': 4,
  'hunger': 2,
  'physical': 3,
  'mood': 1,
};

void main() {
  testWidgets('five scales logged on the dashboard appear in the diary', (
    tester,
  ) async {
    final app = await bootApp(onboarded: true);
    await pumpApp(tester, app);

    // The strip is below the fold on the dashboard.
    await scrollDown(tester);
    await tapAt(tester, find.byKey(const Key('symptom_cell_energy')));

    // Score chips, not sliders — #99 drives a control this sheet has never
    // had (`design/m8_preflight.md` §2.5).
    for (final entry in _scores.entries) {
      await tapAt(tester, find.byKey(Key('score_${entry.key}_${entry.value}')));
    }
    await enterInto(tester, 'symptom_notes_field', 'יום טוב');
    await tapAt(tester, find.byKey(const Key('save_symptoms_button')));

    // Stored, per scale, with the note the user typed — the save that M5's
    // audit caught silently erasing it.
    final log = await app.container
        .read(symptomLogRepositoryProvider)
        .findByDate(DateTime.now());
    expect(log, isNotNull);
    expect(log!.energyScore, 5);
    expect(log.clarityScore, 4);
    expect(log.hungerScore, 2);
    expect(log.physicalScore, 3);
    expect(log.moodScore, 1);
    expect(log.notes, 'יום טוב');

    // And readable in the diary, which is a different screen reading the
    // same day.
    await goToTab(tester, 'tab_diary');
    for (final scale in _scores.keys) {
      expect(find.byKey(Key('symptom_chip_$scale')), findsOneWidget);
    }
    expect(
      find.descendant(
        of: find.byKey(const Key('symptom_chip_mood')),
        matching: find.text('1'),
      ),
      findsOneWidget,
      reason: 'the mood chip must carry mood\'s score, not another scale\'s',
    );
  });

  testWidgets('a past date shows its own day, not today', (tester) async {
    final app = await bootApp(onboarded: true);
    await pumpApp(tester, app);

    // Log today's symptoms.
    await scrollDown(tester);
    await tapAt(tester, find.byKey(const Key('symptom_cell_energy')));
    await tapAt(tester, find.byKey(const Key('score_energy_5')));
    await tapAt(tester, find.byKey(const Key('save_symptoms_button')));

    await goToTab(tester, 'tab_diary');
    expect(find.byKey(const Key('symptom_chip_energy')), findsOneWidget);

    // Yesterday has nothing in it. A day with no log and a day that failed
    // to load must not look alike (`design/m5_handoff.md`), so assert the
    // empty state by name rather than by the absence of chips.
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    await tapAt(
      tester,
      find.byKey(
        Key('date_chip_${yesterday.year}_${yesterday.month}_${yesterday.day}'),
      ),
    );

    expect(find.byKey(const Key('symptom_chip_energy')), findsNothing);
    expect(find.text('לא הוקלטו תסמינים'), findsOneWidget);
  });
}
