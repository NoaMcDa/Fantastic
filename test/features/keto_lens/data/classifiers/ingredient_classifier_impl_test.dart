import 'package:fantastic/core/constants/ingredient_rules.dart';
import 'package:fantastic/features/keto_lens/data/classifiers/ingredient_classifier_impl.dart';
import 'package:fantastic/features/keto_lens/domain/models/verdict_badge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const classifier = IngredientClassifierImpl();

  group('IngredientClassifierImpl severity', () {
    test('a forbidden seed oil is nonKeto', () {
      final verdict = classifier.classify(['canola']);

      expect(verdict.badge, VerdictBadge.nonKeto);
      expect(verdict.flaggedIngredients, ['canola']);
    });

    test('an insulin-spiking sweetener is a caution', () {
      final verdict = classifier.classify(['maltitol']);

      expect(verdict.badge, VerdictBadge.cautionQuantityDependent);
      expect(verdict.flaggedIngredients, ['maltitol']);
    });

    test('a clean fat is cleanKeto with nothing flagged', () {
      final verdict = classifier.classify(['olive oil']);

      expect(verdict.badge, VerdictBadge.cleanKeto);
      expect(verdict.flaggedIngredients, isEmpty);
      expect(verdict.isClean, isTrue);
    });

    test('the worst badge wins over a clean ingredient beside it', () {
      final verdict = classifier.classify(['olive oil', 'canola oil']);

      expect(verdict.badge, VerdictBadge.nonKeto);
      expect(verdict.flaggedIngredients, ['canola oil']);
    });

    test('a forbidden oil outranks a sweetener in the same list', () {
      final verdict = classifier.classify(['maltitol', 'soybean oil']);

      expect(verdict.badge, VerdictBadge.nonKeto);
      expect(verdict.flaggedIngredients, hasLength(2));
    });

    test('an empty list is cleanKeto with no flags', () {
      final verdict = classifier.classify([]);

      expect(verdict.badge, VerdictBadge.cleanKeto);
      expect(verdict.flaggedIngredients, isEmpty);
    });
  });

  group('IngredientClassifierImpl on Hebrew', () {
    test('matches a Hebrew forbidden oil', () {
      final verdict = classifier.classify(['שמן קנולה']);

      expect(verdict.badge, VerdictBadge.nonKeto);
    });

    test('matches a compound Hebrew ingredient by substring', () {
      // "refined canola oil" - the rule word is not the whole token.
      final verdict = classifier.classify(['שמן קנולה מזוקק']);

      expect(verdict.badge, VerdictBadge.nonKeto);
      expect(verdict.flaggedIngredients, ['שמן קנולה מזוקק']);
    });

    test('matches through a conjunction glued to the first word', () {
      final verdict = classifier.classify(['ושמן קנולה']);

      expect(verdict.badge, VerdictBadge.nonKeto);
    });

    test('matches through a definite article on the second word', () {
      // `contains` alone fails here: the rule is "oil canola" and the token
      // is "oil the-canola". The prefix-stripped candidate form is what
      // catches it.
      final verdict = classifier.classify(['שמן הקנולה']);

      expect(verdict.badge, VerdictBadge.nonKeto);
    });

    test('matches a Hebrew sweetener carrying a conjunction', () {
      final verdict = classifier.classify(['ומלטודקסטרין']);

      expect(verdict.badge, VerdictBadge.cautionQuantityDependent);
    });

    test('matches a Hebrew clean fat', () {
      final verdict = classifier.classify(['שמן זית']);

      expect(verdict.badge, VerdictBadge.cleanKeto);
      expect(verdict.matchedCleanIngredients, ['שמן זית']);
    });

    test('strips niqqud before matching', () {
      // A pointed token must classify the same as its plain spelling. The
      // classifier normalises for itself so it works standalone, not only
      // downstream of the parser.
      final pointed = classifier.classify([
        '\u05DE\u05B7\u05DC\u05B0\u05D8\u05B4\u05D9\u05D8\u05D5\u05B9\u05DC',
      ]);

      expect(pointed.badge, VerdictBadge.cautionQuantityDependent);
    });
  });

  group('IngredientClassifierImpl does not over-flag', () {
    test('soy lecithin is not a seed oil', () {
      // An emulsifier. Flagging every occurrence of "soy" would mark most
      // chocolate non-keto, which is why the rule carries the oil word.
      final verdict = classifier.classify(['לציתין סויה']);

      expect(verdict.badge, VerdictBadge.cleanKeto);
      expect(verdict.flaggedIngredients, isEmpty);
    });

    test('soybean oil still is', () {
      expect(classifier.classify(['שמן סויה']).badge, VerdictBadge.nonKeto);
    });

    test('sunflower seeds are not sunflower oil', () {
      final verdict = classifier.classify(['גרעיני חמניות']);

      expect(verdict.badge, VerdictBadge.cleanKeto);
    });

    test('sunflower oil still is', () {
      expect(classifier.classify(['שמן חמניות']).badge, VerdictBadge.nonKeto);
    });

    test('peanut butter is not butter', () {
      final verdict = classifier.classify(['חמאת בוטנים']);

      expect(verdict.matchedCleanIngredients, isEmpty);
    });

    test('a short word beginning with a prefix letter is left whole', () {
      // "salt" must not be stripped down to a two-letter fragment that
      // happens to sit inside a rule.
      final verdict = classifier.classify(['מלח', 'מים']);

      expect(verdict.badge, VerdictBadge.cleanKeto);
      expect(verdict.flaggedIngredients, isEmpty);
    });
  });

  group('IngredientClassifierImpl on unspecified vegetable oil', () {
    test('an unnamed vegetable oil is a caution', () {
      final verdict = classifier.classify(['שמן צמחי']);

      expect(verdict.badge, VerdictBadge.cautionQuantityDependent);
      expect(verdict.flaggedIngredients, ['שמן צמחי']);
    });

    test('a vegetable oil whose plant is named clean is not flagged', () {
      // Amber on coconut oil would train the user to ignore amber.
      final verdict = classifier.classify(['שמן צמחי (קוקוס)']);

      expect(verdict.badge, VerdictBadge.cleanKeto);
      expect(verdict.flaggedIngredients, isEmpty);
    });

    test('a vegetable oil whose plant is forbidden is still nonKeto', () {
      final verdict = classifier.classify(['שמן צמחי (קנולה)']);

      expect(verdict.badge, VerdictBadge.nonKeto);
    });
  });

  group('IngredientVerdict.recognisedNothing', () {
    test('is true when nothing matched any rule', () {
      // A wheat-flour wafer: the badge says cleanKeto because no rule
      // matched, not because the product is keto. This flag is what lets
      // the result sheet say so.
      final verdict = classifier.classify(['קמח חיטה', 'מים']);

      expect(verdict.badge, VerdictBadge.cleanKeto);
      expect(verdict.recognisedNothing, isTrue);
    });

    test('is true for an empty ingredient list', () {
      expect(classifier.classify([]).recognisedNothing, isTrue);
    });

    test('is false when a clean rule matched', () {
      final verdict = classifier.classify(['חמאה', 'מלח']);

      expect(verdict.recognisedNothing, isFalse);
      expect(verdict.matchedCleanIngredients, ['חמאה']);
    });

    test('is false when something was flagged', () {
      expect(classifier.classify(['canola']).recognisedNothing, isFalse);
    });
  });

  group('IngredientClassifierImpl reads IngredientRules', () {
    test('every forbidden rule, English and Hebrew, earns nonKeto', () {
      for (final rule in IngredientRules.allForbiddenSeedOils) {
        expect(
          classifier.classify([rule]).badge,
          VerdictBadge.nonKeto,
          reason: '$rule did not classify as nonKeto',
        );
      }
    });

    test('every sweetener rule earns a caution', () {
      for (final rule in IngredientRules.allInsulinSpikingSweeteners) {
        expect(
          classifier.classify([rule]).badge,
          VerdictBadge.cautionQuantityDependent,
          reason: '$rule did not classify as a caution',
        );
      }
    });

    test('every clean rule earns cleanKeto and is recorded as matched', () {
      for (final rule in IngredientRules.allCleanIngredients) {
        final verdict = classifier.classify([rule]);

        expect(
          verdict.badge,
          VerdictBadge.cleanKeto,
          reason: '$rule did not classify as clean',
        );
        expect(verdict.matchedCleanIngredients, [rule], reason: rule);
      }
    });

    test('no clean rule is also a forbidden or caution rule', () {
      // A rule appearing in two lists would make the classifier order
      // dependent, and the order is an implementation detail.
      for (final clean in IngredientRules.allCleanIngredients) {
        expect(
          classifier.classify([clean]).flaggedIngredients,
          isEmpty,
          reason: '$clean is matched by a flagging rule as well',
        );
      }
    });

    test('case is ignored', () {
      expect(
        classifier.classify(['CANOLA', 'Maltitol']).badge,
        VerdictBadge.nonKeto,
      );
      expect(classifier.classify(['Olive Oil']).matchedCleanIngredients, [
        'Olive Oil',
      ]);
    });
  });
}
