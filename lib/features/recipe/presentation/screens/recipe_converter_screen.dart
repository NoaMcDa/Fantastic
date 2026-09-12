import 'package:fantastic/core/constants/recipe_copy.dart';
import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/core/router/app_router.dart';
import 'package:fantastic/features/recipe/application/providers/recipe_providers.dart';
import 'package:fantastic/features/recipe/data/providers.dart';
import 'package:fantastic/features/recipe/domain/ingredient_line_parser.dart';
import 'package:fantastic/features/recipe/domain/models/ingredient_outcome.dart';
import 'package:fantastic/features/recipe/domain/models/saved_recipe.dart';
import 'package:fantastic/features/recipe/domain/models/suggestion_result.dart';
import 'package:fantastic/features/recipe/domain/substitution_engine.dart';
import 'package:fantastic/features/recipe/presentation/widgets/ingredient_outcome_row.dart';
import 'package:fantastic/features/recipe/presentation/widgets/save_recipe_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The מתכונים tab: paste a recipe, tap convert, see every ingredient line
/// as one of four honest outcomes.
///
/// Synchronous and in-memory — the result list lives in [State], not a
/// provider, because it dies with the screen and nothing else needs it,
/// **except when reopened**: [initial] seeds the field and the results from
/// a stored [SavedRecipe] without re-running the engine, so a recipe reopens
/// exactly as it was saved even after the rule table has since grown.
///
/// **Nothing here is async and nothing animates before a tap.** This is a
/// tab root inside the `ShellRoute`, and `test/widget_test.dart` walks every
/// tab knowing nothing about what is on it — an indeterminate animation
/// that can render before any interaction is what hung `pumpAndSettle` for
/// two router tests in M6 (`design/m6_handoff.md`). That holds through
/// #120's change too: seeding from [initial] happens once, synchronously, in
/// `initState`.
class RecipeConverterScreen extends ConsumerStatefulWidget {
  const RecipeConverterScreen({this.initial, super.key});

  /// The recipe being reopened (`SavedRecipeLoader`, `/recipe/saved/:id`), or
  /// null for a fresh conversion.
  final SavedRecipe? initial;

  @override
  ConsumerState<RecipeConverterScreen> createState() =>
      _RecipeConverterScreenState();
}

class _RecipeConverterScreenState extends ConsumerState<RecipeConverterScreen> {
  final _pasteController = TextEditingController();

  /// Null before the first conversion; converting again replaces the whole
  /// list rather than appending to it.
  List<IngredientOutcome>? _results;

  /// The row to overwrite on the next save. Set from [RecipeConverterScreen.initial]
  /// and then from whatever id the repository assigns on the first save in
  /// this session, so saving again in the same session updates in place
  /// rather than inserting a second row.
  int? _savedId;

  /// Seeds [SaveRecipeDialog]'s field on the next save, so saving again does
  /// not silently blank a title the user already chose.
  String? _lastTitle;

  /// True only immediately after a save attempt that threw. Cleared by the
  /// next successful save and by every new conversion.
  bool _saveFailed = false;

  /// True only while a #396 suggestion request is in flight.
  ///
  /// **Never true before a tap.** This screen is a tab root inside the
  /// `ShellRoute`, and `test/widget_test.dart` walks every tab knowing
  /// nothing about what is on it — the class doc's "nothing animates before
  /// a tap" invariant extends to this spinner exactly as it does to the
  /// convert button.
  bool _suggesting = false;

  /// Set only by a request that reached the model and returned zero usable
  /// outcomes — a real answer, not an error. Cleared by every new attempt and
  /// by every new conversion.
  bool _noSuggestions = false;

