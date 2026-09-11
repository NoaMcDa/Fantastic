import 'package:fantastic/core/constants/ingredient_rules.dart';
import 'package:fantastic/features/keto_lens/data/parsers/hebrew_text_normaliser.dart';
import 'package:fantastic/features/keto_lens/domain/models/ingredient_verdict.dart';
import 'package:fantastic/features/keto_lens/domain/models/verdict_badge.dart';
import 'package:fantastic/features/keto_lens/domain/services/ingredient_classifier.dart';
import 'package:meta/meta.dart';

/// Rule-based ingredient classification, worst badge wins.
///
/// Pure Dart and pure CPU: with `HebrewLabelParser` it is one of the only two
/// parts of the scan pipeline that can be verified without a camera.
///
/// ## The rules live in `IngredientRules`
///
/// Not here. `CLAUDE.md` names `lib/core/constants/ingredient_rules.dart` as
/// the spec, and the `IngredientClassifier` interface says implementations
/// read it "rather than redeclaring them, so the forbidden and clean sets
/// have one source of truth". #82's snippet declared its own copies; see
/// `design/m6_preflight.md` §1.4.
///
/// ## What "clean" does and does not mean here
///
/// An unrecognised token is **not** flagged. The interface documents that
/// deliberately — *"the verdict describes what was found, not what was
/// understood"* — so a list of entirely unknown ingredients earns
/// `cleanKeto`. [IngredientVerdict.matchedCleanIngredients] exists so the UI
/// can tell that case apart from a list where something was positively
/// recognised as clean, and word its copy honestly.
/// `design/m6_preflight.md` §4.1 has the reasoning.
class IngredientClassifierImpl implements IngredientClassifier {
  const IngredientClassifierImpl();

  /// Splits a token into words so each can be tried without its prefix.
  static final RegExp _words = RegExp(r'\s+');

  @override
  IngredientVerdict classify(List<String> ingredients) {
    final flagged = <String>[];
    final matchedClean = <String>[];
    final badges = <VerdictBadge>[];

    for (final ingredient in ingredients) {
      final forms = _candidateForms(ingredient);

      // Descending severity. A token naming both canola and olive oil is
      // non-keto: the worst thing in it is what the badge is about.
      if (_matches(forms, IngredientRules.allForbiddenSeedOils)) {
        flagged.add(ingredient);
        badges.add(VerdictBadge.nonKeto);
        continue;
      }
      if (_matches(forms, IngredientRules.allInsulinSpikingSweeteners)) {
        flagged.add(ingredient);
        badges.add(VerdictBadge.cautionQuantityDependent);
        continue;
      }
      // "Vegetable oil" is a caution only while the plant is unnamed. A
      // label reading `שמן צמחי (קוקוס)` has named it, and flagging that
      // would train the user to ignore the amber badge — which is how a
      // warning stops working. The bracketed plant is not the full
      // `שמן קוקוס` the clean list holds, so `cleanOilSources` is consulted
      // in this branch and nowhere else.
      final unspecifiedOil = _matches(
        forms,
        IngredientRules.unspecifiedVegetableOils,
      );
      final clean =
          _matches(forms, IngredientRules.allCleanIngredients) ||
          (unspecifiedOil && _matches(forms, IngredientRules.cleanOilSources));
      if (unspecifiedOil && !clean) {
        flagged.add(ingredient);
        badges.add(VerdictBadge.cautionQuantityDependent);
        continue;
      }
      if (clean) {
        matchedClean.add(ingredient);
      }
      badges.add(VerdictBadge.cleanKeto);
    }

    return IngredientVerdict(
      badge: VerdictBadge.worst(badges),
      flaggedIngredients: flagged,
      matchedCleanIngredients: matchedClean,
    );
  }

  /// Every spelling of [ingredient] a rule might be hiding in.
  ///
  /// Two forms, not one:
  ///
  /// 1. The normalised, lowercased token. Normalising here as well as in the
  ///    parser is what lets the classifier be used — and tested — on its own:
  ///    a pointed `סוּכָּר` must classify the same way whatever produced it.
  /// 2. The same token with each word's inseparable Hebrew prefix removed.
  ///    `contains` already copes with a prefix on the token's *first* word,
  ///    because the rule is still a substring of `ושמן קנולה`. It does not
  ///    cope with one in the middle: `שמן הקנולה` does not contain
  ///    `שמן קנולה`. Stripping is additive — both forms are tried — so a
  ///    wrong strip can never lose a match.
  @visibleForTesting
  static List<String> candidateForms(String ingredient) =>
      _candidateForms(ingredient);

  static List<String> _candidateForms(String ingredient) {
    final normalised = HebrewTextNormaliser.normalise(ingredient)
        .toLowerCase()
        .trim();
    final stripped = normalised
        .split(_words)
        .map(HebrewTextNormaliser.stripPrefix)
        .join(' ');
    return stripped == normalised ? [normalised] : [normalised, stripped];
  }

  static bool _matches(List<String> forms, List<String> rules) =>
      forms.any((form) => rules.any(form.contains));
}
