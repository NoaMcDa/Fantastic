import 'package:fantastic/core/constants/menu_copy.dart';
import 'package:fantastic/features/menu/domain/models/analysed_dish.dart';
import 'package:fantastic/features/menu/domain/models/dish_verdict.dart';
import 'package:fantastic/features/menu/presentation/widgets/dish_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/analysed_dish_fixture.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  Key whyKeyFor(String name) => Key('dish_why_$name');
  Key modificationKeyFor(String name) => Key('dish_modification_$name');
  Key copyKeyFor(String name) => Key('dish_copy_instruction_$name');
  Key cardKeyFor(String name) => Key('dish_card_$name');

  group('DishCard collapsed', () {
    testWidgets('shows the name and badge, and not the why', (tester) async {
      final dish = AnalysedDishFixture.orderAsIs(name: 'סטייק אנטריקוט');

      await pumpApp(tester, DishCard(dish: dish));

      expect(find.text(dish.name), findsOneWidget);
      expect(find.text('אפשר להזמין'), findsOneWidget);
      expect(find.byKey(whyKeyFor(dish.name)), findsNothing);
    });

    testWidgets('shows the description when present', (tester) async {
      final dish = AnalysedDishFixture.orderAsIs(
        name: 'סלט יווני',
        description: 'עגבניות, מלפפון, פטה וזיתים',
      );

      await pumpApp(tester, DishCard(dish: dish));

      expect(find.text(dish.description!), findsOneWidget);
    });

    testWidgets('a modifiable dish shows the first line of its instruction', (
      tester,
    ) async {
      final dish = AnalysedDishFixture.modifiable(
        name: 'המבורגר',
        modification: 'שורה ראשונה\nשורה שנייה',
      );

      await pumpApp(tester, DishCard(dish: dish));

      expect(find.text('שורה ראשונה'), findsOneWidget);
      expect(find.text('שורה שנייה'), findsNothing);
    });

    testWidgets('a green dish shows no instruction preview', (tester) async {
      final dish = AnalysedDishFixture.orderAsIs(name: 'סטייק');

      await pumpApp(tester, DishCard(dish: dish));

      expect(find.byIcon(Icons.copy), findsNothing);
    });

    testWidgets('a red dish shows no instruction preview', (tester) async {
      final dish = AnalysedDishFixture.nonKeto(name: 'פיצה');

      await pumpApp(tester, DishCard(dish: dish));

      expect(find.byIcon(Icons.copy), findsNothing);
    });
  });

  group('DishCard expand and collapse', () {
    testWidgets('tapping the card reveals the why, tapping again hides it', (
      tester,
    ) async {
      final dish = AnalysedDishFixture.orderAsIs(name: 'סלמון בחמאה');

      await pumpApp(tester, DishCard(dish: dish));
      expect(find.byKey(whyKeyFor(dish.name)), findsNothing);

      await tester.tap(find.byKey(cardKeyFor(dish.name)));
      await tester.pumpAndSettle();

      expect(find.byKey(whyKeyFor(dish.name)), findsOneWidget);
      expect(find.text(dish.why), findsOneWidget);

      await tester.tap(find.byKey(cardKeyFor(dish.name)));
      await tester.pumpAndSettle();

      expect(find.byKey(whyKeyFor(dish.name)), findsNothing);
    });

    testWidgets('starts expanded when initiallyExpanded is true', (
      tester,
    ) async {
      final dish = AnalysedDishFixture.orderAsIs(name: 'עוף בגריל');

      await pumpApp(tester, DishCard(dish: dish, initiallyExpanded: true));

      expect(find.byKey(whyKeyFor(dish.name)), findsOneWidget);
    });

    testWidgets(
      'a modifiable dish shows the full instruction and a copy button when '
      'expanded',
      (tester) async {
        final dish = AnalysedDishFixture.modifiable(name: 'המבורגר עם צ׳יפס');

        await pumpApp(tester, DishCard(dish: dish));
        await tester.tap(find.byKey(cardKeyFor(dish.name)));
        await tester.pumpAndSettle();

        expect(find.text(MenuCopy.modificationHeading), findsOneWidget);
        expect(find.byKey(modificationKeyFor(dish.name)), findsOneWidget);
        expect(find.text(dish.modification!), findsOneWidget);
        expect(find.byKey(copyKeyFor(dish.name)), findsOneWidget);
      },
    );

    testWidgets('a green dish renders no instruction heading when expanded', (
      tester,
    ) async {
      final dish = AnalysedDishFixture.orderAsIs(name: 'סטייק');

      await pumpApp(tester, DishCard(dish: dish));
      await tester.tap(find.byKey(cardKeyFor(dish.name)));
      await tester.pumpAndSettle();

      expect(find.text(MenuCopy.modificationHeading), findsNothing);
      expect(find.byKey(copyKeyFor(dish.name)), findsNothing);
    });

    testWidgets('a red dish renders no instruction heading when expanded', (
      tester,
    ) async {
      final dish = AnalysedDishFixture.nonKeto(name: 'פסטה');

      await pumpApp(tester, DishCard(dish: dish));
      await tester.tap(find.byKey(cardKeyFor(dish.name)));
      await tester.pumpAndSettle();

      expect(find.text(MenuCopy.modificationHeading), findsNothing);
      expect(find.byKey(copyKeyFor(dish.name)), findsNothing);
    });

    testWidgets(
      'a modifiable fixture with a null modification renders no empty '
      'heading',
      (tester) async {
        const dish = AnalysedDish(
          name: 'מנה עמומה',
          verdict: DishVerdict.modifiable,
          why: 'הטקסט לא הכיל הוראה תקפה',
        );

        await pumpApp(
          tester,
          const DishCard(dish: dish, initiallyExpanded: true),
        );

        expect(find.text(MenuCopy.modificationHeading), findsNothing);
        expect(find.byKey(modificationKeyFor(dish.name)), findsNothing);
        expect(find.byKey(copyKeyFor(dish.name)), findsNothing);
        // The why still renders — only the instruction block is withheld.
        expect(find.byKey(whyKeyFor(dish.name)), findsOneWidget);
      },
    );
  });

  group('DishCard copy button', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    tearDown(() {
      TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets(
      'writes the instruction to the clipboard and shows the confirmation',
      (tester) async {
        final calls = <MethodCall>[];
        TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              calls.add(call);
              return null;
            });

        final dish = AnalysedDishFixture.modifiable(name: 'סביח');

        await pumpApp(tester, DishCard(dish: dish));
        await tester.tap(find.byKey(cardKeyFor(dish.name)));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(copyKeyFor(dish.name)));
        await tester.pumpAndSettle();

        final clipboardCall = calls.singleWhere(
          (call) => call.method == 'Clipboard.setData',
        );
        expect((clipboardCall.arguments as Map)['text'], dish.modification);
        expect(find.text(MenuCopy.copiedConfirmation), findsOneWidget);
      },
    );
  });

  group('DishCard layout', () {
    testWidgets('the tap target is at least 44 pt high', (tester) async {
      final dish = AnalysedDishFixture.orderAsIs(name: 'ביצים מקושקשות');

      await pumpApp(tester, DishCard(dish: dish));

      final size = tester.getSize(find.byKey(cardKeyFor(dish.name)));
      expect(size.height, greaterThanOrEqualTo(44));
    });

    testWidgets('renders under RTL', (tester) async {
      final dish = AnalysedDishFixture.orderAsIs(name: 'שקשוקה');

      await pumpApp(tester, DishCard(dish: dish));

      final directionality = tester.widget<Directionality>(
        find.byType(Directionality).first,
      );
      expect(directionality.textDirection, TextDirection.rtl);
      expect(find.text(dish.name), findsOneWidget);
    });

    testWidgets('a 300-character why wraps without overflow at 360px', (
      tester,
    ) async {
      final dish = AnalysedDishFixture.orderAsIs(
        name: 'מנה עם תיאור ארוך',
        why: 'א' * 300,
      );

      await pumpApp(
        tester,
        SizedBox(
          width: 360,
          child: DishCard(dish: dish, initiallyExpanded: true),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(whyKeyFor(dish.name)), findsOneWidget);
    });
  });
}
