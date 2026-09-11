import 'package:fantastic/core/constants/add_meal_copy.dart';
import 'package:fantastic/features/diary/domain/models/estimated_item.dart';
import 'package:fantastic/features/diary/presentation/widgets/estimate_review_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  const egg = EstimatedItem(
    name: 'ביצה',
    grams: 100,
    fatG: 10,
    netCarbsG: 1,
    proteinG: 13,
  );
  const chicken = EstimatedItem(
    name: 'חזה עוף',
    grams: 200,
    fatG: 6,
    netCarbsG: 0,
    proteinG: 46,
  );

  Future<void> pumpList(
    WidgetTester tester, {
    List<EstimatedItem> items = const [egg, chicken],
    List<String> unidentified = const [],
    ValueChanged<int>? onRemove,
  }) => pumpApp(
    tester,
    SingleChildScrollView(
      child: EstimateReviewList(
        items: items,
        unidentified: unidentified,
        onRemove: onRemove ?? (_) {},
      ),
    ),
  );

  group('items', () {
    testWidgets('renders one row per item, named', (tester) async {
      await pumpList(tester);

      expect(find.byKey(const Key('estimate_item_0')), findsOneWidget);
      expect(find.byKey(const Key('estimate_item_1')), findsOneWidget);
      expect(find.text('ביצה'), findsOneWidget);
      expect(find.text('חזה עוף'), findsOneWidget);
    });

    // A user who disagrees with an estimate almost always disagrees with the
    // *weight*, so the weight has to be on screen.
    testWidgets('shows each item weight and its three macros', (tester) async {
      await pumpList(tester, items: const [egg]);

      expect(
        find.text('100 גרם · שומן 10 · פחמימות 1 · חלבון 13'),
        findsOneWidget,
      );
    });

    testWidgets('every row has a remove control', (tester) async {
      await pumpList(tester);

      expect(find.byKey(const Key('estimate_item_remove_0')), findsOneWidget);
      expect(find.byKey(const Key('estimate_item_remove_1')), findsOneWidget);
    });

    testWidgets('removing reports the index tapped', (tester) async {
      final removed = <int>[];
      await pumpList(tester, onRemove: removed.add);

      await tester.tap(find.byKey(const Key('estimate_item_remove_1')));
      await tester.pumpAndSettle();

      expect(removed, [1]);
    });
  });

  group('the total', () {
    testWidgets('is summed over the items on screen', (tester) async {
      await pumpList(tester);

      expect(find.text('שומן 16 · פחמימות 1 · חלבון 59'), findsOneWidget);
    });

    // #257's rule: the number in front of the user when they save is the
    // number that gets saved.
    testWidgets('follows the list when an item is dropped', (tester) async {
      await pumpList(tester, items: const [egg]);

      expect(find.text('שומן 10 · פחמימות 1 · חלבון 13'), findsOneWidget);
    });

    testWidgets('is zero on an empty list rather than absent', (tester) async {
      await pumpList(tester, items: const []);

      expect(find.byKey(const Key('estimate_total_row')), findsOneWidget);
      expect(find.text('שומן 0 · פחמימות 0 · חלבון 0'), findsOneWidget);
    });

    // The defect `design/m8_preflight.md` recorded from the scan prefill.
    testWidgets('never renders floating-point noise', (tester) async {
      await pumpList(
        tester,
        items: const [
          EstimatedItem(
            name: 'שמן',
            grams: 2,
            fatG: 0.1,
            netCarbsG: 0.08,
            proteinG: 0,
          ),
        ],
      );

      expect(find.textContaining('0.17999999999999988'), findsNothing);
      expect(find.text('שומן 0.1 · פחמימות 0.1 · חלבון 0'), findsOneWidget);
    });
  });

  group('unidentified tokens', () {
    // A silently ignored `לחם` turns a 40 g-carb meal into a 2 g one and the
    // day still reads compliant.
    testWidgets('are shown in the list, not hidden', (tester) async {
      await pumpList(tester, unidentified: const ['לחם', 'רוטב']);

      expect(find.text('לחם'), findsOneWidget);
      expect(find.text('רוטב'), findsOneWidget);
    });

    testWidgets('are marked as unidentified', (tester) async {
      await pumpList(tester, unidentified: const ['לחם']);

      expect(find.text(AddMealCopy.unidentifiedMarker), findsOneWidget);
    });

    testWidgets('warn that they are excluded from the total', (tester) async {
      await pumpList(tester, unidentified: const ['לחם']);

      expect(
        find.byKey(const Key('estimate_unidentified_warning')),
        findsOneWidget,
      );
    });

    testWidgets('there is no warning when everything was identified', (
      tester,
    ) async {
      await pumpList(tester);

      expect(
        find.byKey(const Key('estimate_unidentified_warning')),
        findsNothing,
      );
    });

    testWidgets('are not behind an expander', (tester) async {
      await pumpList(tester, unidentified: const ['לחם']);

      expect(find.byType(ExpansionTile), findsNothing);
    });
  });

  group('layout', () {
    testWidgets('does not overflow a narrow screen', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpList(
        tester,
        items: const [
          EstimatedItem(
            name: 'סלט ירקות עם גבינת פטה וזיתים ושמן זית',
            grams: 350,
            fatG: 22.5,
            netCarbsG: 8.25,
            proteinG: 9,
          ),
        ],
      );

      expect(tester.takeException(), isNull);
    });

    // Without this the grams and the three macros are reordered inside the
    // RTL layout.
    testWidgets('digit runs are forced left-to-right', (tester) async {
      await pumpList(tester, items: const [egg]);

      final detail = tester.widget<Text>(
        find.text('100 גרם · שומן 10 · פחמימות 1 · חלבון 13'),
      );
      expect(detail.textDirection, TextDirection.ltr);
    });

    testWidgets('settles — nothing animates forever', (tester) async {
      await pumpList(tester);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pumpAndSettle();
    });
  });
}
