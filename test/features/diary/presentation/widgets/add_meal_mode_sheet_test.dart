import 'package:fantastic/core/constants/add_meal_copy.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_mode_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  /// Pumps a button that opens the chooser and records what it resolved to.
  ///
  /// Driven through `show` rather than by pumping the widget directly,
  /// because `show`'s `Navigator.pop(context, mode)` wiring is half of what
  /// this widget is — a sheet that renders three tiles and returns nothing
  /// would pass a test of its tiles alone.
  Future<List<AddMealMode?>> pumpChooser(WidgetTester tester) async {
    final chosen = <AddMealMode?>[];
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              key: const Key('open'),
              onPressed: () async =>
                  chosen.add(await AddMealModeSheet.show(context)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    return chosen;
  }

  testWidgets('renders all three modes with their keys', (tester) async {
    await pumpChooser(tester);

    expect(find.byKey(const Key('add_meal_mode_manual')), findsOneWidget);
    expect(find.byKey(const Key('add_meal_mode_description')), findsOneWidget);
    expect(find.byKey(const Key('add_meal_mode_photo')), findsOneWidget);
  });

  // Manual first: it is the path that has shipped since M2, and the one a
  // returning user reaches for without reading.
  testWidgets('orders them manual, description, photo', (tester) async {
    await pumpChooser(tester);

    final manual = tester
        .getTopLeft(find.byKey(const Key('add_meal_mode_manual')))
        .dy;
    final description = tester
        .getTopLeft(find.byKey(const Key('add_meal_mode_description')))
        .dy;
    final photo = tester
        .getTopLeft(find.byKey(const Key('add_meal_mode_photo')))
        .dy;

    expect(manual, lessThan(description));
    expect(description, lessThan(photo));
  });

  testWidgets('each mode carries a subtitle saying what it does', (
    tester,
  ) async {
    await pumpChooser(tester);

    expect(find.text(AddMealCopy.manualSubtitle), findsOneWidget);
    expect(find.text(AddMealCopy.descriptionSubtitle), findsOneWidget);
    expect(find.text(AddMealCopy.photoSubtitle), findsOneWidget);
  });

  for (final (key, mode) in <(String, AddMealMode)>[
    ('add_meal_mode_manual', AddMealMode.manual),
    ('add_meal_mode_description', AddMealMode.description),
    ('add_meal_mode_photo', AddMealMode.photo),
  ]) {
    testWidgets('tapping $key resolves to ${mode.name}', (tester) async {
      final chosen = await pumpChooser(tester);

      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();

      expect(chosen, [mode]);
    });
  }

  testWidgets('dismissing resolves to null, not to a mode', (tester) async {
    final chosen = await pumpChooser(tester);

    // Tapping the barrier is how a user actually dismisses a modal sheet.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(chosen, [null]);
  });

  // Apple's HIG minimum. Asserted on all three rather than one, because the
  // tiles are built by the same helper and a regression would hit whichever
  // one a future change touched.
  testWidgets('every tile meets the 44pt minimum touch target', (tester) async {
    await pumpChooser(tester);

    for (final key in const [
      'add_meal_mode_manual',
      'add_meal_mode_description',
      'add_meal_mode_photo',
    ]) {
      expect(
        tester.getSize(find.byKey(Key(key))).height,
        greaterThanOrEqualTo(44),
        reason: key,
      );
    }
  });

  testWidgets('lays out right-to-left', (tester) async {
    await pumpChooser(tester);

    // The leading icon of an RTL `ListTile` sits on the *right*. Asserted
    // against what is painted rather than against a `TextDirection` field,
    // the rule `design/m5_handoff.md` records.
    final tile = tester.getRect(find.byKey(const Key('add_meal_mode_manual')));
    final icon = tester.getCenter(
      find.descendant(
        of: find.byKey(const Key('add_meal_mode_manual')),
        matching: find.byIcon(Icons.edit_outlined),
      ),
    );

    expect(icon.dx, greaterThan(tile.center.dx));
  });

  testWidgets('settles — nothing here animates forever', (tester) async {
    await pumpChooser(tester);

    // A sheet reachable from a tab screen that never settles hangs
    // `widget_test.dart` (`design/m6_handoff.md`).
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpAndSettle();
  });
}
