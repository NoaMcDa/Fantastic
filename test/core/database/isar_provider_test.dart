import 'package:fantastic/core/database/isar_provider.dart';
import 'package:fantastic/features/adaptation/data/schemas/isar_streak_state.dart';
import 'package:fantastic/features/dashboard/data/schemas/isar_daily_log.dart';
import 'package:fantastic/features/diary/data/schemas/isar_meal_entry.dart';
import 'package:fantastic/features/diary/data/schemas/isar_symptom_log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Regression guard for #154: main.dart called `Isar.open([])`, which throws
  // `IsarError: At least one collection needs to be opened` before `runApp`,
  // so the app could not launch at all. No test caught it because none of them
  // call main() — widget_test.dart pumps FantasticApp directly.
  group('startup Isar wiring', () {
    test('the app registers at least one collection', () {
      // Flipped by #35, which added IsarMealEntrySchema. While this list was
      // empty main.dart skipped Isar.open entirely, because Isar rejects an
      // empty schema list and the unguarded call crashed the app before
      // runApp (#154).
      expect(appIsarSchemas, isNotEmpty);
    });

    test('IsarMealEntry is registered', () {
      expect(
        appIsarSchemas.map((schema) => schema.name),
        contains(IsarMealEntrySchema.name),
      );
    });

    test('IsarDailyLog is registered', () {
      expect(
        appIsarSchemas.map((schema) => schema.name),
        contains(IsarDailyLogSchema.name),
      );
    });

    test('IsarStreakState is registered', () {
      expect(
        appIsarSchemas.map((schema) => schema.name),
        contains(IsarStreakStateSchema.name),
      );
    });

    test('IsarSymptomLog is registered', () {
      expect(
        appIsarSchemas.map((schema) => schema.name),
        contains(IsarSymptomLogSchema.name),
      );
    });

    // openAppIsar itself is not exercised here: it calls
    // getApplicationDocumentsDirectory, a platform channel with no binding in
    // a headless test. Its behaviour is covered end-to-end by `flutter run`,
    // and the repository contract suites (#39-#42) prove the schema opens
    // against a real in-memory instance.
  });

  test('isarProvider throws a descriptive UnimplementedError when not '
      'overridden', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // riverpod 3.0 wraps an error thrown by a provider's create function in
    // its own (internal, not publicly exported) ProviderException — assert
    // on its toString() instead, which includes the wrapped exception's
    // message.
    expect(
      () => container.read(isarProvider),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'toString()',
          contains('isarProvider must be overridden at app root'),
        ),
      ),
    );
  });

  // `ref.watch(isarProvider)` resolving via `isarProvider.overrideWithValue`
  // (the "resolves in a widget test with the in-memory override" DoD case)
  // isn't covered here: constructing a real `Isar` value needs
  // `Isar.initializeIsarCore`, which needs the native core binary — see
  // test/helpers/test_isar_test.dart (#24) for why that can't run in this
  // sandbox. The override call site itself (main.dart's
  // `isarProvider.overrideWithValue(db)`) is compile-time checked against
  // `Isar` by `flutter analyze`, which is the verification available here.
}
