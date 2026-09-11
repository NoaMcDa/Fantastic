/// Picks an existing photo off the device.
///
/// The gallery fallback for a label already photographed, or for a device
/// whose camera cannot be opened. Behind an interface for the same reason
/// `CameraSession` is: `ImagePicker` cannot be replaced in a widget test,
/// and there is no gallery in this environment.
abstract interface class PhotoPicker {
  /// Returns the chosen image's path, or null if the user backed out.
  ///
  /// Throws [PhotoPickerException] when the picker itself fails — most
  /// often a refused photo-library permission.
  Future<String?> pickFromGallery();
}

/// Thrown when the picker could not run.
class PhotoPickerException implements Exception {
  const PhotoPickerException(this.detail);

  /// The platform's own message, for a log or a bug report.
  final String detail;

  @override
  String toString() => 'PhotoPickerException: $detail';
}
