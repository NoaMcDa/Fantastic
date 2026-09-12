import 'dart:convert';

import 'package:fantastic/features/recipe/data/suggestion/suggestion_response_parser.dart';
import 'package:fantastic/features/recipe/domain/models/ingredient_outcome.dart';
import 'package:fantastic/features/recipe/domain/models/outcome_source.dart';
import 'package:fantastic/features/recipe/domain/models/parsed_ingredient.dart';
import 'package:fantastic/features/recipe/domain/models/suggestion_result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';

/// The trust boundary for #396's model pass — the reply is JSON from a third
/// party and every case here treats it as hostile input, mirroring
/// `estimate_response_parser_test.dart`.
void main() {
  final flour = IngredientOutcomeFixture.ingredient(
    name: 'קמח לבן',
    raw: '2 כוסות קמח לבן',
  );
  final eggs = IngredientOutcomeFixture.ingredient(
    name: 'ביצים',
    raw: '3 ביצים',
    quantity: 3,
    unit: null,
  );
  final requested = [flour, eggs];

  String replyWith({
    List<Map<String, Object?>> substitutions = const [],
    List<String> alreadyKeto = const [],
    List<String> unknown = const [],
  }) => jsonEncode({
    'substitutions': substitutions,
    'already_keto': alreadyKeto,
    'unknown': unknown,
  });

  Map<String, Object?> substitutionOf({
    Object? original = 'קמח לבן',
    Object? replacement = 'קמח שקדים',
    Object? ratio = 1.0,
    Object? reason = 'סיבה',
  }) => {
    'original': original,
    'replacement': replacement,
    'ratio': ratio,
    'reason': reason,
  };

  group('parse', () {
    test(
      'a well-formed reply yields suggested outcomes keyed by normalised name',
      () {
        final result = SuggestionResponseParser.parse(
          replyWith(
            substitutions: [
              substitutionOf(
                replacement: 'קמח שקדים',
                ratio: 0.25,
                reason: 'עתיר פחמימות',
              ),
            ],
          ),
          requested,
        );

        expect(result, isA<SuggestionsReturned>());
        final outcomes = (result as SuggestionsReturned).outcomes;
        expect(outcomes, hasLength(1));
        final outcome = outcomes.values.single;
        expect(outcome, isA<Substituted>());
        final substituted = outcome as Substituted;
        expect(substituted.ingredient, flour);
        expect(substituted.source, OutcomeSource.suggested);
        expect(substituted.substitution.replacement, 'קמח שקדים');
        expect(substituted.substitution.ratio, 0.25);
        expect(substituted.substitution.reason, 'עתיר פחמימות');
      },
    );

    test('strips a markdown fence', () {
      final fenced =
          '```json\n'
          '${replyWith(substitutions: [substitutionOf()])}\n'
          '```';

      final result = SuggestionResponseParser.parse(fenced, requested);

      expect(result, isA<SuggestionsReturned>());
      expect((result as SuggestionsReturned).outcomes, hasLength(1));
    });

    test('an original not in the request is ignored', () {
      final result = SuggestionResponseParser.parse(
        replyWith(substitutions: [substitutionOf(original: 'משהו שלא נשלח')]),
        requested,
      );

      expect(result, isA<SuggestionsReturned>());
      expect((result as SuggestionsReturned).outcomes, isEmpty);
    });

    test('ratio Infinity, NaN, negative, 0.01 and 50 leave the line out', () {
      for (final ratio in [
        'Infinity',
        'NaN',
        -1.0,
        0.01, // below SuggestionResponseParser.minRatio (0.05)
        50.0, // above SuggestionResponseParser.maxRatio (20)
      ]) {
        final result = SuggestionResponseParser.parse(
          replyWith(substitutions: [substitutionOf(ratio: ratio)]),
          requested,
        );

        expect(
          (result as SuggestionsReturned).outcomes,
          isEmpty,
          reason: 'ratio $ratio should leave the line out',
        );
      }
    });

    test('0.05 and 20 — the inclusive edges — are accepted', () {
      for (final ratio in [
        SuggestionResponseParser.minRatio,
        SuggestionResponseParser.maxRatio,
      ]) {
        final result = SuggestionResponseParser.parse(
          replyWith(substitutions: [substitutionOf(ratio: ratio)]),
          requested,
        );

        expect(
          (result as SuggestionsReturned).outcomes,
          hasLength(1),
          reason: 'ratio $ratio should be accepted',
        );
      }
    });

    test('a replacement naming maltitol leaves the line out', () {
      final result = SuggestionResponseParser.parse(
        replyWith(substitutions: [substitutionOf(replacement: 'מלטיטול')]),
        requested,
      );

      expect((result as SuggestionsReturned).outcomes, isEmpty);
    });

    test('a replacement naming canola oil leaves the line out', () {
      final result = SuggestionResponseParser.parse(
        replyWith(substitutions: [substitutionOf(replacement: 'canola oil')]),
        requested,
      );

      expect((result as SuggestionsReturned).outcomes, isEmpty);
    });

    test('already_keto becomes AlreadyKeto(suggested)', () {
      final result = SuggestionResponseParser.parse(
        replyWith(alreadyKeto: ['ביצים']),
        requested,
      );

      final outcomes = (result as SuggestionsReturned).outcomes;
      expect(outcomes, hasLength(1));
      final outcome = outcomes.values.single;
      expect(outcome, isA<AlreadyKeto>());
      expect((outcome as AlreadyKeto).ingredient, eggs);
      expect(outcome.source, OutcomeSource.suggested);
    });

    test('reason is truncated at 120', () {
      final longReason = 'א' * 200;
      final result = SuggestionResponseParser.parse(
        replyWith(substitutions: [substitutionOf(reason: longReason)]),
        requested,
      );

      final outcomes = (result as SuggestionsReturned).outcomes;
      final substituted = outcomes.values.single as Substituted;
      expect(
        substituted.substitution.reason.length,
        SuggestionResponseParser.maxReasonLength,
      );
    });

    test('an empty replacement leaves the line out', () {
      final result = SuggestionResponseParser.parse(
        replyWith(substitutions: [substitutionOf(replacement: '   ')]),
        requested,
      );

      expect((result as SuggestionsReturned).outcomes, isEmpty);
    });

    test('nothing usable is an empty SuggestionsReturned, not a failure', () {
      final result = SuggestionResponseParser.parse(replyWith(), requested);

      expect(result, isA<SuggestionsReturned>());
      expect((result as SuggestionsReturned).outcomes, isEmpty);
    });

    test('non-JSON is badResponse', () {
      final result = SuggestionResponseParser.parse(
        'not json at all',
        requested,
      );

      expect(
        result,
        const SuggestionsFailed(reason: SuggestionFailureReason.badResponse),
      );
    });

    test('a non-map top level is badResponse', () {
      final result = SuggestionResponseParser.parse(
        jsonEncode([1, 2, 3]),
        requested,
      );

      expect(
        result,
        const SuggestionsFailed(reason: SuggestionFailureReason.badResponse),
      );
    });

    test('a missing substitutions list is badResponse', () {
      final result = SuggestionResponseParser.parse(
        jsonEncode({'already_keto': <String>[]}),
        requested,
      );

      expect(
        result,
        const SuggestionsFailed(reason: SuggestionFailureReason.badResponse),
      );
    });

    test('a non-map entry in substitutions is ignored, not fatal', () {
      final result = SuggestionResponseParser.parse(
        jsonEncode({
          'substitutions': ['not a map'],
          'already_keto': <String>[],
        }),
        requested,
      );

      expect(result, isA<SuggestionsReturned>());
      expect((result as SuggestionsReturned).outcomes, isEmpty);
    });

    test('an empty requested list matches nothing', () {
      final result = SuggestionResponseParser.parse(
        replyWith(substitutions: [substitutionOf()]),
        const <ParsedIngredient>[],
      );

      expect((result as SuggestionsReturned).outcomes, isEmpty);
    });
  });
}
