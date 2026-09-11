import 'dart:convert';

import 'package:fantastic/core/constants/menu_verdict_rules.dart';
import 'package:fantastic/core/services/llm/llm_chat_client.dart';
import 'package:fantastic/features/menu/application/menu_page_reader.dart';
import 'package:fantastic/features/menu/application/remote_menu_analyzer.dart';
import 'package:fantastic/features/menu/data/analysis/menu_analysis_prompt.dart';
import 'package:fantastic/features/menu/domain/models/dish_verdict.dart';
import 'package:fantastic/features/menu/domain/models/menu_analysis.dart';
import 'package:fantastic/features/menu/domain/models/menu_analysis_failure_reason.dart';
import 'package:fantastic/features/menu/domain/models/menu_pages_text.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/fixtures.dart';

class _MockClient extends Mock implements LlmChatClient {}

class _MockPageReader extends Mock implements MenuPageReader {}

void _noOpOnPage(int page, int of) {}

void main() {
  late _MockClient client;
  late _MockPageReader pageReader;
  late RemoteMenuAnalyzer analyzer;

  const pastedText = HebrewMenuFixture.grill;

  setUpAll(() {
    // `List<String>` and the `onPage` function type have no built-in
    // mocktail fallback, so `any()`/`captureAny()` against `read`'s
    // parameters needs one registered once, up front.
    registerFallbackValue(<String>[]);
    registerFallbackValue(_noOpOnPage);
  });

  /// A well-formed reply naming a dish real in [HebrewMenuFixture.grill], so
  /// the happy-path tests pass the parser's provenance rule without
  /// special-casing it.
  String reply({
    String name = 'אנטריקוט על הגריל',
    String verdict = 'orderAsIs',
  }) => jsonEncode({
    'dishes': [
      {
        'name': name,
        'verdict': verdict,
        'why': 'בשר ושומן בלבד, ללא רכיבי פחמימה',
      },
    ],
    'unclassified': <String>[],
  });

  setUp(() {
    client = _MockClient();
    pageReader = _MockPageReader();
    analyzer = RemoteMenuAnalyzer(client: client, pageReader: pageReader);
  });

  /// Stubs the transport to answer with [result].
  void answers(ChatResult result) => when(
    () => client.complete(
      systemPrompt: any(named: 'systemPrompt'),
      userPrompt: any(named: 'userPrompt'),
      imageBase64: any(named: 'imageBase64'),
      imageMediaType: any(named: 'imageMediaType'),
      maxOutputTokens: any(named: 'maxOutputTokens'),
      responseSchema: any(named: 'responseSchema'),
    ),
  ).thenAnswer((_) async => result);

  /// Stubs the reader to answer with [pages] for any call.
  void readerAnswers(MenuPagesText pages) =>
      when(() => pageReader.read(any(), onPage: any(named: 'onPage')))
          .thenAnswer((_) async => pages);

  /// The user turn the analyzer sent.
  String sentUserPrompt() =>
      verify(
            () => client.complete(
              systemPrompt: any(named: 'systemPrompt'),
              userPrompt: captureAny(named: 'userPrompt'),
              imageBase64: any(named: 'imageBase64'),
              imageMediaType: any(named: 'imageMediaType'),
              maxOutputTokens: any(named: 'maxOutputTokens'),
              responseSchema: any(named: 'responseSchema'),
            ),
          ).captured.single
          as String;

  void expectNoClientCall() => verifyNever(
    () => client.complete(
      systemPrompt: any(named: 'systemPrompt'),
      userPrompt: any(named: 'userPrompt'),
      imageBase64: any(named: 'imageBase64'),
      imageMediaType: any(named: 'imageMediaType'),
      maxOutputTokens: any(named: 'maxOutputTokens'),
      responseSchema: any(named: 'responseSchema'),
    ),
  );

  void expectNoReaderCall() =>
      verifyNever(() => pageReader.read(any(), onPage: any(named: 'onPage')));

  group('pasted text alone', () {
    test('the reader is never called', () async {
      answers(ChatSucceeded(reply()));

      await analyzer.analyse(text: pastedText);

      expectNoReaderCall();
    });

    test('the client receives the system prompt, the framed text, the token '
        'bound and the schema', () async {
      answers(ChatSucceeded(reply()));

      await analyzer.analyse(text: pastedText);

      verify(
        () => client.complete(
          systemPrompt: MenuAnalysisPrompt.system,
          userPrompt: MenuAnalysisPrompt.user(pastedText),
          imageBase64: null,
          imageMediaType: null,
          maxOutputTokens: MenuVerdictRules.maxOutputTokens,
          responseSchema: MenuAnalysisPrompt.schema,
        ),
      ).called(1);
    });

    test('a fixture reply becomes MenuAnalysed with pageCount 0', () async {
      answers(ChatSucceeded(reply()));

      final result = await analyzer.analyse(text: pastedText) as MenuAnalysed;

      expect(result.dishes.single.name, 'אנטריקוט על הגריל');
      expect(result.dishes.single.verdict, DishVerdict.orderAsIs);
      expect(result.pageCount, 0);
      expect(result.unreadPages, isEmpty);
    });
  });

  group('photographs alone', () {
    const paths = ['p1.jpg', 'p2.jpg'];

    test('the reader is called once with all paths', () async {
      readerAnswers(
        const MenuPagesText(text: 'אנטריקוט על הגריל', pageCount: 2),
      );
      answers(ChatSucceeded(reply()));

      await analyzer.analyse(imagePaths: paths);

      verify(() => pageReader.read(paths, onPage: any(named: 'onPage')))
          .called(1);
    });

    test("the reader's text is what the client receives", () async {
      readerAnswers(
        const MenuPagesText(text: 'אנטריקוט על הגריל', pageCount: 2),
      );
      answers(ChatSucceeded(reply()));

      await analyzer.analyse(imagePaths: paths);

      expect(sentUserPrompt(), contains('אנטריקוט על הגריל'));
    });

    test('pageCount and unreadPages come from the reader', () async {
      readerAnswers(
        const MenuPagesText(
          text: 'אנטריקוט על הגריל',
          pageCount: 2,
          unreadPages: [2],
        ),
      );
      answers(ChatSucceeded(reply()));

      final result = await analyzer.analyse(imagePaths: paths) as MenuAnalysed;

      expect(result.pageCount, 2);
      expect(result.unreadPages, [2]);
    });

    test('onPage reaches the reader', () async {
      void onPage(int page, int of) {}
      readerAnswers(
        const MenuPagesText(text: 'אנטריקוט על הגריל', pageCount: 2),
      );
      answers(ChatSucceeded(reply()));

      await analyzer.analyse(imagePaths: paths, onPage: onPage);

      verify(() => pageReader.read(paths, onPage: onPage)).called(1);
    });
  });

  group('text and photographs together', () {
    test('both appear in the user turn, pasted text first', () async {
      readerAnswers(const MenuPagesText(text: 'המבורגר בית', pageCount: 1));
      answers(ChatSucceeded(reply()));

      await analyzer.analyse(text: pastedText, imagePaths: ['p1.jpg']);

      final sent = sentUserPrompt();
      expect(sent, contains(pastedText));
      expect(sent, contains('המבורגר בית'));
      expect(sent.indexOf(pastedText), lessThan(sent.indexOf('המבורגר בית')));
    });
  });

  group('empty input', () {
    for (final blank in <String?>[null, '', '   ', '\n\t ']) {
      test('${jsonEncode(blank)} with no photos is emptyInput, before any '
          'reader or client call', () async {
        final result = await analyzer.analyse(text: blank);

        expect(
          result,
          const MenuAnalysisFailed(
            reason: MenuAnalysisFailureReason.emptyInput,
          ),
        );
        expectNoReaderCall();
        expectNoClientCall();
      });
    }
  });

  group('a reader that reports ocrUnavailable', () {
    setUp(
      () => readerAnswers(
        const MenuPagesText(text: '', pageCount: 1, ocrUnavailable: true),
      ),
    );

    test('with pasted text, the pasted text is still analysed', () async {
      answers(ChatSucceeded(reply()));

      final result = await analyzer.analyse(
        text: pastedText,
        imagePaths: ['p1.jpg'],
      ) as MenuAnalysed;

      expect(result.dishes, isNotEmpty);
      expect(sentUserPrompt(), contains(pastedText));
    });

    test('with no pasted text, is ocrUnavailable, no client call', () async {
      final result = await analyzer.analyse(imagePaths: ['p1.jpg']);

      expect(
        result,
        const MenuAnalysisFailed(
          reason: MenuAnalysisFailureReason.ocrUnavailable,
        ),
      );
      expectNoClientCall();
    });
  });

  group('a reader that reads nothing', () {
    setUp(
      () => readerAnswers(
        const MenuPagesText(text: '', pageCount: 1, unreadPages: [1]),
      ),
    );

    test('with no pasted text, is noTextFound, no client call', () async {
      final result = await analyzer.analyse(imagePaths: ['p1.jpg']);

      expect(
        result,
        const MenuAnalysisFailed(reason: MenuAnalysisFailureReason.noTextFound),
      );
      expectNoClientCall();
    });

    test('with pasted text, the pasted text is still analysed', () async {
      answers(ChatSucceeded(reply()));

      final result = await analyzer.analyse(
        text: pastedText,
        imagePaths: ['p1.jpg'],
      ) as MenuAnalysed;

      expect(result.dishes, isNotEmpty);
    });
  });

  group('the client never receives an image part', () {
    /// The image part the analyzer attached, or null when it sent none.
    String? sentImage() =>
        verify(
              () => client.complete(
                systemPrompt: any(named: 'systemPrompt'),
                userPrompt: any(named: 'userPrompt'),
                imageBase64: captureAny(named: 'imageBase64'),
                imageMediaType: any(named: 'imageMediaType'),
                maxOutputTokens: any(named: 'maxOutputTokens'),
                responseSchema: any(named: 'responseSchema'),
              ),
            ).captured.single
            as String?;

    test('for pasted text', () async {
      answers(ChatSucceeded(reply()));
      await analyzer.analyse(text: pastedText);
      expect(sentImage(), isNull);
    });

    test('for photographs', () async {
      readerAnswers(
        const MenuPagesText(text: 'אנטריקוט על הגריל', pageCount: 1),
      );
      answers(ChatSucceeded(reply()));
      await analyzer.analyse(imagePaths: ['p1.jpg']);
      expect(sentImage(), isNull);
    });

    test('for text and photographs together', () async {
      readerAnswers(
        const MenuPagesText(text: 'אנטריקוט על הגריל', pageCount: 1),
      );
      answers(ChatSucceeded(reply()));
      await analyzer.analyse(text: pastedText, imagePaths: ['p1.jpg']);
      expect(sentImage(), isNull);
    });
  });

  test('one complete call per analyse, even with multiple pages', () async {
    readerAnswers(const MenuPagesText(text: 'אנטריקוט על הגריל', pageCount: 3));
    answers(ChatSucceeded(reply()));

    await analyzer.analyse(imagePaths: ['p1.jpg', 'p2.jpg', 'p3.jpg']);

    verify(
      () => client.complete(
        systemPrompt: any(named: 'systemPrompt'),
        userPrompt: any(named: 'userPrompt'),
        imageBase64: any(named: 'imageBase64'),
        imageMediaType: any(named: 'imageMediaType'),
        maxOutputTokens: any(named: 'maxOutputTokens'),
        responseSchema: any(named: 'responseSchema'),
      ),
    ).called(1);
    verify(() => pageReader.read(any(), onPage: any(named: 'onPage')))
        .called(1);
  });

  group('transport failures map one to one', () {
    const mapping = {
      ChatFailureReason.offline: MenuAnalysisFailureReason.offline,
      // From the user's seat a request that never came back and one that
      // could not leave are the same event.
      ChatFailureReason.timeout: MenuAnalysisFailureReason.offline,
      // No key and a rejected key are one instruction: go to Profile.
      ChatFailureReason.unauthorised: MenuAnalysisFailureReason.notConfigured,
      ChatFailureReason.rateLimited: MenuAnalysisFailureReason.rateLimited,
      ChatFailureReason.badResponse: MenuAnalysisFailureReason.badResponse,
    };

    // Every transport reason is covered, so adding one fails here rather
    // than silently falling into a default.
    test('every ChatFailureReason has a mapping', () {
      expect(mapping.keys.toSet(), ChatFailureReason.values.toSet());
    });

    for (final entry in mapping.entries) {
      test('${entry.key.name} becomes ${entry.value.name}', () async {
        answers(ChatFailed(entry.key));

        expect(
          await analyzer.analyse(text: pastedText),
          MenuAnalysisFailed(reason: entry.value),
        );
      });
    }
  });

  group('the never-throws contract', () {
    // `LlmChatClient` promises never to throw. This is here because a
    // promise is not an enforcement: an implementation that breaks it must
    // not be able to take the screen down with it.
    test('a client that throws is reported, not propagated', () async {
      when(
        () => client.complete(
          systemPrompt: any(named: 'systemPrompt'),
          userPrompt: any(named: 'userPrompt'),
          imageBase64: any(named: 'imageBase64'),
          imageMediaType: any(named: 'imageMediaType'),
          maxOutputTokens: any(named: 'maxOutputTokens'),
          responseSchema: any(named: 'responseSchema'),
        ),
      ).thenThrow(StateError('contract violated'));

      expect(
        await analyzer.analyse(text: pastedText),
        const MenuAnalysisFailed(reason: MenuAnalysisFailureReason.badResponse),
      );
    });

    // `MenuPageReader.read` promises never to throw either — same reasoning,
    // and this is the one place a violation of that promise is exercised at
    // all, since `MenuPageReader`'s own suite mocks its recognizer, never
    // itself.
    test('a reader that throws is reported, not propagated', () async {
      when(() => pageReader.read(any(), onPage: any(named: 'onPage')))
          .thenThrow(StateError('contract violated'));

      expect(
        await analyzer.analyse(imagePaths: ['p1.jpg']),
        const MenuAnalysisFailed(reason: MenuAnalysisFailureReason.badResponse),
      );
    });

    test('a client that returns malformed content is badResponse', () async {
      answers(const ChatSucceeded('not json'));

      expect(
        await analyzer.analyse(text: pastedText),
        const MenuAnalysisFailed(reason: MenuAnalysisFailureReason.badResponse),
      );
    });

    test(
      'analyse never throws for any input or collaborator behaviour',
      () async {
        when(() => pageReader.read(any(), onPage: any(named: 'onPage')))
            .thenThrow(const FormatException('bad bytes'));

        await expectLater(analyzer.analyse(imagePaths: ['p1.jpg']), completes);
      },
    );
  });
}
