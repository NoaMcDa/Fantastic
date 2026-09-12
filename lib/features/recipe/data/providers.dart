import 'package:fantastic/core/database/database_provider.dart';
import 'package:fantastic/features/diary/data/providers.dart'
    show llmChatClientProvider;
import 'package:fantastic/features/recipe/data/repositories/sembast_saved_recipe_repository.dart';
import 'package:fantastic/features/recipe/data/suggestion/llm_substitution_suggester.dart';
import 'package:fantastic/features/recipe/domain/repositories/saved_recipe_repository.dart';
import 'package:fantastic/features/recipe/domain/services/substitution_suggester.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The recipe feature's repository wiring.
///
/// Returns the **domain interface**, not the sembast class, so a consumer
/// cannot reach past the abstraction to a store-specific method — the layer
/// rule enforced by the type system rather than by review.
///
/// `ref.watch(databaseProvider)` yields a `Database` directly: the provider is
/// synchronous, and throws a descriptive `UnimplementedError` if the app root
/// never overrode it.
@riverpod
SavedRecipeRepository savedRecipeRepository(Ref ref) =>
    SembastSavedRecipeRepository(ref.watch(databaseProvider));

/// The composition root for #396's model pass, and the only place a concrete
/// [SubstitutionSuggester] is named.
///
/// **The one cross-feature import in the recipe feature**, and it belongs
/// here rather than being avoided: `llmChatClientProvider` is the diary
/// feature's composition root for `LlmChatClient` (`OpenRouterClient` behind
/// `EstimationSettings.isEnabled`), and reusing it is exactly what M15's
/// promotion of the interface to `lib/core/services/llm/` was for — a second consumer
/// without a second gate, a second key, or a second settings screen. The same
/// pattern `add_meal_photo_sheet.dart` uses to reach `ScanOrchestrator`.
///
/// Returns the **domain interface**, not the adapter class, for the same
/// reason every provider here does: a future backend swap is a new
/// `LlmChatClient` implementation and a new branch at that one composition
/// root, never an edit above this line.
@riverpod
SubstitutionSuggester substitutionSuggester(Ref ref) =>
    LlmSubstitutionSuggester(client: ref.watch(llmChatClientProvider));
