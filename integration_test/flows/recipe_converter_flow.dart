import 'package:fantastic/core/constants/recipe_copy.dart';
import 'package:fantastic/core/router/app_router.dart';
import 'package:fantastic/core/services/llm/llm_chat_client.dart';
import 'package:fantastic/core/services/llm/open_router_client.dart';
import 'package:fantastic/features/diary/data/estimation/user_api_key_credentials.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/data/repositories/sembast_estimation_settings_repository.dart';
import 'package:fantastic/features/diary/domain/models/estimated_item.dart';
import 'package:fantastic/features/diary/domain/models/estimation_settings.dart';
import 'package:fantastic/features/diary/domain/models/meal_estimate.dart';
import 'package:fantastic/features/diary/domain/services/macro_estimator.dart';
import 'package:fantastic/features/recipe/data/providers.dart';
import 'package:fantastic/features/recipe/presentation/screens/recipe_library_screen.dart';
import 'package:fantastic/features/recipe/presentation/screens/saved_recipe_loader.dart';
import 'package:fantastic/features/recipe/presentation/widgets/ingredient_outcome_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
// Shown, not imported wholesale: both `flutter_test` and `sembast` export a
// `Finder` (`CLAUDE.md` §Testing).
import 'package:sembast/sembast.dart' show Database;
import 'package:sembast/sembast_memory.dart' show newDatabaseFactoryMemory;

import '../../test/fixtures/fixtures.dart';
import '../helpers/app_harness.dart';

/// #396's model pass, faked. Records every call and hands back a settable,
/// fixed reply.
///
/// Hand-written, never a `mocktail` stub that could fall through to a real
/// provider — the same reasoning `add_meal_photo_flow.dart`'s
/// `_CountingEstimator` and `add_meal_description_flow.dart`'s
/// `_FixedEstimator` both carry, and the reason this suite never makes a
/// real network request.
class _CountingChatClient implements LlmChatClient {
  ChatResult result = const ChatFailed(ChatFailureReason.badResponse);
  int calls = 0;

  @override
  Future<ChatResult> complete({
    required String systemPrompt,
    required String userPrompt,
    String? imageBase64,
    String? imageMediaType,
    int? maxOutputTokens,
    Map<String, Object?>? responseSchema,
  }) async {
    calls++;
    return result;
  }
}

/// A fixed macro estimate for #397's per-serving path.
///
/// A separate double from [_CountingChatClient]: `RecipeMacrosSection`
/// reaches `MacroEstimator` — the diary feature's own estimation interface —
/// never `LlmChatClient` directly, the same two-layer split
/// `RemoteMacroEstimator` sits behind for the description and photo modes.
/// Overriding it touches nothing the substitution engine or #396's suggester
/// use, so group 1 stays a test of the shipped conversion table.
class _FixedEstimator implements MacroEstimator {
  _FixedEstimator(this.result);

  final MealEstimate result;

  @override
  Future<MealEstimate> estimate({
    String? description,
    String? imagePath,
  }) async => result;
}

