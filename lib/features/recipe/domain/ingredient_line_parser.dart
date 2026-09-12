import 'package:fantastic/core/utils/hebrew_text_normaliser.dart';
import 'package:fantastic/features/recipe/domain/models/parsed_ingredient.dart';

/// Splits one pasted recipe line into a quantity, a unit and an ingredient
/// name.
///
/// Pure Dart, never throws. A line this cannot make sense of is not an
/// error — its whole text becomes [ParsedIngredient.name] with a null
/// quantity, because a recipe line with no recognisable measurement (`מלח`)
/// is exactly as valid as one with a rich one (`2 כוסות קמח`).
abstract final class IngredientLineParser {
  /// A bracketed note — kept in [ParsedIngredient.raw], dropped from
  /// [ParsedIngredient.name]: `קמח (מנופה)` → `קמח`.
  static final RegExp _bracketed = RegExp(r'\([^)]*\)');

  /// The `-` or `:` a Hebrew blog uses between a name and a trailing
  /// quantity: `קמח - 2 כוסות`.
  static final RegExp _separator = RegExp(r'\s*[-:]\s*');

  static final RegExp _wordSplit = RegExp(r'\s+');

  /// `1/2`, `3/4` — a numeral divided by a numeral.
  static final RegExp _numericFraction = RegExp(r'^(\d+)/(\d+)$');

  /// A whole number glued to a Unicode vulgar fraction: `1½`.
  static final RegExp _gluedMixedNumber = RegExp(r'^(\d+)([½¼¾⅓⅔])$');

  static final RegExp _wholeNumber = RegExp(r'^\d+$');

  /// Hebrew fraction words, bare — `חצי כוס` (half a cup).
  static const Map<String, double> _fractionWords = {
    'חצי': 0.5,
    'רבע': 0.25,
    'שליש': 1 / 3,
  };

  /// Unicode vulgar fractions, bare — `½ כוס`.
  static const Map<String, double> _vulgarFractions = {
    '½': 0.5,
    '¼': 0.25,
    '¾': 0.75,
    '⅓': 1 / 3,
    '⅔': 2 / 3,
  };

  /// "Three quarters" as two separate words — the one fraction that is not
  /// one token.
  static const List<String> _threeQuartersWords = ['שלושת', 'רבעי'];
  static const double _threeQuartersValue = 0.75;

  /// Parser data, not a product rule — deliberately not in
  /// `lib/core/constants/`. Every entry is written exactly as it appears
  /// after [HebrewTextNormaliser.normalise], which already canonicalises
  /// geresh variants to a plain apostrophe.
  static const Set<String> units = {
    'כוס',
    'כוסות',
    'כף',
    'כפות',
    'כפית',
    'כפיות',
    'גרם',
    "ג'",
    'ק"ג',
    'מ"ל',
    'ליטר',
    'יחידה',
    'יחידות',
    'חבילה',
    'חבילות',
    'קורט',
    'cup',
    'cups',
    'tbsp',
    'tsp',
    'g',
    'kg',
    'ml',
    'oz',
  };

  /// Never throws. An unparseable line is the whole string as [name][1]
  /// with a null quantity; an empty line is an empty name.
  ///
  /// [1]: ParsedIngredient.name
  static ParsedIngredient parse(String line) {
    final normalised = HebrewTextNormaliser.normalise(line);
    if (normalised.isEmpty) {
      return ParsedIngredient(name: '', raw: line);
    }

    final withoutBrackets = normalised
        .replaceAll(_bracketed, ' ')
        .replaceAll(_wordSplit, ' ')
        .trim();
    if (withoutBrackets.isEmpty) {
      return ParsedIngredient(name: '', raw: line);
    }

    // Quantity-first: "2 כוסות קמח".
    final leading = _tryLeadingQuantity(withoutBrackets);
    if (leading != null) {
      return ParsedIngredient(
        name: leading.remainder.trim(),
        raw: line,
        quantity: leading.quantity,
        unit: leading.unit,
      );
    }

    // Name, then separator, then quantity: "קמח - 2 כוסות".
    final separatorMatch = _separator.firstMatch(withoutBrackets);
    if (separatorMatch != null) {
      final namePart = withoutBrackets
          .substring(0, separatorMatch.start)
          .trim();
      final tail = withoutBrackets.substring(separatorMatch.end).trim();
      if (namePart.isNotEmpty && tail.isNotEmpty) {
        final tailQuantity = _tryLeadingQuantity(tail);
        if (tailQuantity != null && tailQuantity.remainder.trim().isEmpty) {
          return ParsedIngredient(
            name: namePart,
            raw: line,
            quantity: tailQuantity.quantity,
            unit: tailQuantity.unit,
          );
        }
      }
    }

    // No quantity found anywhere — the whole line is the name.
    return ParsedIngredient(name: withoutBrackets, raw: line);
  }

