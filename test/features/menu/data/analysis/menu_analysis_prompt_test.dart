import 'package:fantastic/core/constants/menu_verdict_rules.dart';
import 'package:fantastic/features/menu/data/analysis/menu_analysis_prompt.dart';
import 'package:fantastic/features/menu/domain/models/dish_verdict.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';

void main() {
  group('MenuAnalysisPrompt.system', () {
    test('contains every verdict definition verbatim', () {
      for (final definition in MenuVerdictRules.definitions.values) {
        expect(MenuAnalysisPrompt.system, contains(definition));
      }
    });

    test('contains every hidden carb trap', () {
      for (final trap in MenuVerdictRules.hiddenCarbTraps) {
        expect(MenuAnalysisPrompt.system, contains(trap));
      }
    });

    test('names every DishVerdict by its .name', () {
      for (final verdict in DishVerdict.values) {
        expect(MenuAnalysisPrompt.system, contains(verdict.name));
      }
    });

    test('requires a JSON-object-only reply with no markdown fence', () {
      expect(MenuAnalysisPrompt.system, isNot(contains('```')));
      expect(MenuAnalysisPrompt.system, contains('"dishes"'));
      expect(MenuAnalysisPrompt.system, contains('"unclassified"'));
    });

    test('states that modification is required only for modifiable dishes', () {
      expect(MenuAnalysisPrompt.system, contains('modification'));
      expect(MenuAnalysisPrompt.system, contains(DishVerdict.modifiable.name));
    });

    test('states the menu text is data, not instruction', () {
      expect(MenuAnalysisPrompt.system, contains('נתון בלבד'));
    });

    test('is stable across reads', () {
      expect(MenuAnalysisPrompt.system, MenuAnalysisPrompt.system);
    });
  });

  group('MenuAnalysisPrompt.user', () {
    test('embeds a short menu unchanged when under the cap', () {
      const menu = HebrewMenuFixture.grill;
      final user = MenuAnalysisPrompt.user(menu);

      expect(user, contains(menu));
    });

    test('preserves Hebrew text for every corpus fixture under the cap', () {
      for (final menu in HebrewMenuFixture.all) {
        final user = MenuAnalysisPrompt.user(menu);
        expect(user, contains(menu.trim()));
      }
    });

    test('wraps the menu text in a clearly delimited block', () {
      final user = MenuAnalysisPrompt.user(HebrewMenuFixture.grill);
      final start = user.indexOf(HebrewMenuFixture.grill.trim());

      expect(
        start,
        greaterThan(0),
        reason: 'menu text must be framed, not first',
      );
      expect(user.substring(0, start), isNotEmpty);
      expect(
        user.substring(start + HebrewMenuFixture.grill.trim().length),
        isNotEmpty,
      );
    });

    test('truncates at maxMenuChars for an over-long menu', () {
      final overLong = 'א' * (MenuVerdictRules.maxMenuChars + 500);
      final user = MenuAnalysisPrompt.user(overLong);

      expect(user, isNot(contains(overLong)));
      expect(user, contains('א' * MenuVerdictRules.maxMenuChars));
    });

    test('never splits a UTF-16 surrogate pair at the truncation boundary', () {
      // U+1F354 (🍔) is a surrogate pair in UTF-16 — two code units — placed
      // so its high surrogate lands exactly at the cut index.
      const emoji = '🍔';
      expect(emoji.length, 2);

      final padding = 'א' * (MenuVerdictRules.maxMenuChars - 1);
      final overLong = '$padding$emoji tail text that must be cut off';

      final user = MenuAnalysisPrompt.user(overLong);

      // A correct cut drops the whole pair rather than keeping an orphaned
      // high surrogate — the padding survives intact and the emoji does not.
      expect(user, contains(padding));
      expect(user, isNot(contains(emoji)));
      expect(user, isNot(contains('tail text that must be cut off')));
    });

    test('trims surrounding whitespace before capping', () {
      final user = MenuAnalysisPrompt.user(
        '   \n${HebrewMenuFixture.fish}\n\n  ',
      );
      expect(user, contains(HebrewMenuFixture.fish.trim()));
    });
  });

  group('MenuAnalysisPrompt.schema', () {
    test('declares dishes and unclassified as required top-level fields', () {
      final schema = MenuAnalysisPrompt.schema;
      expect(schema['type'], 'object');
      expect(
        schema['required'],
        containsAll(<String>['dishes', 'unclassified']),
      );
    });

    test('enumerates exactly the three DishVerdict names', () {
      final schema = MenuAnalysisPrompt.schema;
      final properties = schema['properties'] as Map<String, Object?>;
      final dishes = properties['dishes'] as Map<String, Object?>;
      final items = dishes['items'] as Map<String, Object?>;
      final itemProperties = items['properties'] as Map<String, Object?>;
      final verdict = itemProperties['verdict'] as Map<String, Object?>;
      final verdictEnum = verdict['enum'] as List<Object?>;

      expect(verdictEnum, DishVerdict.values.map((v) => v.name).toList());
    });

    test('marks name, verdict and why as required on a dish', () {
      final schema = MenuAnalysisPrompt.schema;
      final properties = schema['properties'] as Map<String, Object?>;
      final dishes = properties['dishes'] as Map<String, Object?>;
      final items = dishes['items'] as Map<String, Object?>;
      final required = items['required'] as List<Object?>;

      expect(required, containsAll(<String>['name', 'verdict', 'why']));
      expect(required, isNot(contains('description')));
      expect(required, isNot(contains('modification')));
    });

    test('unclassified is an array of strings', () {
      final schema = MenuAnalysisPrompt.schema;
      final properties = schema['properties'] as Map<String, Object?>;
      final unclassified = properties['unclassified'] as Map<String, Object?>;

      expect(unclassified['type'], 'array');
      final items = unclassified['items'] as Map<String, Object?>;
      expect(items['type'], 'string');
    });
  });
}
