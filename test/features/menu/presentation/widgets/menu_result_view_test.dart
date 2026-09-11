import 'package:fantastic/core/constants/menu_copy.dart';
import 'package:fantastic/core/constants/menu_verdict_rules.dart';
import 'package:fantastic/features/menu/domain/models/analysed_dish.dart';
import 'package:fantastic/features/menu/domain/models/dish_verdict.dart';
import 'package:fantastic/features/menu/domain/models/menu_analysis.dart';
import 'package:fantastic/features/menu/presentation/widgets/dish_verdict_badge.dart';
import 'package:fantastic/features/menu/presentation/widgets/menu_result_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/analysed_dish_fixture.dart';
import '../../../../fixtures/menu_analysis_fixture.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  Key cardKeyFor(String name) => Key('dish_card_$name');
  const redHeaderKey = Key('menu_red_header');
  const legendKey = Key('menu_legend');
  const unreadPagesKey = Key('menu_unread_pages');
  const unclassifiedKey = Key('menu_unclassified');
  const noDishesNoteKey = Key('menu_no_dishes_note');
  const orderAsIsHeadingKey = Key('menu_orderAsIs_heading');
  const modifiableHeadingKey = Key('menu_modifiable_heading');

  /// The `'(N)'` count `Text` inside the widget found under [key], as
  /// [MenuResultView] renders every count as its own `Text` separate from
  /// the label beside it.
  String countTextIn(WidgetTester tester, Key key) {
    final texts = tester
        .widgetList<Text>(
          find.descendant(of: find.byKey(key), matching: find.byType(Text)),
        )
        .where((text) => text.data?.startsWith('(') ?? false);
    return texts.single.data!;
  }

  MenuAnalysed analysisOf({
    List<AnalysedDish>? dishes,
    List<String> unclassified = const [],
    List<int> unreadPages = const [],
  }) => MenuAnalysisFixture.analysed(
    withDishes: dishes,
    unclassified: unclassified,
    unreadPages: unreadPages,
  );

  group('MenuResultView sections', () {
    testWidgets(
      'renders green then yellow rows, then the collapsed red header with '
      'the right count',
      (tester) async {
        final analysis = analysisOf();
        final green = analysis.withVerdict(DishVerdict.orderAsIs).single;
        final yellow = analysis.withVerdict(DishVerdict.modifiable).single;
        final red = analysis.withVerdict(DishVerdict.nonKeto).single;

        await pumpApp(tester, MenuResultView(analysis: analysis));

        expect(find.text(green.name), findsOneWidget);
        expect(find.text(yellow.name), findsOneWidget);
        expect(find.byKey(redHeaderKey), findsOneWidget);
        expect(countTextIn(tester, redHeaderKey), '(1)');
        // Collapsed by default: the red dish itself is not in the tree.
        expect(find.byKey(cardKeyFor(red.name)), findsNothing);
      },
    );

    testWidgets(
      'tapping the red header reveals the red DishCards, tapping again '
      'hides them',
      (tester) async {
        final analysis = analysisOf();
        final red = analysis.withVerdict(DishVerdict.nonKeto).single;

        await pumpApp(tester, MenuResultView(analysis: analysis));
        expect(find.byKey(cardKeyFor(red.name)), findsNothing);

        await tester.tap(find.byKey(redHeaderKey));
        await tester.pumpAndSettle();
        expect(find.byKey(cardKeyFor(red.name)), findsOneWidget);
        expect(find.text(red.name), findsOneWidget);

        await tester.tap(find.byKey(redHeaderKey));
        await tester.pumpAndSettle();
        expect(find.byKey(cardKeyFor(red.name)), findsNothing);
      },
    );

    testWidgets('starts expanded when redInitiallyExpanded is true', (
      tester,
    ) async {
      final analysis = analysisOf();
      final red = analysis.withVerdict(DishVerdict.nonKeto).single;

      await pumpApp(
        tester,
        MenuResultView(analysis: analysis, redInitiallyExpanded: true),
      );

      expect(find.byKey(cardKeyFor(red.name)), findsOneWidget);
    });

    testWidgets('the legend renders three badges with three definitions', (
      tester,
    ) async {
      await pumpApp(tester, MenuResultView(analysis: analysisOf()));

      expect(find.byKey(legendKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(legendKey),
          matching: find.byType(DishVerdictBadge),
        ),
        findsNWidgets(3),
      );
      for (final verdict in DishVerdict.values) {
        expect(
          find.text(MenuVerdictRules.definitions[verdict]!),
          findsOneWidget,
        );
      }
    });
  });

  group('MenuResultView edge cases', () {
    testWidgets('no red dishes means no red header at all', (tester) async {
      final analysis = analysisOf(
        dishes: [
          AnalysedDishFixture.orderAsIs(),
          AnalysedDishFixture.modifiable(),
        ],
      );

      await pumpApp(tester, MenuResultView(analysis: analysis));

      expect(find.byKey(redHeaderKey), findsNothing);
    });

    testWidgets('no green dishes means no green heading', (tester) async {
      final analysis = analysisOf(
        dishes: [
          AnalysedDishFixture.modifiable(),
          AnalysedDishFixture.nonKeto(),
        ],
      );

      await pumpApp(tester, MenuResultView(analysis: analysis));

      expect(find.byKey(orderAsIsHeadingKey), findsNothing);
      // The yellow heading is unaffected.
      expect(find.byKey(modifiableHeadingKey), findsOneWidget);
    });

    testWidgets('no yellow dishes means no yellow heading', (tester) async {
      final analysis = analysisOf(
        dishes: [
          AnalysedDishFixture.orderAsIs(),
          AnalysedDishFixture.nonKeto(),
        ],
      );

      await pumpApp(tester, MenuResultView(analysis: analysis));

      expect(find.byKey(modifiableHeadingKey), findsNothing);
      expect(find.byKey(orderAsIsHeadingKey), findsOneWidget);
    });

    testWidgets('unreadPages: [3] names page 3 as a warning line', (
      tester,
    ) async {
      final analysis = analysisOf(
        dishes: MenuAnalysisFixture.dishes(),
        unreadPages: const [3],
      );

      await pumpApp(tester, MenuResultView(analysis: analysis));

      expect(find.byKey(unreadPagesKey), findsOneWidget);
      expect(find.text('עמוד 3 לא נקרא — נסו לצלם שוב'), findsOneWidget);
    });

    testWidgets('several unread pages are joined with ו-', (tester) async {
      final analysis = analysisOf(
        dishes: MenuAnalysisFixture.dishes(),
        unreadPages: const [4, 2],
      );

      await pumpApp(tester, MenuResultView(analysis: analysis));

      expect(find.text('עמודים 2 ו-4 לא נקראו — נסו לצלם שוב'), findsOneWidget);
    });

    testWidgets('unreadPages: [] shows no warning line', (tester) async {
      final analysis = analysisOf(dishes: MenuAnalysisFixture.dishes());

      await pumpApp(tester, MenuResultView(analysis: analysis));

      expect(find.byKey(unreadPagesKey), findsNothing);
    });

    testWidgets(
      'dishes: [] and unclassified: [x] shows the explanatory line and the '
      'unclassified section, not an empty-list state',
      (tester) async {
        final analysis = analysisOf(
          dishes: const [],
          unclassified: const ['מנת היום'],
        );

        await pumpApp(tester, MenuResultView(analysis: analysis));

        expect(find.byKey(noDishesNoteKey), findsOneWidget);
        expect(find.text(MenuCopy.noDishesClassifiedNote), findsOneWidget);
        expect(find.byKey(unclassifiedKey), findsOneWidget);
        expect(find.text('מנת היום'), findsOneWidget);
        expect(find.byKey(orderAsIsHeadingKey), findsNothing);
        expect(find.byKey(modifiableHeadingKey), findsNothing);
        expect(find.byKey(redHeaderKey), findsNothing);
      },
    );

    testWidgets('no unclassified names means no unclassified section', (
      tester,
    ) async {
      final analysis = analysisOf(dishes: MenuAnalysisFixture.dishes());

      await pumpApp(tester, MenuResultView(analysis: analysis));

      expect(find.byKey(unclassifiedKey), findsNothing);
      expect(find.byKey(noDishesNoteKey), findsNothing);
    });

    testWidgets('unclassified names render as plain rows with no badge', (
      tester,
    ) async {
      final analysis = analysisOf(
        dishes: MenuAnalysisFixture.dishes(),
        unclassified: const ['מנת היום', 'תוספת חצי'],
      );

      await pumpApp(tester, MenuResultView(analysis: analysis));

      expect(find.text('מנת היום'), findsOneWidget);
      expect(find.text('תוספת חצי'), findsOneWidget);
      expect(countTextIn(tester, unclassifiedKey), '(2)');
    });
  });

  group('MenuResultView scrolling', () {
    testWidgets('forty dishes scroll, and a card below the fold is '
        'reachable after scrolling', (tester) async {
      final dishes = List.generate(
        40,
        (i) => AnalysedDishFixture.orderAsIs(name: 'מנה מספר $i'),
      );
      final lastDish = dishes.last;

      await pumpApp(
        tester,
        MenuResultView(analysis: analysisOf(dishes: dishes)),
      );

      expect(find.byKey(cardKeyFor(lastDish.name)), findsNothing);

      await tester.scrollUntilVisible(
        find.byKey(cardKeyFor(lastDish.name)),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.byKey(cardKeyFor(lastDish.name)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('MenuResultView RTL and counts', () {
    testWidgets('renders under RTL with counts LTR', (tester) async {
      final analysis = analysisOf();

      await pumpApp(tester, MenuResultView(analysis: analysis));

      final directionality = tester.widget<Directionality>(
        find.byType(Directionality).first,
      );
      expect(directionality.textDirection, TextDirection.rtl);

      final countText = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(orderAsIsHeadingKey),
              matching: find.byType(Text),
            ),
          )
          .firstWhere((text) => text.data?.startsWith('(') ?? false);
      expect(countText.textDirection, TextDirection.ltr);
    });
  });
}
