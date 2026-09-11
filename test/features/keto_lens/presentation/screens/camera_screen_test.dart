import 'dart:async';

import 'package:fantastic/features/keto_lens/data/providers.dart';
import 'package:fantastic/features/keto_lens/domain/models/scan_result.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/camera_controller_session.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/camera_session.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/image_picker_photo_picker.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/photo_picker.dart';
import 'package:fantastic/features/keto_lens/presentation/screens/camera_screen.dart';
import 'package:fantastic/features/keto_lens/presentation/widgets/scan_result_sheet.dart';
import 'package:flutter/material.dart';
import 'package:fantastic/core/widgets/skeleton_box.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

/// A camera that is whatever the test needs it to be.
///
/// The whole reason `CameraSession` exists: #85 drove `CameraController`
/// and the top-level `availableCameras()` straight from `initState`, and
/// neither can be replaced in a widget test. **There is no camera in this
/// environment**, so this fake is the only thing that can reach the screen's
/// states at all.
class _FakeSession implements CameraSession {
  // Set after construction rather than passed in: every test needs the
  // fake before it knows which failure it is provoking, and a constructor
  // parameter nobody passes trips `unused_element_parameter`.
  CameraSessionException? startError;
  CameraSessionException? captureError;
  CameraSessionException? torchError;

  String capturePath = '/tmp/label.jpg';

  /// Holds `capturePhoto` open so a test can observe the busy state.
  ///
  /// Without it every fake resolves inside one microtask drain and the
  /// intermediate frame never renders — the state is real, the test just
  /// cannot see it.
  Completer<void>? captureGate;
  bool started = false;
  bool stopped = false;
  int captures = 0;
  bool? torch;

  @override
  Future<void> start() async {
    if (startError != null) {
      throw startError!;
    }
    started = true;
  }

  @override
  Widget buildPreview() =>
      const ColoredBox(key: Key('fake_preview'), color: Colors.black);

  @override
  Future<String> capturePhoto() async {
    captures++;
    await captureGate?.future;
    if (captureError != null) {
      throw captureError!;
    }
    return capturePath;
  }

  @override
  Future<void> setTorch({required bool on}) async {
    if (torchError != null) {
      throw torchError!;
    }
    torch = on;
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }
}

/// OCR that returns whatever the test put in it.
class _FakeRecognizer implements TextRecognitionService {
  _FakeRecognizer({this.isAvailable = true, this.text = ''});

  @override
  final bool isAvailable;
  final String text;

  @override
  Future<String> recognise(String imagePath) async => text;
}

/// A gallery that returns whatever the test put in it.
class _FakePicker implements PhotoPicker {
  String? path;
  PhotoPickerException? error;
  int calls = 0;

  @override
  Future<String?> pickFromGallery() async {
    calls++;
    if (error != null) {
      throw error!;
    }
    return path;
  }
}

