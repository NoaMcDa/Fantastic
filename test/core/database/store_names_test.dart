import 'package:fantastic/features/adaptation/data/repositories/sembast_streak_repository.dart';
import 'package:fantastic/features/dashboard/data/repositories/sembast_daily_log_repository.dart';
import 'package:fantastic/features/diary/data/repositories/sembast_meal_repository.dart';
import 'package:fantastic/features/diary/data/repositories/sembast_symptom_log_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// The successor to the `appIsarSchemas` registration assertions.
///
/// sembast has no schema to register and creates a store on first write, which
/// means a store-name collision between two features does not fail — it
/// silently merges two collections into one. Nothing else in the build catches
/// that, so this test is the whole safety net. It also pins each name, so
/// renaming a store (which orphans every record already written under the old
/// name) has to be a deliberate, reviewed edit.
void main() {
  group('sembast store names', () {
    final stores = {
      'meals': mealsStore,
      'daily_logs': dailyLogsStore,
      'symptom_logs': symptomLogsStore,
      'streak_state': streakStateStore,
    };

    test('every feature store has its expected name', () {
      for (final entry in stores.entries) {
        expect(entry.value.name, entry.key);
      }
    });

    test('no two features write to the same store', () {
      final names = stores.values.map((store) => store.name).toList();

      expect(names.toSet(), hasLength(names.length));
    });
  });
}
