import 'dart:async';

import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/keto_lens/application/scan_orchestrator.dart';
import 'package:fantastic/features/keto_lens/data/providers.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/camera_controller_session.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/camera_session.dart';
import 'package:fantastic/features/keto_lens/presentation/widgets/scan_result_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Keto Lens tab: a live viewfinder, a crop guide, and a shutter.
///
/// ## The states, in the order they are checked
///
/// M3's most expensive lesson was that a screen which checks its loading
/// state before its error state shows a spinner forever. This screen is
/// almost entirely loading and error states, so the order below is
/// deliberate and the failure tests assert the spinner is **absent**:
///
/// 1. **OCR unavailable** — the browser. Checked first and before the
///    camera is even opened: there is no point asking for a camera
///    permission to run a scanner that cannot run. #85 has no such state.
/// 2. **Camera problem** — refused, refused permanently, none present, or
///    a platform failure. #85 had only "denied", and its
///    `if (cameras.isEmpty) return;` left the screen on a spinner forever
///    on a device with no camera.
/// 3. **Starting** — the spinner.
/// 4. **Ready** — the viewfinder.
///
/// ## No `permission_handler`
///
/// `CameraSession.start()` reports the permission answer as a
/// [CameraProblem], read off the `camera` plugin's own exception codes.
/// `design/m6_preflight.md` §2.2. The cost is `openAppSettings`, so the
/// permanently-denied state names the Settings path in copy instead.
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  /// The headline for a camera problem.
  @visibleForTesting
  static String problemTitle(CameraProblem problem) => switch (problem) {
    CameraProblem.permissionDenied ||
    CameraProblem.permissionDeniedPermanently => 'נדרשת גישה למצלמה',
    CameraProblem.noCamera => 'לא נמצאה מצלמה',
    CameraProblem.failed => 'לא ניתן לפתוח את המצלמה',
  };

  /// What to do about it.
  @visibleForTesting
  static String problemAdvice(CameraProblem problem) => switch (problem) {
    CameraProblem.permissionDenied =>
      'כדי לסרוק תוויות צריך אישור לשימוש במצלמה.',
    CameraProblem.permissionDeniedPermanently =>
      'פתחו הגדרות ← פרטיות ← מצלמה ואפשרו גישה ל-Fantastic.',
    CameraProblem.noCamera => 'אפשר לייבא תמונה של תווית מהגלריה במקום.',
    CameraProblem.failed => 'משהו השתבש בפתיחת המצלמה. נסו שוב.',
  };

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  CameraSession? _session;
  CameraProblem? _problem;
  bool _ocrUnavailable = false;
  bool _starting = true;
  bool _scanning = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    // Not awaited: dispose cannot be async, and the platform tears the
    // camera down regardless. Holding the session in a local first so the
    // field is already null if anything re-enters.
    final session = _session;
    _session = null;
    unawaited(session?.stop());
    super.dispose();
  }

  Future<void> _start() async {
    if (!ref.read(textRecognitionServiceProvider).isAvailable) {
      setState(() {
        _ocrUnavailable = true;
        _starting = false;
      });
      return;
    }

    final session = ref.read(cameraSessionBuilderProvider)();
    try {
      await session.start();
    } on CameraSessionException catch (error) {
      if (mounted) {
        setState(() {
          _problem = error.problem;
          _starting = false;
        });
      }
      return;
    } on Object {
      if (mounted) {
        setState(() {
          _problem = CameraProblem.failed;
          _starting = false;
        });
      }
      return;
    }

    if (!mounted) {
      // Left while the camera was opening. Release it rather than leaking
      // a live camera for the life of the app.
      await session.stop();
      return;
    }
    setState(() {
      _session = session;
      _starting = false;
    });
  }

  Future<void> _retry() async {
    final previous = _session;
    _session = null;
    unawaited(previous?.stop());
    setState(() {
      _problem = null;
      _starting = true;
    });
    await _start();
  }

  @override
  Widget build(BuildContext context) {
    if (_ocrUnavailable) {
      return const _MessageState(
        key: Key('lens_unavailable'),
        icon: Icons.no_photography_outlined,
        title: 'הסורק זמין באפליקציה לאייפון',
        body:
            'זיהוי הטקסט פועל על המכשיר בלבד ואינו נתמך בדפדפן. שאר '
            'האפליקציה עובדת כרגיל.',
      );
    }
    if (_problem != null) {
      return _MessageState(
        key: const Key('lens_camera_problem'),
        icon: Icons.videocam_off_outlined,
        title: CameraScreen.problemTitle(_problem!),
        body: CameraScreen.problemAdvice(_problem!),
        onRetry: _problem == CameraProblem.permissionDeniedPermanently
            ? null
            : _retry,
      );
    }
    if (_starting || _session == null) {
      // Deliberately **not** a CircularProgressIndicator.
      //
      // An indeterminate animation never lets `pumpAndSettle` return, and
      // this screen is a tab: `test/widget_test.dart`'s router tests visit
      // every tab and know nothing about cameras, so a spinner here hangs
      // tests that have no business touching this feature. Opening a
      // camera is sub-second anyway, and a spinner flashing over a black
      // screen for 300 ms is noise rather than feedback.
      return const Scaffold(
        key: Key('lens_starting'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_camera_outlined,
                size: 40,
                color: AppTheme.accent,
              ),
              SizedBox(height: 12),
              Text('פותח מצלמה...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _session!.buildPreview(),
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _CropOverlay())),
          ),
          const Positioned(
            top: 24,
            left: 24,
            right: 24,
            child: Text(
              'מקמו את טבלת הערכים התזונתיים בתוך המסגרת',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              key: const Key('torch_button'),
              tooltip: _torchOn ? 'כבה פנס' : 'הדלק פנס',
              icon: Icon(
                _torchOn ? Icons.flashlight_on : Icons.flashlight_off,
                color: Colors.white,
              ),
              onPressed: _toggleTorch,
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: _scanning
                  ? const SizedBox(
                      key: Key('lens_scanning'),
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(color: AppTheme.accent),
                    )
                  : IconButton(
                      key: const Key('capture_button'),
                      tooltip: 'סרוק תווית',
                      iconSize: 64,
                      icon: const Icon(
                        Icons.camera,
                        color: Colors.white,
                        size: 64,
                      ),
                      onPressed: _capture,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTorch() async {
    final session = _session;
    if (session == null) {
      return;
    }
    final wanted = !_torchOn;
    try {
      await session.setTorch(on: wanted);
    } on Object {
      // A device with no torch, or one that refuses. Not worth an error
      // state; the button simply does not latch.
      return;
    }
    if (mounted) {
      setState(() => _torchOn = wanted);
    }
  }

  Future<void> _capture() async {
    final session = _session;
    if (session == null || _scanning) {
      return;
    }
    setState(() => _scanning = true);

    final String path;
    try {
      path = await session.capturePhoto();
    } on CameraSessionException catch (_) {
      // takePicture throws routinely - a disposed controller, a capture
      // already in flight, no storage. #85's try/finally had no catch, so
      // the exception escaped into the zone: no message, no recovery, and
      // a screen that simply did nothing.
      if (mounted) {
        setState(() => _scanning = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('הצילום נכשל, נסו שוב')));
      }
      return;
    }

    await scanFile(path);
  }

  /// Scans the image at [path] and shows the result.
  ///
  /// The single path from "there is an image on disk" to a result sheet.
  /// #87's gallery import is a second *caller*, not a second copy.
  ///
  /// The busy state is cleared **before** the sheet opens, not after. The
  /// sheet is awaited until the user dismisses it, so clearing afterwards
  /// would leave an indeterminate spinner running underneath a modal for as
  /// long as it is up — invisible to the user, and a `pumpAndSettle` that
  /// never returns for anyone testing this screen.
  @visibleForTesting
  Future<void> scanFile(String path) async {
    if (mounted && !_scanning) {
      setState(() => _scanning = true);
    }

    final result = await ref.read(scanOrchestratorProvider).scan(path);

    if (!mounted) {
      return;
    }
    setState(() => _scanning = false);
    await ScanResultSheet.show(
      context,
      result: result,
      date: DateTime.now(),
      // Retrying from here is just "close the sheet": the viewfinder is
      // still live behind it. The callback exists so the sheet knows a
      // retry is possible at all — on web it is not, and is suppressed.
      onRetry: () {},
    );
  }
}

/// A full-screen icon, headline, explanation and optional retry.
class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: AppTheme.accent),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('lens_retry_button'),
                  onPressed: onRetry,
                  child: const Text('נסו שוב'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Dims everything outside a landscape rectangle in the middle of the
/// frame, and outlines it.
///
/// A nutrition table is wider than it is tall, so the guide is too — a
/// square guide encourages the user to frame the whole pack, which is
/// exactly the shot that produces no macro rows.
class _CropOverlay extends CustomPainter {
  const _CropOverlay();

  /// Fraction of the frame's width the guide spans.
  static const double widthFraction = 0.86;

  /// The guide's aspect ratio, width over height.
  static const double aspectRatio = 1.45;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width * widthFraction;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: width,
      height: width / aspectRatio,
    );
    final rounded = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(rounded),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
    canvas.drawRRect(
      rounded,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppTheme.accent,
    );
  }

  @override
  bool shouldRepaint(_CropOverlay oldDelegate) => false;
}
