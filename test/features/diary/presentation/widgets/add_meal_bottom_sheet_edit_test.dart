import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/diary/application/meal_logging_service.dart';
import 'package:fantastic/features/diary/domain/models/macro_source.dart';
import 'package:fantastic/features/diary/domain/models/meal_entry.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/meal_entry_fixture.dart';
import '../../../../helpers/pump_app.dart';

class _MockMealLoggingService extends Mock implements MealLoggingService {}

void main() {
  late _MockMealLoggingService service;

  final date = DateTime(2026, 9, 11);

  /// An estimate on disk, with the two fields nothing renders filled in.
  MealEntry stored({
    MacroSource source = MacroSource.estimatedFromText,
    double fatG = 20,
    double netCarbsG = 5,
    double proteinG = 15,
  }) => MealEntryFixture.fixture(
    id: 7,
    mealName: 'שקשוקה',
    fatG: fatG,
    netCarbsG: netCarbsG,
    proteinG: proteinG,
    source: source,
    ingredients: const ['ביצים', 'עגבניות'],
    imageRef: 'meals/7.jpg',
  );

  setUpAll(() => registerFallbackValue(MealEntryFixture.fixture()));

  setUp(() {
    service = _MockMealLoggingService();
    when(() => service.updateMeal(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as MealEntry,
    );
    when(() => service.logMeal(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as MealEntry,
    );
  });

  Future<void> pumpSheet(WidgetTester tester, {MealEntry? existing}) => pumpApp(
    tester,
    AddMealBottomSheet(date: date, existing: existing),
    overrides: [mealLoggingServiceProvider.overrideWithValue(service)],
  );

  String fieldText(WidgetTester tester, String key) => tester
      .widget<EditableText>(
        find.descendant(
          of: find.byKey(Key(key)),
          matching: find.byType(EditableText),
        ),
      )
      .controller
      .text;

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('save_meal_button')));
    await tester.pumpAndSettle();
  }

  /// The entry the sheet handed to `updateMeal`.
  MealEntry updated() =>
      verify(() => service.updateMeal(captureAny())).captured.single
          as MealEntry;

  group('edit mode', () {
    testWidgets('prefills every field from the stored meal', (tester) async {
      await pumpSheet(tester, existing: stored());

      expect(fieldText(tester, 'meal_name_field'), 'שקשוקה');
      expect(fieldText(tester, 'fat_field'), '20');
      expect(fieldText(tester, 'carbs_field'), '5');
      expect(fieldText(tester, 'protein_field'), '15');
    });

    testWidgets('says it is editing, not adding', (tester) async {
      await pumpSheet(tester, existing: stored());

      expect(find.text('עריכת ארוחה'), findsOneWidget);
      expect(find.text('הוספת ארוחה'), findsNothing);
      expect(find.text('עדכן'), findsOneWidget);
      expect(find.text('שמור'), findsNothing);
    });

    // The stored meal is the truth: a caller that passed both is editing.
    testWidgets('the stored meal wins over the initial prefills', (
      tester,
    ) async {
      await pumpApp(
        tester,
        AddMealBottomSheet(
          date: date,
          existing: stored(),
          initialName: 'ignored',
          initialFatG: 999,
        ),
        overrides: [mealLoggingServiceProvider.overrideWithValue(service)],
      );

      expect(fieldText(tester, 'meal_name_field'), 'שקשוקה');
      expect(fieldText(tester, 'fat_field'), '20');
    });

    testWidgets('saving updates rather than logs', (tester) async {
      await pumpSheet(tester, existing: stored());
      await save(tester);

      verify(() => service.updateMeal(any())).called(1);
      verifyNever(() => service.logMeal(any()));
    });

    testWidgets('the id reaches the service', (tester) async {
      await pumpSheet(tester, existing: stored());
      await save(tester);

      // Without it `save` would append a duplicate instead of overwriting.
      expect(updated().id, 7);
    });

    // The fields nothing in the diary renders — and therefore the ones an
    // inline `MealEntry(...)` would drop with no assertion noticing.
    testWidgets('ingredients and imageRef survive an edit', (tester) async {
      await pumpSheet(tester, existing: stored());
      await tester.enterText(find.byKey(const Key('fat_field')), '30');
      await save(tester);

      final entry = updated();
      expect(entry.ingredients, ['ביצים', 'עגבניות']);
      expect(entry.imageRef, 'meals/7.jpg');
    });

    // A correction to the carb count must not move the meal to 14:32 today.
    testWidgets('an edit does not move the timestamp', (tester) async {
      final original = stored();
      await pumpSheet(tester, existing: original);
      await tester.enterText(find.byKey(const Key('carbs_field')), '9');
      await save(tester);

      expect(updated().timestamp, original.timestamp);
    });

    testWidgets('the edited values reach the service', (tester) async {
      await pumpSheet(tester, existing: stored());
      await tester.enterText(find.byKey(const Key('meal_name_field')), 'חביתה');
      await tester.enterText(find.byKey(const Key('fat_field')), '31');
      await tester.enterText(find.byKey(const Key('carbs_field')), '2');
      await tester.enterText(find.byKey(const Key('protein_field')), '18');
      await save(tester);

      final entry = updated();
      expect(entry.mealName, 'חביתה');
      expect(entry.fatG, 31);
      expect(entry.netCarbsG, 2);
      expect(entry.proteinG, 18);
    });
  });

  // `MacroSource` exists so a badge can warn "this number was guessed". Once
  // a human has corrected the number that warning is false, and a badge that
  // lies trains people to ignore it.
  group('the re-sourcing rule', () {
    test('a changed fat re-sources to manual', () {
      expect(
        AddMealBottomSheet.sourceAfterEdit(
          stored(),
          fatG: 21,
          netCarbsG: 5,
          proteinG: 15,
        ),
        MacroSource.manual,
      );
    });

    test('a changed carb count re-sources to manual', () {
      expect(
        AddMealBottomSheet.sourceAfterEdit(
          stored(),
          fatG: 20,
          netCarbsG: 25,
          proteinG: 15,
        ),
        MacroSource.manual,
      );
    });

    test('a changed protein re-sources to manual', () {
      expect(
        AddMealBottomSheet.sourceAfterEdit(
          stored(),
          fatG: 20,
          netCarbsG: 5,
          proteinG: 16,
        ),
        MacroSource.manual,
      );
    });

    // Nothing about the numbers' origin changed.
    test('identical macros leave an estimate an estimate', () {
      expect(
        AddMealBottomSheet.sourceAfterEdit(
          stored(),
          fatG: 20,
          netCarbsG: 5,
          proteinG: 15,
        ),
        MacroSource.estimatedFromText,
      );
    });

    test('a scanned label stays scanned when its macros are untouched', () {
      expect(
        AddMealBottomSheet.sourceAfterEdit(
          stored(source: MacroSource.scannedLabel),
          fatG: 20,
          netCarbsG: 5,
          proteinG: 15,
        ),
        MacroSource.scannedLabel,
      );
    });

    test('a manual meal stays manual', () {
      expect(
        AddMealBottomSheet.sourceAfterEdit(
          stored(source: MacroSource.manual),
          fatG: 40,
          netCarbsG: 1,
          proteinG: 2,
        ),
        MacroSource.manual,
      );
    });

    // Compared on the parsed doubles, not the field strings.
    test('retyping 12.0 over 12 is not an edit', () {
      expect(
        AddMealBottomSheet.sourceAfterEdit(
          stored(fatG: 12),
          fatG: 12.0,
          netCarbsG: 5,
          proteinG: 15,
        ),
        MacroSource.estimatedFromText,
      );
    });
  });

  group('the rule applied through the form', () {
    testWidgets('editing only the name leaves the source alone', (
      tester,
    ) async {
      await pumpSheet(tester, existing: stored());
      await tester.enterText(find.byKey(const Key('meal_name_field')), 'חביתה');
      await save(tester);

      expect(updated().source, MacroSource.estimatedFromText);
    });

    testWidgets('editing a macro re-sources the saved meal to manual', (
      tester,
    ) async {
      await pumpSheet(tester, existing: stored());
      await tester.enterText(find.byKey(const Key('carbs_field')), '25');
      await save(tester);

      expect(updated().source, MacroSource.manual);
    });

    testWidgets('retyping the same value through the form is not an edit', (
      tester,
    ) async {
      await pumpSheet(tester, existing: stored(fatG: 12));
      await tester.enterText(find.byKey(const Key('fat_field')), '12.0');
      await save(tester);

      expect(updated().source, MacroSource.estimatedFromText);
    });
  });

  group('failure', () {
    testWidgets('a failed update keeps the sheet open with the typed values', (
      tester,
    ) async {
      when(() => service.updateMeal(any()))
          .thenThrow(const PersistenceException('write failed', 'closed'));
      await pumpSheet(tester, existing: stored());
      await tester.enterText(find.byKey(const Key('fat_field')), '44');
      await save(tester);

      // Closing would tell the user a correction was saved that was not.
      expect(find.byType(AddMealBottomSheet), findsOneWidget);
      expect(fieldText(tester, 'fat_field'), '44');
      expect(find.text('השמירה נכשלה, נסו שוב'), findsOneWidget);
    });

    testWidgets('a failed update re-enables the button', (tester) async {
      when(() => service.updateMeal(any()))
          .thenThrow(const PersistenceException('write failed', 'closed'));
      await pumpSheet(tester, existing: stored());
      await save(tester);

      expect(
        tester
            .widget<ButtonStyleButton>(
              find.byKey(const Key('save_meal_button')),
            )
            .onPressed,
        isNotNull,
      );
    });

    // The same validator, because there is exactly one.
    for (final (field, value) in const [
      ('fat_field', '-1'),
      ('carbs_field', 'NaN'),
      ('protein_field', 'Infinity'),
    ]) {
      testWidgets('$field rejects "$value" when editing too', (tester) async {
        await pumpSheet(tester, existing: stored());
        await tester.enterText(find.byKey(Key(field)), value);
        await save(tester);

        verifyNever(() => service.updateMeal(any()));
        expect(find.text('יש להזין מספר חיובי'), findsOneWidget);
      });
    }

    testWidgets('an empty name is rejected when editing too', (tester) async {
      await pumpSheet(tester, existing: stored());
      await tester.enterText(find.byKey(const Key('meal_name_field')), '  ');
      await save(tester);

      verifyNever(() => service.updateMeal(any()));
      expect(find.text('שדה חובה'), findsOneWidget);
    });
  });

  // Adding is M15's regression surface: `existing: null` must follow today's
  // exact path.
  group('add mode is unchanged', () {
    testWidgets('says it is adding', (tester) async {
      await pumpSheet(tester);

      expect(find.text('הוספת ארוחה'), findsOneWidget);
      expect(find.text('שמור'), findsOneWidget);
    });

    testWidgets('saving logs rather than updates', (tester) async {
      await pumpSheet(tester);
      await tester.enterText(find.byKey(const Key('meal_name_field')), 'ביצים');
      await tester.enterText(find.byKey(const Key('fat_field')), '20');
      await tester.enterText(find.byKey(const Key('carbs_field')), '1');
      await tester.enterText(find.byKey(const Key('protein_field')), '12');
      await save(tester);

      verify(() => service.logMeal(any())).called(1);
      verifyNever(() => service.updateMeal(any()));
    });
  });
}
