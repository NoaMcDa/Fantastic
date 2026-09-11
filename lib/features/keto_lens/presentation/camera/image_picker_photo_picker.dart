import 'package:fantastic/features/keto_lens/presentation/camera/photo_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_picker_photo_picker.g.dart';

/// [PhotoPicker] over `package:image_picker`.
///
/// **The only file in `lib/` that imports `image_picker`** — the same
/// one-adapter-one-plugin shape as `tesseract_plugin_recognizer.dart` and
/// `camera_controller_session.dart`, and what lets `CameraScreen` be tested
/// with no platform at all.
class ImagePickerPhotoPicker implements PhotoPicker {
  ImagePickerPhotoPicker();

  final ImagePicker _picker = ImagePicker();

  @override
  Future<String?> pickFromGallery() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      // Null means the user backed out of the picker. Not an error, and
      // not something to tell them about.
      return file?.path;
    } on Object catch (error) {
      // A refused photo-library permission arrives as a PlatformException.
      throw PhotoPickerException('$error');
    }
  }
}

/// How [CameraScreen] imports a photo.
///
/// Overridden in widget tests with a fake.
@Riverpod(keepAlive: true)
PhotoPicker photoPicker(Ref ref) => ImagePickerPhotoPicker();
