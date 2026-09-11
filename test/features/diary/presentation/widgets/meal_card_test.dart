import 'package:fantastic/features/diary/domain/models/macro_source.dart';
import 'package:fantastic/features/diary/domain/models/meal_entry.dart';
import 'package:fantastic/features/diary/presentation/macro_source_copy.dart';
import 'package:fantastic/features/diary/presentation/widgets/meal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/meal_entry_fixture.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  const badge = Key('meal_card_source_badge');

  /// No provider override anywhere in this file, deliberately: `MealCard`
  /// takes the entry it renders and must keep doing so.
  Future<void> pumpCard(WidgetTester tester, MealEntry meal) =>
      pumpApp(tester, MealCard(meal: meal));

  group('the badge', () {
    // Most meals are typed, and a badge on every card is a badge nobody
    // reads. Manual entry is also the whole milestone's regression surface.
    testWidgets('a manual meal shows none at all', (tester) async {
      await pumpCard(tester, MealEntryFixture.fixture());

      expect(find.byKey(badge), findsNothing);
    });

    testWidgets('an estimate from text is marked as an estimate', (
      tester,
    ) async {
      await pumpCard(tester, MealEntryFixture.estimated());

      expect(find.byKey(badge), findsOneWidget);
      expect(
        find.text(MacroSource.estimatedFromText.badgeLabel!),
        findsOneWidget,
      );
    });

    testWidgets('an estimate from a photo carries the same label', (
      tester,
    ) async {
      await pumpCard(
        tester,
        MealEntryFixture.estimated(source: MacroSource.estimatedFromPhoto),
      );

      expect(find.text('הערכה'), findsOneWidget);
    });

    testWidgets('a scanned label says it was read, not guessed', (
      tester,
    ) async {
      await pumpCard(
        tester,
        MealEntryFixture.fixture(source: MacroSource.scannedLabel),
      );

      expect(find.text('מתווית'), findsOneWidget);
    });

    // The marker is the difference between a figure that was read and one
    // that was guessed, so it is meaningful rather than decorative. Asserted
    // through the semantics tree, not the render tree.
    testWidgets('is announced to a screen reader', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCard(tester, MealEntryFixture.estimated());

      expect(
        find.bySemanticsLabel(MacroSource.estimatedFromText.badgeDescription!),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('a photo estimate is announced differently from a text one', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpCard(
        tester,
        MealEntryFixture.estimated(source: MacroSource.estimatedFromPhoto),
      );

      expect(
        find.bySemanticsLabel('הערכים חושבו מתמונת הארוחה'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('הערכים חושבו מתיאור הארוחה'), findsNothing);
      handle.dispose();
    });
  });

  group('layout', () {
    // A long meal name plus a badge is the overflow case, and the smallest
    // phone at the largest text scale is where it bites.
    testWidgets('does not overflow at 320px with a doubled text scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpApp(
        tester,
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MealCard(
            meal: MealEntryFixture.estimated().copyWith(
              mealName: 'ארוחה ' * 20,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('the badge sits beside the macro summary, not over it', (
      tester,
    ) async {
      await pumpCard(tester, MealEntryFixture.estimated());

      final summary = tester.getRect(find.textContaining('שומן'));
      final marker = tester.getRect(find.byKey(badge));

      expect(summary.overlaps(marker), isFalse);
    });

    // RTL: the summary comes first, so it starts on the right and the badge
    // follows to its left. Asserted against what is painted, the rule
    // `design/m5_handoff.md` records.
    testWidgets('lays the badge out to the left of the summary under RTL', (
      tester,
    ) async {
      await pumpCard(tester, MealEntryFixture.estimated());

      expect(
        tester.getCenter(find.byKey(badge)).dx,
        lessThan(tester.getCenter(find.textContaining('שומן')).dx),
      );
    });
  });

  group('what the badge must not change', () {
    testWidgets('the macro summary is unchanged on an estimated meal', (
      tester,
    ) async {
      await pumpCard(tester, MealEntryFixture.estimated());

      expect(find.text('שומן 20 · פחמימות 5 · חלבון 15'), findsOneWidget);
    });

    testWidgets('the time still renders left-to-right', (tester) async {
      await pumpCard(tester, MealEntryFixture.estimated());

      final time = tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere((t) => t.textDirection == TextDirection.ltr);
      expect(time.data, matches(RegExp(r'^\d{2}:\d{2}$')));
    });

    testWidgets('the meal name still renders', (tester) async {
      await pumpCard(tester, MealEntryFixture.estimated());

      expect(find.text('שקשוקה'), findsOneWidget);
    });
  });
}
