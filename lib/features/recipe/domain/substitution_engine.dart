import 'package:fantastic/core/constants/ingredient_rules.dart';
import 'package:fantastic/core/constants/substitution_rules.dart';
import 'package:fantastic/core/utils/hebrew_text_normaliser.dart';
import 'package:fantastic/features/recipe/domain/models/ingredient_outcome.dart';
import 'package:fantastic/features/recipe/domain/models/parsed_ingredient.dart';
import 'package:fantastic/features/recipe/domain/models/substitution.dart';

/// Answers one of four honest things about every ingredient line: a known
/// keto replacement, already fine, known non-keto with no substitute, or
/// genuinely unknown.
///
/// Pure Dart, no I/O, no Flutter: three tables and a matcher. **No stemming
/// and no fuzzy matching** — Hebrew morphology is the hard part, and a fuzzy
/// matcher is what maps סולת to סלט. Singular and plural are listed as
/// separate aliases instead. Exact after normalisation, no corrupted-letter
/// tolerance: pasted text is typed, not OCR'd — `HebrewLabelParser`'s
/// one-letter absorption exists for Tesseract, not for this.
class SubstitutionEngine {
  /// Defaults to [SubstitutionRules]; a test passes a small table so an
  /// assertion is not made against the whole shipped set.
  const SubstitutionEngine({
    List<SubstitutionRow>? substitutions,
    List<String>? staples,
  }) : _substitutions = substitutions ?? SubstitutionRules.substitutions,
       _staples = staples ?? SubstitutionRules.ketoStaples;

  final List<SubstitutionRow> _substitutions;
  final List<String> _staples;

  static final RegExp _words = RegExp(r'\s+');

  /// The matching key: normalise → fold final forms → lowercase → trim.
  ///
  /// Public because #396's parser must match a model's echo of a line with
  /// the same function.
  ///
  /// Folding is applied to both sides — the tables in
  /// [SubstitutionRules] are stored already folded (asserted by
  /// `test/core/constants/substitution_rules_test.dart`) and the input is
  /// folded here. **It is not added to [HebrewTextNormaliser.normalise]**:
  /// `IngredientClassifierImpl` matches `IngredientRules` entries by
  /// `contains` on the unfolded normalised input, and `מלטודקסטרין` ends in
  /// a final nun, so folding there would silently stop that rule firing on
  /// every label that prints it.
  static String key(String text) =>
      _foldFinalForms(HebrewTextNormaliser.normalise(text))
          .toLowerCase()
          .trim();

  static String _foldFinalForms(String text) => text
      .replaceAll('ך', 'כ')
      .replaceAll('ם', 'מ')
      .replaceAll('ן', 'נ')
      .replaceAll('ף', 'פ')
      .replaceAll('ץ', 'צ');

  /// Classifies one ingredient. Never throws — an empty [ParsedIngredient.name]
  /// is [Unrecognised], never an error.
  ///
  /// Matching order, stopping at the first hit, and load-bearing: `שמן קנולה`
  /// is a substitution alias **and** on `IngredientRules`' forbidden list, and
  /// must come back [Substituted] — we have a better oil to suggest — not
  /// [Flagged].
  ///
  /// 1. **An exact alias**, tried before anything else, including staples.
  ///    `קמח שקדים` (almond flour, a staple) *begins* with the word `קמח`
  ///    (row 1's bare wheat-flour alias) — without an exact match taking
  ///    priority, an already-keto almond flour would "whole word" match that
  ///    unrelated shorter alias and come back `Substituted` for itself under
  ///    a wheat-flour reason. An exact match can never be ambiguous this way,
  ///    so both tables get their exact-match pass before either gets its
  ///    whole-word pass.
  /// 2. An exact staple.
  /// 3. The longest alias that appears in the key as a whole word, tried
  ///    again with [HebrewTextNormaliser.stripPrefix] applied to the key's
  ///    first word (`הקמח` → `קמח`), additively — for a name that is not
  ///    itself one alias but *contains* one, `קמח כוסמין מלא` reaching the
  ///    ten-character `קמח כוסמין` row rather than the three-character `קמח`
  ///    row.
  /// 4. The same whole-word search against [SubstitutionRules.ketoStaples].
  /// 5. [IngredientRules] — `contains`, exactly as `IngredientClassifierImpl`
  ///    matches it: on the *unfolded* normalised form, tried with each
  ///    word's prefix stripped. Folding is deliberately skipped here for the
  ///    same reason it is absent from the shared normaliser — a final-letter
  ///    sweetener like `מלטודקסטרין` must still match its own unfolded rule
  ///    entry.
  /// 6. [Unrecognised].
  IngredientOutcome classify(ParsedIngredient ingredient) {
    final rawKey = key(ingredient.name);
    if (rawKey.isEmpty) {
      return Unrecognised(ingredient);
    }
    final strippedKey = _stripFirstWord(rawKey);

    final exactSubstitution =
        _exactSubstitution(rawKey) ?? _exactSubstitution(strippedKey);
    if (exactSubstitution != null) {
      return Substituted(
        ingredient,
        substitution: _toSubstitution(exactSubstitution),
      );
    }
    if (_exactStaple(rawKey) || _exactStaple(strippedKey)) {
      return AlreadyKeto(ingredient);
    }

    final substitutionRow =
        _matchSubstitution(rawKey) ?? _matchSubstitution(strippedKey);
    if (substitutionRow != null) {
      return Substituted(
        ingredient,
        substitution: _toSubstitution(substitutionRow),
      );
    }

    if (_matchesStaple(rawKey) || _matchesStaple(strippedKey)) {
      return AlreadyKeto(ingredient);
    }

    if (_matchesIngredientRules(ingredient.name)) {
      return Flagged(ingredient);
    }

    return Unrecognised(ingredient);
  }

