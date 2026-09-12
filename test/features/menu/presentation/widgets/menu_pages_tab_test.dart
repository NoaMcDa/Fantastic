import 'dart:async';

import 'package:fantastic/core/constants/menu_copy.dart';
import 'package:fantastic/core/constants/menu_verdict_rules.dart';
import 'package:fantastic/features/keto_lens/data/providers.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/camera_controller_session.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/camera_session.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/image_picker_photo_picker.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/photo_picker.dart';
import 'package:fantastic/features/keto_lens/presentation/screens/camera_screen.dart';
import 'package:fantastic/features/menu/presentation/widgets/menu_pages_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../helpers/pump_app.dart';

/// A camera that is whatever the test needs it to be.
///
/// The same hand-rolled shape `camera_screen_test.dart` uses — there is no
/// camera in this environment, so this fake is the only thing that can
/// drive [MenuPagesTab] through every state a device would be needed for.
class _FakeSession implements CameraSession {
  CameraSessionException? startError;
  CameraSessionException? captureError;
  CameraSessionException? torchError;

  /// Holds `start` open so a test can observe the starting state before it
  /// resolves — the same technique `camera_screen_test.dart`'s
  /// `captureGate` uses, for the same reason: a fake that resolves inside
  /// one microtask drain never renders the intermediate frame.
  Completer<void>? startGate;

  bool started = false;
  bool stopped = false;
  bool? torch;
  final List<String> captures = [];

