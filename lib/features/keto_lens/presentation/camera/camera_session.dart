import 'package:flutter/widgets.dart';

/// One live camera, behind an interface.
///
/// ## Why this exists
///
/// #85 drives `CameraController` and the top-level `availableCameras()`
/// directly from the screen's `initState`. Neither can be replaced in a
/// widget test — `availableCameras()` is a bare function over a method
/// channel — so the issue's four widget tests would have had to mock the
/// platform channel and hope, or not run at all.
///
/// Behind this interface the screen has no camera dependency whatsoever: a
/// test supplies a fake session and drives every state the screen can reach,
/// including the ones a device would be needed to provoke. That matters more
/// than usual here, because **there is no camera in this environment** and a
/// widget test is the only thing that can see this screen at all.
///
/// It also keeps `package:camera` in one file, the same way
/// `tesseract_plugin_recognizer.dart` keeps the OCR binding in one file.
abstract interface class CameraSession {
  /// Opens the camera and makes [buildPreview] valid.
  ///
  /// Throws [CameraSessionException] when the camera cannot be opened —
  /// permission refused, no camera present, or a platform failure. On iOS
  /// this is the call that shows the permission prompt.
  Future<void> start();

  /// The live viewfinder.
  ///
  /// Only valid between a successful [start] and [stop].
  Widget buildPreview();

  /// Turns the torch on or off.
  ///
  /// Epic #10 lists a torch toggle in scope and no child issue specifies
  /// one. It earns its place: an Israeli supermarket's chiller aisle is
  /// dim, the nutrition table is printed small in low contrast, and OCR
  /// accuracy falls off a cliff in that light.
  ///
  /// Throws [CameraSessionException] on a device with no torch. The screen
  /// swallows that and simply does not latch the button.
  Future<void> setTorch({required bool on});

  /// Takes a photo and returns its path on disk.
  ///
  /// Throws [CameraSessionException] if the capture fails — a disposed
  /// controller, a capture already in flight, no storage.
  Future<String> capturePhoto();

  /// Releases the camera. Safe to call more than once.
  Future<void> stop();
}

/// Why a camera session could not be opened or used.
class CameraSessionException implements Exception {
  const CameraSessionException(this.problem, [this.detail]);

  final CameraProblem problem;

  /// The platform's own message, for a log or a bug report.
  final String? detail;

  @override
  String toString() =>
      'CameraSessionException(${problem.name}${detail == null ? '' : ': $detail'})';
}

/// The distinguishable camera failures.
///
/// Separate values because the screen says something different for each, and
/// only one of them is worth a retry button.
enum CameraProblem {
  /// The user refused, and can be asked again.
  permissionDenied,

  /// The user refused before. iOS will not prompt a second time; the only
  /// route is Settings.
  permissionDeniedPermanently,

  /// The device reports no camera at all. #85's `if (cameras.isEmpty)
  /// return;` left the screen on a spinner forever in this case.
  noCamera,

  /// Anything else the platform threw.
  failed,
}