/// `#398` — the מתכונים tab, end to end: a real conversion against the
/// shipped `SubstitutionRules` table, saving, the library, a reopen by path,
/// deletion, #397's per-serving estimate and logged serving, and #396's
/// model pass with the zero-call gate and the `IngredientRules` re-check.
void main() {
  /// Boots onto the tab, the way a user reaches it — never `router.go`
  /// (`design/user_bugs_handoff.md`: a flow that exercises one route to a
  /// capability is not a test that the capability is reachable).
  Future<AppUnderTest> bootRecipeApp(
    WidgetTester tester, {
    List<Override> overrides = const [],
    Database? database,
  }) async {
    final app = await bootApp(
      onboarded: true,
      overrides: overrides,
      database: database,
    );
    await pumpApp(tester, app);
    await goToTab(tester, 'tab_recipe');
    return app;
  }

  Future<void> pasteAndConvert(
    WidgetTester tester, [
    String text = RecipeFixture.cake,
  ]) async {
    await enterInto(tester, 'recipe_paste_field', text);
    await tapAt(tester, find.byKey(const Key('recipe_convert_button')));
  }

  /// Saves the conversion on screen under [title].
  ///
  /// Fires the confirmation `SnackBar`'s own auto-dismiss timer before
  /// returning — the same fix `recipe_converter_screen_macros_test.dart`
  /// carries — rather than leaving it to intercept whatever the caller taps
  /// next, since `RecipeMacrosSection` mounts at the exact moment the
  /// SnackBar appears.
  Future<void> saveRecipe(WidgetTester tester, String title) async {
    await tapAt(tester, find.byKey(const Key('save_recipe_button')));
    await enterInto(tester, 'recipe_title_field', title);
    await tapAt(tester, find.byKey(const Key('recipe_title_save_button')));
    await tester.pump(const Duration(seconds: 5));
    await settle(tester);
  }

  group('the deterministic path — the shipped substitution table, no engine '
      'or model override', () {
    testWidgets('the מתכונים tab opens the converter', (tester) async {
      await bootRecipeApp(tester);

      expect(find.byKey(const Key('recipe_paste_field')), findsOneWidget);
    });

    testWidgets(
      'paste, convert: one row per non-blank line, each variant rendered '
      'distinctly',
      (tester) async {
        await bootRecipeApp(tester);
        await pasteAndConvert(tester);

        expect(find.byKey(const Key('outcome_substituted_0')), findsOneWidget);
        expect(find.byKey(const Key('outcome_substituted_1')), findsOneWidget);
        expect(find.byKey(const Key('outcome_already_keto_2')), findsOneWidget);
        expect(find.byKey(const Key('outcome_flagged_3')), findsOneWidget);
        expect(find.byKey(const Key('outcome_unrecognised_4')), findsOneWidget);
        // The blank line never became a sixth row.
        expect(find.byType(IngredientOutcomeRow), findsNWidgets(5));

        // The unknown row is not styled as approved — two different labels,
        // both on screen, is what proves neither collapsed onto the other.
        expect(find.text(RecipeCopy.alreadyKeto), findsOneWidget);
        expect(find.text(RecipeCopy.unrecognised), findsOneWidget);
        expect(find.text(RecipeCopy.flagged), findsOneWidget);
      },
    );

    testWidgets('a ratio is applied to the quantity, not just displayed '
        'beside it', (tester) async {
      await bootRecipeApp(tester);
      await pasteAndConvert(tester);

      // `4 כפות קורנפלור` substituted at ratio 0.125 — the adjusted `0.5`,
      // never the raw `4`.
      expect(
        find.descendant(
          of: find.byKey(const Key('outcome_substituted_1')),
          matching: find.text('0.5 כפות'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('outcome_substituted_1')),
          matching: find.text('4 כפות'),
        ),
        findsNothing,
      );
    });

    testWidgets(
      'save with a title → library shows it → reopen shows the same rows → '
      'delete removes it',
      (tester) async {
        final app = await bootRecipeApp(tester);
        await pasteAndConvert(tester);
        await saveRecipe(tester, RecipeFixture.title);

        final saved = await app.container
            .read(savedRecipeRepositoryProvider)
            .findAll();
        final id = saved.single.id!;

        await tapAt(tester, find.byKey(const Key('open_recipe_library')));
        expect(find.byType(RecipeLibraryScreen), findsOneWidget);
        expect(find.text(RecipeFixture.title), findsOneWidget);

        await tapAt(tester, find.byKey(Key('saved_recipe_$id')));
        expect(find.byType(SavedRecipeLoader), findsOneWidget);
        // Reopened exactly as it was saved — the same five rows, not re-run
        // against the (unchanged) rule table.
        expect(find.byKey(const Key('outcome_substituted_0')), findsOneWidget);
        expect(find.byKey(const Key('outcome_substituted_1')), findsOneWidget);
        expect(find.byKey(const Key('outcome_already_keto_2')), findsOneWidget);
        expect(find.byKey(const Key('outcome_flagged_3')), findsOneWidget);
        expect(find.byKey(const Key('outcome_unrecognised_4')), findsOneWidget);
        expect(find.byKey(const Key('recipe_not_found_notice')), findsNothing);

        // Back to the library and delete.
        await tapAt(tester, find.byKey(const Key('open_recipe_library')));
        await tester.drag(
          find.byKey(Key('saved_recipe_$id')),
          const Offset(500, 0),
        );
        await settle(tester);

        await waitFor(tester, () async {
          final remaining = await app.container
              .read(savedRecipeRepositoryProvider)
              .findAll();
          return remaining.isEmpty;
        }, reason: 'the deleted recipe is still in storage');
        expect(find.text(RecipeCopy.emptyLibraryTitle), findsOneWidget);
      },
    );

    testWidgets('the tab bar stays on screen in the library and on a reopened '
        'recipe, with the recipe tab active', (tester) async {
      final app = await bootRecipeApp(tester);
      await pasteAndConvert(tester);
      await saveRecipe(tester, RecipeFixture.title);
      final id =
          (await app.container.read(savedRecipeRepositoryProvider).findAll())
              .single
              .id!;

      await tapAt(tester, find.byKey(const Key('open_recipe_library')));
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        kTabPaths.indexOf(kRecipePath),
      );

      await tapAt(tester, find.byKey(Key('saved_recipe_$id')));
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        kTabPaths.indexOf(kRecipePath),
      );
    });

    testWidgets('a reload of /recipe/saved/:id reopens the same recipe', (
      tester,
    ) async {
      final app = await bootRecipeApp(tester);
      await pasteAndConvert(tester);
      await saveRecipe(tester, RecipeFixture.title);
      final id =
          (await app.container.read(savedRecipeRepositoryProvider).findAll())
              .single
              .id!;

      // Pumped at the path directly, the way a browser reload or a deep link
      // arrives — never through the library button — proving the *route*
      // resolves the recipe rather than leftover in-memory screen state.
      app.container.read(appRouterProvider).go('$kRecipePath/saved/$id');
      await settle(tester);

      expect(find.byType(SavedRecipeLoader), findsOneWidget);
      expect(find.byKey(const Key('outcome_already_keto_2')), findsOneWidget);
      expect(find.byKey(const Key('recipe_not_found_notice')), findsNothing);
    });

    testWidgets(
      'servings 4 → estimate (fake) → per-serving row is a quarter → log '
      'serving opens the form with per-serving figures',
      (tester) async {
        // The batch's whole-pot totals — 40 g fat, 8 g net carbs, 16 g
        // protein — divided by 4 servings is a clean quarter: 10, 2, 4.
        final estimator = _FixedEstimator(
          const EstimateSucceeded(
            items: [
              EstimatedItem(
                name: 'עוגה',
                grams: 800,
                fatG: 40,
                netCarbsG: 8,
                proteinG: 16,
              ),
            ],
          ),
        );
        await bootRecipeApp(
          tester,
          overrides: [macroEstimatorProvider.overrideWithValue(estimator)],
        );
        await pasteAndConvert(tester);
        // `RecipeMacrosSection` mounts only after the recipe is saved
        // (correction (4) — until #397 it did not, and the hint rendered in
        // its place).
        await saveRecipe(tester, RecipeFixture.title);

        await enterInto(tester, 'recipe_servings_field', '4');
        // Closes the IME before the next tap — a plain `enterText` leaves the
        // following tap hit-testing against a focused-field frame and it
        // silently lands nowhere (`recipe_converter_screen_macros_test.dart`).
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await settle(tester);

        await tapAt(tester, find.byKey(const Key('recipe_estimate_button')));

        expect(
          find.text(RecipeCopy.perServingSummary(10, 2, 4)),
          findsOneWidget,
        );

        await tapAt(tester, find.byKey(const Key('recipe_log_serving_button')));

        expect(fieldText(tester, 'meal_name_field'), RecipeFixture.title);
        expect(fieldText(tester, 'fat_field'), '10');
        expect(fieldText(tester, 'carbs_field'), '2');
        expect(fieldText(tester, 'protein_field'), '4');
      },
    );
  });

  group('the model path — #396, llmChatClientProvider overridden', () {
    testWidgets(
      'estimation off: tapping suggest makes zero calls and shows the '
      'profile escape',
      (tester) async {
        // **Deliberately not `_CountingChatClient` here.** `RecipeConverterScreen`
        // and `LlmSubstitutionSuggester` carry no credentials check of their
        // own — the *only* shipped short-circuit lives inside
        // `OpenRouterClient.complete()`, which returns before ever touching
        // its `http.Client` when no token is configured. Plugging a raw
        // `LlmChatClient` double in at `llmChatClientProvider` would bypass
        // that check entirely, so a `calls == 0` assertion against it would
        // pass even if the real gate were deleted — exactly the "a test that
        // skips where the bug lives reads identically to a pass" trap
        // `design/user_bugs_handoff.md` names. Using the real
        // `OpenRouterClient`, wired to the real (unseeded) credentials chain,
        // and faking only the raw HTTP transport underneath it, tests the
        // shipped short-circuit itself while still making no real network
        // request — the same `MockClient` idiom
        // `test/core/services/llm/open_router_client_test.dart` already
        // uses for exactly this case.
        final requestsSent = <http.Request>[];
        final db = await newDatabaseFactoryMemory().openDatabase(
          'recipe-flow-estimation-off.db',
        );
        await bootRecipeApp(
          tester,
          database: db,
          overrides: [
            llmChatClientProvider.overrideWithValue(
              OpenRouterClient(
                httpClient: MockClient((request) async {
                  requestsSent.add(request);
                  return http.Response('{}', 500);
                }),
                credentials: UserApiKeyCredentials(
                  SembastEstimationSettingsRepository(db),
                ),
              ),
            ),
          ],
        );

        // Only one Unrecognised line is needed to reveal the suggest button.
        await pasteAndConvert(tester, RecipeFixture.cake);

        await tapAt(tester, find.byKey(const Key('suggest_button')));

        expect(requestsSent, isEmpty);
        expect(find.byKey(const Key('suggest_failure')), findsOneWidget);
        expect(
          find.text(RecipeCopy.suggestFailedNotConfigured),
          findsOneWidget,
        );
        expect(find.byKey(const Key('suggest_profile_button')), findsOneWidget);
        // The row itself never moved.
        expect(find.byKey(const Key('outcome_unrecognised_4')), findsOneWidget);

        await tapAt(tester, find.byKey(const Key('suggest_profile_button')));
        expect(find.text('פרופיל'), findsWidgets);
      },
    );

    testWidgets('estimation on with a fixed reply: the unknown row becomes a '
        'substitution with the suggested marker', (tester) async {
      final chatClient = _CountingChatClient()
        ..result = const ChatSucceeded(
          '{"substitutions":[{"original":"פירורי עוגיות",'
          '"replacement":"פירורי שקדים","ratio":1.0,'
          '"reason":"תחליף אפוי קלוי"}]}',
        );
      final app = await bootRecipeApp(
        tester,
        overrides: [llmChatClientProvider.overrideWithValue(chatClient)],
      );
      // Seeded through the real repository, per the issue's plan — inert
      // for `_CountingChatClient`, which does not consult credentials at
      // all, but written so the app is not left in a state no real user
      // reaches (the same reasoning `menu_text_flow.dart` records).
      await app.container
          .read(estimationSettingsRepositoryProvider)
          .save(
            const EstimationSettings(
              apiKey: 'sk-e2e-flow-key',
              consentAccepted: true,
            ),
          );
      await pasteAndConvert(tester);

      await tapAt(tester, find.byKey(const Key('suggest_button')));

      expect(chatClient.calls, 1);
      expect(find.byKey(const Key('outcome_unrecognised_4')), findsNothing);
      expect(find.byKey(const Key('outcome_substituted_4')), findsOneWidget);
      expect(find.text(RecipeCopy.suggestedMarker), findsOneWidget);
      expect(find.text('פירורי שקדים'), findsOneWidget);
    });

    testWidgets('a reply proposing maltitol leaves the row unrecognised', (
      tester,
    ) async {
      final chatClient = _CountingChatClient()
        ..result = const ChatSucceeded(
          '{"substitutions":[{"original":"פירורי עוגיות",'
          '"replacement":"מלטיטול","ratio":1.0,"reason":"ממתיק"}]}',
        );
      final app = await bootRecipeApp(
        tester,
        overrides: [llmChatClientProvider.overrideWithValue(chatClient)],
      );
      await app.container
          .read(estimationSettingsRepositoryProvider)
          .save(
            const EstimationSettings(
              apiKey: 'sk-e2e-flow-key',
              consentAccepted: true,
            ),
          );
      await pasteAndConvert(tester);

      await tapAt(tester, find.byKey(const Key('suggest_button')));

      expect(chatClient.calls, 1);
      // `IngredientRules`' own re-check, independent of what the prompt
      // asked for: a model naming a flagged sweetener is answered with
      // nothing usable, so the line stays exactly what it was.
      expect(find.byKey(const Key('outcome_unrecognised_4')), findsOneWidget);
      expect(find.byKey(const Key('outcome_substituted_4')), findsNothing);
      expect(find.text(RecipeCopy.noSuggestions), findsOneWidget);
    });

    testWidgets('a reply for a line that was not asked about changes nothing', (
      tester,
    ) async {
      final chatClient = _CountingChatClient()
        ..result = const ChatSucceeded(
          '{"substitutions":[{"original":"שוקולד מריר",'
          '"replacement":"שוקולד 90 אחוז","ratio":1.0,"reason":"פחות סוכר"}]}',
        );
      final app = await bootRecipeApp(
        tester,
        overrides: [llmChatClientProvider.overrideWithValue(chatClient)],
      );
      await app.container
          .read(estimationSettingsRepositoryProvider)
          .save(
            const EstimationSettings(
              apiKey: 'sk-e2e-flow-key',
              consentAccepted: true,
            ),
          );
      await pasteAndConvert(tester);

      await tapAt(tester, find.byKey(const Key('suggest_button')));

      expect(chatClient.calls, 1);
      // Nothing the model was not asked about moved — every other outcome
      // is exactly as the rule table classified it, and the one line
      // actually sent stays `Unrecognised` because the reply named a line
      // that was never requested.
      expect(find.byKey(const Key('outcome_substituted_0')), findsOneWidget);
      expect(find.byKey(const Key('outcome_substituted_1')), findsOneWidget);
      expect(find.byKey(const Key('outcome_already_keto_2')), findsOneWidget);
      expect(find.byKey(const Key('outcome_flagged_3')), findsOneWidget);
      expect(find.byKey(const Key('outcome_unrecognised_4')), findsOneWidget);
      expect(find.text(RecipeCopy.noSuggestions), findsOneWidget);
    });
  });
}