  /// Set only by a request that did not produce an answer. Cleared by every
  /// new attempt and by every new conversion.
  SuggestionFailureReason? _suggestFailure;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _pasteController.text = initial.originalText;
      _results = initial.outcomes;
      _savedId = initial.id;
      _lastTitle = initial.title;
    }
  }

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
      _saveFailed = false;
      // A fresh conversion invalidates whatever the model answered about the
      // previous one — the unrecognised lines themselves may have changed.
      _noSuggestions = false;
      _suggestFailure = null;
    });
  }

  /// Whether the suggest button renders: results exist and at least one
  /// outcome is `Unrecognised`. Absent otherwise — a recipe the rule table
  /// fully answered must cost nothing against a 50-requests-a-day quota.
  bool get _hasUnrecognised =>
      _results?.any((outcome) => outcome is Unrecognised) ?? false;

  Future<void> _suggest() async {
    final results = _results;
    if (results == null) {
      return;
    }
    setState(() {
      _suggesting = true;
      _noSuggestions = false;
      _suggestFailure = null;
    });

    final unrecognised = [
      for (final outcome in results)
        if (outcome is Unrecognised) outcome.ingredient,
    ];

    SuggestionResult result;
    try {
      result = await ref
          .read(substitutionSuggesterProvider)
          .suggest(unrecognised);
    } on Object catch (_) {
      // `SubstitutionSuggester` promises never to throw. This catch exists
      // because a promise is not an enforcement — the same reasoning
      // `AddMealDescriptionSheet._estimate` records for its own estimator.
      result = const SuggestionsFailed(
        reason: SuggestionFailureReason.badResponse,
      );
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _suggesting = false;
      switch (result) {
        case SuggestionsReturned(:final outcomes):
          if (outcomes.isEmpty) {
            _noSuggestions = true;
            return;
          }
          // Every returned key replaces that line's `Unrecognised` outcome;
          // everything else — including lines the model did not answer — is
          // untouched.
          _results = [
            for (final outcome in results)
              if (outcome is Unrecognised)
                outcomes[SubstitutionEngine.key(outcome.ingredient.name)] ??
                    outcome
              else
                outcome,
          ];
        case SuggestionsFailed(:final reason):
          _suggestFailure = reason;
      }
    });
  }

  void _openProfileForEstimation() {
    // `maybeOf`, not `of`: a widget test may render this screen inside a
    // `MaterialApp` with no router, where `of` throws.
    GoRouter.maybeOf(context)?.go(kProfilePath);
  }

  /// Whether the save affordance renders: results exist and at least one
  /// outcome is not [Unrecognised] — a recipe of nothing the app recognised
  /// is noise, not something worth keeping.
  bool get _canSave {
    final results = _results;
    return results != null &&
        results.isNotEmpty &&
        results.any((outcome) => outcome is! Unrecognised);
  }

  Future<void> _save() async {
    final results = _results;
    if (results == null) {
      return;
    }
    final title = await SaveRecipeDialog.show(
      context,
      initialTitle: _lastTitle,
    );
    if (title == null || !mounted) {
      // Cancelled — the conversion on screen is untouched either way.
      return;
    }

    final recipe = SavedRecipe(
      id: _savedId,
      title: title,
      originalText: _pasteController.text,
      outcomes: results,
      savedAt: DateTime.now(),
    );

    try {
      final saved = await ref.read(savedRecipeRepositoryProvider).save(recipe);
      if (!mounted) {
        return;
      }
      setState(() {
        _savedId = saved.id;
        _lastTitle = saved.title;
        _saveFailed = false;
      });
      ref.invalidate(savedRecipesProvider);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(RecipeCopy.saved)));
    } on PersistenceException catch (_) {
      // The conversion stays exactly as it was — a failed save must never
      // look like a silent loss of the user's work.
      if (mounted) {
        setState(() => _saveFailed = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No back affordance: this is a tab root inside the `ShellRoute`, not
      // a pushed screen, so nothing is implied and none should be added.
      appBar: AppBar(
        title: const Text(RecipeCopy.title),
        actions: [
          IconButton(
            key: const Key('open_recipe_library'),
            tooltip: RecipeCopy.openLibrary,
            icon: const Icon(Icons.collections_bookmark_outlined),
            // A push, not a go: this stays inside the `ShellRoute` as a
            // child of the recipe tab route, so it keeps the tab bar and
            // gains its own back affordance — the tab root has none, its
            // child does. The path is built from `kRecipePath` rather than
            // spelled out: `app_router.dart` and this file import each other,
            // which Dart resolves without complaint, and #396 needs the same
            // import for `kProfilePath` anyway.
            onPressed: () => context.push('$kRecipePath/library'),
          ),
        ],
      ),
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
            if (_canSave) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(
                key: const Key('save_recipe_button'),
                onPressed: _save,
                child: const Text(RecipeCopy.save),
              ),
              if (_saveFailed) ...[
                const SizedBox(height: 4),
                const Text(
                  RecipeCopy.saveFailed,
                  key: Key('recipe_save_failed'),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
            if (_hasUnrecognised) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(
                key: const Key('suggest_button'),
                // Disabled while a request is in flight — never a second
                // request stacked on the first.
                onPressed: _suggesting ? null : _suggest,
                child: Text(
                  _suggesting
                      ? RecipeCopy.suggesting
                      : RecipeCopy.suggestButton,
                ),
              ),
              // Rendered only after a tap, never on build: this screen is a
              // tab root and `test/widget_test.dart` walks every tab without
              // interacting with any of them — an animation visible before a
              // tap is what hung `pumpAndSettle` for two router tests in M6.
              if (_suggesting) ...[
                const SizedBox(height: 8),
                const Center(
                  child: CircularProgressIndicator(
                    key: Key('suggest_progress'),
                  ),
                ),
              ],
              if (_noSuggestions) ...[
                const SizedBox(height: 4),
                const Text(
                  RecipeCopy.noSuggestions,
                  key: Key('recipe_no_suggestions'),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_suggestFailure != null) ...[
                const SizedBox(height: 8),
                _suggestFailureView(_suggestFailure!),
              ],
            ],
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

  /// One headline per [SuggestionFailureReason], and a way out for the one
  /// reason retrying cannot fix.
  ///
  /// **The deterministic results stay on screen through every failure** —
  /// this widget renders below them, never over them, and nothing here ever
  /// touches [_results].
  Widget _suggestFailureView(SuggestionFailureReason reason) {
    final theme = Theme.of(context);
    return Column(
      key: const Key('suggest_failure'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _suggestFailureHeadline(reason),
          key: const Key('suggest_failure_headline'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
        if (reason == SuggestionFailureReason.notConfigured) ...[
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              key: const Key('suggest_profile_button'),
              onPressed: _openProfileForEstimation,
              child: const Text(RecipeCopy.openProfile),
            ),
          ),
        ],
      ],
    );
  }

  static String _suggestFailureHeadline(
    SuggestionFailureReason reason,
  ) => switch (reason) {
    // Unreachable here — the button is absent below the empty-input case
    // (`_suggest` is only ever called with at least one `Unrecognised`
    // line) — and worded anyway, so an unhandled case is a compile error
    // rather than a blank headline.
    SuggestionFailureReason.emptyInput => RecipeCopy.suggestFailedBadResponse,
    SuggestionFailureReason.notConfigured =>
      RecipeCopy.suggestFailedNotConfigured,
    SuggestionFailureReason.offline => RecipeCopy.suggestFailedOffline,
    SuggestionFailureReason.rateLimited => RecipeCopy.suggestFailedRateLimited,
    SuggestionFailureReason.badResponse => RecipeCopy.suggestFailedBadResponse,
  };
}
