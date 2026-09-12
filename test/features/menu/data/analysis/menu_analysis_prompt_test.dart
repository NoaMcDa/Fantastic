import 'dart:convert';

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

    test('tells the model the two optional fields are null when absent', () {
      // Strict mode makes `description` and `modification` required keys, so
      // the prompt has to say what goes there when a dish has neither —
      // otherwise the model invents a modification for a green dish.
      expect(MenuAnalysisPrompt.system, contains('"modification"'));
      expect(MenuAnalysisPrompt.system, contains('"description"'));
      expect(MenuAnalysisPrompt.system, contains('null'));
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

    // Strict-mode validators (`design/m16_structured_output_fix.md`) refuse
    // a schema with an optional property or an open object before any model
    // sees the request; these three tests are the shape that passes them.
    test('lists every dish property as required, in strict-mode form', () {
      final schema = MenuAnalysisPrompt.schema;
      final properties = schema['properties'] as Map<String, Object?>;
      final dishes = properties['dishes'] as Map<String, Object?>;
      final items = dishes['items'] as Map<String, Object?>;
      final itemProperties = items['properties'] as Map<String, Object?>;
      final required = items['required'] as List<Object?>;

      expect(required, unorderedEquals(itemProperties.keys));
      expect(
        required,
        containsAll(<String>[
          'name',
          'description',
          'verdict',
          'why',
          'modification',
        ]),
      );
    });

    test('types description and modification as string or null', () {
      final schema = MenuAnalysisPrompt.schema;
      final properties = schema['properties'] as Map<String, Object?>;
      final dishes = properties['dishes'] as Map<String, Object?>;
      final items = dishes['items'] as Map<String, Object?>;
      final itemProperties = items['properties'] as Map<String, Object?>;

      for (final field in ['description', 'modification']) {
        final spec = itemProperties[field] as Map<String, Object?>;
        expect(spec['type'], ['string', 'null'], reason: field);
      }
      // The three fields a dish cannot lack stay plain strings.
      for (final field in ['name', 'verdict', 'why']) {
        final spec = itemProperties[field] as Map<String, Object?>;
        expect(spec['type'], 'string', reason: field);
      }
    });

    test('closes both objects with additionalProperties false', () {
      final schema = MenuAnalysisPrompt.schema;
      expect(schema['additionalProperties'], isFalse);

      final properties = schema['properties'] as Map<String, Object?>;
      final dishes = properties['dishes'] as Map<String, Object?>;
      final items = dishes['items'] as Map<String, Object?>;
      expect(items['additionalProperties'], isFalse);
    });

    test('is JSON-encodable as sent over the wire', () {
      expect(() => jsonEncode(MenuAnalysisPrompt.schema), returnsNormally);
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
