import 'package:fantastic/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('renders the dashboard tab at the initial route', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FantasticApp()));
    await tester.pumpAndSettle();

    expect(find.text('בית'), findsOneWidget);
  });

  testWidgets('every one of the 5 tab routes navigates without error', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FantasticApp()));
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.text('בית')));

    const routesAndLabels = {
      '/': 'בית',
      '/lens': 'מצלמה',
      '/diary': 'יומן',
      '/adaptation': 'התאמה',
      '/profile': 'פרופיל',
    };

    for (final entry in routesAndLabels.entries) {
      router.go(entry.key);
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
    }
  });

  testWidgets('an unknown route falls through to the error screen, not a '
      'crash', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FantasticApp()));
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.text('בית')));
    router.go('/does-not-exist');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
