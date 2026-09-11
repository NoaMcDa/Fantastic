import 'package:fantastic/core/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('renders the icon, headline and subtitle', (tester) async {
    await pumpApp(
      tester,
      const EmptyStateWidget(
        icon: Icons.inbox_outlined,
        headline: 'אין נתונים',
        subtitle: 'הוסיפו רשומה כדי להתחיל',
      ),
    );

    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    expect(find.text('אין נתונים'), findsOneWidget);
    expect(find.text('הוסיפו רשומה כדי להתחיל'), findsOneWidget);
  });

  // Not every empty state has a second line to say. Requiring one would mean
  // inventing user-visible copy for the symptom section inside a refactor.
  testWidgets('omits the subtitle when none is given', (tester) async {
    await pumpApp(
      tester,
      const EmptyStateWidget(
        icon: Icons.inbox_outlined,
        headline: 'אין נתונים',
      ),
    );

    expect(find.text('אין נתונים'), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('renders the action when one is given', (tester) async {
    await pumpApp(
      tester,
      EmptyStateWidget(
        icon: Icons.inbox_outlined,
        headline: 'אין נתונים',
        action: TextButton(
          key: const Key('cta'),
          onPressed: () {},
          child: const Text('הוסף'),
        ),
      ),
    );

    expect(find.byKey(const Key('cta')), findsOneWidget);
  });

  // `EmptyMealsState` relies on this: the screen's FAB is the action, and a
  // second button would compete with it.
  testWidgets('renders no action when none is given', (tester) async {
    await pumpApp(
      tester,
      const EmptyStateWidget(
        icon: Icons.inbox_outlined,
        headline: 'אין נתונים',
      ),
    );

    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  // The text beside it already carries the meaning; announcing the icon too
  // would say it twice.
  testWidgets('the icon is excluded from semantics', (tester) async {
    await pumpApp(
      tester,
      const EmptyStateWidget(
        icon: Icons.inbox_outlined,
        headline: 'אין נתונים',
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.inbox_outlined));
    expect(icon.semanticLabel, isNull);
  });

  // Hardcoded greys vanish against the dark-mode-first palette.
  testWidgets('takes its colours from the theme, not a literal grey', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const EmptyStateWidget(
        icon: Icons.inbox_outlined,
        headline: 'אין נתונים',
        subtitle: 'הוסיפו רשומה כדי להתחיל',
      ),
    );

    final context = tester.element(find.byType(EmptyStateWidget));
    final expected = Theme.of(context).colorScheme.onSurfaceVariant;

    final icon = tester.widget<Icon>(find.byIcon(Icons.inbox_outlined));
    expect(icon.color, expected);
    expect(icon.color, isNot(Colors.grey));

    final subtitle = tester.widget<Text>(find.text('הוסיפו רשומה כדי להתחיל'));
    expect(subtitle.style?.color, expected);
  });

  testWidgets('a long headline wraps rather than overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(
      tester,
      const EmptyStateWidget(
        icon: Icons.inbox_outlined,
        headline: 'כותרת ארוכה מאוד שאמורה לעבור לשורה הבאה ולא לגלוש',
        subtitle: 'שורה שנייה ארוכה גם היא כדי לבדוק את הפריסה הצרה',
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders right-to-left', (tester) async {
    await pumpApp(
      tester,
      const EmptyStateWidget(
        icon: Icons.inbox_outlined,
        headline: 'אין נתונים',
      ),
    );

    expect(
      Directionality.of(tester.element(find.text('אין נתונים'))),
      TextDirection.rtl,
    );
  });
}
