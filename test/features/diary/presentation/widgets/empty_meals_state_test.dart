import 'package:fantastic/core/widgets/app_illustration.dart';
import 'package:fantastic/features/diary/presentation/widgets/empty_meals_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('shows the headline', (tester) async {
    await pumpApp(tester, const EmptyMealsState());

    expect(find.text('לא נרשמו ארוחות להיום'), findsOneWidget);
  });

  testWidgets('shows the prompt pointing at the FAB', (tester) async {
    await pumpApp(tester, const EmptyMealsState());

    expect(find.text('הקש על + כדי להוסיף ארוחה'), findsOneWidget);
  });

  // The drawing replaces the icon rather than joining it; the icon stays on
  // the call as the fallback `EmptyStateWidget` renders without one.
  testWidgets('draws the empty plate in place of an icon', (tester) async {
    await pumpApp(tester, const EmptyMealsState());

    expect(find.byType(EmptyPlateIllustration), findsOneWidget);
    expect(find.byIcon(Icons.restaurant_menu_outlined), findsNothing);
  });

  // The parent screen's FAB is the action. A button here would compete with it.
  testWidgets('offers no button of its own', (tester) async {
    await pumpApp(tester, const EmptyMealsState());

    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  // Hardcoded greys vanish against the dark-mode-first palette.
  testWidgets('takes its colours from the theme, not literals', (tester) async {
    await pumpApp(tester, const EmptyMealsState());

    final context = tester.element(find.byType(EmptyMealsState));
    final expected = Theme.of(context).colorScheme.onSurfaceVariant;

    final illustration = tester.widget<EmptyPlateIllustration>(
      find.byType(EmptyPlateIllustration),
    );
    expect(illustration.color, expected);

    final subtitle = tester.widget<Text>(
      find.text('הקש על + כדי להוסיף ארוחה'),
    );
    expect(subtitle.style?.color, expected);
  });

  testWidgets('lays out without overflowing a narrow screen', (tester) async {
    // Hebrew strings are long and a 320pt phone is the narrowest target.
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpApp(tester, const EmptyMealsState());

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders right-to-left', (tester) async {
    await pumpApp(tester, const EmptyMealsState());

    expect(
      Directionality.of(tester.element(find.byType(EmptyMealsState))),
      TextDirection.rtl,
    );
  });
}
