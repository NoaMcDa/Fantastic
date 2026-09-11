import 'package:fantastic/core/constants/add_meal_copy.dart';
import 'package:fantastic/features/diary/presentation/widgets/coming_soon_sheet.dart';
import 'package:flutter/material.dart';

/// Photograph the plate or the label.
///
/// **A placeholder with its final signature**, for the reason
/// `AddMealDescriptionSheet` gives: #324 fills the body in and changes
/// nothing above it.
abstract final class AddMealPhotoSheet {
  /// Opens the photo mode for [date].
  ///
  /// [date] is unused while this is a placeholder and is part of the contract
  /// regardless — see `AddMealDescriptionSheet.show`.
  static Future<void> show(BuildContext context, {required DateTime date}) =>
      ComingSoonSheet.show(
        context,
        title: AddMealCopy.photoTitle,
        sheetKey: 'add_meal_photo_sheet',
      );
}