  /// Tries to read a quantity (and optional unit) from the start of [text].
  /// Returns null when [text] does not open with one, in which case the
  /// caller falls back to treating [text] as a bare name.
  static _LeadingQuantity? _tryLeadingQuantity(String text) {
    final words = text
        .split(_wordSplit)
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) {
      return null;
    }

    double? quantity;
    var index = 0;

    final numeric = _tryNumericQuantity(words, 0);
    if (numeric != null) {
      quantity = numeric.value;
      index = numeric.nextIndex;
    } else {
      final fractionWord = _tryFractionWord(words, 0);
      if (fractionWord != null) {
        quantity = fractionWord.value;
        index = fractionWord.nextIndex;
      }
    }

    // "כוס וחצי" — a bare unit followed by "ו" + a fraction word means one
    // of that unit, plus the fraction: 1.5 כוס.
    if (quantity == null && units.contains(words[0]) && words.length > 1) {
      final idiom = _tryVavFraction(words[1]);
      if (idiom != null) {
        return _LeadingQuantity(
          quantity: 1.0 + idiom,
          unit: words[0],
          remainder: words.sublist(2).join(' '),
        );
      }
    }

    if (quantity == null) {
      return null;
    }

    // A continuation of the same form: "2 וחצי" = 2.5.
    if (index < words.length) {
      final vav = _tryVavFraction(words[index]);
      if (vav != null) {
        quantity += vav;
        index++;
      }
    }

    String? unit;
    if (index < words.length && units.contains(words[index])) {
      unit = words[index];
      index++;
    }

    return _LeadingQuantity(
      quantity: quantity,
      unit: unit,
      remainder: words.sublist(index).join(' '),
    );
  }

  static _NumericMatch? _tryNumericQuantity(List<String> words, int index) {
    final token = words[index];

    final glued = _gluedMixedNumber.firstMatch(token);
    if (glued != null) {
      final wholePart = double.parse(glued.group(1)!);
      final fraction = _vulgarFractions[glued.group(2)!]!;
      return _NumericMatch(wholePart + fraction, index + 1);
    }

    // A mixed number written as two tokens: "1 1/2".
    if (_wholeNumber.hasMatch(token) && index + 1 < words.length) {
      final fractionMatch = _numericFraction.firstMatch(words[index + 1]);
      if (fractionMatch != null) {
        final wholePart = double.parse(token);
        final numerator = double.parse(fractionMatch.group(1)!);
        final denominator = double.parse(fractionMatch.group(2)!);
        return _NumericMatch(wholePart + numerator / denominator, index + 2);
      }
    }

    final vulgar = _vulgarFractions[token];
    if (vulgar != null) {
      return _NumericMatch(vulgar, index + 1);
    }

    final fractionOnly = _numericFraction.firstMatch(token);
    if (fractionOnly != null) {
      final numerator = double.parse(fractionOnly.group(1)!);
      final denominator = double.parse(fractionOnly.group(2)!);
      return _NumericMatch(numerator / denominator, index + 1);
    }

    final value = double.tryParse(token);
    if (value != null && value.isFinite) {
      return _NumericMatch(value, index + 1);
    }

    return null;
  }

  static _NumericMatch? _tryFractionWord(List<String> words, int index) {
    if (index + 1 < words.length &&
        words[index] == _threeQuartersWords[0] &&
        words[index + 1] == _threeQuartersWords[1]) {
      return _NumericMatch(_threeQuartersValue, index + 2);
    }
    final value = _fractionWords[words[index]];
    if (value != null) {
      return _NumericMatch(value, index + 1);
    }
    return null;
  }

  /// A word beginning with the conjunction "ו" whose remainder is a known
  /// fraction word — `וחצי` = "and a half".
  static double? _tryVavFraction(String word) {
    if (!word.startsWith('ו') || word.length < 2) {
      return null;
    }
    return _fractionWords[word.substring(1)];
  }
}

class _NumericMatch {
  const _NumericMatch(this.value, this.nextIndex);

  final double value;
  final int nextIndex;
}

class _LeadingQuantity {
  const _LeadingQuantity({
    required this.quantity,
    required this.unit,
    required this.remainder,
  });

  final double quantity;
  final String? unit;
  final String remainder;
}
