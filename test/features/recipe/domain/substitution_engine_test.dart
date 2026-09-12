import 'package:fantastic/core/constants/substitution_rules.dart';
import 'package:fantastic/features/recipe/domain/models/ingredient_outcome.dart';
import 'package:fantastic/features/recipe/domain/models/outcome_source.dart';
import 'package:fantastic/features/recipe/domain/models/parsed_ingredient.dart';
import 'package:fantastic/features/recipe/domain/substitution_engine.dart';
import 'package:flutter_test/flutter_test.dart';

ParsedIngredient _ingredient(String name) =>
    ParsedIngredient(name: name, raw: name);

void main() {
  group('SubstitutionEngine.key', () {
    test('key: strips niqqud, folds final forms, lowercases', () {
      expect(SubstitutionEngine.key('קָמַח'), 'קמח');
      expect(SubstitutionEngine.key('לחם'), 'לחמ');
      expect(SubstitutionEngine.key('Flour'), 'flour');
      expect(SubstitutionEngine.key('  קמח  '), 'קמח');
    });

    test('key is idempotent — folding an already-folded string is a no-op', () {
      final once = SubstitutionEngine.key('לחם');
      expect(SubstitutionEngine.key(once), once);
    });
  });

  group('SubstitutionEngine.classify — substitutions', () {
    const engine = SubstitutionEngine();

    for (final row in SubstitutionRules.substitutions) {
      for (final alias in row.aliases) {
        test(
          'classify: alias "$alias" maps to ${row.replacement}, ${row.ratio}, ${row.reason}',
          () {
            final outcome = engine.classify(_ingredient(alias));
            expect(outcome, isA<Substituted>());
            final substituted = outcome as Substituted;
            expect(substituted.substitution.replacement, row.replacement);
            expect(substituted.substitution.ratio, row.ratio);
            expect(substituted.substitution.reason, row.reason);
            expect(substituted.source, OutcomeSource.rule);
          },
        );
      }
    }

    test('classify: קמח כוסמין matches its own row, not קמח', () {
      // The default table's generic-flour and spelt-flour rows happen to
      // substitute to the same replacement, so this uses a small table where
      // the two rows are observably different — proving the *mechanism*
      // (longest alias wins, matched as a whole word) rather than relying on
      // the seed data's coincidence.
      const customEngine = SubstitutionEngine(
        substitutions: [
          (
            aliases: ['קמח'],
            replacement: 'תחליף כללי',
            ratio: 1.0,
            reason: 'קמח רגיל',
          ),
          (
            aliases: ['קמח כוסמינ'],
            replacement: 'תחליף כוסמין',
            ratio: 1.0,
            reason: 'קמח כוסמין',
          ),
        ],
        staples: [],
      );
      // "קמח כוסמין מלא" is not itself an exact alias, but it contains both
      // "קמח" and "קמח כוסמין" as whole-word prefixes — only the longest may
      // win.
      final outcome = customEngine.classify(_ingredient('קמח כוסמין מלא'));
      expect(outcome, isA<Substituted>());
      expect((outcome as Substituted).substitution.replacement, 'תחליף כוסמין');
    });

    test('classify: הקמח matches קמח via stripPrefix', () {
      final outcome = engine.classify(_ingredient('הקמח'));
      expect(outcome, isA<Substituted>());
      expect((outcome as Substituted).substitution.replacement, 'קמח שקדים');
    });

    test('classify: קָמַח (pointed) matches קמח', () {
      final outcome = engine.classify(_ingredient('קָמַח'));
      expect(outcome, isA<Substituted>());
      expect((outcome as Substituted).substitution.replacement, 'קמח שקדים');
    });

    test(
      'classify: an alias ending in a final letter matches its folded input',
      () {
        // "לחם" (bread) is naturally spelled with a final mem; the table
        // stores its alias folded as "לחמ". The unfolded, natural spelling
        // must still match through SubstitutionEngine.key's own folding.
        final outcome = engine.classify(_ingredient('לחם'));
        expect(outcome, isA<Substituted>());
        expect((outcome as Substituted).substitution.replacement, 'לחם שקדים');
      },
    );

    test('classify: שמן קנולה is Substituted, not Flagged', () {
      // שמן קנולה is both a substitution alias and on IngredientRules'
      // forbidden-oils list — substitutions must win because there is a
      // better oil to suggest.
      final outcome = engine.classify(_ingredient('שמן קנולה'));
      expect(outcome, isA<Substituted>());
      expect((outcome as Substituted).substitution.replacement, 'שמן זית');
    });

    test('almond flour (a staple beginning with the wheat-flour alias word) is AlreadyKeto', () {
      // Regression for the exact-match-first fix: "קמח שקדים" begins with
      // "קמח" (row 1's bare alias) and must not be "corrected" into itself.
      final outcome = engine.classify(_ingredient('קמח שקדים'));
      expect(outcome, isA<AlreadyKeto>());
    });
  });

  group('SubstitutionEngine.classify — staples', () {
    const engine = SubstitutionEngine();

    for (final staple in SubstitutionRules.ketoStaples) {
      test('classify: staple "$staple" is AlreadyKeto', () {
        final outcome = engine.classify(_ingredient(staple));
        expect(outcome, isA<AlreadyKeto>());
        expect((outcome as AlreadyKeto).source, OutcomeSource.rule);
      });
    }
  });

  group('SubstitutionEngine.classify — flags and unknowns', () {
    const engine = SubstitutionEngine();

    test('classify: מלטיטול is Flagged, not Unrecognised', () {
      final outcome = engine.classify(_ingredient('מלטיטול'));
      expect(outcome, isA<Flagged>());
    });

    test(
      'classify: an unknown ingredient is Unrecognised, never AlreadyKeto',
      () {
        final outcome = engine.classify(_ingredient('קינואה'));
        expect(outcome, isA<Unrecognised>());
      },
    );

    test('classify: an empty name is Unrecognised', () {
      final outcome = engine.classify(
        const ParsedIngredient(name: '', raw: ''),
      );
      expect(outcome, isA<Unrecognised>());
    });

    test('classify: never throws on punctuation-only input', () {
      expect(() => engine.classify(_ingredient('!!!')), returnsNormally);
      expect(engine.classify(_ingredient('!!!')), isA<Unrecognised>());
    });
  });

  group('SubstitutionEngine.convert', () {
    const engine = SubstitutionEngine();

    test('convert: preserves order', () {
      final ingredients = [
        _ingredient('קמח'),
        _ingredient('ביצה'),
        _ingredient('מלטיטול'),
        _ingredient('קינואה'),
      ];
      final outcomes = engine.convert(ingredients);
      expect(outcomes, hasLength(4));
      expect(outcomes[0], isA<Substituted>());
      expect(outcomes[1], isA<AlreadyKeto>());
      expect(outcomes[2], isA<Flagged>());
      expect(outcomes[3], isA<Unrecognised>());
    });

    test('convert: empty in, empty out', () {
      expect(engine.convert(const []), isEmpty);
    });
  });
}
