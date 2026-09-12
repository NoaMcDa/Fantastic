import 'package:fantastic/core/constants/recipe_copy.dart';
import 'package:fantastic/core/router/app_router.dart';
import 'package:fantastic/core/utils/numeric_input.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/domain/models/estimate_failure_reason.dart';
import 'package:fantastic/features/diary/domain/models/estimated_item.dart';
import 'package:fantastic/features/diary/domain/models/macro_source.dart';
import 'package:fantastic/features/diary/domain/models/meal_estimate.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_bottom_sheet.dart';
import 'package:fantastic/features/diary/presentation/widgets/estimate_failure_view.dart';
import 'package:fantastic/features/diary/presentation/widgets/estimate_review_list.dart';
import 'package:fantastic/features/recipe/domain/models/ingredient_outcome.dart';
import 'package:fantastic/features/recipe/domain/models/saved_recipe.dart';
import 'package:fantastic/features/recipe/domain/recipe_description_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Estimates a converted recipe's macros for the whole batch, divides by a
/// servings count, and hands one serving to `AddMealBottomSheet`.
///
/// **A recipe is a batch, not a meal.** Everything `MacroEstimator` returns
/// here describes the whole pot — dividing by [initialServings] (or whatever
/// the field currently holds) before anything is labelled "per serving" is
/// the one assertion most worth getting right, and the only figures that
/// ever reach the form are the divided ones.
///
/// Reuses `EstimateReviewList`, `EstimateFailureView` and
/// `AddMealBottomSheet` from the diary feature rather than copying any of
/// them — the same cross-feature presentation reuse `AddMealFab` already
/// established, and a copy of a shared safety surface is a second place the
/// same rule can drift.
///
/// **The total shown is the total logged** (#257): the per-serving row is
/// computed over [_items] as it stands on screen — after any removal — never
/// over a stored figure.
class RecipeMacrosSection extends ConsumerStatefulWidget {
  const RecipeMacrosSection({
    required this.outcomes,
    required this.recipeTitle,
    required this.date,
    required this.onSaved,
    this.initialServings,
    this.initialPerServing,
    super.key,
  });

  /// The outcomes currently on screen — the converted, keto version of the
  /// recipe. `RecipeDescriptionBuilder` turns these into the one description
  /// `MacroEstimator` is asked about; the original pasted recipe is never
  /// estimated.
  final List<IngredientOutcome> outcomes;

  /// Seeds `AddMealBottomSheet`'s name field when logging a serving, and the
  /// manual-entry escape from a failed estimate.
  final String recipeTitle;

  /// The day a logged serving is saved against — from `TodayTracker`, never
  /// `DateTime.now()` read inside `build`.
  final DateTime date;

  /// Called with a fresh estimate's servings count and per-serving totals so
  /// the screen can write them onto the stored `SavedRecipe`.
  final ValueChanged<({int servings, MacroTotals perServing})> onSaved;

  /// Bottom padding the scrolling body that hosts this section needs so its
  /// last control is not covered by a `SnackBar`.
  ///
  /// The same problem `AddMealFab.bodyClearance` names, arriving from the
  /// other direction: a `SnackBar` floats over the body rather than
  /// displacing it. It matters here specifically because **this section
  /// mounts at the moment a `SnackBar` appears** — saving the recipe is what
  /// brings it into existence, and `RecipeCopy.saved` is shown by the same
  /// tap. A user's next action is `ערכים למנה`, and for the SnackBar's
  /// lifetime that tap would land on the SnackBar instead of the button.
  /// Found by a test that reproduced the covered tap rather than working
  /// around it.
  static const double snackBarClearance = 72;

  /// The recipe's own stored servings count, if any — seeds the field on
  /// reopen.
  final int? initialServings;

  /// A previously saved per-serving total, if any. When present the per
  /// serving row and the log button render immediately, with no request:
  /// `MacroEstimator` is never asked about a recipe reopened exactly as it
  /// was saved.
  final MacroTotals? initialPerServing;

  @override
  ConsumerState<RecipeMacrosSection> createState() =>
      _RecipeMacrosSectionState();
}

