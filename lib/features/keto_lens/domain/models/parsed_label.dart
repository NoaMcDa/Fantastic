import 'package:fantastic/core/utils/list_equality.dart';
import 'package:fantastic/features/keto_lens/domain/models/serving_basis.dart';
import 'package:meta/meta.dart';

/// Structured nutritional data extracted from a scanned label's OCR text.
///
/// Every macro is nullable because OCR routinely extracts some values and not
/// others — a null means "not found", never zero.
///
/// Pure domain: no Flutter, no persistence package, no Riverpod.
@immutable
class ParsedLabel {
  const ParsedLabel({
    this.fatG,
    this.netCarbsG,
    this.proteinG,
    this.ingredients = const [],
    this.rawText = '',
    this.basis = ServingBasis.unknown,
    this.servingGrams,
    this.totalCarbsG,
    this.fibreG,
    this.sugarsG,
    this.polyolsG,
    this.energyKcal,
  });

  final double? fatG;
  final double? netCarbsG;
  final double? proteinG;

  /// Ingredient tokens extracted after the "רכיבים:" marker.
  final List<String> ingredients;

  /// Raw OCR output before parsing — retained so a mis-parse can be diagnosed
  /// from a bug report.
  final String rawText;

  /// What [fatG], [netCarbsG] and [proteinG] are measured against.
  ///
  /// Defaults to [ServingBasis.unknown] so every existing construction — every
  /// fixture, every test, the failure path in `parse` — keeps the behaviour it
  /// had before #257: no scaling, and the sheet's "check the serving size"
  /// caption.
  final ServingBasis basis;

  /// The declared serving weight in grams, where the label printed one
  /// (`גודל מנה 30 גרם`).
  ///
  /// Only a default for the sheet's amount field — it is what the *package*
  /// calls a serving, not what the user ate. Null when no such row was found,
  /// which is most labels.
  final double? servingGrams;

  /// Total carbohydrate and fibre, as printed.
  ///
  /// [netCarbsG] is already their difference; these are kept because a polyol
  /// subtraction has to be checked against them, and because the energy
  /// cross-check needs *total* carbohydrate rather than net.
  final double? totalCarbsG;
  final double? fibreG;

  /// `מתוכם סוכרים`.
  ///
  /// Moves no band — that is `MacroClassifier`'s rule — but it bounds the
  /// polyol residual, and it is the most persuasive thing the sheet can print
  /// under an amber chip.
  final double? sugarsG;

  /// `מתוכם רב כהליים`.
  ///
  /// Declared *inside* total carbohydrate on an Israeli label, so a product
  /// sweetened cleanly with polyols prints carbs the body does not see.
  final double? polyolsG;

  /// `אנרגיה (קלוריות)` — the panel's own check on itself.
  final double? energyKcal;

  /// Whether at least one macro was successfully extracted.
  ///
  /// Lets the result sheet decide whether to render the macro card at all.
  bool get hasMacros => fatG != null || netCarbsG != null || proteinG != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedLabel &&
          other.fatG == fatG &&
          other.totalCarbsG == totalCarbsG &&
          other.fibreG == fibreG &&
          other.sugarsG == sugarsG &&
          other.polyolsG == polyolsG &&
          other.energyKcal == energyKcal &&
          other.netCarbsG == netCarbsG &&
          other.proteinG == proteinG &&
          other.rawText == rawText &&
          other.basis == basis &&
          other.servingGrams == servingGrams &&
          listEquals(other.ingredients, ingredients);

  @override
  int get hashCode => Object.hash(
    fatG,
    netCarbsG,
    proteinG,
    rawText,
    basis,
    servingGrams,
    listHash(ingredients),
    totalCarbsG,
    fibreG,
    sugarsG,
    polyolsG,
    energyKcal,
  );
}
