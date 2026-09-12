import 'package:meta/meta.dart';

/// One ingredient line, split into what a quantity means and what the food
/// is.
///
/// [name] is what [SubstitutionEngine] matches against — it never includes
/// the quantity or unit, so a rule table only has to know ingredient words,
/// never units or numbers.
@immutable
class ParsedIngredient {
  const ParsedIngredient({
    required this.name,
    required this.raw,
    this.quantity,
    this.unit,
  });

  /// The ingredient with quantity and unit removed, trimmed. Never empty
  /// unless [raw] was.
  final String name;

  /// The line as pasted.
  final String raw;

  final double? quantity;
  final String? unit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedIngredient &&
          other.name == name &&
          other.raw == raw &&
          other.quantity == quantity &&
          other.unit == unit;

  @override
  int get hashCode => Object.hash(name, raw, quantity, unit);

  @override
  String toString() =>
      'ParsedIngredient(name: $name, raw: $raw, quantity: $quantity, unit: $unit)';
}