class _RecipeMacrosSectionState extends ConsumerState<RecipeMacrosSection> {
  late final TextEditingController _servingsController = TextEditingController(
    text: (widget.initialServings ?? 1).toString(),
  );

  /// The batch's items from the most recent successful estimate *this
  /// session*. Null before the first attempt and on reopen until the user
  /// asks for a fresh one — `widget.initialPerServing` covers that gap.
  List<EstimatedItem>? _items;
  List<String> _unidentified = const [];

  /// The servings count [_items] was divided by. Captured at the moment of
  /// a successful estimate rather than read live from the field, so editing
  /// the field afterwards without re-estimating cannot silently re-divide an
  /// already-shown total by a different number.
  int? _servingsUsed;

  EstimateFailureReason? _failure;
  bool _estimating = false;

  @override
  void initState() {
    super.initState();
    _servingsController.addListener(_onServingsTyped);
  }

  @override
  void dispose() {
    _servingsController
      ..removeListener(_onServingsTyped)
      ..dispose();
    super.dispose();
  }

  void _onServingsTyped() => setState(() {});

  /// The field's value as a servings count, or null if it is not one.
  ///
  /// `NumericInput.positiveFinite` rejects `0`, `-1`, non-numeric text,
  /// `Infinity` and `NaN` in one place; rounding to an integer and requiring
  /// it to be at least 1 is this method's own remaining job.
  int? get _servings {
    final parsed = NumericInput.positiveFinite(_servingsController.text);
    if (parsed == null) {
      return null;
    }
    final rounded = parsed.round();
    return rounded >= 1 ? rounded : null;
  }

  bool get _canEstimate => !_estimating && _servings != null;

  /// `ערכים למנה` the first time, `חשבו מחדש` once a per-serving figure
  /// already exists to recalculate — from a reopened recipe or from a
  /// successful estimate earlier this session.
  String get _estimateButtonLabel =>
      widget.initialPerServing != null || _servingsUsed != null
      ? RecipeCopy.recalculateMacrosButton
      : RecipeCopy.estimateMacrosButton;

  /// The per-serving figures to show and to log, or null if there are none
  /// yet.
  ///
  /// Computed, never stored: summed over [_items] as it stands — which is
  /// what makes removing a review item move this row — and divided by
  /// [_servingsUsed]. Falls back to [RecipeMacrosSection.initialPerServing]
  /// only while no fresh estimate has run this session.
  MacroTotals? get _perServing {
    final items = _items;
    final divisor = _servingsUsed;
    if (items != null && divisor != null) {
      // The batch total comes from `EstimateReviewList` itself rather than a
      // second fold over the same list. There is one definition of "the
      // total" in the app and this is not allowed to become a second one:
      // #257's rule is that the total shown is the total logged, and a
      // private copy here would drift the moment that widget's getters
      // changed what they count. `AddMealDescriptionSheet._confirm` reads
      // them the same way.
      final batch = _reviewList(items);
      return MacroTotals(
        fatG: batch.fatG / divisor,
        netCarbsG: batch.netCarbsG / divisor,
        proteinG: batch.proteinG / divisor,
      );
    }
    return items == null ? widget.initialPerServing : null;
  }

  /// The review list for [items] as it stands — rendered in `build`, and read
  /// for its totals by [_perServing].
  EstimateReviewList _reviewList(List<EstimatedItem> items) =>
      EstimateReviewList(
        key: const Key('estimate_review_list'),
        items: items,
        unidentified: _unidentified,
        onRemove: _removeItem,
      );

