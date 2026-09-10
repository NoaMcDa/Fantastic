import 'package:fantastic/features/keto_lens/domain/models/ingredient_verdict.dart';
import 'package:fantastic/features/keto_lens/domain/models/verdict_badge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IngredientVerdict.isClean', () {
    test('is true for a cleanKeto verdict with no flags', () {
      expect(
        const IngredientVerdict(badge: VerdictBadge.cleanKeto).isClean,
        isTrue,
      );
    });

    test('is false for a cleanKeto verdict with a non-empty flag list', () {
      // Contradictory state — report false rather than trusting the badge.
      expect(
        const IngredientVerdict(
          badge: VerdictBadge.cleanKeto,
          flaggedIngredients: ['canola'],
        ).isClean,
        isFalse,
      );
    });

    test('is false for a nonKeto verdict', () {
      expect(
        const IngredientVerdict(
          badge: VerdictBadge.nonKeto,
          flaggedIngredients: ['soybean oil'],
        ).isClean,
        isFalse,
      );
    });

    test('is false for a caution verdict even with no flags', () {
      expect(
        const IngredientVerdict(badge: VerdictBadge.cautionQuantityDependent)
            .isClean,
        isFalse,
      );
    });
  });

  group('IngredientVerdict defaults', () {
    test('flaggedIngredients defaults to an empty list', () {
      expect(
        const IngredientVerdict(badge: VerdictBadge.cleanKeto)
            .flaggedIngredients,
        isEmpty,
      );
    });
  });

  group('IngredientVerdict equality', () {
    test('two instances with identical field values are equal', () {
      expect(
        const IngredientVerdict(badge: VerdictBadge.nonKeto),
        const IngredientVerdict(badge: VerdictBadge.nonKeto),
      );
      expect(
        const IngredientVerdict(badge: VerdictBadge.nonKeto).hashCode,
        const IngredientVerdict(badge: VerdictBadge.nonKeto).hashCode,
      );
    });

    test('equal-but-not-identical flag lists are still equal', () {
      // Built as runtime locals rather than const literals: const would
      // canonicalise the two lists into one object and defeat the test.
      final first = <String>['canola', 'soybean'];
      final second = <String>['canola', 'soybean'];
      final a = IngredientVerdict(
        badge: VerdictBadge.nonKeto,
        flaggedIngredients: first,
      );
      final b = IngredientVerdict(
        badge: VerdictBadge.nonKeto,
        flaggedIngredients: second,
      );

      expect(identical(a.flaggedIngredients, b.flaggedIngredients), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('two instances differing only in badge are not equal', () {
      expect(
        const IngredientVerdict(badge: VerdictBadge.cleanKeto),
        isNot(const IngredientVerdict(badge: VerdictBadge.nonKeto)),
      );
    });

    test('two instances differing only in flags are not equal', () {
      expect(
        const IngredientVerdict(
          badge: VerdictBadge.nonKeto,
          flaggedIngredients: ['canola'],
        ),
        isNot(const IngredientVerdict(badge: VerdictBadge.nonKeto)),
      );
    });
  });
}
