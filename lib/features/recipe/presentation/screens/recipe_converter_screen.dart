import 'package:fantastic/core/constants/recipe_copy.dart';
import 'package:fantastic/features/recipe/application/providers/recipe_providers.dart';
import 'package:fantastic/features/recipe/domain/ingredient_line_parser.dart';
import 'package:fantastic/features/recipe/domain/models/ingredient_outcome.dart';
import 'package:fantastic/features/recipe/presentation/widgets/ingredient_outcome_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The מתכונים tab: paste a recipe, tap convert, see every ingredient line
/// as one of four honest outcomes.
///
/// Synchronous and in-memory — the result list lives in [State], not a
/// provider, because it dies with the screen and nothing else needs it
/// (yet: #120 adds the save affordance). **No `initial` parameter and no
/// reference to `SavedRecipe`** — that is #120's, deliberately, to avoid a
/// circular dependency with #395's files built in the same wave.
///
/// **Nothing here is async and nothing animates before a tap.** This is a
/// tab root inside the `ShellRoute`, and `test/widget_test.dart` walks every
/// tab knowing nothing about what is on it — an indeterminate animation
/// that can render before any interaction is what hung `pumpAndSettle` for
/// two router tests in M6 (`design/m6_handoff.md`).
class RecipeConverterScreen extends ConsumerStatefulWidget {
  const RecipeConverterScreen({super.key});

  @override
  ConsumerState<RecipeConverterScreen> createState() =>
      _RecipeConverterScreenState();
}

class _RecipeConverterScreenState extends ConsumerState<RecipeConverterScreen> {
  final _pasteController = TextEditingController();

  /// Null before the first conversion; converting again replaces the whole
  /// list rather than appending to it.
  List<IngredientOutcome>? _results;

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  void _convert() {
    final lines = _pasteController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    final ingredients = lines.map(IngredientLineParser.parse).toList();
    final engine = ref.read(substitutionEngineProvider);
    setState(() {
      _results = engine.convert(ingredients);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No back affordance: this is a tab root inside the `ShellRoute`, not
      // a pushed screen, so nothing is implied and none should be added.
      appBar: AppBar(title: const Text(RecipeCopy.title)),
      body: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // `expands: true` inside a bounded `Expanded` — not an
            // unconstrained height — is what keeps a long paste from
            // pushing the convert button and the results off screen. The
            // field still takes `maxLines: null`; it scrolls internally
            // instead of growing the column.
            Expanded(
              flex: 2,
              child: TextField(
                key: const Key('recipe_paste_field'),
                controller: _pasteController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: RecipeCopy.pasteHint,
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // A `ValueListenableBuilder` on the controller itself — it is
            // already a `ValueNotifier<TextEditingValue>` — rather than a
            // second piece of state to keep in sync with the field.
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _pasteController,
              builder: (context, value, _) => FilledButton(
                key: const Key('recipe_convert_button'),
                // Disabled while the trimmed text is empty — never run the
                // engine over nothing and render an empty card.
                onPressed: value.text.trim().isEmpty ? null : _convert,
                child: const Text(RecipeCopy.convert),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(flex: 3, child: _resultsList()),
          ],
        ),
      ),
    );
  }

  Widget _resultsList() {
    final results = _results;
    if (results == null) {
      return const SizedBox.shrink();
    }
    if (results.isEmpty) {
      return const Center(child: Text(RecipeCopy.emptyResult));
    }
    return ListView.separated(
      key: const Key('recipe_results_list'),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => IngredientOutcomeRow(
        key: _keyFor(results[index], index),
        outcome: results[index],
      ),
    );
  }

  /// `Key('outcome_substituted_$index')` and its three siblings — one row
  /// per line, keyed by variant and position so a test can address a
  /// specific outcome without depending on rendered text.
  static Key _keyFor(IngredientOutcome outcome, int index) => switch (outcome) {
    Substituted() => Key('outcome_substituted_$index'),
    AlreadyKeto() => Key('outcome_already_keto_$index'),
    Flagged() => Key('outcome_flagged_$index'),
    Unrecognised() => Key('outcome_unrecognised_$index'),
  };
}
