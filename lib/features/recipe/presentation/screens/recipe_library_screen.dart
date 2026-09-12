import 'dart:async';

import 'package:fantastic/core/constants/recipe_copy.dart';
import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/core/widgets/empty_state_widget.dart';
import 'package:fantastic/core/widgets/skeleton_box.dart';
import 'package:fantastic/features/recipe/application/providers/recipe_providers.dart';
import 'package:fantastic/features/recipe/data/providers.dart';
import 'package:fantastic/features/recipe/domain/models/ingredient_outcome.dart';
import 'package:fantastic/features/recipe/domain/models/saved_recipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// `intl` exports its own `TextDirection`, which shadows the Flutter one and
// has no `ltr` — the same guard `ProfileScreen` carries. Only `DateFormat`
// is wanted here.
import 'package:intl/intl.dart' show DateFormat;

/// `/recipe/library` — every saved recipe, newest first, reopenable and
/// swipeable to delete.
///
/// A `ConsumerStatefulWidget`, not the `ConsumerWidget` the issue text
/// sketches: tracking rows already swiped away needs somewhere to live
/// across rebuilds, and `MealListSection`'s `_dismissedIds` — the settled
/// answer to the async-delete trap this screen has too — is exactly that.
/// The public constructor is unchanged either way.
class RecipeLibraryScreen extends ConsumerStatefulWidget {
  const RecipeLibraryScreen({super.key});

  @override
  ConsumerState<RecipeLibraryScreen> createState() =>
      _RecipeLibraryScreenState();
}

class _RecipeLibraryScreenState extends ConsumerState<RecipeLibraryScreen> {
  /// Ids swiped away but still present in the provider's last value.
  ///
  /// Mirrors `MealListSection._dismissedIds`: `Dismissible` asserts a
  /// dismissed child leaves the tree immediately, but the delete is
  /// asynchronous, so hiding the id on dismissal closes the gap between the
  /// gesture completing and the refetch confirming it — and stops the row
  /// flashing back mid-refetch. Pruned once the refetch confirms an id gone,
  /// and explicitly un-hidden by [_delete] when the delete itself failed.
  final Set<int> _dismissedIds = {};

  /// Bumped for an id whose delete failed.
  ///
  /// Found empirically, not in the issue text: simply removing an id from
  /// [_dismissedIds] to bring its row back throws
  /// `A dismissed Dismissible widget is still part of the tree` — once a
  /// `Dismissible` has actually dismissed itself, Flutter refuses to accept
  /// a widget under the *same* key as part of the tree again. Folding this
  /// count into the row's key (`'$id-$attempt'`) gives the restored row a
  /// genuinely new `Dismissible` identity instead of resurrecting the old
  /// one, which is what `MealListSection`'s pattern — which never actually
  /// un-hides a row — did not need to solve.
  final Map<int, int> _dismissAttempt = {};

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(savedRecipesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(RecipeCopy.libraryTitle)),
      body: _body(recipesAsync),
    );
  }

  Widget _body(AsyncValue<List<SavedRecipe>> recipesAsync) {
    // `hasError` before `hasValue`, and no `AsyncValue.when` — riverpod 3
    // reports a provider that failed before ever producing a value as
    // `AsyncLoading` *with* an error attached, and `when` is loading-first,
    // which is the failure that cost four milestones in four disguises. A
    // failed read and an empty library must not look alike either
    // (`design/m5_handoff.md`), which is why this and the empty branch below
    // render different widgets with different keys.
    if (recipesAsync.hasError) {
      return const Center(
        key: Key('recipe_library_load_failed'),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(RecipeCopy.loadFailed, textAlign: TextAlign.center),
        ),
      );
    }

    if (!recipesAsync.hasValue) {
      return const _LibrarySkeleton();
    }

    final recipes = recipesAsync.requireValue;
    if (recipes.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.menu_book_outlined,
        headline: RecipeCopy.emptyLibraryTitle,
        subtitle: RecipeCopy.emptyLibraryBody,
      );
    }

    return _buildList(recipes);
  }

  Widget _buildList(List<SavedRecipe> recipes) {
    _pruneDismissed(recipes);
    final visible = recipes.where((recipe) => !_isHidden(recipe)).toList();

    return ListView.separated(
      key: const Key('recipe_library_list'),
      padding: const EdgeInsets.all(16),
      itemCount: visible.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _dismissible(visible[index]),
    );
  }

  bool _isHidden(SavedRecipe recipe) =>
      recipe.id != null && _dismissedIds.contains(recipe.id);

  /// Forgets ids the refetch has confirmed gone.
  void _pruneDismissed(List<SavedRecipe> recipes) {
    final present = recipes.map((recipe) => recipe.id).whereType<int>().toSet();
    _dismissedIds.removeWhere((id) => !present.contains(id));
  }

  Widget _dismissible(SavedRecipe recipe) {
    final id = recipe.id;
    // Every entry here came from the repository, so this is unreachable in
    // practice — rendering it un-dismissible beats `recipe.id!` throwing
    // inside a build.
    if (id == null) {
      return _RecipeCard(recipe: recipe);
    }

    // Keyed by id **and** by dismiss attempt, not by id alone: dismissing
    // re-orders the list, so an index key would animate the wrong row out —
    // and a plain id key cannot be reused after a failed delete restores the
    // row, see [_dismissAttempt].
    final attempt = _dismissAttempt[id] ?? 0;

    return Dismissible(
      key: ValueKey('$id-$attempt'),
      direction: DismissDirection.endToStart,
      background: const _DeleteBackground(),
      onDismissed: (_) {
        setState(() => _dismissedIds.add(id));
        unawaited(_delete(id));
      },
      child: _RecipeCard(
        key: Key('saved_recipe_$id'),
        recipe: recipe,
        onTap: () => context.push('/recipe/saved/$id'),
      ),
    );
  }

  Future<void> _delete(int id) async {
    // Captured before the `await` — using `context` after an async gap on a
    // widget that may no longer be mounted is exactly what the `mounted`
    // check below exists to guard against.
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await ref.read(savedRecipeRepositoryProvider).deleteById(id);
    } on PersistenceException catch (_) {
      // The store and the screen must agree again: un-hide the row rather
      // than leaving it dismissed from the tree while it is still stored.
      // Bumping `_dismissAttempt` alongside is what makes that legal — see
      // its doc comment.
      if (mounted) {
        setState(() {
          _dismissedIds.remove(id);
          _dismissAttempt[id] = (_dismissAttempt[id] ?? 0) + 1;
        });
      }
      messenger?.showSnackBar(
        const SnackBar(content: Text(RecipeCopy.deleteFailed)),
      );
    } finally {
      if (mounted) {
        // Re-reads the list either way: on success this drops the row for
        // good, and on failure this is what proves — via the row
        // reappearing — that it never actually left.
        ref.invalidate(savedRecipesProvider);
      }
    }
  }
}

