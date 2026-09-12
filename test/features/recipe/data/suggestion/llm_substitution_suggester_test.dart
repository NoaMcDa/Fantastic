import 'dart:convert';

import 'package:fantastic/core/services/llm/llm_chat_client.dart';
import 'package:fantastic/features/recipe/data/suggestion/llm_substitution_suggester.dart';
import 'package:fantastic/features/recipe/data/suggestion/substitution_prompt.dart';
import 'package:fantastic/features/recipe/domain/models/parsed_ingredient.dart';
import 'package:fantastic/features/recipe/domain/models/suggestion_result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';

/// A hand-written fake, never a `mocktail` stub.
///
/// **This is the one guarantee in the file that no test here makes a real
/// network request**: [complete] never touches `dart:io` or `package:http` —
/// it is pure Dart that records what it was asked and returns whatever
/// [answer] says. A `mocktail` `Mock` could in principle be left unstubbed
/// and fall through to a real method body; a hand-written fake has no real
/// method body to fall through to.
class _FakeLlmChatClient implements LlmChatClient {
  ChatResult answer = const ChatFailed(ChatFailureReason.badResponse);

  String? capturedSystemPrompt;
  String? capturedUserPrompt;
  int callCount = 0;

  @override
  Future<ChatResult> complete({
    required String systemPrompt,
    required String userPrompt,
    String? imageBase64,
    String? imageMediaType,
    int? maxOutputTokens,
    Map<String, Object?>? responseSchema,
  }) async {
    callCount++;
    capturedSystemPrompt = systemPrompt;
    capturedUserPrompt = userPrompt;
    return answer;
  }
}

void main() {
  late _FakeLlmChatClient client;
  late LlmSubstitutionSuggester suggester;

  setUp(() {
    client = _FakeLlmChatClient();
    suggester = LlmSubstitutionSuggester(client: client);
  });

  final flour = IngredientOutcomeFixture.ingredient(
    name: 'קמח לבן',
    raw: '2 כוסות קמח לבן',
  );

  group('suggest', () {
    test('empty input makes no call', () async {
      final result = await suggester.suggest(const []);

      expect(
        result,
        const SuggestionsFailed(reason: SuggestionFailureReason.emptyInput),
      );
      expect(client.callCount, 0);
    });

    test('sends names only, never quantities or raw lines', () async {
      client.answer = ChatSucceeded(
        jsonEncode({
          'substitutions': <Object?>[],
          'already_keto': <String>[],
          'unknown': <String>[],
        }),
      );

      await suggester.suggest([flour]);

      final sent = client.capturedUserPrompt!;
      expect(sent, contains(flour.name));
      expect(sent, isNot(contains(flour.raw)));
      expect(sent, isNot(contains('2 כוסות')));
      expect(client.capturedSystemPrompt, SubstitutionPrompt.system);
    });

    test('caps at maxLines', () async {
      client.answer = ChatSucceeded(
        jsonEncode({
          'substitutions': <Object?>[],
          'already_keto': <String>[],
          'unknown': <String>[],
        }),
      );

      final many = [
        for (var i = 0; i < SubstitutionPrompt.maxLines + 10; i++)
          ParsedIngredient(name: 'מצרך $i', raw: 'מצרך $i'),
      ];

      await suggester.suggest(many);

      final sentLines = client.capturedUserPrompt!.split('\n');
      // Every name sent must be one of the first `maxLines` inputs — none of
      // the excess ten ever left the device.
      for (var i = SubstitutionPrompt.maxLines; i < many.length; i++) {
        expect(sentLines, isNot(contains(many[i].name)));
      }
      for (var i = 0; i < SubstitutionPrompt.maxLines; i++) {
        expect(sentLines, contains(many[i].name));
      }
    });

    test('maps each ChatFailureReason', () async {
      final cases = {
        ChatFailureReason.offline: SuggestionFailureReason.offline,
        ChatFailureReason.timeout: SuggestionFailureReason.offline,
        ChatFailureReason.unauthorised: SuggestionFailureReason.notConfigured,
        ChatFailureReason.rateLimited: SuggestionFailureReason.rateLimited,
        ChatFailureReason.badResponse: SuggestionFailureReason.badResponse,
      };

      for (final entry in cases.entries) {
        client.answer = ChatFailed(entry.key);
        final result = await suggester.suggest([flour]);
        expect(
          result,
          SuggestionsFailed(reason: entry.value),
          reason: 'ChatFailureReason.${entry.key.name}',
        );
      }
    });

    test('a throwing client is badResponse', () async {
      final throwing = _ThrowingLlmChatClient();
      final throwingSuggester = LlmSubstitutionSuggester(client: throwing);

      final result = await throwingSuggester.suggest([flour]);

      expect(
        result,
        const SuggestionsFailed(reason: SuggestionFailureReason.badResponse),
      );
    });
  });
}

/// A client that breaks its own "never throws" promise, so the suggester's
/// defensive `on Object catch` is what is actually under test here.
class _ThrowingLlmChatClient implements LlmChatClient {
  @override
  Future<ChatResult> complete({
    required String systemPrompt,
    required String userPrompt,
    String? imageBase64,
    String? imageMediaType,
    int? maxOutputTokens,
    Map<String, Object?>? responseSchema,
  }) async {
    throw StateError('a promise is not an enforcement');
  }
}