  static Substitution _toSubstitution(SubstitutionRow row) => Substitution(
    replacement: row.replacement,
    ratio: row.ratio,
    reason: row.reason,
  );

  SubstitutionRow? _exactSubstitution(String candidateKey) {
    if (candidateKey.isEmpty) {
      return null;
    }
    for (final row in _substitutions) {
      if (row.aliases.contains(candidateKey)) {
        return row;
      }
    }
    return null;
  }

  bool _exactStaple(String candidateKey) =>
      candidateKey.isNotEmpty && _staples.contains(candidateKey);

  /// Preserves input order. Empty in, empty out.
  List<IngredientOutcome> convert(List<ParsedIngredient> ingredients) =>
      ingredients.map(classify).toList(growable: false);

  SubstitutionRow? _matchSubstitution(String candidateKey) {
    if (candidateKey.isEmpty) {
      return null;
    }
    SubstitutionRow? best;
    var bestAliasLength = -1;
    for (final row in _substitutions) {
      for (final alias in row.aliases) {
        if (alias.length > bestAliasLength &&
            _isWholeWordMatch(candidateKey, alias)) {
          best = row;
          bestAliasLength = alias.length;
        }
      }
    }
    return best;
  }

  bool _matchesStaple(String candidateKey) {
    if (candidateKey.isEmpty) {
      return false;
    }
    return _staples.any((staple) => _isWholeWordMatch(candidateKey, staple));
  }

  static bool _isWholeWordMatch(String key, String alias) {
    if (alias.isEmpty) {
      return false;
    }
    if (key == alias) {
      return true;
    }
    return key.startsWith('$alias ') ||
        key.endsWith(' $alias') ||
        key.contains(' $alias ');
  }

  static String _stripFirstWord(String candidateKey) {
    final words = candidateKey.split(' ');
    if (words.isEmpty) {
      return candidateKey;
    }
    final strippedFirst = HebrewTextNormaliser.stripPrefix(words.first);
    if (strippedFirst == words.first) {
      return candidateKey;
    }
    return ([strippedFirst, ...words.skip(1)]).join(' ');
  }

  /// `IngredientClassifierImpl._candidateForms`, reproduced rather than
  /// imported: `domain/` may not depend on another feature's `data/` layer
  /// (#393's whole reason for existing), so the normalise-then-strip-prefix
  /// shape is duplicated here in miniature instead of shared.
  bool _matchesIngredientRules(String name) {
    final normalised = HebrewTextNormaliser.normalise(name)
        .toLowerCase()
        .trim();
    final words = normalised.split(_words);
    final stripped = words.map(HebrewTextNormaliser.stripPrefix).join(' ');
    final forms = stripped == normalised
        ? [normalised]
        : [normalised, stripped];
    return forms.any(
      (form) =>
          IngredientRules.allForbiddenSeedOils.any(form.contains) ||
          IngredientRules.allInsulinSpikingSweeteners.any(form.contains),
    );
  }
}
