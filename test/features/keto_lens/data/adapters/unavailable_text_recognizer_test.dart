import 'package:fantastic/features/keto_lens/data/adapters/unavailable_text_recognizer.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const recognizer = UnavailableTextRecognizer();

  group('UnavailableTextRecognizer', () {
    test('reports itself unavailable', () {
      expect(recognizer.isAvailable, isFalse);
    });

    test('throws rather than returning an empty string', () async {
      // An empty string is what a blank photo returns. Rendering "we read
      // the label and found nothing" in a browser, where no label can ever
      // be read, is the wrong thing to tell the user.
      await expectLater(
        recognizer.recognise('/tmp/label.jpg'),
        throwsA(isA<TextRecognitionUnavailableException>()),
      );
    });

    test('the exception carries a reason worth putting in a bug report', () {
      const exception = TextRecognitionUnavailableException(
        UnavailableTextRecognizer.reason,
      );

      expect(exception.reason, isNotEmpty);
      expect('$exception', contains('native-only'));
    });

    test('is a TextRecognitionService', () {
      expect(recognizer, isA<TextRecognitionService>());
    });

    test('the factory builds one', () {
      // Imported directly rather than through text_recognizer_factory.dart:
      // on the VM that conditional export resolves to the ML Kit half, so
      // this half can only be reached by naming its file.
      final service = createTextRecognitionService();

      expect(service, isA<UnavailableTextRecognizer>());
      expect(service.isAvailable, isFalse);
    });
  });
}
