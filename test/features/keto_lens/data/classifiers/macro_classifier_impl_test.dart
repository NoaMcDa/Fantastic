import 'package:fantastic/core/constants/product_verdict_constants.dart';
import 'package:fantastic/features/keto_lens/data/classifiers/macro_classifier_impl.dart';
import 'package:fantastic/features/keto_lens/domain/models/macro_verdict.dart';
import 'package:fantastic/features/keto_lens/domain/models/parsed_label.dart';
import 'package:fantastic/features/keto_lens/domain/models/serving_basis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const classifier = MacroClassifierImpl();

  MacroVerdict judge({
    double? netCarbsG,
    double? totalCarbsG,
    double? fibreG,
    double? sugarsG,
    double? polyolsG,
    double? energyKcal,
    double? fatG,
    double? proteinG,
    double? servingGrams,
    ServingBasis basis = ServingBasis.per100g,
    List<String> ingredients = const [],
  }) => classifier.classify(
    ParsedLabel(
      fatG: fatG,
      netCarbsG: netCarbsG,
      proteinG: proteinG,
      totalCarbsG: totalCarbsG,
      fibreG: fibreG,
      sugarsG: sugarsG,
      polyolsG: polyolsG,
      energyKcal: energyKcal,
      servingGrams: servingGrams,
      basis: basis,
      ingredients: ingredients,
    ),
  );

  group('the derived band edges', () {
    // "Why 25 g per 100 g?" has an answer: it is 5 g of carbs in a 20 g
    // portion. Every edge is computed, never typed.
    test('are division, not literals', () {
      expect(ProductVerdictConstants.ketoDensitySolid, 5);
      expect(ProductVerdictConstants.notKetoDensitySolid, 25);
      expect(ProductVerdictConstants.ketoDensityLiquid, 2);
      expect(ProductVerdictConstants.notKetoDensityLiquid, 5);
    });
  });

  group('stage 0 — the panel checks itself', () {
    // 9(3.3) + 4(10.9) + 4(41.2) = 238.1 against a declared 238.
    test('the real bread agrees with its own calorie figure', () {
      final verdict = judge(
        fatG: 3.3,
        netCarbsG: 34.2,
        totalCarbsG: 41.2,
        fibreG: 7,
        proteinG: 10.9,
        energyKcal: 238,
      );

      expect(verdict.judgement, isNot(MacroJudgement.indeterminate));
    });

    test('a mis-read digit is caught rather than banded confidently', () {
      // The carb row read as 4.12 instead of 41.2: energy no longer fits.
      final verdict = judge(
        fatG: 3.3,
        netCarbsG: 4.12,
        totalCarbsG: 4.12,
        proteinG: 10.9,
        energyKcal: 238,
      );

      expect(verdict.judgement, MacroJudgement.indeterminate);
      expect(verdict.reason, MacroIndeterminacy.energyMismatch);
    });

    // A label is never penalised for a row it did not print.
    test('is skipped entirely when the energy row did not parse', () {
      final verdict = judge(fatG: 3.3, netCarbsG: 34.2, proteinG: 10.9);

      expect(verdict.judgement, MacroJudgement.notKeto);
    });

    test('accepts fibre counted outside carbohydrate as well as inside', () {
      // The EU shape the real bread prints: predicted + 2 x fibre.
      final verdict = judge(
        fatG: 1,
        netCarbsG: 10,
        totalCarbsG: 10,
        fibreG: 20,
        proteinG: 1,
        energyKcal: 93,
      );

      expect(verdict.judgement, isNot(MacroJudgement.indeterminate));
    });
  });

  group('stage 1 — the polyol adjustment', () {
    const cleanBar = ['erythritol', 'cocoa'];

    test('subtracts declared polyols when they can be attributed', () {
      final verdict = judge(
        netCarbsG: 22,
        totalCarbsG: 30,
        fibreG: 8,
        polyolsG: 20,
        ingredients: cleanBar,
      );

      expect(verdict.adjustedForPolyols, isTrue);
      expect(verdict.netCarbsPer100, 2);
      expect(verdict.judgement, MacroJudgement.keto);
    });

    // An ingredient name carries no quantity.
    test('never infers grams from an ingredient name alone', () {
      final verdict = judge(netCarbsG: 22, ingredients: cleanBar);

      expect(verdict.adjustedForPolyols, isFalse);
    });

    // A bar with both subtracts nothing: the split is unattributable.
    test('refuses when an insulin-spiking sweetener is also named', () {
      final verdict = judge(
        netCarbsG: 22,
        totalCarbsG: 30,
        fibreG: 8,
        polyolsG: 20,
        ingredients: const ['erythritol', 'maltitol'],
      );

      expect(verdict.adjustedForPolyols, isFalse);
    });

    // A panel-only crop can attribute nothing, and an unattributed
    // subtraction is a green tick bought with no evidence.
    test('refuses on a panel-only crop with no ingredient list', () {
      final verdict = judge(
        netCarbsG: 22,
        totalCarbsG: 30,
        fibreG: 8,
        polyolsG: 20,
      );

      expect(verdict.adjustedForPolyols, isFalse);
    });

    // RealOcrFixture.proteinBar is exactly this: carbs 30, fibre 8,
    // polyols 25. The declared polyols do not fit the residual, so the panel
    // was mis-read.
    test('refuses when declared polyols exceed the carbohydrate residual', () {
      final verdict = judge(
        netCarbsG: 22,
        totalCarbsG: 30,
        fibreG: 8,
        polyolsG: 25,
        ingredients: cleanBar,
      );

      expect(verdict.adjustedForPolyols, isFalse);
      expect(verdict.netCarbsPer100, 22);
    });
  });

  group('stage 2 — basis and serving load', () {
    test('a per-100-g label bands on its printed density', () {
      expect(judge(netCarbsG: 34.2).judgement, MacroJudgement.notKeto);
      expect(judge(netCarbsG: 3).judgement, MacroJudgement.keto);
      expect(judge(netCarbsG: 12).judgement, MacroJudgement.moderation);
    });

    // A glass is 250 ml, so the liquid edges are stricter per hundred.
    test('a per-100-ml label uses the liquid edges', () {
      final verdict = judge(netCarbsG: 3, basis: ServingBasis.per100ml);

      expect(verdict.judgement, MacroJudgement.moderation);
      expect(judge(netCarbsG: 3).judgement, MacroJudgement.keto);
    });

    test('a per-serving label with a weight derives a density', () {
      final verdict = judge(
        netCarbsG: 3,
        servingGrams: 30,
        basis: ServingBasis.perServing,
      );

      expect(verdict.netCarbsPer100, closeTo(10, 0.001));
      expect(verdict.servingNetCarbsG, 3);
    });

    // There is a cost, but no density evidence either way.
    test('a per-serving label with no weight judges moderation', () {
      final verdict = judge(netCarbsG: 3, basis: ServingBasis.perServing);

      expect(verdict.judgement, MacroJudgement.moderation);
      expect(verdict.netCarbsPer100, isNull);
    });

    // Three macros cannot outweigh the food containing them, so 24+57+7 = 88
    // over a declared 25 g serving PROVES the figures are per 100 g.
    test('the mass check proves a per-100 basis on an unknown one', () {
      final verdict = judge(
        fatG: 24,
        netCarbsG: 57,
        proteinG: 7,
        servingGrams: 25,
        basis: ServingBasis.unknown,
      );

      expect(verdict.basisAssumed, isFalse);
    });

    test('macros outweighing 100 g are indeterminate, not banded', () {
      final verdict = judge(
        fatG: 60,
        netCarbsG: 50,
        proteinG: 30,
        basis: ServingBasis.unknown,
      );

      expect(verdict.judgement, MacroJudgement.indeterminate);
      expect(verdict.reason, MacroIndeterminacy.implausibleMass);
    });

    // Substituting 0 for a missing macro would fire the proof on labels it can
    // prove nothing about.
    test('the mass check needs all three macros', () {
      final verdict = judge(
        fatG: 24,
        netCarbsG: 57,
        servingGrams: 25,
        basis: ServingBasis.unknown,
      );

      expect(verdict.basisAssumed, isTrue);
    });
  });

  group('stage 3 — band, override, clamp', () {
    test(
      'a serving over 10 g of net carbs is not keto whatever the density',
      () {
        // 4 g/100 g is inside the green edge; a 400 g portion is not.
        final verdict = judge(netCarbsG: 4, servingGrams: 400);

        expect(verdict.servingNetCarbsG, 16);
        expect(verdict.judgement, MacroJudgement.notKeto);
      },
    );

    test('a serving over the portion budget drags green down to amber', () {
      final verdict = judge(netCarbsG: 4, servingGrams: 200);

      expect(verdict.servingNetCarbsG, 8);
      expect(verdict.judgement, MacroJudgement.moderation);
    });

    // The condiment rescue: it costs almost nothing and the pack says so.
    test('a negligible small serving is keto despite a high density', () {
      final verdict = judge(netCarbsG: 40, servingGrams: 2);

      expect(verdict.servingNetCarbsG, closeTo(0.8, 0.001));
      expect(verdict.judgement, MacroJudgement.keto);
    });

    test('a negligible serving on a large pack is not rescued', () {
      // Under a gram of carbs, but the serving is 200 g — not a condiment.
      final verdict = judge(netCarbsG: 0.4, servingGrams: 200);

      expect(verdict.judgement, MacroJudgement.keto);
      expect(
        judge(netCarbsG: 40, servingGrams: 200).judgement,
        MacroJudgement.notKeto,
      );
    });

    test('an implausible declared serving is ignored, not trusted', () {
      final verdict = judge(netCarbsG: 3, servingGrams: 100000);

      expect(verdict.servingNetCarbsG, isNull);
      expect(verdict.judgement, MacroJudgement.keto);
    });

    test('reports the grams that would exhaust a day of carbs', () {
      final verdict = judge(netCarbsG: 34.2);

      // 100 x 20 / 34.2 — the number that turns a band into an instruction.
      expect(verdict.gramsToDailyBudget, closeTo(58.5, 0.1));
    });
  });

  group('the assumed-basis clamp', () {
    // If the figures were really per serving and are read as per 100 g, the
    // density understates the truth by 2.5-5x — the error is always
    // optimistic, because a serving is never more than 100 g.
    test('withholds green under an assumed basis', () {
      final verdict = judge(netCarbsG: 3, basis: ServingBasis.unknown);

      expect(verdict.basisAssumed, isTrue);
      expect(verdict.judgement, MacroJudgement.moderation);
    });

    test('leaves amber and red alone — they stay right either way', () {
      expect(
        judge(netCarbsG: 12, basis: ServingBasis.unknown).judgement,
        MacroJudgement.moderation,
      );
      expect(
        judge(netCarbsG: 34.2, basis: ServingBasis.unknown).judgement,
        MacroJudgement.notKeto,
      );
    });

    // A printed zero is zero on every basis.
    test('does not withhold green from a printed zero', () {
      final verdict = judge(netCarbsG: 0, basis: ServingBasis.unknown);

      expect(verdict.judgement, MacroJudgement.keto);
      expect(verdict.basisAssumed, isFalse);
    });
  });

  group('indeterminacy', () {
    test('no carbohydrate row read', () {
      final verdict = judge(fatG: 10);

      expect(verdict.judgement, MacroJudgement.indeterminate);
      expect(verdict.reason, MacroIndeterminacy.noCarbRow);
      expect(verdict.netCarbsPer100, isNull);
      expect(verdict.badge, isNull);
    });

    // The badge is null so the caller reduces over the badges that exist
    // rather than over an invented one.
    test('carries no badge, because it has no opinion', () {
      expect(judge().badge, isNull);
    });
  });
}
