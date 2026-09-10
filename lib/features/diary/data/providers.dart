import 'package:fantastic/core/database/database_provider.dart';
import 'package:fantastic/features/diary/data/repositories/sembast_meal_repository.dart';
import 'package:fantastic/features/diary/data/repositories/sembast_symptom_log_repository.dart';
import 'package:fantastic/features/diary/domain/repositories/meal_repository.dart';
import 'package:fantastic/features/diary/domain/repositories/symptom_log_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The diary feature's repository wiring.
///
/// Both providers return the **domain interface**, not the sembast class, so
/// a consumer cannot reach past the abstraction to a store-specific method —
/// the layer rule enforced by the type system rather than by review.
///
/// `ref.watch(databaseProvider)` yields a `Database` directly: the provider is
/// synchronous, and throws a descriptive `UnimplementedError` if the app root
/// never overrode it.
@riverpod
MealRepository mealRepository(Ref ref) =>
    SembastMealRepository(ref.watch(databaseProvider));

@riverpod
SymptomLogRepository symptomLogRepository(Ref ref) =>
    SembastSymptomLogRepository(ref.watch(databaseProvider));
