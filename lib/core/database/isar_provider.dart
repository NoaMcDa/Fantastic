import 'package:fantastic/features/adaptation/data/schemas/isar_streak_state.dart';
import 'package:fantastic/features/dashboard/data/schemas/isar_daily_log.dart';
import 'package:fantastic/features/diary/data/schemas/isar_meal_entry.dart';
import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'isar_provider.g.dart';

/// Isar collections the app opens at startup.
///
/// The single registration point for schemas — M1 appends `IsarMealEntrySchema`
/// and friends here (#35–#38). It stays empty through M0, which defines no
/// domain models by design, and `main.dart` skips opening Isar entirely while
/// it is: `Isar.open` throws `IsarError: At least one collection needs to be
/// opened` on an empty list, which crashed the app before `runApp` (#154).
const List<CollectionSchema<dynamic>> appIsarSchemas = [
  IsarMealEntrySchema,
  IsarDailyLogSchema,
  IsarStreakStateSchema,
];

@Riverpod(keepAlive: true)
Isar isar(Ref ref) => throw UnimplementedError(
  'isarProvider must be overridden at app root with an opened Isar instance',
);
