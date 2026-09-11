import 'dart:io';

// `show` is required, not tidiness: the analyzer does not resolve the
// conditional export, so it sees `createTextRecognitionService` declared by
// both this library and the factory and reports an ambiguous import. The VM
// resolves them to the same library and the test runs either way — only
// `flutter analyze`, which CI gates on, objects.
import 'package:fantastic/features/keto_lens/data/adapters/tesseract_ffi_recognizer.dart'
    show TesseractFfiRecognizer;
import 'package:fantastic/features/keto_lens/data/adapters/tesseract_plugin_recognizer.dart'
    show TesseractPluginRecognizer;
import 'package:fantastic/features/keto_lens/data/adapters/text_recognizer_factory.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('text_recognizer_factory', () {
    test('resolves to a native half on a platform with dart:io', () {
      // `flutter test` runs on the VM, so `dart.library.io` is true and the
      // conditional export picks tesseract_native_text_recognizer.dart. That
      // file then dispatches on the running OS, which is what this asserts —
      // the pairing, not just that something came back.
      //
      // This is the only assertion in the suite that can observe which half
      // was chosen. The browser half is verified by CI's `flutter build web`
      // step and by driving the built app; see
      // `design/m6_platform_research.md`.
      final service = createTextRecognitionService();

      if (Platform.isAndroid || Platform.isIOS) {
        expect(service, isA<TesseractPluginRecognizer>());
      } else {
        expect(service, isA<TesseractFfiRecognizer>());
      }
    });

    test('exposes only the interface to its callers', () {
      final TextRecognitionService service = createTextRecognitionService();

      expect(service, isA<TextRecognitionService>());
    });
  });
}
