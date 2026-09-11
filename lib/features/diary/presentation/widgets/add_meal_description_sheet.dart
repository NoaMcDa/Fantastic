import 'package:fantastic/core/constants/add_meal_copy.dart';
import 'package:fantastic/features/diary/presentation/widgets/coming_soon_sheet.dart';
import 'package:flutter/material.dart';

/// Describe a meal in words; the estimator does the arithmetic.
///
/// **A placeholder with its final signature.** The flow that fills this in
/// (#323) replaces the body and touches nothing else — not `AddMealFab`, not
/// the chooser — which is what makes the chooser independently mergeable
/// ahead of either flow.
abstract final class AddMealDescriptionSheet {
  /// Opens the description mode for [date].
  ///
  /// [date] is unused while this is a placeholder and is part of the contract
  /// regardless: the sheet that replaces this one logs against a day, and the
  /// providers it reads are families keyed on it.
  static Future<void> show(BuildContext context, {required DateTime date}) =>
      ComingSoonSheet.show(
        context,
        title: AddMealCopy.descriptionTitle,
        sheetKey: 'add_meal_description_sheet',
      );
}
