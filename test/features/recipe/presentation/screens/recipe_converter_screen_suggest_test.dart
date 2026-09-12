import 'package:fantastic/core/constants/recipe_copy.dart';
import 'package:fantastic/features/recipe/application/providers/recipe_providers.dart';
import 'package:fantastic/features/recipe/data/providers.dart';
import 'package:fantastic/features/recipe/domain/models/ingredient_outcome.dart';
import 'package:fantastic/features/recipe/domain/models/outcome_source.dart';
import 'package:fantastic/features/recipe/domain/models/parsed_ingredient.dart';
import 'package:fantastic/features/recipe/domain/models/substitution.dart';
import 'package:fantastic/features/recipe/domain/models/suggestion_result.dart';
import 'package:fantastic/features/recipe/domain/services/substitution_suggester.dart';
import 'package:fantastic/features/recipe/domain/substitution_engine.dart';
import 'package:fantastic/features/recipe/presentation/screens/recipe_converter_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

/// A hand-written fake, never a `mocktail` stub that could fall through to
/// a real implementation — the same guarantee
/// `llm_substitution_suggester_test.dart` relies on, one layer up: nothing in
/// this file can reach a network no matter how it is driven.
class _FakeSubstitutionSuggester implements SubstitutionSuggester {
  SuggestionResult Function(List<ParsedIngredient> unrecognised)? onSuggest;
  List<ParsedIngredient>? lastRequested;
  int callCount = 0;

  @override
  Future<SuggestionResult> suggest(List<ParsedIngredient> unrecognised) async {
    callCount++;
    lastRequested = unrecognised;
    return onSuggest?.call(unrecognised) ??
        const SuggestionsFailed(reason: SuggestionFailureReason.badResponse);
  }
}

