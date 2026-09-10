import 'package:fantastic/core/database/isar_provider.dart';
import 'package:fantastic/features/diary/data/repositories/isar_meal_repository.dart';
import 'package:fantastic/features/diary/data/repositories/isar_symptom_log_repository.dart';
import 'package:fantastic/features/diary/domain/repositories/meal_repository.dart';
import 'package:fantastic/features/diary/domain/repositories/symptom_log_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The diary feature's repository wiring.
///
/// Both providers return the **domain interface**, not the Isar class, so a
/// consumer cannot reach past the abstraction to an Isar-specific method — the
/// layer rule enforced by the type system rather than by review.
///
/// `ref.watch(isarProvider)` yields an `Isar` directly: the provider is
/// synchronous, and throws a descriptive `UnimplementedError` if the app root
/// never overrode it.
@riverpod
MealRepository mealRepository(Ref ref) =>
    IsarMealRepository(ref.watch(isarProvider));

@riverpod
SymptomLogRepository symptomLogRepository(Ref ref) =>
    IsarSymptomLogRepository(ref.watch(isarProvider));