  Future<void> _estimate() async {
    final servings = _servings;
    if (servings == null) {
      return;
    }
    setState(() {
      _estimating = true;
      _failure = null;
      _items = null;
    });

    final built = RecipeDescriptionBuilder.build(widget.outcomes);

    // A batch of nothing but `Flagged`/`Unrecognised` lines builds an empty
    // description. Refused locally, the same way the description sheet's own
    // estimate button stays disabled on empty text — a request already known
    // to fail costs a quota slot for nothing.
    if (built.description.isEmpty) {
      setState(() {
        _estimating = false;
        _failure = EstimateFailureReason.emptyInput;
        _unidentified = built.excluded;
      });
      return;
    }

    MealEstimate result;
    try {
      result = await ref
          .read(macroEstimatorProvider)
          .estimate(description: built.description);
    } on Object catch (_) {
      // `MacroEstimator` promises never to throw — the same reasoning
      // `AddMealDescriptionSheet._estimate` records for its own call.
      result = const EstimateFailed(reason: EstimateFailureReason.badResponse);
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _estimating = false;
      switch (result) {
        case EstimateSucceeded(:final items, :final unidentified):
          _items = List.of(items);
          _unidentified = [...unidentified, ...built.excluded];
          _servingsUsed = servings;
        case EstimateFailed(:final reason):
          _failure = reason;
      }
    });
  }

  void _removeItem(int index) => setState(() {
    _items = [..._items!]..removeAt(index);
  });

  Future<void> _save() async {
    final perServing = _perServing;
    final servings = _servingsUsed;
    if (_items == null || perServing == null || servings == null) {
      return;
    }
    widget.onSaved((servings: servings, perServing: perServing));
  }

  Future<void> _logServing() async {
    final perServing = _perServing;
    if (perServing == null) {
      return;
    }
    await AddMealBottomSheet.show(
      context,
      date: widget.date,
      initialName: widget.recipeTitle,
      initialFatG: perServing.fatG,
      initialNetCarbsG: perServing.netCarbsG,
      initialProteinG: perServing.proteinG,
      source: MacroSource.estimatedFromText,
    );
  }

  /// The failure view's manual-entry escape. Opens the plain form with no
  /// prefilled macros — the user types the per-serving figures off the
  /// recipe themselves, `MacroSource.manual` by the form's own default.
  Future<void> _openManual() async {
    if (!mounted) {
      return;
    }
    await AddMealBottomSheet.show(
      context,
      date: widget.date,
      initialName: widget.recipeTitle,
    );
  }

  void _openProfile() {
    // `maybeOf`, not `of`: a widget test may render this section inside a
    // `MaterialApp` with no router, where `of` throws.
    GoRouter.maybeOf(context)?.go(kProfilePath);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final perServing = _perServing;

    return Column(
      key: const Key('recipe_macros_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('recipe_servings_field'),
                controller: _servingsController,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: RecipeCopy.servingsFieldLabel,
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              key: const Key('recipe_estimate_button'),
              onPressed: _canEstimate ? _estimate : null,
              child: Text(_estimateButtonLabel),
            ),
          ],
        ),
        if (_estimating) ...[
          const SizedBox(height: 12),
          const Center(
            child: CircularProgressIndicator(
              key: Key('recipe_estimate_progress'),
            ),
          ),
        ],
        if (_failure != null) ...[
          const SizedBox(height: 12),
          EstimateFailureView(
            reason: _failure!,
            onRetry: _estimate,
            onManual: _openManual,
            onProfile: _openProfile,
          ),
        ],
        if (_items != null) ...[
          const SizedBox(height: 12),
          _reviewList(_items!),
        ],
        if (perServing != null) ...[
          const SizedBox(height: 12),
          Wrap(
            key: const Key('recipe_per_serving_row'),
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                RecipeCopy.perServingLabel,
                style: theme.textTheme.titleSmall,
              ),
              Text(
                RecipeCopy.perServingSummary(
                  perServing.fatG,
                  perServing.netCarbsG,
                  perServing.proteinG,
                ),
                textDirection: TextDirection.ltr,
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
        ],
        if (_items != null) ...[
          const SizedBox(height: 12),
          FilledButton.tonal(
            key: const Key('recipe_save_macros_button'),
            onPressed: _save,
            child: const Text(RecipeCopy.saveMacrosButton),
          ),
        ],
        if (perServing != null) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('recipe_log_serving_button'),
            onPressed: _logServing,
            child: const Text(RecipeCopy.logServingButton),
          ),
        ],
      ],
    );
  }
}
