import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'meal_photo_source.g.dart';

/// Where a meal photograph comes from.
///
/// ## Why this is not `PhotoPicker` or `CameraSession`
///
/// Keto Lens has both, and neither fits. `CameraSession` exists to drive a
/// **live viewfinder** with a crop guide and a torch, because a nutrition
/// panel is small, low-contrast print in a dim chiller aisle and framing it
/// is the whole job; a bottom sheet is the wrong host for that screen.
/// `PhotoPicker` is gallery-only, and #324's Definition of Done forbids
/// modifying anything under `lib/features/keto_lens/` — the label path has to
/// keep exactly the behaviour and wording #257 left it with.
///
/// So the diary gets its own seam over the same already-present
/// `image_picker`: the platform's own capture UI, no new plugin, no
/// `permission_handler`, and nothing in the lens touched. A refused
/// permission arrives from the plugin as a `PlatformException` and leaves
/// here as [MealPhotoSourceException], the way `PhotoPicker` already handles
/// the gallery case.
abstract interface class MealPhotoSource {
  /// Whether this platform can take a photograph at all.
  ///
  /// Checked so the camera option can be **absent** rather than present and
  /// failing. `image_picker` implements `ImageSource.camera` on Android, iOS
  /// and the browser; the three desktops have no implementation and throw.
  bool get canTakePhoto;

  /// Opens the camera. Returns the path, or null if the user backed out.
  Future<String?> takePhoto();

  /// Opens the gallery. Returns the path, or null if the user backed out.
  Future<String?> pickFromGallery();
}

/// Thrown when the picker itself failed — most often a refused permission.
class MealPhotoSourceException implements Exception {
  const MealPhotoSourceException(this.detail);

  /// The platform's own message, for a log or a bug report. **Not** shown to
  /// the user: it is English, written for a developer, and this is a
  /// Hebrew-first UI.
  final String detail;

  @override
  String toString() => 'MealPhotoSourceException: $detail';
}

/// [MealPhotoSource] over `image_picker`.
class ImagePickerMealPhotoSource implements MealPhotoSource {
  ImagePickerMealPhotoSource();

  final ImagePicker _picker = ImagePicker();

  /// `defaultTargetPlatform`, never `dart:io` — `Platform` does not compile
  /// for the browser and this file ships in the web bundle. The same rule
  /// `CameraScreen.unavailableAdvice` follows.
  @override
  bool get canTakePhoto =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<String?> takePhoto() => _pick(ImageSource.camera);

  @override
  Future<String?> pickFromGallery() => _pick(ImageSource.gallery);

  Future<String?> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source);
      // Null means the user backed out. Not an error, and not something to
      // tell them about.
      return file?.path;
    } on Object catch (error) {
      throw MealPhotoSourceException('$error');
    }
  }
}

/// The composition root for the diary's photo capture.
///
/// `keepAlive` because `ImagePicker` is cheap to hold and rebuilding it per
/// sheet buys nothing — the same choice `photoPickerProvider` makes.
/// Overridden in widget tests with a fake: there is no camera and no gallery
/// in this environment.
@Riverpod(keepAlive: true)
MealPhotoSource mealPhotoSource(Ref ref) => ImagePickerMealPhotoSource();
