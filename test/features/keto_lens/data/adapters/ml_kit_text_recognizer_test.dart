import 'package:fantastic/features/keto_lens/data/adapters/ml_kit_text_recognizer.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The channel `TextRecognizer` talks over, read off the plugin source.
const MethodChannel _channel = MethodChannel('google_mlkit_text_recognizer');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const recognizer = MlKitTextRecognizer();
  late List<MethodCall> calls;

  /// Stands in for the native side.
  ///
  /// #80 claimed this adapter "cannot be unit-tested without a real image
  /// and device". The ML Kit plugin is a `MethodChannel` and a JSON codec,
  /// and `InputImage.fromFilePath` never touches the filesystem, so the
  /// whole Dart half is testable on the VM. What genuinely cannot be tested
  /// here is whether ML Kit recognises Hebrew on a real label — which is a
  /// different claim, and is recorded as unverified in the handoff.
  void mockNative(Future<Object?>? Function(MethodCall) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) {
          calls.add(call);
          return handler(call);
        });
  }

  setUp(() => calls = <MethodCall>[]);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('MlKitTextRecognizer', () {
    test('reports itself available', () {
      expect(recognizer.isAvailable, isTrue);
    });

    test('returns the recognised text', () async {
      const hebrew = 'שומנים 12';
      mockNative((call) async {
        if (call.method == 'vision#startTextRecognizer') {
          return <String, Object?>{'text': hebrew, 'blocks': <Object?>[]};
        }
        return null;
      });

      expect(await recognizer.recognise('/tmp/label.jpg'), hebrew);
    });

    test('passes the file path through as a file-type image', () async {
      mockNative((call) async {
        if (call.method == 'vision#startTextRecognizer') {
          return <String, Object?>{'text': '', 'blocks': <Object?>[]};
        }
        return null;
      });

      await recognizer.recognise('/tmp/label.jpg');

      final start = calls.firstWhere(
        (c) => c.method == 'vision#startTextRecognizer',
      );
      final image =
          (start.arguments as Map<Object?, Object?>)['imageData']!
              as Map<Object?, Object?>;

      expect(image['path'], '/tmp/label.jpg');
      expect(image['type'], 'file');
      // fromFile would have needed a dart:io File; fromFilePath does not,
      // which is what keeps this file's only native import ML Kit itself.
      expect(image['bytes'], isNull);
    });

    test('asks for the Latin script recogniser', () async {
      // There is no Hebrew model. Hebrew rides on the Latin recogniser and
      // HebrewLabelParser does the script-aware work afterwards.
      mockNative((call) async {
        if (call.method == 'vision#startTextRecognizer') {
          return <String, Object?>{'text': '', 'blocks': <Object?>[]};
        }
        return null;
      });

      await recognizer.recognise('/tmp/label.jpg');

      final start = calls.firstWhere(
        (c) => c.method == 'vision#startTextRecognizer',
      );

      expect((start.arguments as Map<Object?, Object?>)['script'], 0);
    });

    test('an image with no text yields an empty string, not null', () async {
      mockNative((call) async {
        if (call.method == 'vision#startTextRecognizer') {
          return <String, Object?>{'text': '', 'blocks': <Object?>[]};
        }
        return null;
      });

      expect(await recognizer.recognise('/tmp/blank.jpg'), isEmpty);
    });

    test('closes the native recogniser after a successful scan', () async {
      mockNative((call) async {
        if (call.method == 'vision#startTextRecognizer') {
          return <String, Object?>{'text': 'x', 'blocks': <Object?>[]};
        }
        return null;
      });

      await recognizer.recognise('/tmp/label.jpg');

      expect(calls.map((c) => c.method), [
        'vision#startTextRecognizer',
        'vision#closeTextRecognizer',
      ]);
    });

    test('closes the native recogniser even when recognition throws', () async {
      // The whole reason close() is in a finally: the platform side holds a
      // model in memory, and a leaked one survives the scan.
      mockNative((call) async {
        if (call.method == 'vision#startTextRecognizer') {
          throw PlatformException(code: 'error', message: 'boom');
        }
        return null;
      });

      await expectLater(
        recognizer.recognise('/tmp/label.jpg'),
        throwsA(isA<PlatformException>()),
      );
      expect(
        calls.map((c) => c.method),
        contains('vision#closeTextRecognizer'),
      );
    });

    test('lets a platform failure propagate rather than swallowing it', () {
      // ScanOrchestrator decides what a failed scan looks like. It cannot
      // if the failure was already turned into an empty string here.
      mockNative((call) async {
        if (call.method == 'vision#startTextRecognizer') {
          throw PlatformException(code: 'MLKitError');
        }
        return null;
      });

      expect(
        recognizer.recognise('/tmp/label.jpg'),
        throwsA(isA<PlatformException>()),
      );
    });

    test('is a TextRecognitionService', () {
      expect(recognizer, isA<TextRecognitionService>());
    });
  });
}
