import 'dart:async';

import 'package:fantastic/features/diary/application/meal_logging_service.dart';
import 'package:fantastic/features/diary/application/providers/meal_providers.dart';
import 'package:fantastic/features/diary/domain/models/meal_entry.dart';
import 'package:fantastic/features/diary/presentation/widgets/meal_card.dart';
import 'package:fantastic/features/diary/presentation/widgets/meal_list_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

class _MockMealLoggingService extends Mock implements MealLoggingService {}

void main() {
  final date = MealEntryFixture.defaultTimestamp;
  late _MockMealLoggingService loggingService;

  /// The meals the provider currently serves.
  ///
  /// Mutable, and the mocked `deleteMeal` removes from it, because that is
  /// what production does: the section invalidates the provider after a
  /// delete, the refetch hits a repository the row is gone from, and the row
  /// leaves the tree. A fixed list would keep handing the dismissed row back,
  /// and `Dismissible` asserts that a dismissed child is actually removed.
  late List<MealEntry> stored;

  setUp(() {
    stored = [];
    loggingService = _MockMealLoggingService();
    when(() => loggingService.deleteMeal(any(), any()))
        .thenAnswer((invocation) async {
          final id = invocation.positionalArguments.first as int;
          stored = stored.where((m) => m.id != id).toList();
        });
  });

  Future<void> pumpSection(
    WidgetTester tester, {
    required List<MealEntry> meals,
  }) {
    stored = meals;
    return pumpApp(
      tester,
      MealListSection(date: date),
      overrides: [
        todaysMealsProvider(date).overrideWith((ref) async => stored),
        mealLoggingServiceProvider.overrideWithValue(loggingService),
      ],
    );
  }

  group('rendering', () {
    testWidgets('renders one card per meal', (tester) async {
      await pumpSection(
        tester,
        meals: [
          MealEntryFixture.fixture(id: 1, mealName: 'Breakfast'),
          MealEntryFixture.fixture(id: 2, mealName: 'Lunch'),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byType(MealCard), findsNWidgets(2));
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
    });

    testWidgets('an empty day renders nothing, without crashing', (
      tester,
    ) async {
      await pumpSection(tester, meals: []);
      await tester.pumpAndSettle();

      expect(find.byType(MealCard), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows each meal macros and time', (tester) async {
      await pumpSection(
        tester,
        meals: [
          MealEntryFixture.fixture(
            id: 1,
            fatG: 20,
            netCarbsG: 5,
            proteinG: 15,
            timestamp: DateTime(2026, 9, 9, 19, 30),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('שומן 20 · פחמימות 5 · חלבון 15'), findsOneWidget);
      expect(find.text('19:30'), findsOneWidget);
    });

    testWidgets('zero-pads a single-digit time', (tester) async {
      await pumpSection(
        tester,
        meals: [
          MealEntryFixture.fixture(
            id: 1,
            timestamp: DateTime(2026, 9, 9, 8, 5),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('08:05'), findsOneWidget);
    });

    testWidgets('shows a spinner while loading', (tester) async {
      await pumpApp(
        tester,
        MealListSection(date: date),
        overrides: [
          todaysMealsProvider(date)
              .overrideWith((ref) => Completer<List<MealEntry>>().future),
          mealLoggingServiceProvider.overrideWithValue(loggingService),
        ],
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // An empty list and a failed load look identical otherwise.
    testWidgets('a failed load says so rather than rendering nothing', (
      tester,
    ) async {
      await pumpApp(
        tester,
        MealListSection(date: date),
        overrides: [
          todaysMealsProvider(date)
              .overrideWith((ref) async => throw Exception('disk gone')),
          mealLoggingServiceProvider.overrideWithValue(loggingService),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('לא ניתן לטעון את הארוחות'), findsOneWidget);
    });
  });

  group('swipe to delete', () {
    // The app runs RTL, where the start edge is the right. An `endToStart`
    // dismissal therefore travels *rightward* — a positive dx. Dragging
    // negative here would silently test nothing, which is exactly what these
    // tests did before this comment existed.
    const dismissSwipe = Offset(500, 0);
    const oppositeSwipe = Offset(-500, 0);

    testWidgets('deletes the swiped meal', (tester) async {
      await pumpSection(
        tester,
        meals: [MealEntryFixture.fixture(id: 7, mealName: 'Lunch')],
      );
      await tester.pumpAndSettle();

      await tester.drag(find.text('Lunch'), dismissSwipe);
      await tester.pumpAndSettle();

      verify(() => loggingService.deleteMeal(7, date)).called(1);
    });

    // Keyed by id, not index: dismissing re-orders the list, so an index key
    // would delete whichever row happened to land in that position.
    testWidgets('deletes the meal that was swiped, not the one at its index', (
      tester,
    ) async {
      await pumpSection(
        tester,
        meals: [
          MealEntryFixture.fixture(id: 1, mealName: 'First'),
          MealEntryFixture.fixture(id: 2, mealName: 'Second'),
          MealEntryFixture.fixture(id: 3, mealName: 'Third'),
        ],
      );
      await tester.pumpAndSettle();

      await tester.drag(find.text('Second'), dismissSwipe);
      await tester.pumpAndSettle();

      verify(() => loggingService.deleteMeal(2, date)).called(1);
      verifyNever(() => loggingService.deleteMeal(1, any()));
      verifyNever(() => loggingService.deleteMeal(3, any()));
    });

    testWidgets('deletes against the date the section was built for', (
      tester,
    ) async {
      await pumpSection(
        tester,
        meals: [MealEntryFixture.fixture(id: 7, mealName: 'Lunch')],
      );
      await tester.pumpAndSettle();

      await tester.drag(find.text('Lunch'), dismissSwipe);
      await tester.pumpAndSettle();

      final captured = verify(
        () => loggingService.deleteMeal(any(), captureAny()),
      ).captured.single;
      expect(captured, date);
    });

    // Only one direction deletes. Firing on both would make an accidental
    // drag in either direction destroy data.
    testWidgets('does not delete on a swipe the other way', (tester) async {
      await pumpSection(
        tester,
        meals: [MealEntryFixture.fixture(id: 7, mealName: 'Lunch')],
      );
      await tester.pumpAndSettle();

      await tester.drag(find.text('Lunch'), oppositeSwipe);
      await tester.pumpAndSettle();

      verifyNever(() => loggingService.deleteMeal(any(), any()));
    });

    // Every entry from the repository has an id, but rendering an un-saved one
    // must not throw from inside a build.
    testWidgets(
      'a meal with no id renders un-dismissible instead of throwing',
      (tester) async {
        await pumpSection(
          tester,
          meals: [MealEntryFixture.fixture(mealName: 'Unsaved')],
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Unsaved'), findsOneWidget);
        expect(find.byType(Dismissible), findsNothing);
      },
    );
  });
}
