import 'package:fantastic/core/utils/list_equality.dart';
import 'package:meta/meta.dart';

/// Structured nutritional data extracted from a scanned label's OCR text.
///
/// Every macro is nullable because OCR routinely extracts some values and not
/// others — a null means "not found", never zero.
///
/// Pure domain: no Flutter, Isar or Riverpod.
@immutable
class ParsedLabel {
  const ParsedLabel({
    this.fatG,
    this.netCarbsG,
    this.proteinG,
    this.ingredients = const [],
    this.rawText = '',
  });

  final double? fatG;
  final double? netCarbsG;
  final double? proteinG;

  /// Ingredient tokens extracted after the "רכיבים:" marker.
  final List<String> ingredients;

  /// Raw OCR output before parsing — retained so a mis-parse can be diagnosed
  /// from a bug report.
  final String rawText;

  /// Whether at least one macro was successfully extracted.
  ///
  /// Lets the result sheet decide whether to render the macro card at all.
  bool get hasMacros => fatG != null || netCarbsG != null || proteinG != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedLabel &&
          other.fatG == fatG &&
          other.netCarbsG == netCarbsG &&
          other.proteinG == proteinG &&
          other.rawText == rawText &&
          listEquals(other.ingredients, ingredients);

  @override
  int get hashCode =>
      Object.hash(fatG, netCarbsG, proteinG, rawText, listHash(ingredients));
}
