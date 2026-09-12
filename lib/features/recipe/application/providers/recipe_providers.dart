import 'package:fantastic/features/recipe/domain/substitution_engine.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recipe_providers.g.dart';

/// The shipped [SubstitutionEngine], as a provider so a widget test can
/// override it with a small table rather than asserting against the whole
/// seeded set.
@riverpod
SubstitutionEngine substitutionEngine(Ref ref) => const SubstitutionEngine();