  @override
  Future<void> start() async {
    await startGate?.future;
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
    if (captureError != null) {
      throw captureError!;
    }
    final path = '/tmp/menu-page-${captures.length + 1}.jpg';
    captures.add(path);
    return path;
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

/// OCR whose availability the test controls. Never actually asked to
/// recognise anything — [MenuPagesTab] only reads [isAvailable].
class _FakeRecognizer implements TextRecognitionService {
  _FakeRecognizer({this.isAvailable = true});

  @override
  final bool isAvailable;

  @override
  Future<String> recognise(String imagePath) async => '';
}

/// A gallery that returns whatever the test put in it.
class _FakePicker implements PhotoPicker {
  List<String> multiplePaths = const [];
  PhotoPickerException? error;
  int? lastLimit;

  @override
  Future<String?> pickFromGallery() async => null;

  @override
  Future<List<String>> pickMultiple({required int limit}) async {
    lastLimit = limit;
    if (error != null) {
      throw error!;
    }
    return multiplePaths;
  }
}

void main() {
  late _FakeSession session;
  late _FakePicker picker;
  late List<String>? analysed;
  late bool switchedToTextMode;

  setUp(() {
    session = _FakeSession();
    picker = _FakePicker();
    analysed = null;
    switchedToTextMode = false;
  });

  List<Override> overrides({bool ocrAvailable = true}) => [
    cameraSessionBuilderProvider.overrideWithValue(() => session),
    photoPickerProvider.overrideWithValue(picker),
    textRecognitionServiceProvider.overrideWithValue(
      _FakeRecognizer(isAvailable: ocrAvailable),
    ),
  ];

  Future<void> pumpTab(
    WidgetTester tester, {
    bool ocrAvailable = true,
    bool analysing = false,
  }) async {
    await pumpApp(
      tester,
      MenuPagesTab(
        onAnalyse: (paths) => analysed = paths,
        onSwitchToTextMode: () => switchedToTextMode = true,
        analysing: analysing,
      ),
      overrides: overrides(ocrAvailable: ocrAvailable),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capturePages(WidgetTester tester, int count) async {
    for (var i = 0; i < count; i++) {
      await tester.tap(find.byKey(const Key('menu_capture_button')));
      await tester.pumpAndSettle();
    }
  }

  group('OCR unavailable', () {
    testWidgets('explains instead of opening the camera', (tester) async {
      await pumpTab(tester, ocrAvailable: false);

      expect(find.byKey(const Key('menu_pages_unavailable')), findsOneWidget);
      expect(find.text(CameraScreen.unavailableAdvice()), findsOneWidget);
      expect(session.started, isFalse);
    });

    testWidgets('offers a working link back to the text tab', (tester) async {
      await pumpTab(tester, ocrAvailable: false);

      await tester.tap(find.byKey(const Key('menu_switch_to_text_button')));
      await tester.pumpAndSettle();

      expect(switchedToTextMode, isTrue);
    });

    testWidgets('shows no camera control at all', (tester) async {
      await pumpTab(tester, ocrAvailable: false);

      expect(find.byKey(const Key('menu_capture_button')), findsNothing);
      expect(find.byKey(const Key('menu_gallery_button')), findsNothing);
    });
  });

  group('camera problem', () {
    testWidgets('a refused permission is explained and retryable', (
      tester,
    ) async {
      session.startError = const CameraSessionException(
        CameraProblem.permissionDenied,
      );
      await pumpTab(tester);

      expect(find.byKey(const Key('menu_camera_problem')), findsOneWidget);
      expect(
        find.text(CameraScreen.problemTitle(CameraProblem.permissionDenied)),
        findsOneWidget,
      );
      expect(find.byKey(const Key('menu_camera_retry_button')), findsOneWidget);
    });

    testWidgets('a permanently refused permission offers no retry', (
      tester,
    ) async {
      session.startError = const CameraSessionException(
        CameraProblem.permissionDeniedPermanently,
      );
      await pumpTab(tester);

      expect(find.byKey(const Key('menu_camera_retry_button')), findsNothing);
    });

    testWidgets('the gallery stays offered — a photo taken earlier is a '
        'real case', (tester) async {
      session.startError = const CameraSessionException(CameraProblem.noCamera);
      picker.multiplePaths = ['/tmp/g1.jpg'];
      await pumpTab(tester);

      expect(find.byKey(const Key('menu_gallery_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('menu_gallery_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('menu_page_thumb_0')), findsOneWidget);
    });

    testWidgets('retry reopens the camera', (tester) async {
      session.startError = const CameraSessionException(
        CameraProblem.permissionDenied,
      );
      await pumpTab(tester);

      session.startError = null;
      await tester.tap(find.byKey(const Key('menu_camera_retry_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fake_preview')), findsOneWidget);
      expect(session.started, isTrue);
    });
  });

  group('starting', () {
    testWidgets('shows a labelled indicator, never a bare spinner', (
      tester,
    ) async {
      session.startGate = Completer<void>();
      await pumpTab(tester);

      expect(find.byKey(const Key('menu_camera_starting')), findsOneWidget);
      expect(find.text(MenuCopy.cameraStartingLabel), findsOneWidget);

      session.startGate!.complete();
      await tester.pumpAndSettle();
    });
  });

  group('ready viewfinder', () {
    testWidgets('shows the preview, torch, shutter, gallery and counter', (
      tester,
    ) async {
      await pumpTab(tester);

      expect(find.byKey(const Key('fake_preview')), findsOneWidget);
      expect(find.byKey(const Key('menu_capture_button')), findsOneWidget);
      expect(find.byKey(const Key('menu_gallery_button')), findsOneWidget);
      expect(find.byKey(const Key('menu_torch_button')), findsOneWidget);
      expect(find.text('0 / 8'), findsOneWidget);
    });

    testWidgets('נתחו is disabled at zero pages', (tester) async {
      await pumpTab(tester);

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('menu_analyse_pages_button')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('releases the camera when the widget goes away', (
      tester,
    ) async {
      await pumpTab(tester);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      expect(session.stopped, isTrue);
    });

    testWidgets('the torch latches on and off', (tester) async {
      await pumpTab(tester);

      await tester.tap(find.byKey(const Key('menu_torch_button')));
      await tester.pumpAndSettle();
      expect(session.torch, isTrue);

      await tester.tap(find.byKey(const Key('menu_torch_button')));
      await tester.pumpAndSettle();
      expect(session.torch, isFalse);
    });

    testWidgets('a device with no torch simply does not latch', (tester) async {
      session.torchError = const CameraSessionException(CameraProblem.failed);
      await pumpTab(tester);

      await tester.tap(find.byKey(const Key('menu_torch_button')));
      await tester.pumpAndSettle();

      expect(session.torch, isNull);
      expect(tester.takeException(), isNull);
    });
  });

  group('capture', () {
    testWidgets('a capture appends a page and enables נתחו', (tester) async {
      await pumpTab(tester);

      await capturePages(tester, 1);

      expect(find.byKey(const Key('menu_page_thumb_0')), findsOneWidget);
      expect(find.text('1 / 8'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('menu_analyse_pages_button')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('a failed capture shows a notice and does not crash', (
      tester,
    ) async {
      session.captureError = const CameraSessionException(
        CameraProblem.failed,
        'busy',
      );
      await pumpTab(tester);

      await tester.tap(find.byKey(const Key('menu_capture_button')));
      await tester.pumpAndSettle();

      expect(find.text(MenuCopy.captureFailed), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the shutter stops working once the cap is reached', (
      tester,
    ) async {
      await pumpTab(tester);

      await capturePages(tester, MenuVerdictRules.maxPages);

      final button = tester.widget<IconButton>(
        find.byKey(const Key('menu_capture_button')),
      );
      expect(button.onPressed, isNull);
      expect(session.captures, hasLength(MenuVerdictRules.maxPages));
    });
  });

  group('gallery import', () {
    testWidgets('adds the picked pages', (tester) async {
      picker.multiplePaths = ['/tmp/g1.jpg', '/tmp/g2.jpg'];
      await pumpTab(tester);

      await tester.tap(find.byKey(const Key('menu_gallery_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('menu_page_thumb_0')), findsOneWidget);
      expect(find.byKey(const Key('menu_page_thumb_1')), findsOneWidget);
      expect(find.text('2 / 8'), findsOneWidget);
    });

    testWidgets('cancelling the picker changes nothing and shows no error', (
      tester,
    ) async {
      picker.multiplePaths = const [];
      await pumpTab(tester);

      await tester.tap(find.byKey(const Key('menu_gallery_button')));
      await tester.pumpAndSettle();

      expect(find.text('0 / 8'), findsOneWidget);
      expect(find.byKey(const Key('menu_page_notice')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a pick of ten with two pages already present adds six and '
        'shows the cap notice', (tester) async {
      picker.multiplePaths = List.generate(10, (i) => '/tmp/g$i.jpg');
      await pumpTab(tester);
      await capturePages(tester, 2);

      await tester.tap(find.byKey(const Key('menu_gallery_button')));
      await tester.pumpAndSettle();

      expect(picker.lastLimit, 6);
      expect(find.text('8 / 8'), findsOneWidget);
      expect(
        find.text(MenuCopy.pageCapNotice(MenuVerdictRules.maxPages)),
        findsOneWidget,
      );
    });

    testWidgets('a refused gallery permission is reported, not thrown', (
      tester,
    ) async {
      picker.error = const PhotoPickerException('denied');
      await pumpTab(tester);

      await tester.tap(find.byKey(const Key('menu_gallery_button')));
      await tester.pumpAndSettle();

      expect(find.text(MenuCopy.galleryError), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a pick at the cap adds nothing and shows the notice', (
      tester,
    ) async {
      picker.multiplePaths = ['/tmp/g1.jpg'];
      await pumpTab(tester);
      await capturePages(tester, MenuVerdictRules.maxPages);

      await tester.tap(find.byKey(const Key('menu_gallery_button')));
      await tester.pumpAndSettle();

      expect(
        find.text(MenuCopy.pageCapNotice(MenuVerdictRules.maxPages)),
        findsOneWidget,
      );
      expect(
        find.text(
          '${MenuVerdictRules.maxPages} / ${MenuVerdictRules.maxPages}',
        ),
        findsOneWidget,
      );
    });
  });

  group('remove', () {
    testWidgets('removing page 2 of 3 leaves two, renumbered', (tester) async {
      await pumpTab(tester);
      await capturePages(tester, 3);

      await tester.tap(find.byKey(const Key('menu_page_remove_1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('menu_page_thumb_0')), findsOneWidget);
      expect(find.byKey(const Key('menu_page_thumb_1')), findsOneWidget);
      expect(find.byKey(const Key('menu_page_thumb_2')), findsNothing);
      expect(find.text('2 / 8'), findsOneWidget);
    });
  });

  group('analyse', () {
    testWidgets('נתחו calls onAnalyse with the collected paths, in order', (
      tester,
    ) async {
      await pumpTab(tester);
      await capturePages(tester, 2);

      await tester.tap(find.byKey(const Key('menu_analyse_pages_button')));
      await tester.pumpAndSettle();

      expect(analysed, ['/tmp/menu-page-1.jpg', '/tmp/menu-page-2.jpg']);
    });

    testWidgets('נתחו stays disabled while analysing, even with pages', (
      tester,
    ) async {
      await pumpTab(tester, analysing: true);
      await capturePages(tester, 1);

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('menu_analyse_pages_button')),
      );
      expect(button.onPressed, isNull);
    });
  });

  group('RTL layout', () {
    testWidgets('the thumbnail strip lays out right-to-left', (tester) async {
      await pumpTab(tester);
      await capturePages(tester, 2);

      // A horizontal list already starts on the right under the app's RTL
      // `Directionality` — the first page collected renders to the right of
      // the second, with no `reverse` needed.
      final firstX = tester
          .getCenter(find.byKey(const Key('menu_page_thumb_0')))
          .dx;
      final secondX = tester
          .getCenter(find.byKey(const Key('menu_page_thumb_1')))
          .dx;
      expect(firstX, greaterThan(secondX));
    });
  });
}
