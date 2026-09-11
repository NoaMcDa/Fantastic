import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/diary/application/meal_logging_service.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_bottom_sheet.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class _MockMealLoggingService extends Mock implements MealLoggingService {}

void main() {
  final date = DateTime(2026, 9, 11);

  late _MockMealLoggingService loggingService;

  setUp(() => loggingService = _MockMealLoggingService());

  /// Pumped inside a `Scaffold` of its own, because that is the only place a
  /// `FloatingActionButton` is laid out — `pumpApp` supplies one.
  Future<void> pumpFab(WidgetTester tester, {DateTime? on}) => pumpApp(
    tester,
    Builder(
      builder: (context) =>
          Scaffold(floatingActionButton: AddMealFab(date: on ?? date)),
    ),
    overrides: [mealLoggingServiceProvider.overrideWithValue(loggingService)],
  );

  testWidgets('renders a + icon', (tester) async {
    await pumpFab(tester);

    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('opens the add-meal sheet for the date it was given', (
    tester,
  ) async {
    await pumpFab(tester);

    await tester.tap(find.byType(AddMealFab));
    await tester.pumpAndSettle();

    final sheet = tester.widget<AddMealBottomSheet>(
      find.byType(AddMealBottomSheet),
    );
    expect(sheet.date, date);
  });

  testWidgets('passes a past date straight through', (tester) async {
    final past = DateTime(2026, 9, 1);
    await pumpFab(tester, on: past);

    await tester.tap(find.byType(AddMealFab));
    await tester.pumpAndSettle();

    expect(
      tester.widget<AddMealBottomSheet>(find.byType(AddMealBottomSheet)).date,
      past,
    );
  });

  // Apple's HIG minimum, and the reason the standard FAB size is kept rather
  // than shrunk to fit a denser layout.
  testWidgets('meets the 44pt minimum touch target', (tester) async {
    await pumpFab(tester);

    final size = tester.getSize(find.byType(AddMealFab));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  // Named rather than inherited: it renders gold today only because
  // `ColorScheme.dark`'s `primaryContainer` falls back to `primary`. A colour
  // scheme change must not be able to take the contrast off the one control
  // the whole tracker depends on.
  testWidgets('uses the accent colour explicitly', (tester) async {
    await pumpFab(tester);

    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(fab.backgroundColor, AppTheme.accent);
    expect(fab.foregroundColor, AppTheme.primary);
  });

  testWidgets('announces itself in Hebrew', (tester) async {
    await pumpFab(tester);

    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(fab.tooltip, 'הוספת ארוחה');
  });
}
