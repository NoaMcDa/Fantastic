import 'dart:async';

import 'package:fantastic/features/diary/application/meal_logging_service.dart';
import 'package:fantastic/features/diary/domain/models/meal_entry.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

class _MockMealLoggingService extends Mock implements MealLoggingService {}

void main() {
  final date = MealEntryFixture.defaultTimestamp;
  late _MockMealLoggingService loggingService;

  setUpAll(() => registerFallbackValue(MealEntryFixture.fixture()));

  setUp(() {
    loggingService = _MockMealLoggingService();
    when(() => loggingService.logMeal(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as MealEntry,
    );
  });

  Future<void> pumpSheet(WidgetTester tester) => pumpApp(
    tester,
    AddMealBottomSheet(date: date),
    overrides: [mealLoggingServiceProvider.overrideWithValue(loggingService)],
  );

  Future<void> fillForm(
    WidgetTester tester, {
    String name = 'Test Meal',
    String fat = '20',
    String carbs = '5',
    String protein = '15',
  }) async {
    await tester.enterText(find.byKey(const Key('meal_name_field')), name);
    await tester.enterText(find.byKey(const Key('fat_field')), fat);
    await tester.enterText(find.byKey(const Key('carbs_field')), carbs);
    await tester.enterText(find.byKey(const Key('protein_field')), protein);
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('save_meal_button')));
    await tester.pumpAndSettle();
  }

  /// The entry handed to `logMeal`.
  MealEntry loggedEntry() =>
      verify(() => loggingService.logMeal(captureAny())).captured.single
          as MealEntry;

  group('valid submission', () {
    testWidgets('logs a meal built from the form', (tester) async {
      await pumpSheet(tester);
      await fillForm(
        tester,
        name: 'ביצים',
        fat: '22.5',
        carbs: '1',
        protein: '13',
      );
      await submit(tester);

      final entry = loggedEntry();
      expect(entry.mealName, 'ביצים');
      expect(entry.fatG, 22.5);
      expect(entry.netCarbsG, 1);
      expect(entry.proteinG, 13);
    });

    // Regression for #201: `timestamp: widget.date` stored the midnight-
    // normalised date verbatim, so every meal ever logged rendered as 00:00.
    testWidgets('carries the current time of day, not midnight', (
      tester,
    ) async {
      await pumpSheet(tester);
      await fillForm(tester);

      // Bracket the submit so the assertion is a range. Asserting "not
      // midnight" would fail for real once a year, at midnight.
      final before = DateTime.now();
      await submit(tester);
      final after = DateTime.now();

      DateTime onDate(DateTime clock) => DateTime(
        date.year,
        date.month,
        date.day,
        clock.hour,
        clock.minute,
        clock.second,
      );

      final stamped = loggedEntry().timestamp;
      expect(
        stamped.isBefore(onDate(before)),
        isFalse,
        reason: '$stamped precedes the clock reading taken before the save',
      );
      expect(
        stamped.isAfter(onDate(after)),
        isFalse,
        reason: '$stamped follows the clock reading taken after the save',
      );
    });

    testWidgets('keeps the calendar day it was opened for', (tester) async {
      await pumpSheet(tester);
      await fillForm(tester);
      await submit(tester);

      final stamped = loggedEntry().timestamp;
      expect(stamped.year, date.year);
      expect(stamped.month, date.month);
      expect(stamped.day, date.day);
    });

    testWidgets('trims surrounding whitespace from the name', (tester) async {
      await pumpSheet(tester);
      await fillForm(tester, name: '  סלט  ');
      await submit(tester);

      expect(loggedEntry().mealName, 'סלט');
    });

    testWidgets('accepts zero for a macro', (tester) async {
      // A zero-carb meal is the common case on keto, not an edge case.
      await pumpSheet(tester);
      await fillForm(tester, carbs: '0');
      await submit(tester);

      expect(loggedEntry().netCarbsG, 0);
    });
  });

  group('validation', () {
    testWidgets('an empty name blocks the save', (tester) async {
      await pumpSheet(tester);
      await fillForm(tester, name: '');
      await submit(tester);

      expect(find.text('שדה חובה'), findsOneWidget);
      verifyNever(() => loggingService.logMeal(any()));
    });

    testWidgets('a whitespace-only name blocks the save', (tester) async {
      await pumpSheet(tester);
      await fillForm(tester, name: '   ');
      await submit(tester);

      verifyNever(() => loggingService.logMeal(any()));
    });

    testWidgets('a negative macro blocks the save', (tester) async {
      await pumpSheet(tester);
      await fillForm(tester, fat: '-1');
      await submit(tester);

      expect(find.text('יש להזין מספר חיובי'), findsOneWidget);
      verifyNever(() => loggingService.logMeal(any()));
    });

    testWidgets('a non-numeric macro blocks the save', (tester) async {
      await pumpSheet(tester);
      await fillForm(tester, protein: 'abc');
      await submit(tester);

      expect(find.text('יש להזין מספר חיובי'), findsOneWidget);
      verifyNever(() => loggingService.logMeal(any()));
    });

    testWidgets('an empty macro blocks the save', (tester) async {
      await pumpSheet(tester);
      await fillForm(tester, fat: '');
      await submit(tester);

      verifyNever(() => loggingService.logMeal(any()));
    });

    // `double.tryParse` accepts both, and neither is caught by a `< 0` check.
    // Either would poison every total derived from it.
    testWidgets('Infinity is rejected', (tester) async {
      await pumpSheet(tester);
      await fillForm(tester, fat: 'Infinity');
      await submit(tester);

      verifyNever(() => loggingService.logMeal(any()));
    });

    testWidgets('NaN is rejected', (tester) async {
      await pumpSheet(tester);
      await fillForm(tester, carbs: 'NaN');
      await submit(tester);

      verifyNever(() => loggingService.logMeal(any()));
    });
  });

  group('submission lifecycle', () {
    testWidgets('closes the sheet after a successful save', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AddMealBottomSheet.show(context, date: date),
            child: const Text('open'),
          ),
        ),
        overrides: [
          mealLoggingServiceProvider.overrideWithValue(loggingService),
        ],
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(AddMealBottomSheet), findsOneWidget);

      await fillForm(tester);
      await submit(tester);

      expect(find.byType(AddMealBottomSheet), findsNothing);
    });

    testWidgets('disables the button while the save is in flight', (
      tester,
    ) async {
      final completer = Completer<MealEntry>();
      when(() => loggingService.logMeal(any()))
          .thenAnswer((_) => completer.future);

      await pumpSheet(tester);
      await fillForm(tester);
      await tester.tap(find.byKey(const Key('save_meal_button')));
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('save_meal_button')),
      );
      expect(button.onPressed, isNull);

      completer.complete(MealEntryFixture.fixture());
      await tester.pumpAndSettle();
    });

    testWidgets('a second tap while saving does not log twice', (tester) async {
      final completer = Completer<MealEntry>();
      when(() => loggingService.logMeal(any()))
          .thenAnswer((_) => completer.future);

      await pumpSheet(tester);
      await fillForm(tester);
      await tester.tap(find.byKey(const Key('save_meal_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('save_meal_button')));
      await tester.pump();

      verify(() => loggingService.logMeal(any())).called(1);

      completer.complete(MealEntryFixture.fixture());
      await tester.pumpAndSettle();
    });

    // Closing on failure would discard what the user typed while implying it
    // had been saved.
    testWidgets('a failed save keeps the sheet open and says so', (
      tester,
    ) async {
      when(() => loggingService.logMeal(any()))
          .thenThrow(Exception('disk gone'));

      await pumpSheet(tester);
      await fillForm(tester, name: 'ביצים');
      await submit(tester);

      expect(find.text('השמירה נכשלה, נסו שוב'), findsOneWidget);
      expect(find.byType(AddMealBottomSheet), findsOneWidget);
    });

    testWidgets('a failed save keeps the typed values', (tester) async {
      when(() => loggingService.logMeal(any()))
          .thenThrow(Exception('disk gone'));

      await pumpSheet(tester);
      await fillForm(tester, name: 'ביצים');
      await submit(tester);

      expect(find.text('ביצים'), findsOneWidget);
    });

    testWidgets('a failed save re-enables the button for a retry', (
      tester,
    ) async {
      when(() => loggingService.logMeal(any()))
          .thenThrow(Exception('disk gone'));

      await pumpSheet(tester);
      await fillForm(tester);
      await submit(tester);

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('save_meal_button')),
      );
      expect(button.onPressed, isNotNull);
    });
  });

  testWidgets('all four fields carry their integration-test keys', (
    tester,
  ) async {
    await pumpSheet(tester);

    expect(find.byKey(const Key('meal_name_field')), findsOneWidget);
    expect(find.byKey(const Key('fat_field')), findsOneWidget);
    expect(find.byKey(const Key('carbs_field')), findsOneWidget);
    expect(find.byKey(const Key('protein_field')), findsOneWidget);
  });

  group('prefilled macros (#304)', () {
    /// The sheet as the scan result opens it, with a scaled macro that carries
    /// binary floating-point noise.
    Future<void> pumpPrefilled(WidgetTester tester, double fatG) => pumpApp(
      tester,
      AddMealBottomSheet(date: date, initialFatG: fatG),
      overrides: [mealLoggingServiceProvider.overrideWithValue(loggingService)],
    );

    String fieldText(WidgetTester tester, String key) =>
        tester.widget<TextFormField>(find.byKey(Key(key))).controller!.text;

    // The regression. `ScanResultSheet`'s macro strip displayed `0.2`, and the
    // prefill wrote `0.17999999999999988` into the field beneath it — so the
    // number in front of the user when they pressed save was not the number
    // that got saved.
    testWidgets('show the figure the sheet displayed, not float noise', (
      tester,
    ) async {
      await pumpPrefilled(tester, 0.17999999999999988);

      expect(fieldText(tester, 'fat_field'), '0.2');
    });

    testWidgets('keep dropping a pointless trailing .0', (tester) async {
      await pumpPrefilled(tester, 12);

      expect(fieldText(tester, 'fat_field'), '12');
    });

    testWidgets('an absent macro stays empty, never zero', (tester) async {
      // A zero-macro meal saves without complaint and is invisible in the
      // day's totals; empty makes the form's validator ask.
      await pumpPrefilled(tester, 0);

      expect(fieldText(tester, 'carbs_field'), '');
    });
  });
}