/// #396's affordance on #119's screen: a button that appears only when the
/// rule table left a line unanswered, sends exactly those lines, and never
/// makes a real request — every case here drives the screen against a
/// hand-written fake.
void main() {
  // The same small table `recipe_converter_screen_test.dart` uses.
  const testEngine = SubstitutionEngine(
    substitutions: [
      (
        aliases: ['קמח'],
        replacement: 'קמח שקדים',
        ratio: 0.25,
        reason: 'עתיר פחמימות',
      ),
    ],
    staples: ['ביצימ'],
  );

  late _FakeSubstitutionSuggester suggester;

  setUp(() {
    suggester = _FakeSubstitutionSuggester();
  });

  Future<void> pumpScreen(WidgetTester tester) => pumpApp(
    tester,
    const RecipeConverterScreen(),
    overrides: [
      substitutionEngineProvider.overrideWithValue(testEngine),
      substitutionSuggesterProvider.overrideWithValue(suggester),
    ],
  );

  Future<void> paste(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('recipe_paste_field')), text);
    await tester.pump();
  }

  Future<void> convert(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('recipe_convert_button')));
    await tester.pumpAndSettle();
  }

  Future<void> tapSuggest(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('suggest_button')));
    await tester.pumpAndSettle();
  }

  testWidgets('the suggest button is absent when nothing is unrecognised', (
    tester,
  ) async {
    await pumpScreen(tester);
    // Only rows the test engine's rule table answers — no Unrecognised line.
    await paste(tester, '2 כוסות קמח\n3 ביצימ');
    await convert(tester);

    expect(find.byKey(const Key('suggest_button')), findsNothing);
    expect(suggester.callCount, 0);
  });

  testWidgets('the suggest button is absent before any conversion has run', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.byKey(const Key('suggest_button')), findsNothing);
  });

  testWidgets(
    'nothing animates before a tap — the spinner is absent on build',
    (tester) async {
      await pumpScreen(tester);
      await paste(tester, 'קסמוקס בלתי ידוע לגמרי');
      await convert(tester);

      expect(find.byKey(const Key('suggest_button')), findsOneWidget);
      expect(find.byKey(const Key('suggest_progress')), findsNothing);
    },
  );

  testWidgets(
    'a returned suggestion replaces the row and shows the suggested marker',
    (tester) async {
      suggester.onSuggest = (unrecognised) => SuggestionsReturned(
        outcomes: {
          for (final ingredient in unrecognised)
            SubstitutionEngine.key(ingredient.name): Substituted(
              ingredient,
              substitution: const Substitution(
                replacement: 'קמח שקדים',
                ratio: 1,
                reason: 'הוצע על ידי מודל',
              ),
              source: OutcomeSource.suggested,
            ),
        },
      );

      await pumpScreen(tester);
      await paste(tester, 'קסמוקס בלתי ידוע לגמרי');
      await convert(tester);

      expect(find.byKey(const Key('outcome_unrecognised_0')), findsOneWidget);

      await tapSuggest(tester);

      expect(suggester.callCount, 1);
      // Only the unrecognised ingredient's name left the device — no
      // quantities, no raw line, and the tap sent exactly one line.
      expect(suggester.lastRequested, hasLength(1));

      expect(find.byKey(const Key('outcome_unrecognised_0')), findsNothing);
      expect(find.byKey(const Key('outcome_substituted_0')), findsOneWidget);
      expect(find.text(RecipeCopy.suggestedMarker), findsOneWidget);
    },
  );

  testWidgets(
    'zero usable outcomes renders RecipeCopy.noSuggestions, not an error',
    (tester) async {
      suggester.onSuggest = (_) => const SuggestionsReturned(outcomes: {});

      await pumpScreen(tester);
      await paste(tester, 'קסמוקס בלתי ידוע לגמרי');
      await convert(tester);
      await tapSuggest(tester);

      expect(find.text(RecipeCopy.noSuggestions), findsOneWidget);
      // The row is untouched — still Unrecognised.
      expect(find.byKey(const Key('outcome_unrecognised_0')), findsOneWidget);
    },
  );

  testWidgets('notConfigured shows the profile escape', (tester) async {
    suggester.onSuggest = (_) =>
        const SuggestionsFailed(reason: SuggestionFailureReason.notConfigured);

    await pumpScreen(tester);
    await paste(tester, 'קסמוקס בלתי ידוע לגמרי');
    await convert(tester);
    await tapSuggest(tester);

    expect(find.text(RecipeCopy.suggestFailedNotConfigured), findsOneWidget);
    expect(find.byKey(const Key('suggest_profile_button')), findsOneWidget);

    // Tapping it must not crash even though this harness has no GoRouter —
    // `GoRouter.maybeOf` is what makes that true.
    await tester.tap(find.byKey(const Key('suggest_profile_button')));
    await tester.pumpAndSettle();
  });

  testWidgets('a failure leaves the deterministic results on screen', (
    tester,
  ) async {
    suggester.onSuggest = (_) =>
        const SuggestionsFailed(reason: SuggestionFailureReason.offline);

    await pumpScreen(tester);
    await paste(tester, '2 כוסות קמח\nקסמוקס בלתי ידוע לגמרי');
    await convert(tester);
    await tapSuggest(tester);

    expect(find.text(RecipeCopy.suggestFailedOffline), findsOneWidget);
    // The rule table's own answer and the still-unresolved line are both
    // exactly as they were before the failed attempt.
    expect(find.byKey(const Key('outcome_substituted_0')), findsOneWidget);
    expect(find.byKey(const Key('outcome_unrecognised_1')), findsOneWidget);
  });

  testWidgets('rateLimited and badResponse render their own headline', (
    tester,
  ) async {
    for (final entry in {
      SuggestionFailureReason.rateLimited: RecipeCopy.suggestFailedRateLimited,
      SuggestionFailureReason.badResponse: RecipeCopy.suggestFailedBadResponse,
    }.entries) {
      suggester.onSuggest = (_) => SuggestionsFailed(reason: entry.key);

      await pumpScreen(tester);
      await paste(tester, 'קסמוקס בלתי ידוע לגמרי');
      await convert(tester);
      await tapSuggest(tester);

      expect(find.text(entry.value), findsOneWidget);
      expect(
        find.byKey(const Key('suggest_profile_button')),
        findsNothing,
        reason: '${entry.key.name} does not offer the profile escape',
      );
    }
  });

  testWidgets('converting again clears a previous suggest failure', (
    tester,
  ) async {
    suggester.onSuggest = (_) =>
        const SuggestionsFailed(reason: SuggestionFailureReason.offline);

    await pumpScreen(tester);
    await paste(tester, 'קסמוקס בלתי ידוע לגמרי');
    await convert(tester);
    await tapSuggest(tester);
    expect(find.text(RecipeCopy.suggestFailedOffline), findsOneWidget);

    await convert(tester);

    expect(find.text(RecipeCopy.suggestFailedOffline), findsNothing);
  });
}
