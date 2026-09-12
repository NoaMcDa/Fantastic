import 'package:fantastic/core/constants/recipe_copy.dart';
import 'package:fantastic/core/widgets/skeleton_box.dart';
import 'package:fantastic/features/recipe/application/providers/recipe_providers.dart';
import 'package:fantastic/features/recipe/presentation/screens/recipe_converter_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `/recipe/saved/:id` — reopens a saved recipe by its path id.
///
/// **By id, never by `extra`.** A browser reload drops `extra` — it is not
/// serialisable — which is exactly what `app_router.dart`'s onboarding route
/// documents `extra` costing on a reload. Loading through
/// [savedRecipeProvider] instead means `/recipe/saved/3` reopens the same
/// recipe after a reload, not an empty converter.
///
/// A missing, non-numeric or unknown id never crashes — it renders the same
/// empty, usable converter a bad onboarding deep link gets, with a one-line
/// notice in place of a seeded conversion.
class SavedRecipeLoader extends ConsumerWidget {
  const SavedRecipeLoader({required this.id, super.key});

  /// Parsed by the router from the `:id` path parameter
  /// (`int.tryParse(state.pathParameters['id'] ?? '')`) — null for a missing
  /// or non-numeric id.
  final int? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = this.id;
    if (id == null) {
      return const _NotFoundConverter();
    }

    final recipeAsync = ref.watch(savedRecipeProvider(id));

    // `hasError` before `hasValue`, per the app's convention — but there is
    // nothing more useful to show for one deep-linked recipe than the same
    // fallback an unknown id already gets. Adding a second failure surface
    // that only this route would ever show is not worth the complexity; what
    // matters is that a failed read never renders a stuck spinner and never
    // crashes, and both are true here.
    if (recipeAsync.hasError) {
      return const _NotFoundConverter();
    }
    if (!recipeAsync.hasValue) {
      return const _SavedRecipeLoaderSkeleton();
    }

    final recipe = recipeAsync.requireValue;
    return recipe == null
        ? const _NotFoundConverter()
        : RecipeConverterScreen(initial: recipe);
  }
}

/// The empty converter with [RecipeCopy.recipeNotFound] overlaid, for an id
/// that never resolves to a stored recipe.
class _NotFoundConverter extends StatelessWidget {
  const _NotFoundConverter();

  @override
  Widget build(BuildContext context) =>
      const Stack(children: [RecipeConverterScreen(), _NotFoundBanner()]);
}

class _NotFoundBanner extends StatelessWidget {
  const _NotFoundBanner();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: kToolbarHeight + 8),
        child: Material(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              RecipeCopy.recipeNotFound,
              key: Key('recipe_not_found_notice'),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Static, per the shared rule the converter itself follows: nothing here
/// animates before a tap, because `test/widget_test.dart` walks every tab
/// knowing nothing about what is on it.
class _SavedRecipeLoaderSkeleton extends StatelessWidget {
  const _SavedRecipeLoaderSkeleton();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(RecipeCopy.title)),
    body: const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonBox(width: double.infinity, height: 200),
          SizedBox(height: 16),
          SkeletonBox(width: double.infinity, height: 48),
        ],
      ),
    ),
  );
}
