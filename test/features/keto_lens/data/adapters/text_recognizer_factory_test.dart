// `show` is required, not tidiness: the analyzer does not resolve the
// conditional export, so it sees `createTextRecognitionService` declared by
// both this library and the factory and reports an ambiguous import. The VM
// resolves them to the same library and the test runs either way — only
// `flutter analyze`, which CI gates on, objects.
import 'package:fantastic/features/keto_lens/data/adapters/ml_kit_text_recognizer.dart'
    show MlKitTextRecognizer;
import 'package:fantastic/features/keto_lens/data/adapters/text_recognizer_factory.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('text_recognizer_factory', () {
    test('resolves to the ML Kit half on a platform with dart:io', () {
      // `flutter test` runs on the VM, so `dart.library.io` is true and the
      // conditional export picks ml_kit_text_recognizer.dart. This is the
      // only assertion in the suite that can observe which half was chosen;
      // the web half is verified by CI's `flutter build web` step, which is
      // what proves nothing native reached the browser bundle.
      final service = createTextRecognitionService();

      expect(service, isA<MlKitTextRecognizer>());
      expect(service.isAvailable, isTrue);
    });

    test('exposes only the interface to its callers', () {
      final TextRecognitionService service = createTextRecognitionService();

      expect(service, isA<TextRecognitionService>());
    });
  });
}
