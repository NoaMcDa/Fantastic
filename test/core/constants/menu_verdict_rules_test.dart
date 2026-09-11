import 'package:fantastic/core/constants/menu_verdict_rules.dart';
import 'package:fantastic/features/menu/domain/models/dish_verdict.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MenuVerdictRules.definitions', () {
    test('has exactly one entry per DishVerdict value', () {
      expect(
        MenuVerdictRules.definitions.keys.toSet(),
        DishVerdict.values.toSet(),
      );
      expect(
        MenuVerdictRules.definitions,
        hasLength(DishVerdict.values.length),
      );
    });

    test('every definition is a non-empty Hebrew sentence', () {
      for (final entry in MenuVerdictRules.definitions.values) {
        expect(entry.trim(), entry, reason: 'untrimmed definition: "$entry"');
        expect(entry, isNotEmpty);
      }
    });

    test('every definition is distinct', () {
      expect(
        MenuVerdictRules.definitions.values.toSet(),
        hasLength(MenuVerdictRules.definitions.length),
      );
    });
  });

  group('MenuVerdictRules.hiddenCarbTraps', () {
    test('is non-empty and holds no duplicates', () {
      expect(MenuVerdictRules.hiddenCarbTraps, isNotEmpty);
      expect(
        MenuVerdictRules.hiddenCarbTraps.toSet(),
        hasLength(MenuVerdictRules.hiddenCarbTraps.length),
      );
    });

    test('names every trap the spec calls out, in both languages', () {
      expect(
        MenuVerdictRules.hiddenCarbTraps,
        containsAll(<String>[
          'glaze',
          'sweet sauce',
          'breading',
          'cornstarch',
          'croutons',
        ]),
      );
      expect(
        MenuVerdictRules.hiddenCarbTraps,
        containsAll(<String>['גלייז', 'רוטב מתוק', 'קרוטונים']),
      );
    });

    test('no entry is blank or carries surrounding whitespace', () {
      for (final entry in MenuVerdictRules.hiddenCarbTraps) {
        expect(entry.trim(), entry, reason: 'untrimmed entry: "$entry"');
        expect(entry, isNotEmpty);
      }
    });
  });

  group('MenuVerdictRules.nameOf', () {
    test('returns the enum\'s own .name for every verdict', () {
      for (final verdict in DishVerdict.values) {
        expect(MenuVerdictRules.nameOf(verdict), verdict.name);
      }
    });
  });

  group('MenuVerdictRules.verdictOf', () {
    test('matches every verdict name exactly', () {
      for (final verdict in DishVerdict.values) {
        expect(MenuVerdictRules.verdictOf(verdict.name), verdict);
      }
    });

    test('is case-sensitive, matching by .name and never by index', () {
      expect(MenuVerdictRules.verdictOf('MODIFIABLE'), isNull);
    });

    test('returns null for a non-name string', () {
      expect(MenuVerdictRules.verdictOf('1'), isNull);
    });

    test('returns null for an empty string', () {
      expect(MenuVerdictRules.verdictOf(''), isNull);
    });

    test('returns null for a completely unrelated string', () {
      expect(MenuVerdictRules.verdictOf('cleanKeto'), isNull);
    });
  });

  group('MenuVerdictRules caps', () {
    test('are all positive', () {
      expect(MenuVerdictRules.maxMenuChars, greaterThan(0));
      expect(MenuVerdictRules.maxPages, greaterThan(0));
      expect(MenuVerdictRules.maxDishes, greaterThan(0));
      expect(MenuVerdictRules.maxDishNameChars, greaterThan(0));
      expect(MenuVerdictRules.maxWhyChars, greaterThan(0));
      expect(MenuVerdictRules.maxModificationChars, greaterThan(0));
      expect(MenuVerdictRules.maxOutputTokens, greaterThan(0));
      expect(MenuVerdictRules.provenanceMinWordChars, greaterThan(0));
    });

    test(
      'maxDishes times a per-dish token budget fits under maxOutputTokens',
      () {
        // The doc comment's own arithmetic: ~150 dishes x ~40 tokens.
        const perDishTokenBudget = 40;
        expect(
          MenuVerdictRules.maxDishes * perDishTokenBudget,
          lessThanOrEqualTo(MenuVerdictRules.maxOutputTokens),
        );
      },
    );

    test(
      'provenanceMinWordChars is short enough to match a real dish word',
      () {
        // A three-letter Hebrew word (e.g. "עוף") must satisfy the bound the
        // parser rule (#357) will apply.
        expect(MenuVerdictRules.provenanceMinWordChars, lessThanOrEqualTo(3));
      },
    );
  });
}
