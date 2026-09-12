import 'package:fantastic/core/constants/ingredient_rules.dart';
import 'package:fantastic/core/constants/substitution_rules.dart';
import 'package:fantastic/features/recipe/domain/substitution_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// The consistency suite: if this app's converter ever recommends what its
/// own label scanner flags, the app contradicts itself. This is what
/// prevents that, over the two constant files together.
void main() {
  group('SubstitutionRules consistency', () {
    test('no replacement contains a forbidden oil or an insulin-spiking sweetener', () {
      final banned = [
        ...IngredientRules.allForbiddenSeedOils,
        ...IngredientRules.allInsulinSpikingSweeteners,
      ].map((entry) => entry.toLowerCase());

      for (final row in SubstitutionRules.substitutions) {
        final replacement = row.replacement.toLowerCase();
        for (final term in banned) {
          expect(
            replacement.contains(term),
            isFalse,
            reason:
                'replacement "${row.replacement}" contains banned term "$term"',
          );
        }
      }
    });

    test('no alias is also a staple', () {
      final aliases = SubstitutionRules.substitutions
          .expand((row) => row.aliases)
          .toSet();
      final staples = SubstitutionRules.ketoStaples.toSet();
      final overlap = aliases.intersection(staples);
      expect(
        overlap,
        isEmpty,
        reason: 'aliases also listed as staples: $overlap',
      );
    });

    test('no staple is on a forbidden list', () {
      final banned = [
        ...IngredientRules.allForbiddenSeedOils,
        ...IngredientRules.allInsulinSpikingSweeteners,
      ].map((entry) => entry.toLowerCase());

      for (final staple in SubstitutionRules.ketoStaples) {
        final lower = staple.toLowerCase();
        for (final term in banned) {
          expect(
            lower.contains(term),
            isFalse,
            reason: 'staple "$staple" contains banned term "$term"',
          );
        }
      }
    });

    test('no alias appears in two rows', () {
      final seen = <String>{};
      final duplicates = <String>{};
      for (final row in SubstitutionRules.substitutions) {
        for (final alias in row.aliases) {
          if (!seen.add(alias)) {
            duplicates.add(alias);
          }
        }
      }
      expect(
        duplicates,
        isEmpty,
        reason: 'aliases appearing in more than one row: $duplicates',
      );
    });

    test('no staple appears twice', () {
      final seen = <String>{};
      final duplicates = <String>{};
      for (final staple in SubstitutionRules.ketoStaples) {
        if (!seen.add(staple)) {
          duplicates.add(staple);
        }
      }
      expect(
        duplicates,
        isEmpty,
        reason: 'staples appearing more than once: $duplicates',
      );
    });

    test('every ratio is finite and positive; every replacement and reason is non-empty', () {
      for (final row in SubstitutionRules.substitutions) {
        expect(
          row.ratio.isFinite,
          isTrue,
          reason: '${row.replacement} has a non-finite ratio',
        );
        expect(
          row.ratio,
          greaterThan(0),
          reason: '${row.replacement} has a non-positive ratio',
        );
        expect(row.replacement, isNotEmpty);
        expect(row.reason, isNotEmpty);
        expect(row.aliases, isNotEmpty);
        for (final alias in row.aliases) {
          expect(alias, isNotEmpty);
        }
      }
    });

    test('every alias and staple equals SubstitutionEngine.key of itself', () {
      for (final row in SubstitutionRules.substitutions) {
        for (final alias in row.aliases) {
          expect(
            SubstitutionEngine.key(alias),
            alias,
            reason:
                'alias "$alias" is not already normalised/folded/lowercased',
          );
        }
      }
      for (final staple in SubstitutionRules.ketoStaples) {
        expect(
          SubstitutionEngine.key(staple),
          staple,
          reason:
              'staple "$staple" is not already normalised/folded/lowercased',
        );
      }
    });
  });
}
