import 'package:fantastic/features/recipe/domain/models/ingredient_outcome.dart';
import 'package:fantastic/features/recipe/domain/models/outcome_source.dart';
import 'package:fantastic/features/recipe/domain/models/suggestion_result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';

/// `SuggestionResult` carries no logic of its own to unit-test — it is a data
/// carrier the parser builds and the screen reads — but the file has real
/// method bodies (`toString`, `==`, `hashCode`), so it needs a test that
/// imports it for `tool/check_coverage_files.sh` to find a coverage record.
void main() {
  group('SuggestionsReturned', () {
    test('carries its outcomes, keyed as the caller built them', () {
      final outcome = AlreadyKeto(
        IngredientOutcomeFixture.ingredient(),
        source: OutcomeSource.suggested,
      );
      final result = SuggestionsReturned(outcomes: {'קמח': outcome});

      expect(result.outcomes['קמח'], outcome);
      expect(result.toString(), contains('1 outcomes'));
    });

    test('an empty map is a valid, real answer', () {
      const result = SuggestionsReturned(outcomes: {});

      expect(result.outcomes, isEmpty);
    });
  });

  group('SuggestionsFailed', () {
    test('equality and hashCode are by reason', () {
      const a = SuggestionsFailed(reason: SuggestionFailureReason.offline);
      const b = SuggestionsFailed(reason: SuggestionFailureReason.offline);
      const c = SuggestionsFailed(reason: SuggestionFailureReason.rateLimited);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('toString names the reason and carries no other detail', () {
      const result = SuggestionsFailed(
        reason: SuggestionFailureReason.badResponse,
      );

      expect(result.toString(), 'SuggestionsFailed(badResponse)');
    });
  });
}
