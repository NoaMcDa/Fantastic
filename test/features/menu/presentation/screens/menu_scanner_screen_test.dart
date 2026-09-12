import 'dart:async';

import 'package:fantastic/core/constants/add_meal_copy.dart';
import 'package:fantastic/core/constants/menu_copy.dart';
import 'package:fantastic/core/router/app_router.dart';
import 'package:fantastic/features/keto_lens/data/providers.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/camera_controller_session.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/camera_session.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/image_picker_photo_picker.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/photo_picker.dart';
import 'package:fantastic/features/keto_lens/presentation/screens/camera_screen.dart';
import 'package:fantastic/features/menu/data/providers.dart';
import 'package:fantastic/features/menu/domain/models/menu_analysis.dart';
import 'package:fantastic/features/menu/domain/models/menu_analysis_failure_reason.dart';
import 'package:fantastic/features/menu/domain/services/menu_analyzer.dart';
import 'package:fantastic/features/menu/presentation/screens/menu_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

/// A [MenuAnalyzer] that returns whatever the test put in it.
///
/// The interface, never the concrete `RemoteMenuAnalyzer` — the DoD item
/// this screen must hold, and the only way to reach every failure reason
/// without a network.
class _FakeMenuAnalyzer implements MenuAnalyzer {
  MenuAnalysis result = MenuAnalysisFixture.clean();
  Object? error;

  String? capturedText;
  List<String> capturedImagePaths = const [];

  /// Held open so a test can observe the analysing state before it
  /// resolves — the same technique `camera_screen_test.dart`'s
  /// `captureGate` uses for the same reason: a fake that resolves inside one
  /// microtask drain never renders the intermediate frame.
  Completer<void>? gate;

  /// `(page, of)` pairs delivered to `onPage`, for a test to drive.
  void Function(int page, int of)? onPage;

  @override
  Future<MenuAnalysis> analyse({
    String? text,
    List<String> imagePaths = const [],
    void Function(int page, int of)? onPage,
  }) async {
    capturedText = text;
    capturedImagePaths = imagePaths;
    this.onPage = onPage;
    await gate?.future;
    if (error != null) {
      throw error!;
    }
    return result;
  }
}

/// A camera that is whatever the test needs it to be — the same fake
/// `camera_screen_test.dart` uses, duplicated per that file's own
/// hand-rolled-fake convention rather than shared, so this suite has no
/// dependency on Keto Lens's test file.
class _FakeSession implements CameraSession {
  CameraSessionException? startError;
  bool started = false;
  bool stopped = false;
  final List<String> captures = [];

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
    final path = '/tmp/menu-page-${captures.length + 1}.jpg';
    captures.add(path);
    return path;
  }

  @override
  Future<void> setTorch({required bool on}) async {}

  @override
  Future<void> stop() async {
    stopped = true;
  }
}

/// OCR whose availability the test controls.
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

  @override
  Future<String?> pickFromGallery() async => null;

  @override
  Future<List<String>> pickMultiple({required int limit}) async {
    if (error != null) {
      throw error!;
    }
    return multiplePaths;
  }
}

