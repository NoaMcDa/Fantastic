import 'package:fantastic/core/constants/menu_verdict_rules.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';
import 'package:fantastic/features/menu/application/menu_page_reader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRecognizer extends Mock implements TextRecognitionService {}

void main() {
  late _MockRecognizer recognizer;
  late MenuPageReader reader;

  setUp(() {
    recognizer = _MockRecognizer();
    reader = MenuPageReader(recognizer: recognizer);
    when(() => recognizer.isAvailable).thenReturn(true);
  });

  group('MenuPageReader happy path', () {
    test(
      'three readable pages produce text with three markers in order',
      () async {
        when(() => recognizer.recognise('p1.jpg'))
            .thenAnswer((_) async => 'עוגת שוקולד');
        when(() => recognizer.recognise('p2.jpg'))
            .thenAnswer((_) async => 'סלט יווני');
        when(() => recognizer.recognise('p3.jpg'))
            .thenAnswer((_) async => 'פסטה ברוטב שמנת');

        final result = await reader.read(['p1.jpg', 'p2.jpg', 'p3.jpg']);

        expect(result.pageCount, 3);
        expect(result.unreadPages, isEmpty);
        expect(result.ocrUnavailable, isFalse);
        final marker1 = result.text.indexOf(MenuPageReader.pageMarker(1));
        final marker2 = result.text.indexOf(MenuPageReader.pageMarker(2));
        final marker3 = result.text.indexOf(MenuPageReader.pageMarker(3));
        expect(marker1, greaterThanOrEqualTo(0));
        expect(marker2, greaterThan(marker1));
        expect(marker3, greaterThan(marker2));
        expect(result.text, contains('עוגת שוקולד'));
        expect(result.text, contains('סלט יווני'));
        expect(result.text, contains('פסטה ברוטב שמנת'));
      },
    );

    test('onPage is called (1,3), (2,3), (3,3) in order, before '
        'each recognise', () async {
      final calls = <List<int>>[];
      when(() => recognizer.recognise(any())).thenAnswer((_) async => 'טקסט');

      await reader.read([
        'p1.jpg',
        'p2.jpg',
        'p3.jpg',
      ], onPage: (page, of) => calls.add([page, of]));

      expect(calls, [
        [1, 3],
        [2, 3],
        [3, 3],
      ]);
    });

    test('onPage fires before recognise is called for that page', () async {
      final order = <String>[];
      when(() => recognizer.recognise('p1.jpg')).thenAnswer((_) async {
        order.add('recognise');
        return 'טקסט';
      });

      await reader.read(['p1.jpg'], onPage: (page, of) => order.add('onPage'));

      expect(order, ['onPage', 'recognise']);
    });

    test('pageCount equals the number of paths given', () async {
      when(() => recognizer.recognise(any())).thenAnswer((_) async => 'טקסט');

      final result = await reader.read(['p1.jpg', 'p2.jpg']);

      expect(result.pageCount, 2);
    });
  });

  group('MenuPageReader edge cases', () {
    test('a page that reads whitespace only is listed in unreadPages and '
        'contributes no marker', () async {
      when(() => recognizer.recognise('p1.jpg'))
          .thenAnswer((_) async => '   \n  ');
      when(() => recognizer.recognise('p2.jpg'))
          .thenAnswer((_) async => 'סלט יווני');

      final result = await reader.read(['p1.jpg', 'p2.jpg']);

      expect(result.unreadPages, [1]);
      expect(result.text, isNot(contains(MenuPageReader.pageMarker(1))));
      expect(result.text, contains('סלט יווני'));
    });

    test('every page unreadable -> readNothing true, unreadPages = all, '
        'ocrUnavailable false', () async {
      when(() => recognizer.recognise(any())).thenAnswer((_) async => '');

      final result = await reader.read(['p1.jpg', 'p2.jpg']);

      expect(result.readNothing, isTrue);
      expect(result.unreadPages, [1, 2]);
      expect(result.ocrUnavailable, isFalse);
    });

    test('an empty path list returns pageCount: 0 and never touches the '
        'recogniser', () async {
      final result = await reader.read(const []);

      expect(result.pageCount, 0);
      expect(result.text, '');
      expect(result.unreadPages, isEmpty);
      verifyNever(() => recognizer.isAvailable);
      verifyNever(() => recognizer.recognise(any()));
    });

    test(
      'more than maxPages paths: only the first maxPages are recognised',
      (() async {
        final paths = List.generate(
          MenuVerdictRules.maxPages + 2,
          (i) => 'p${i + 1}.jpg',
        );
        when(() => recognizer.recognise(any())).thenAnswer((_) async => 'טקסט');

        final result = await reader.read(paths);

        verify(() => recognizer.recognise(any()))
            .called(MenuVerdictRules.maxPages);
        expect(
          result.text,
          isNot(
            contains(MenuPageReader.pageMarker(MenuVerdictRules.maxPages + 1)),
          ),
        );
        // The truncated pages are silently dropped, never reported unread.
        expect(result.unreadPages, isEmpty);
      }),
    );
  });

  group('MenuPageReader failure handling', () {
    test(
      'isAvailable == false -> ocrUnavailable true, recognise never called',
      () async {
        when(() => recognizer.isAvailable).thenReturn(false);

        final result = await reader.read(['p1.jpg', 'p2.jpg']);

        expect(result.ocrUnavailable, isTrue);
        expect(result.pageCount, 2);
        expect(result.unreadPages, [1, 2]);
        expect(result.text, '');
        verifyNever(() => recognizer.recognise(any()));
      },
    );

    test('a page whose recognise throws an Exception is listed as unread and '
        'the next page is still read', () async {
      when(() => recognizer.recognise('p1.jpg')).thenThrow(Exception('boom'));
      when(() => recognizer.recognise('p2.jpg'))
          .thenAnswer((_) async => 'סלט יווני');

      final result = await reader.read(['p1.jpg', 'p2.jpg']);

      expect(result.unreadPages, [1]);
      expect(result.text, contains('סלט יווני'));
    });

    test('a page whose recognise throws an Error (not Exception) is handled '
        'the same - the on Object rule', () async {
      when(() => recognizer.recognise('p1.jpg')).thenThrow(StateError('bad'));
      when(() => recognizer.recognise('p2.jpg'))
          .thenAnswer((_) async => 'סלט יווני');

      final result = await reader.read(['p1.jpg', 'p2.jpg']);

      expect(result.unreadPages, [1]);
      expect(result.text, contains('סלט יווני'));
    });

    test('read never throws', () async {
      when(() => recognizer.recognise(any()))
          .thenThrow(StateError('always fails'));

      await expectLater(reader.read(['p1.jpg']), completes);
    });
  });
}