/// One saved recipe: title, save date, and a counts line.
class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe, this.onTap, super.key});

  final SavedRecipe recipe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final substitutedCount = recipe.outcomes.whereType<Substituted>().length;

    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(recipe.title),
        subtitle: Text(_formatDate(recipe.savedAt)),
        // A digit run inside this RTL layout needs `TextDirection.ltr` —
        // the same guard `ProfileScreen._ValueRow` carries — or the count
        // and the middot reorder.
        trailing: Text(
          '${RecipeCopy.ingredientCount(recipe.outcomes.length)} · '
          '${RecipeCopy.substitutedCount(substitutedCount)}',
          textDirection: TextDirection.ltr,
        ),
      ),
    );
  }

  /// `9 בספטמבר 2026`, falling back to the locale-independent format — the
  /// same guard `ProfileScreen._formatDate` carries: `DateFormat` with an
  /// explicit locale throws when its symbol data was never initialised, and
  /// a date on a recipe card is not worth taking the tab down over.
  static String _formatDate(DateTime date) {
    try {
      return DateFormat('d MMMM yyyy', 'he').format(date);
    } on Object catch (_) {
      return DateFormat('d MMMM yyyy').format(date);
    }
  }
}

/// The panel revealed behind a row being swiped away.
///
/// Identical to `MealListSection`'s own — private to each file rather than
/// shared, since both are small and neither is `lib/core/`'s to own.
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      // An `endToStart` dismissal slides the row toward the start edge, so
      // the panel behind it is revealed at the *end*. Directional alignment
      // rather than `Alignment.centerRight`: end is the right in LTR and the
      // left in RTL, and this app runs RTL.
      alignment: AlignmentDirectional.centerEnd,
      padding: const EdgeInsetsDirectional.only(end: 20),
      child: Icon(Icons.delete_outline, color: colors.onErrorContainer),
    );
  }
}

/// The screen's shape before the list resolves.
///
/// Static, per the shared rule every skeleton in this app follows: an
/// indeterminate animation on a tab-reachable screen hangs `pumpAndSettle`.
class _LibrarySkeleton extends StatelessWidget {
  const _LibrarySkeleton();

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: 6,
    separatorBuilder: (_, _) => const SizedBox(height: 8),
    itemBuilder: (_, _) =>
        const SkeletonBox(width: double.infinity, height: 72),
  );
}