void main() {
  late _FakeSession session;
  late _FakePicker picker;

  setUp(() {
    session = _FakeSession();
    picker = _FakePicker();
  });

  List<Override> overrides({bool ocrAvailable = true, String ocrText = ''}) => [
    cameraSessionBuilderProvider.overrideWithValue(() => session),
    photoPickerProvider.overrideWithValue(picker),
    textRecognitionServiceProvider.overrideWithValue(
      _FakeRecognizer(isAvailable: ocrAvailable, text: ocrText),
    ),
  ];

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool ocrAvailable = true,
    String ocrText = '',
  }) async {
    await pumpApp(
      tester,
      const CameraScreen(),
      overrides: overrides(ocrAvailable: ocrAvailable, ocrText: ocrText),
    );
    await tester.pumpAndSettle();
  }

  group('CameraScreen when OCR cannot run here', () {
    testWidgets('explains instead of opening the camera', (tester) async {
      await pumpScreen(tester, ocrAvailable: false);

      expect(find.byKey(const Key('lens_unavailable')), findsOneWidget);
      // Checked before the camera, not after: there is no point asking for
      // a camera permission to run a scanner that cannot run.
      expect(session.started, isFalse);
    });

    testWidgets('shows no spinner', (tester) async {
      // M3's lesson: a terminal state that also draws a spinner is
      // indistinguishable from a hang, and the test passes either way.
      await pumpScreen(tester, ocrAvailable: false);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(SkeletonBox), findsNothing);
    });

    testWidgets('offers no retry', (tester) async {
      await pumpScreen(tester, ocrAvailable: false);

      expect(find.byKey(const Key('lens_retry_button')), findsNothing);
    });
  });

  group('CameraScreen when the camera will not open', () {
    testWidgets('a refused permission is explained and retryable', (
      tester,
    ) async {
      session.startError = const CameraSessionException(
        CameraProblem.permissionDenied,
      );

      await pumpScreen(tester);

      expect(find.byKey(const Key('lens_camera_problem')), findsOneWidget);
      expect(
        find.text(CameraScreen.problemTitle(CameraProblem.permissionDenied)),
        findsOneWidget,
      );
      expect(find.byKey(const Key('lens_retry_button')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(SkeletonBox), findsNothing);
    });

    testWidgets('a permanently refused permission offers no retry', (
      tester,
    ) async {
      // iOS will not prompt twice. A retry button that cannot work is
      // worse than none; the copy names the Settings path instead.
      session.startError = const CameraSessionException(
        CameraProblem.permissionDeniedPermanently,
      );

      await pumpScreen(tester);

      expect(find.byKey(const Key('lens_retry_button')), findsNothing);
      expect(
        find.text(
          CameraScreen.problemAdvice(CameraProblem.permissionDeniedPermanently),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a device with no camera does not spin forever', (
      tester,
    ) async {
      // #85's `if (cameras.isEmpty) return;` left the screen on a spinner
      // with nothing to say and nothing to do.
      session.startError = const CameraSessionException(CameraProblem.noCamera);

      await pumpScreen(tester);

      expect(
        find.text(CameraScreen.problemTitle(CameraProblem.noCamera)),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(SkeletonBox), findsNothing);
    });

    testWidgets('an unexpected failure is still a state, not a crash', (
      tester,
    ) async {
      session.startError = const CameraSessionException(
        CameraProblem.failed,
        'something',
      );

      await pumpScreen(tester);

      expect(find.byKey(const Key('lens_camera_problem')), findsOneWidget);
    });

    testWidgets('every problem has its own title and advice', (tester) async {
      final titles = CameraProblem.values.map(CameraScreen.problemTitle);
      final advice = CameraProblem.values.map(CameraScreen.problemAdvice);

      // The two permission problems deliberately share a headline and
      // differ in the advice, which is the part that matters.
      expect(titles.toSet(), hasLength(CameraProblem.values.length - 1));
      expect(advice.toSet(), hasLength(CameraProblem.values.length));
    });

    testWidgets('retry reopens the camera', (tester) async {
      session.startError = const CameraSessionException(
        CameraProblem.permissionDenied,
      );
      await pumpScreen(tester);

      session.startError = null;
      await tester.tap(find.byKey(const Key('lens_retry_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fake_preview')), findsOneWidget);
      expect(session.started, isTrue);
    });
  });

  group('CameraScreen viewfinder', () {
    testWidgets('shows the preview, the guide copy and the controls', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byKey(const Key('fake_preview')), findsOneWidget);
      expect(find.byKey(const Key('capture_button')), findsOneWidget);
      expect(find.byKey(const Key('torch_button')), findsOneWidget);
      expect(find.textContaining('הערכים התזונתיים'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(SkeletonBox), findsNothing);
    });

    testWidgets('releases the camera when the screen goes away', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      expect(session.stopped, isTrue);
    });

    testWidgets('the torch latches on and off', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('torch_button')));
      await tester.pumpAndSettle();
      expect(session.torch, isTrue);
      expect(find.byIcon(Icons.flashlight_on), findsOneWidget);

      await tester.tap(find.byKey(const Key('torch_button')));
      await tester.pumpAndSettle();
      expect(session.torch, isFalse);
      expect(find.byIcon(Icons.flashlight_off), findsOneWidget);
    });

    testWidgets('a device with no torch simply does not latch', (tester) async {
      session.torchError = const CameraSessionException(CameraProblem.failed);
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('torch_button')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.flashlight_off), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('CameraScreen capture', () {
    testWidgets('a scan of a real label opens the result sheet', (
      tester,
    ) async {
      await pumpScreen(tester, ocrText: HebrewLabelFixture.tahini);

      await tester.tap(find.byKey(const Key('capture_button')));
      await tester.pumpAndSettle();

      expect(session.captures, 1);
      expect(find.byType(ScanResultSheet), findsOneWidget);
      // The real parser and classifier ran: 53.8 g of fat came off the
      // fixture, not out of a stub.
      expect(find.text('53.8 ג'), findsOneWidget);
    });

    testWidgets('an unreadable photo opens a failure sheet, not a verdict', (
      tester,
    ) async {
      await pumpScreen(tester, ocrText: '');

      await tester.tap(find.byKey(const Key('capture_button')));
      await tester.pumpAndSettle();

      expect(
        find.text(ScanResultSheet.failureTitle(ScanFailureReason.noTextFound)),
        findsOneWidget,
      );
    });

    testWidgets('the shutter is replaced by a spinner while scanning', (
      tester,
    ) async {
      final gate = Completer<void>();
      session.captureGate = gate;
      await pumpScreen(tester, ocrText: HebrewLabelFixture.tahini);

      await tester.tap(find.byKey(const Key('capture_button')));
      await tester.pump();

      // Replaced rather than disabled: there is nothing left to tap, so a
      // second scan cannot be started at all.
      expect(find.byKey(const Key('lens_scanning')), findsOneWidget);
      expect(find.byKey(const Key('capture_button')), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ScanResultSheet), findsOneWidget);
    });

    testWidgets('a failed capture reports and recovers', (tester) async {
      // takePicture throws routinely. #85's try/finally had no catch, so
      // the exception escaped into the zone and the screen just sat there.
      session.captureError = const CameraSessionException(
        CameraProblem.failed,
        'busy',
      );
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('capture_button')));
      await tester.pumpAndSettle();

      expect(find.text('הצילום נכשל, נסו שוב'), findsOneWidget);
      expect(find.byKey(const Key('capture_button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('CameraScreen gallery import', () {
    testWidgets('the viewfinder offers a gallery button', (tester) async {
      await pumpScreen(tester);

      expect(find.byKey(const Key('gallery_button')), findsOneWidget);
    });

    testWidgets('an imported photo runs the same pipeline as a capture', (
      tester,
    ) async {
      picker.path = '/tmp/from-gallery.jpg';
      await pumpScreen(tester, ocrText: HebrewLabelFixture.tahini);

      await tester.tap(find.byKey(const Key('gallery_button')));
      await tester.pumpAndSettle();

      expect(picker.calls, 1);
      // The identical sheet a capture produces, from the identical code
      // path - scanFile is shared, not copied.
      expect(find.byType(ScanResultSheet), findsOneWidget);
      expect(find.text('53.8 ג'), findsOneWidget);
      // And the camera was not used for it.
      expect(session.captures, 0);
    });

    testWidgets('backing out of the picker does nothing at all', (
      tester,
    ) async {
      picker.path = null;
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('gallery_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ScanResultSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a refused gallery permission is reported, not thrown', (
      tester,
    ) async {
      picker.error = const PhotoPickerException('denied');
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('gallery_button')));
      await tester.pumpAndSettle();

      expect(find.text('לא ניתן לפתוח את הגלריה'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the gallery button is disabled while a scan is running', (
      tester,
    ) async {
      final gate = Completer<void>();
      session.captureGate = gate;
      await pumpScreen(tester, ocrText: HebrewLabelFixture.tahini);

      await tester.tap(find.byKey(const Key('capture_button')));
      await tester.pump();

      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('gallery_button')))
            .onPressed,
        isNull,
      );

      gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('a camera that will not open still offers the gallery', (
      tester,
    ) async {
      // The real value of the fallback, and what #85's noCamera advice
      // promises the user.
      session.startError = const CameraSessionException(CameraProblem.noCamera);
      picker.path = '/tmp/from-gallery.jpg';
      await pumpScreen(tester, ocrText: HebrewLabelFixture.tahini);

      expect(find.byKey(const Key('gallery_fallback_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('gallery_fallback_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ScanResultSheet), findsOneWidget);
    });

    testWidgets('a browser is offered no gallery either', (tester) async {
      // OCR cannot run on a gallery photo any more than on a live one.
      await pumpScreen(tester, ocrAvailable: false);

      expect(find.byKey(const Key('gallery_fallback_button')), findsNothing);
      expect(find.byKey(const Key('gallery_button')), findsNothing);
    });
  });
}
