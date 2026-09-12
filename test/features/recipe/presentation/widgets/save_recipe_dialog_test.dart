import 'package:fantastic/core/constants/recipe_copy.dart';
import 'package:fantastic/features/recipe/presentation/widgets/save_recipe_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  /// Pumps a screen with a button that opens the dialog and stashes its
  /// eventual result in [captured] — `late` because the `Future` is only
  /// created once the button is tapped, but the test needs a handle on it
  /// before the dialog closes.
  Future<void> openDialog(
    WidgetTester tester, {
    String? initialTitle,
    required void Function(Future<String?> result) captured,
  }) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => captured(
            SaveRecipeDialog.show(context, initialTitle: initialTitle),
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('save is disabled on an empty title', (tester) async {
    await openDialog(tester, captured: (_) {});

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('recipe_title_save_button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('save stays disabled on a whitespace-only title', (tester) async {
    await openDialog(tester, captured: (_) {});

    await tester.enterText(find.byKey(const Key('recipe_title_field')), '   ');
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('recipe_title_save_button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('resolves to the trimmed title', (tester) async {
    late Future<String?> result;
    await openDialog(tester, captured: (future) => result = future);

    await tester.enterText(
      find.byKey(const Key('recipe_title_field')),
      '  פשטידת כרובית  ',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('recipe_title_save_button')));
    await tester.pumpAndSettle();

    expect(await result, 'פשטידת כרובית');
  });

  testWidgets('cancel resolves to null', (tester) async {
    late Future<String?> result;
    await openDialog(tester, captured: (future) => result = future);

    await tester.enterText(
      find.byKey(const Key('recipe_title_field')),
      'שם כלשהו',
    );
    await tester.pump();
    await tester.tap(find.text(RecipeCopy.cancel));
    await tester.pumpAndSettle();

    expect(await result, isNull);
  });

  testWidgets('seeds the field from initialTitle', (tester) async {
    await openDialog(tester, initialTitle: 'שם קיים', captured: (_) {});

    final field = tester.widget<TextField>(
      find.byKey(const Key('recipe_title_field')),
    );
    expect(field.controller!.text, 'שם קיים');

    // And the seeded title alone is enough to enable save, without typing.
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('recipe_title_save_button')),
    );
    expect(button.onPressed, isNotNull);
  });
}
