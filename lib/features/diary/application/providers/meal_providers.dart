import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/domain/models/meal_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'meal_providers.g.dart';

/// Every [MealEntry] logged on [date], newest first.
///
/// Returns an empty list when nothing is logged — never null. List screens
/// render "no items", not "no data": an empty day and a missing day look the
/// same to the user, so there is nothing for a null to express.
///
/// This is the individual-meal view; `todaysDailyLogProvider` (#47) is the
/// aggregate. Both are keyed by date and both are invalidated after a write.
///
/// The date is normalised to midnight before the query. **Pass a date-only
/// value** — the family is keyed on the argument as given, so a wall-clock
/// `DateTime.now()` recomputed in a `build` method would allocate a fresh
/// provider on every rebuild and refetch forever.
@riverpod
Future<List<MealEntry>> todaysMeals(Ref ref, DateTime date) {
  final repository = ref.watch(mealRepositoryProvider);
  return repository.findByDate(DateTime(date.year, date.month, date.day));
}
