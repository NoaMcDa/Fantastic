import 'package:fantastic/features/keto_lens/presentation/camera/image_picker_photo_picker.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/photo_picker.dart';
import 'package:flutter_test/flutter_test.dart';

/// [ImagePickerPhotoPicker.capped] is the one piece of real logic
/// `pickMultiple` carries: `image_picker`'s own `limit` argument to
/// `pickMultiImage` is not honoured on every platform, so the cap is
/// enforced here in Dart. `ImagePicker` itself cannot be substituted in a
/// unit test, so this is tested directly through the `@visibleForTesting`
/// seam rather than through `ImagePickerPhotoPicker.pickMultiple` itself.
void main() {
  group('ImagePickerPhotoPicker.capped', () {
    test('caps at limit', () {
      final paths = List.generate(10, (i) => 'path$i');

      expect(ImagePickerPhotoPicker.capped(paths, 8), paths.take(8).toList());
    });

    test('returns every path when under the limit', () {
      final paths = ['a', 'b', 'c'];

      expect(ImagePickerPhotoPicker.capped(paths, 8), paths);
    });

    test('an empty pick returns []', () {
      expect(ImagePickerPhotoPicker.capped(const [], 8), <String>[]);
    });

    test('limit of 1 returns at most one path', () {
      final paths = ['a', 'b', 'c'];

      expect(ImagePickerPhotoPicker.capped(paths, 1), ['a']);
    });
  });

  group('ImagePickerPhotoPicker.pickMultiple', () {
    test('a platform failure is a PhotoPickerException', () async {
      // There is no image_picker platform implementation registered in this
      // test environment — the same reason `CameraSession` and `PhotoPicker`
      // are interfaces at all. The plugin call this provokes therefore
      // fails the same way a real platform failure would, and this asserts
      // it surfaces through the same `on Object catch` shape
      // `pickFromGallery` already uses, message intact.
      final picker = ImagePickerPhotoPicker();

      await expectLater(
        picker.pickMultiple(limit: 5),
        throwsA(isA<PhotoPickerException>()),
      );
    });
  });
}
