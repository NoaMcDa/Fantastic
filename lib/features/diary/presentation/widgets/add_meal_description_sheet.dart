import 'package:fantastic/core/constants/add_meal_copy.dart';
import 'package:fantastic/core/router/app_router.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/domain/models/estimate_failure_reason.dart';
import 'package:fantastic/features/diary/domain/models/estimated_item.dart';
import 'package:fantastic/features/diary/domain/models/macro_source.dart';
import 'package:fantastic/features/diary/domain/models/meal_estimate.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_bottom_sheet.dart';
import 'package:fantastic/features/diary/presentation/widgets/estimate_failure_view.dart';
import 'package:fantastic/features/diary/presentation/widgets/estimate_review_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Describe a meal in words; the estimator does the arithmetic; the user
/// checks it before anything is saved.
///
/// **The engine is not the safety mechanism — this screen is.** The daily net
/// carb budget is 20 g, and the best 2026 vision model's 80.7 kcal mean
/// calorie error is 20 g of carbohydrate. `MealLoggingService` rolls whatever
/// is saved into the `DailyLog` and hands the day to `AdaptationPhaseService`,
/// so a wrong estimate reaches the streak. This sheet stands between the two
/// by showing the working and then handing off to the form the user already
/// knows, which owns validation and saving.
///
/// Depends on `MacroEstimator`, the **interface**, and never on the remote
/// implementation — which is what lets every test here run with a fake and no
/// network.
///
/// State is local rather than a notifier: the estimate belongs to one open
/// sheet and dies with it, and `design/m2_handoff.md`'s convention is
/// parameters over un-overridable providers.
class AddMealDescriptionSheet extends ConsumerStatefulWidget {
  const AddMealDescriptionSheet({required this.date, super.key});

  /// The day the meal is logged against.
  final DateTime date;

  /// Signature unchanged from the placeholder #322 shipped, so `AddMealFab`
  /// is not touched by this issue.
  static Future<void> show(BuildContext context, {required DateTime date}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => AddMealDescriptionSheet(
          date: date,
          key: const Key('add_meal_description_sheet'),
        ),
      );

  @override
  ConsumerState<AddMealDescriptionSheet> createState() =>
      _AddMealDescriptionSheetState();
}

class _AddMealDescriptionSheetState
    extends ConsumerState<AddMealDescriptionSheet> {
  final TextEditingController _description = TextEditingController();

  /// The items still in the review list.
  ///
  /// A copy rather than the `EstimateSucceeded` itself, because removing an
  /// item has to change the total and the estimate is immutable. The total is
  /// then summed over what is on screen — which is the #257 rule: the number
  /// in front of the user when they save is the number that gets saved.
  List<EstimatedItem>? _items;
  List<String> _unidentified = const [];

  EstimateFailureReason? _failure;
  bool _estimating = false;

  @override
  void initState() {
    super.initState();
    // Drives the estimate button's enabled state off what is typed.
    _description.addListener(_onTyped);
  }

  @override
  void dispose() {
    _description
      ..removeListener(_onTyped)
      ..dispose();
    super.dispose();
  }

  void _onTyped() => setState(() {});

  bool get _canEstimate => !_estimating && _description.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      // Lifts the field clear of the software keyboard, as
      // `AddMealBottomSheet` does.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AddMealCopy.descriptionTitle,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('meal_description_field'),
              controller: _description,
              // **Never disabled, not even mid-estimate.** What the user typed
              // stays legible while they wait, and stays legible after a
              // failure — nothing they wrote is ever discarded.
              maxLines: 3,
              minLines: 2,
              decoration: const InputDecoration(
                labelText: AddMealCopy.descriptionFieldLabel,
                hintText: AddMealCopy.descriptionHint,
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('estimate_button'),
              onPressed: _canEstimate ? _estimate : null,
              child: Text(
                _estimating ? AddMealCopy.estimating : AddMealCopy.estimate,
              ),
            ),
            if (_estimating) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(key: Key('estimate_progress')),
              ),
            ],
            if (_failure != null) ...[
              const SizedBox(height: 16),
              EstimateFailureView(
                reason: _failure!,
                onRetry: _estimate,
                onManual: _openManual,
                onProfile: _openProfile,
              ),
            ],
            if (_items != null) ...[
              const SizedBox(height: 16),
              EstimateReviewList(
                key: const Key('estimate_review_list'),
                items: _items!,
                unidentified: _unidentified,
                onRemove: _removeItem,
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('estimate_confirm_button'),
                // Disabled on an empty list rather than handing over a
                // zero-macro meal: a meal with no macros saves without
                // complaint and is invisible in the day's totals.
                onPressed: _items!.isEmpty ? null : _confirm,
                child: const Text(AddMealCopy.reviewAndSave),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _estimate() async {
    setState(() {
      _estimating = true;
      _failure = null;
      _items = null;
      _unidentified = const [];
    });

    MealEstimate result;
    try {
      result = await ref
          .read(macroEstimatorProvider)
          .estimate(description: _description.text);
    } on Object catch (_) {
      // `MacroEstimator` promises never to throw. This catch exists because a
      // promise is not an enforcement: a future implementation that breaks it
      // must not be able to take the sheet down with it.
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
          _unidentified = unidentified;
        case EstimateFailed(:final reason):
          _failure = reason;
      }
    });
  }

  void _removeItem(int index) => setState(() {
    // A new list, not a mutation: the old one is what the previous frame
    // rendered, and editing it in place is how a stale total survives.
    _items = [..._items!]..removeAt(index);
  });

  /// Opens the manual form, prefilled from whatever is on screen.
  ///
  /// [source] is what the opener knew, not what the fields look like: a user
  /// who retypes every figure of an estimate has still reached the number
  /// through one.
  Future<void> _openManual({
    double? fatG,
    double? netCarbsG,
    double? proteinG,
    MacroSource source = MacroSource.manual,
  }) async {
    final navigator = Navigator.of(context);
    final name = _trimmedName;
    navigator.pop();
    if (!navigator.mounted) {
      return;
    }
    final host = navigator.context;
    if (!host.mounted) {
      return;
    }
    await AddMealBottomSheet.show(
      host,
      date: widget.date,
      initialName: name,
      initialFatG: fatG,
      initialNetCarbsG: netCarbsG,
      initialProteinG: proteinG,
      source: source,
    );
  }

  Future<void> _confirm() {
    final list = EstimateReviewList(
      items: _items!,
      unidentified: _unidentified,
      onRemove: _removeItem,
    );
    // Summed over the list as it stands, so what was reviewed is what is
    // prefilled. `GramsText.format` inside the form rounds to one decimal, so
    // `0.17999999999999988` cannot reach a field — the defect
    // `design/m8_preflight.md` recorded from the scan prefill.
    return _openManual(
      fatG: list.fatG,
      netCarbsG: list.netCarbsG,
      proteinG: list.proteinG,
      source: MacroSource.estimatedFromText,
    );
  }

  void _openProfile() {
    // `maybeOf`, not `of`: this sheet is rendered in widget tests that supply
    // a `MaterialApp` and no router, and `of` throws there. A sheet that
    // closes and goes nowhere is a fine degradation; a crash is not.
    final router = GoRouter.maybeOf(context);
    Navigator.of(context).pop();
    router?.go(kProfilePath);
  }

  /// The description, cut to the name field's own maximum.
  ///
  /// Trimmed for the *name* only — the estimate is run on the whole text.
  String get _trimmedName {
    final text = _description.text.trim();
    return text.length > AddMealBottomSheet.maxNameLength
        ? text.substring(0, AddMealBottomSheet.maxNameLength)
        : text;
  }
}
