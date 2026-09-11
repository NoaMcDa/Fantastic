import 'package:fantastic/features/keto_lens/domain/models/ingredient_verdict.dart';
import 'package:fantastic/features/keto_lens/domain/models/label_verdict.dart';
import 'package:fantastic/features/keto_lens/domain/models/macro_verdict.dart';
import 'package:fantastic/features/keto_lens/domain/models/verdict_badge.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';

void main() {
  IngredientVerdict ingredients({
    VerdictBadge badge = VerdictBadge.cleanKeto,
    List<String> flagged = const [],
    List<String> clean = const ['olive oil'],
  }) => IngredientVerdict(
    badge: badge,
    flaggedIngredients: flagged,
    matchedCleanIngredients: clean,
  );

  /// Nothing in the list matched any rule — not evidence of cleanliness.
  IngredientVerdict recognisedNothing() => ingredients(clean: const []);

  VerdictBadge? combine(IngredientVerdict i, MacroVerdict m) =>
      LabelVerdict.combine(ingredients: i, macros: m);

  group('collecting evidence', () {
    test('neither side has any — the neutral chip', () {
      expect(
        combine(recognisedNothing(), MacroVerdictFixture.indeterminate()),
        isNull,
      );
    });

    // The whole point of that flag: recognising nothing is not evidence of
    // cleanliness, so it must not outvote a panel that does say something.
    test('an unrecognised ingredient list does not soften a red panel', () {
      expect(
        combine(recognisedNothing(), MacroVerdictFixture.notKeto()),
        VerdictBadge.nonKeto,
      );
    });

    test('a panel with no verdict leaves the ingredient badge standing', () {
      expect(
        combine(
          ingredients(badge: VerdictBadge.nonKeto, flagged: const ['canola']),
          MacroVerdictFixture.indeterminate(),
        ),
        VerdictBadge.nonKeto,
      );
    });
  });

  group('the worst badge wins', () {
    // A flagged seed oil is never softened by flattering macros.
    test('a flagged seed oil survives clean macros', () {
      expect(
        combine(
          ingredients(badge: VerdictBadge.nonKeto, flagged: const ['canola']),
          MacroVerdictFixture.keto(),
        ),
        VerdictBadge.nonKeto,
      );
    });

    // And a green ingredient list never survives 34 g of net carbs. This is
    // the reported defect: the bread rendered as a green tick.
    test('a clean ingredient list does not survive a red panel', () {
      expect(
        combine(ingredients(), MacroVerdictFixture.notKeto()),
        VerdictBadge.nonKeto,
      );
    });

    test('two clean sides stay clean', () {
      expect(
        combine(ingredients(), MacroVerdictFixture.keto()),
        VerdictBadge.cleanKeto,
      );
    });
  });

  group('escalation', () {
    IngredientVerdict maltitol() => ingredients(
      badge: VerdictBadge.cautionQuantityDependent,
      flagged: const ['maltitol'],
    );

    // The amber badge means "insulin-spiking sweeteners IN SMALL AMOUNT" — a
    // claim about quantity that nothing could test until the panel could.
    test('amber plus a spiking sweetener plus a costly portion is red', () {
      expect(
        combine(maltitol(), MacroVerdictFixture.moderation()),
        VerdictBadge.nonKeto,
      );
      expect(
        LabelVerdict.escalated(
          ingredients: maltitol(),
          macros: MacroVerdictFixture.moderation(),
        ),
        isTrue,
      );
    });

    // A trace of sorbitol in a 3 g/100 g product is precisely the small amount
    // the amber badge was written for.
    test('keto macros leave the caution as a caution', () {
      expect(
        combine(maltitol(), MacroVerdictFixture.keto()),
        VerdictBadge.cautionQuantityDependent,
      );
    });

    // No evidence, no escalation. No new claim without a number behind it.
    test('an unreadable panel leaves the caution as a caution', () {
      expect(
        combine(maltitol(), MacroVerdictFixture.indeterminate()),
        VerdictBadge.cautionQuantityDependent,
      );
      expect(
        LabelVerdict.escalated(
          ingredients: maltitol(),
          macros: MacroVerdictFixture.indeterminate(),
        ),
        isFalse,
      );
    });

    // The OTHER source of an amber badge. That caution is about identity — the
    // oil may be palm or coconut — and carbs say nothing about which oil it
    // is. Escalating would punish a product for an unrelated fact.
    test('an unspecified vegetable oil is never escalated on carbs', () {
      final oil = ingredients(
        badge: VerdictBadge.cautionQuantityDependent,
        flagged: const ['שמן צמחי'],
      );

      expect(
        combine(oil, MacroVerdictFixture.moderation()),
        VerdictBadge.cautionQuantityDependent,
      );
      expect(
        LabelVerdict.escalated(
          ingredients: oil,
          macros: MacroVerdictFixture.moderation(),
        ),
        isFalse,
      );
    });

    test('an already-red result is not "escalated"', () {
      expect(
        LabelVerdict.escalated(
          ingredients: ingredients(
            badge: VerdictBadge.nonKeto,
            flagged: const ['maltitol'],
          ),
          macros: MacroVerdictFixture.notKeto(),
        ),
        isFalse,
      );
    });

    test('escalated reports false when there is no evidence at all', () {
      expect(
        LabelVerdict.escalated(
          ingredients: recognisedNothing(),
          macros: MacroVerdictFixture.indeterminate(),
        ),
        isFalse,
      );
    });
  });
}
