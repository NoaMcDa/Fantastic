import 'package:fantastic/core/constants/electrolyte_constants.dart';
import 'package:fantastic/core/constants/phase_copy.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/adaptation/presentation/widgets/phase_description_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, AdaptationPhase phase) =>
      pumpApp(tester, PhaseDescriptionCard(phase: phase));

  group('copy', () {
    testWidgets('induction shows its own description', (tester) async {
      await pumpCard(tester, AdaptationPhase.induction);

      expect(
        find.text(PhaseCopy.descriptions[AdaptationPhase.induction]!),
        findsOneWidget,
      );
    });

    testWidgets('deep ketosis shows different copy', (tester) async {
      await pumpCard(tester, AdaptationPhase.deepKetosis);

      expect(
        find.text(PhaseCopy.descriptions[AdaptationPhase.deepKetosis]!),
        findsOneWidget,
      );
      expect(
        find.text(PhaseCopy.descriptions[AdaptationPhase.induction]!),
        findsNothing,
      );
    });

    // Guards the maps against a phase being added to the enum and forgotten
    // here — the widget would then throw on a null assertion at runtime.
    test('every phase has a name, a range, a summary and a description', () {
      for (final phase in AdaptationPhase.values) {
        expect(PhaseCopy.names[phase], isNotNull, reason: '$phase name');
        expect(PhaseCopy.dayRanges[phase], isNotNull, reason: '$phase range');
        expect(PhaseCopy.summaries[phase], isNotNull, reason: '$phase summary');
        expect(
          PhaseCopy.descriptions[phase],
          isNotNull,
          reason: '$phase description',
        );
      }
    });

    // The ranges must agree with AdaptationPhaseService's thresholds (8 and
    // 28) — see design/m3_preflight.md §1.4. The issue's own copy said
    // "8–28" and "29+", which disagreed with its own code on both ends.
    test('the day ranges match the service thresholds', () {
      expect(PhaseCopy.dayRanges[AdaptationPhase.induction], contains('1–7'));
      expect(PhaseCopy.dayRanges[AdaptationPhase.fatAdapted], contains('8–27'));
      expect(PhaseCopy.dayRanges[AdaptationPhase.deepKetosis], contains('28'));
    });
  });

  group('electrolyte targets', () {
    testWidgets('names all three minerals', (tester) async {
      await pumpCard(tester, AdaptationPhase.induction);

      expect(find.text('נתרן'), findsOneWidget);
      expect(find.text('אשלגן'), findsOneWidget);
      expect(find.text('מגנזיום'), findsOneWidget);
    });

    // Induction carries the highest sodium target, because glycogen depletion
    // drives rapid sodium excretion. If this row ever shows the later
    // phases' numbers the card is advising the wrong phase.
    testWidgets('induction shows the phase 1 sodium range', (tester) async {
      await pumpCard(tester, AdaptationPhase.induction);

      expect(find.text('3,000–5,000 מ״ג'), findsOneWidget);
    });

    testWidgets('fat adapted shows the lower phase 2/3 range', (tester) async {
      await pumpCard(tester, AdaptationPhase.fatAdapted);

      expect(find.text('2,000–3,000 מ״ג'), findsOneWidget);
      expect(find.text('3,000–5,000 מ״ג'), findsNothing);
    });

    testWidgets('deep ketosis shares the phase 2/3 range', (tester) async {
      await pumpCard(tester, AdaptationPhase.deepKetosis);

      expect(find.text('2,000–3,000 מ״ג'), findsOneWidget);
    });

    // The rendered figures must be the constants, not numbers typed into the
    // widget — that is the whole reason the card reads ElectrolyteConstants
    // rather than carrying a copy of the table.
    testWidgets('the figures come from ElectrolyteConstants', (tester) async {
      await pumpCard(tester, AdaptationPhase.induction);

      final magnesium =
          '${ElectrolyteConstants.phase1MagnesiumMinMg.round()}–'
          '${ElectrolyteConstants.phase1MagnesiumMaxMg.round()} מ״ג';
      expect(find.text(magnesium), findsOneWidget);
    });

    // A digit run inside the RTL layout renders reversed without a direction
    // of its own — '3,000–5,000' would come out backwards.
    testWidgets('ranges are laid out left-to-right', (tester) async {
      await pumpCard(tester, AdaptationPhase.induction);

      expect(
        tester.widget<Text>(find.text('3,000–5,000 מ״ג')).textDirection,
        TextDirection.ltr,
      );
    });
  });

  testWidgets('renders without overflowing a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpCard(tester, AdaptationPhase.induction);

    expect(tester.takeException(), isNull);
  });
}
