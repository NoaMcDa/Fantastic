import 'package:camera/camera.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/camera_session.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'camera_controller_session.g.dart';

/// [CameraSession] over `package:camera`.
///
/// **The only file in `lib/` that imports `package:camera`.** Same shape as
/// `tesseract_plugin_recognizer.dart`: one adapter, one plugin, and a screen that
/// knows about neither.
///
/// No `permission_handler`. `CameraController.initialize()` already triggers
/// the iOS prompt and reports the answer as a `CameraException` code, so the
/// permission states below are read off that rather than from a second
/// native-only plugin. `design/m6_preflight.md` §2.2.
class CameraControllerSession implements CameraSession {
  CameraControllerSession();

  CameraController? _controller;

  @override
  Future<void> start() async {
    final List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } on CameraException catch (error) {
      throw CameraSessionException(_problemFor(error.code), error.description);
    }

    if (cameras.isEmpty) {
      throw const CameraSessionException(CameraProblem.noCamera);
    }

    // The back camera where there is one: a label is held away from the
    // user, and `cameras.first` is the front camera on some Android
    // hardware. `firstWhere` with an orElse rather than a lookup, because
    // a device with only a front camera should still scan.
    final description = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      description,
      ResolutionPreset.high,
      // Nothing here records sound, and asking for the microphone
      // permission alongside the camera is how a camera permission gets
      // refused.
      enableAudio: false,
    );
    try {
      await controller.initialize();
    } on CameraException catch (error) {
      await controller.dispose();
      throw CameraSessionException(_problemFor(error.code), error.description);
    }
    _controller = controller;
  }

  @override
  Widget buildPreview() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return CameraPreview(controller);
  }

  @override
  Future<void> setTorch({required bool on}) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw const CameraSessionException(CameraProblem.failed, 'not started');
    }
    try {
      await controller.setFlashMode(on ? FlashMode.torch : FlashMode.off);
    } on CameraException catch (error) {
      throw CameraSessionException(CameraProblem.failed, error.description);
    }
  }

  @override
  Future<String> capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw const CameraSessionException(CameraProblem.failed, 'not started');
    }
    try {
      final file = await controller.takePicture();
      return file.path;
    } on CameraException catch (error) {
      throw CameraSessionException(CameraProblem.failed, error.description);
    }
  }

  @override
  Future<void> stop() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  /// Maps the plugin's string codes onto [CameraProblem].
  ///
  /// The codes are the plugin's documented contract (see its README), not
  /// guesses: `CameraAccessDenied`, `CameraAccessDeniedWithoutPrompt` and
  /// `CameraAccessRestricted`.
  static CameraProblem _problemFor(String code) => switch (code) {
    'CameraAccessDenied' => CameraProblem.permissionDenied,
    'CameraAccessDeniedWithoutPrompt' ||
    'CameraAccessRestricted' => CameraProblem.permissionDeniedPermanently,
    _ => CameraProblem.failed,
  };
}

/// Builds a fresh [CameraSession].
///
/// A builder rather than a session: a session owns a live camera, and the
/// screen opens one when it mounts and releases it when it leaves.
typedef CameraSessionBuilder = CameraSession Function();

/// How [CameraScreen] gets a camera.
///
/// Overridden in widget tests with a fake, which is what makes the screen's
/// permission, failure and capture paths testable with no device.
@Riverpod(keepAlive: true)
CameraSessionBuilder cameraSessionBuilder(Ref ref) =>
    CameraControllerSession.new;