void main() {
  late _FakeMenuAnalyzer analyzer;
  late _FakeSession session;
  late _FakePicker picker;

  setUp(() {
    analyzer = _FakeMenuAnalyzer();
    session = _FakeSession();
    picker = _FakePicker();
  });

  List<Override> overrides({bool ocrAvailable = true}) => [
    menuAnalyzerProvider.overrideWithValue(analyzer),
    cameraSessionBuilderProvider.overrideWithValue(() => session),
    photoPickerProvider.overrideWithValue(picker),
    textRecognitionServiceProvider.overrideWithValue(
      _FakeRecognizer(isAvailable: ocrAvailable),
    ),
  ];

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool ocrAvailable = true,
  }) async {
    await pumpApp(
      tester,
      const MenuScannerScreen(),
      overrides: overrides(ocrAvailable: ocrAvailable),
    );
    await tester.pumpAndSettle();
  }

  Future<void> typeAndAnalyse(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('menu_text_field')), text);
    await tester.pump();
    await tester.tap(find.byKey(const Key('menu_analyse_button')));
    await tester.pumpAndSettle();
  }

  /// Switches to `צלמו עמודים`.
  Future<void> openPhotoTab(WidgetTester tester) async {
    await tester.tap(find.text(MenuCopy.photoPagesTab));
    await tester.pumpAndSettle();
  }

  /// Captures [count] pages on an already-open photo tab.
  Future<void> capturePages(WidgetTester tester, int count) async {
    for (var i = 0; i < count; i++) {
      await tester.tap(find.byKey(const Key('menu_capture_button')));
      await tester.pumpAndSettle();
    }
  }

  group('input', () {
    testWidgets('the analyse button is disabled on blank text', (tester) async {
      await pumpScreen(tester);

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('menu_analyse_button')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('typing enables the analyse button', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(
        find.byKey(const Key('menu_text_field')),
        'סלט יווני',
      );
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('menu_analyse_button')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets(
      'the photo tab is a real camera and page collector, not the stub',
      (tester) async {
        await pumpScreen(tester);

        await openPhotoTab(tester);

        expect(find.byKey(const Key('fake_preview')), findsOneWidget);
        expect(find.byKey(const Key('menu_capture_button')), findsOneWidget);
        expect(find.byKey(const Key('menu_gallery_button')), findsOneWidget);
        expect(find.byKey(const Key('menu_text_field')), findsNothing);
        expect(find.byKey(const Key('menu_analyse_button')), findsNothing);
      },
    );
  });

  group('photo mode (#365)', () {
    testWidgets(
      'captures and a gallery pick together produce the right count',
      (tester) async {
        picker.multiplePaths = ['/tmp/g1.jpg', '/tmp/g2.jpg'];
        await pumpScreen(tester);
        await openPhotoTab(tester);

        await capturePages(tester, 2);
        await tester.tap(find.byKey(const Key('menu_gallery_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('menu_page_thumb_0')), findsOneWidget);
        expect(find.byKey(const Key('menu_page_thumb_3')), findsOneWidget);
        expect(find.text('4 / 8'), findsOneWidget);
      },
    );

    testWidgets('נתחו calls the analyser with the paths, in order, no text', (
      tester,
    ) async {
      await pumpScreen(tester);
      await openPhotoTab(tester);
      await capturePages(tester, 2);

      await tester.tap(find.byKey(const Key('menu_analyse_pages_button')));
      await tester.pumpAndSettle();

      expect(analyzer.capturedText, isNull);
      expect(analyzer.capturedImagePaths, [
        '/tmp/menu-page-1.jpg',
        '/tmp/menu-page-2.jpg',
      ]);
    });

    testWidgets('onPage renders קורא עמוד N מתוך M during OCR', (tester) async {
      analyzer.gate = Completer<void>();
      await pumpScreen(tester);
      await openPhotoTab(tester);
      await capturePages(tester, 1);

      await tester.tap(find.byKey(const Key('menu_analyse_pages_button')));
      await tester.pump();
      analyzer.onPage?.call(2, 4);
      await tester.pump();

      expect(find.byKey(const Key('menu_reading_page')), findsOneWidget);
      expect(find.text(MenuCopy.readingPageLabel(2, 4)), findsOneWidget);

      analyzer.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets(
      'נתחו is disabled at zero pages, enabled once one is collected',
      (tester) async {
        await pumpScreen(tester);
        await openPhotoTab(tester);

        var button = tester.widget<FilledButton>(
          find.byKey(const Key('menu_analyse_pages_button')),
        );
        expect(button.onPressed, isNull);

        await capturePages(tester, 1);

        button = tester.widget<FilledButton>(
          find.byKey(const Key('menu_analyse_pages_button')),
        );
        expect(button.onPressed, isNotNull);
      },
    );

    testWidgets('a MenuAnalysed with unreadPages renders the unread line', (
      tester,
    ) async {
      analyzer.result = MenuAnalysisFixture.analysed(unreadPages: const [3]);
      await pumpScreen(tester);
      await openPhotoTab(tester);
      await capturePages(tester, 1);

      await tester.tap(find.byKey(const Key('menu_analyse_pages_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('menu_unread_pages')), findsOneWidget);
      expect(find.text(MenuCopy.unreadPagesLine(const [3])), findsOneWidget);
    });

    testWidgets(
      'a failure returns to the pages tab with the thumbnails intact',
      (tester) async {
        analyzer.result = MenuAnalysisFixture.failed(
          reason: MenuAnalysisFailureReason.badResponse,
        );
        await pumpScreen(tester);
        await openPhotoTab(tester);
        await capturePages(tester, 2);

        await tester.tap(find.byKey(const Key('menu_analyse_pages_button')));
        await tester.pumpAndSettle();

        expect(find.text(MenuCopy.failedBadResponseHeadline), findsOneWidget);
        expect(find.byKey(const Key('menu_page_thumb_0')), findsOneWidget);
        expect(find.byKey(const Key('menu_page_thumb_1')), findsOneWidget);
        expect(find.text('2 / 8'), findsOneWidget);
        // The button works again — the retry a user actually has, since the
        // pages tab and its analyse button are still right there.
        final button = tester.widget<FilledButton>(
          find.byKey(const Key('menu_analyse_pages_button')),
        );
        expect(button.onPressed, isNotNull);
      },
    );

    testWidgets('offline offers a retry that resends the same pages', (
      tester,
    ) async {
      analyzer.result = MenuAnalysisFixture.failed(
        reason: MenuAnalysisFailureReason.offline,
      );
      await pumpScreen(tester);
      await openPhotoTab(tester);
      await capturePages(tester, 2);
      await tester.tap(find.byKey(const Key('menu_analyse_pages_button')));
      await tester.pumpAndSettle();

      analyzer.result = MenuAnalysisFixture.clean();
      // The photo tab's viewfinder plus thumbnails plus the failure view
      // together exceed the test surface's height, so the retry button
      // needs scrolling into view before it can be hit-tested.
      await tester.ensureVisible(find.byKey(const Key('menu_retry_button')));
      await tester.tap(find.byKey(const Key('menu_retry_button')));
      await tester.pumpAndSettle();

      expect(analyzer.capturedImagePaths, [
        '/tmp/menu-page-1.jpg',
        '/tmp/menu-page-2.jpg',
      ]);
      expect(find.byKey(const Key('menu_legend')), findsOneWidget);
    });

    testWidgets(
      'OCR unavailable explains instead of opening the camera, with a link '
      'to the text tab',
      (tester) async {
        await pumpScreen(tester, ocrAvailable: false);
        await openPhotoTab(tester);

        expect(find.byKey(const Key('menu_pages_unavailable')), findsOneWidget);
        expect(find.byKey(const Key('fake_preview')), findsNothing);
        expect(session.started, isFalse);
        expect(analyzer.capturedImagePaths, isEmpty);

        await tester.tap(find.byKey(const Key('menu_switch_to_text_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('menu_text_field')), findsOneWidget);
      },
    );

    testWidgets('every CameraProblem renders M6 copy and still offers the '
        'gallery', (tester) async {
      session.startError = const CameraSessionException(CameraProblem.noCamera);
      await pumpScreen(tester);
      await openPhotoTab(tester);

      expect(
        find.text(CameraScreen.problemTitle(CameraProblem.noCamera)),
        findsOneWidget,
      );
      expect(find.byKey(const Key('menu_gallery_button')), findsOneWidget);
    });

    testWidgets('a PhotoPickerException renders an error line and keeps '
        'existing pages', (tester) async {
      await pumpScreen(tester);
      await openPhotoTab(tester);
      await capturePages(tester, 1);

      picker.error = const PhotoPickerException('denied');
      await tester.tap(find.byKey(const Key('menu_gallery_button')));
      await tester.pumpAndSettle();

      expect(find.text(MenuCopy.galleryError), findsOneWidget);
      expect(find.byKey(const Key('menu_page_thumb_0')), findsOneWidget);
    });
  });

  group('analysing', () {
    testWidgets('calls the analyser with the pasted text and no image paths', (
      tester,
    ) async {
      await pumpScreen(tester);

      await typeAndAnalyse(tester, 'המבורגר, סלט קיסר');

      expect(analyzer.capturedText, 'המבורגר, סלט קיסר');
      expect(analyzer.capturedImagePaths, isEmpty);
    });

    testWidgets('shows a labelled indicator and keeps the pasted text', (
      tester,
    ) async {
      analyzer.gate = Completer<void>();
      await pumpScreen(tester);

      await tester.enterText(
        find.byKey(const Key('menu_text_field')),
        'פסטה ברוטב שמנת',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('menu_analyse_button')));
      await tester.pump();

      expect(find.byKey(const Key('menu_analysing')), findsOneWidget);
      expect(find.text(MenuCopy.analysingLabel), findsOneWidget);
      expect(find.text('פסטה ברוטב שמנת'), findsOneWidget);

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('menu_analyse_button')),
      );
      expect(button.onPressed, isNull);

      analyzer.gate!.complete();
      await tester.pumpAndSettle();
    });
  });

  group('result', () {
    testWidgets('a MenuAnalysed renders MenuResultView', (tester) async {
      analyzer.result = MenuAnalysisFixture.analysed();
      await pumpScreen(tester);

      await typeAndAnalyse(tester, 'תפריט מסעדה');

      expect(find.byKey(const Key('menu_legend')), findsOneWidget);
      expect(find.byKey(const Key('menu_analysing')), findsNothing);
    });

    testWidgets('נתחו תפריט אחר returns to input with the pasted text intact', (
      tester,
    ) async {
      analyzer.result = MenuAnalysisFixture.clean();
      await pumpScreen(tester);

      await typeAndAnalyse(tester, 'תפריט מסעדה');
      await tester.tap(find.byKey(const Key('menu_analyse_another_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('menu_text_field')), findsOneWidget);
      final field = tester.widget<TextField>(
        find.byKey(const Key('menu_text_field')),
      );
      expect(field.controller!.text, 'תפריט מסעדה');
      expect(find.byKey(const Key('menu_legend')), findsNothing);
    });
  });

  group('failure headlines — one per reachable reason', () {
    Future<void> failWith(
      WidgetTester tester,
      MenuAnalysisFailureReason reason,
    ) async {
      analyzer.result = MenuAnalysisFixture.failed(reason: reason);
      await pumpScreen(tester);
      await typeAndAnalyse(tester, 'תפריט לבדיקה');
    }

    testWidgets('ocrUnavailable', (tester) async {
      await failWith(tester, MenuAnalysisFailureReason.ocrUnavailable);
      expect(find.text(MenuCopy.failedOcrUnavailableHeadline), findsOneWidget);
    });

    testWidgets('noTextFound', (tester) async {
      await failWith(tester, MenuAnalysisFailureReason.noTextFound);
      expect(find.text(MenuCopy.failedNoTextFoundHeadline), findsOneWidget);
    });

    testWidgets('notConfigured', (tester) async {
      await failWith(tester, MenuAnalysisFailureReason.notConfigured);
      expect(find.text(MenuCopy.failedNotConfiguredHeadline), findsOneWidget);
    });

    testWidgets('offline', (tester) async {
      await failWith(tester, MenuAnalysisFailureReason.offline);
      expect(find.text(MenuCopy.failedOfflineHeadline), findsOneWidget);
    });

    testWidgets('rateLimited', (tester) async {
      await failWith(tester, MenuAnalysisFailureReason.rateLimited);
      expect(find.text(MenuCopy.failedRateLimitedHeadline), findsOneWidget);
      // Research §7: the quota line #321 already shows, reused rather than
      // restated.
      expect(find.text(AddMealCopy.rateLimitDetail), findsOneWidget);
    });

    testWidgets('unauthorised', (tester) async {
      await failWith(tester, MenuAnalysisFailureReason.unauthorised);
      expect(find.text(MenuCopy.failedUnauthorisedHeadline), findsOneWidget);
    });

    testWidgets('badResponse', (tester) async {
      await failWith(tester, MenuAnalysisFailureReason.badResponse);
      expect(find.text(MenuCopy.failedBadResponseHeadline), findsOneWidget);
    });

    testWidgets('noDishesFound', (tester) async {
      await failWith(tester, MenuAnalysisFailureReason.noDishesFound);
      expect(find.text(MenuCopy.failedNoDishesFoundHeadline), findsOneWidget);
    });
  });

  group('failure retry offer', () {
    testWidgets('ocrUnavailable offers no retry', (tester) async {
      analyzer.result = MenuAnalysisFixture.failed(
        reason: MenuAnalysisFailureReason.ocrUnavailable,
      );
      await pumpScreen(tester);
      await typeAndAnalyse(tester, 'תפריט');

      expect(find.byKey(const Key('menu_retry_button')), findsNothing);
    });

    testWidgets('offline offers a retry', (tester) async {
      analyzer.result = MenuAnalysisFixture.failed(
        reason: MenuAnalysisFailureReason.offline,
      );
      await pumpScreen(tester);
      await typeAndAnalyse(tester, 'תפריט');

      expect(find.byKey(const Key('menu_retry_button')), findsOneWidget);
    });

    testWidgets('badResponse offers a retry', (tester) async {
      analyzer.result = MenuAnalysisFixture.failed(
        reason: MenuAnalysisFailureReason.badResponse,
      );
      await pumpScreen(tester);
      await typeAndAnalyse(tester, 'תפריט');

      expect(find.byKey(const Key('menu_retry_button')), findsOneWidget);
    });

    testWidgets('notConfigured and unauthorised offer Profile', (tester) async {
      analyzer.result = MenuAnalysisFixture.failed(
        reason: MenuAnalysisFailureReason.notConfigured,
      );
      await pumpScreen(tester);
      await typeAndAnalyse(tester, 'תפריט');

      expect(find.byKey(const Key('menu_profile_button')), findsOneWidget);
      expect(find.byKey(const Key('menu_retry_button')), findsNothing);
    });

    testWidgets('tapping Profile navigates to the profile tab', (tester) async {
      analyzer.result = MenuAnalysisFixture.failed(
        reason: MenuAnalysisFailureReason.unauthorised,
      );
      String? pushed;
      final router = GoRouter(
        initialLocation: '/lens/menu',
        routes: [
          GoRoute(
            path: '/lens/menu',
            builder: (_, _) => const MenuScannerScreen(),
          ),
          GoRoute(
            path: kProfilePath,
            builder: (_, state) {
              pushed = state.uri.toString();
              return const SizedBox.shrink();
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await typeAndAnalyse(tester, 'תפריט');
      await tester.tap(find.byKey(const Key('menu_profile_button')));
      await tester.pumpAndSettle();

      expect(pushed, kProfilePath);
    });
  });

  group('failure safety', () {
    testWidgets('renders no progress indicator', (tester) async {
      analyzer.result = MenuAnalysisFixture.failed(
        reason: MenuAnalysisFailureReason.badResponse,
      );
      await pumpScreen(tester);

      await typeAndAnalyse(tester, 'תפריט');

      expect(find.byKey(const Key('menu_analysing')), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('the pasted text survives every failure', (tester) async {
      analyzer.result = MenuAnalysisFixture.failed(
        reason: MenuAnalysisFailureReason.noDishesFound,
      );
      await pumpScreen(tester);

      await typeAndAnalyse(tester, 'טקסט תפריט שהודבק');

      final field = tester.widget<TextField>(
        find.byKey(const Key('menu_text_field')),
      );
      expect(field.controller!.text, 'טקסט תפריט שהודבק');
    });

    testWidgets(
      'an analyser that throws is handled without the screen crashing',
      (tester) async {
        analyzer.error = StateError('a contract violation');
        await pumpScreen(tester);

        await typeAndAnalyse(tester, 'תפריט');

        expect(tester.takeException(), isNull);
        expect(find.text(MenuCopy.failedBadResponseHeadline), findsOneWidget);
      },
    );
  });

  group('MenuScannerScreen.headlineFor / adviceFor', () {
    test('every reason has a headline and advice string', () {
      for (final reason in MenuAnalysisFailureReason.values) {
        expect(MenuScannerScreen.headlineFor(reason), isNotEmpty);
        expect(MenuScannerScreen.adviceFor(reason), isNotEmpty);
      }
    });
  });
}
