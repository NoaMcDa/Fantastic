import 'dart:async';

import 'package:fantastic/core/constants/menu_copy.dart';
import 'package:fantastic/core/services/llm/llm_chat_client.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/keto_lens/data/providers.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/image_picker_photo_picker.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/photo_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/fixtures/fixtures.dart';
import '../helpers/app_harness.dart';

/// #366 — the photo-pages half of the two flows this milestone closes on.
///
/// **This is the one place Epic #351's first invariant is checked from the
/// outside.** `MenuAnalyzer` is real (`RemoteMenuAnalyzer`): only the four
/// seams at the edges are faked —
///
/// - [PhotoPicker] — no gallery under the headless tester.
/// - [TextRecognitionService] — the desktop OCR arm is `dart:ffi` against a
///   system `libtesseract`, which this container does not have.
/// - `CameraSession` — deliberately **not overridden**, the same technique
///   `keto_lens_flow.dart` uses: `CameraControllerSession.start()` fails on
///   its own under `flutter-tester` (no `camera` plugin channel), and
///   `MenuPagesTab` already turns that into its camera-problem state, whose
///   `menu_gallery_button` is the same key the ready state offers. Nothing
///   here has to know which one rendered.
/// - [LlmChatClient] — the app's one outbound network call. Faking it here,
///   rather than faking `MenuAnalyzer` above it, is what lets this flow run
///   `MenuPageReader`, `MenuAnalysisPrompt` and `MenuResponseParser` for
///   real and still make no network call.
///
/// ## What the OCR text is standing in for
///
/// `HebrewMenuFixture.grill` is a hand-typed transcript of a real Israeli
/// menu, not engine output — #372 (a rendered-menu OCR capture) and #373 (a
/// photographed real menu) are the still-open gap between "a human typed
/// this" and "Tesseract produced this", the same distinction
/// `real_ocr_fixture.dart` draws for Keto Lens. This flow's
/// `_FakeTextRecognizer` returns it verbatim for page 1 and an empty string
/// for page 2 — a page OCR could not read, which is what page 2 is
/// standing in for, not a claim about what any engine actually returns.
class _FakeTextRecognizer implements TextRecognitionService {
  _FakeTextRecognizer({this.isAvailable = true});

  @override
  final bool isAvailable;

  /// Held open until the test has asserted the `קורא עמוד N מתוך M…` row —
  /// the same technique `menu_scanner_screen_test.dart`'s `gate` uses, and
  /// for the same reason: a fake that resolves inside one microtask drain
  /// never renders the intermediate frame.
  final Completer<void> gate = Completer<void>();

  final Map<String, String> textByPath = {};

  @override
  Future<String> recognise(String imagePath) async {
    await gate.future;
    return textByPath[imagePath] ?? '';
  }
}

/// Records the one call `RemoteMenuAnalyzer` may make, and answers it.
class _RecordingLlmChatClient implements LlmChatClient {
  ChatResult response = const ChatSucceeded(MenuReplyFixture.grill);

  bool called = false;
  String? capturedUserPrompt;
  String? capturedImageBase64;
  int? capturedMaxOutputTokens;
  Map<String, Object?>? capturedResponseSchema;

  @override
  Future<ChatResult> complete({
    required String systemPrompt,
    required String userPrompt,
    String? imageBase64,
    String? imageMediaType,
    int? maxOutputTokens,
    Map<String, Object?>? responseSchema,
  }) async {
    called = true;
    capturedUserPrompt = userPrompt;
    capturedImageBase64 = imageBase64;
    capturedMaxOutputTokens = maxOutputTokens;
    capturedResponseSchema = responseSchema;
    return response;
  }
}

class _FixturePhotoPicker implements PhotoPicker {
  const _FixturePhotoPicker(this.paths);

  final List<String> paths;

  @override
  Future<String?> pickFromGallery() async => null;

  @override
  Future<List<String>> pickMultiple({required int limit}) async => paths;
}

/// Opens the menu scanner's `צלמו עמודים` tab from the lens tab.
Future<void> _openMenuPhotoTab(WidgetTester tester) async {
  await goToTab(tester, 'tab_lens');
  await tapAt(tester, find.byKey(const Key('lens_mode_menu')));
  await tapAt(tester, find.text(MenuCopy.photoPagesTab));
}

void main() {
  testWidgets(
    'photographed pages are OCR\'d on the device and only recognised text '
    'reaches the client — no image part, ever',
    (tester) async {
      const page1 = '/tmp/menu-page-1.jpg';
      const page2 = '/tmp/menu-page-2.jpg';
      final recognizer = _FakeTextRecognizer()
        ..textByPath[page1] = HebrewMenuFixture.grill;
      final client = _RecordingLlmChatClient();

      final app = await bootApp(
        onboarded: true,
        overrides: [
          photoPickerProvider.overrideWithValue(
            const _FixturePhotoPicker([page1, page2]),
          ),
          textRecognitionServiceProvider.overrideWithValue(recognizer),
          llmChatClientProvider.overrideWithValue(client),
        ],
      );
      await pumpApp(tester, app);

      await _openMenuPhotoTab(tester);

      // The camera fails on its own headless, landing on the camera-problem
      // state — same key either state offers.
      await tapAt(tester, find.byKey(const Key('menu_gallery_button')));
      expect(find.byKey(const Key('menu_page_thumb_0')), findsOneWidget);
      expect(find.byKey(const Key('menu_page_thumb_1')), findsOneWidget);

      // Tapped without `tapAt`'s trailing `settle`: the recognizer's gate is
      // still open, and a bare `pump()` is what lets the intermediate
      // reading-page frame be observed rather than raced past it.
      await tester.ensureVisible(
        find.byKey(const Key('menu_analyse_pages_button')),
      );
      await tester.tap(find.byKey(const Key('menu_analyse_pages_button')));
      await tester.pump();

      expect(find.byKey(const Key('menu_reading_page')), findsOneWidget);
      expect(find.text(MenuCopy.readingPageLabel(1, 2)), findsOneWidget);
      expect(
        client.called,
        isFalse,
        reason: 'OCR must finish before the client is ever reached',
      );

      recognizer.gate.complete();
      await settle(tester);

      // **The invariant.** The client received the page-1 OCR text and
      // nothing that came from a photograph.
      expect(client.called, isTrue);
      expect(
        // `.trim()`: `MenuPagesText.text` trims the whole joined buffer, so
        // the fixture's own trailing newline does not survive verbatim —
        // the content between "מסעדת" and "₪18" does, which is what this
        // asserts.
        client.capturedUserPrompt,
        contains(HebrewMenuFixture.grill.trim()),
        reason: 'the recognised text must reach the model as text',
      );
      expect(
        client.capturedImageBase64,
        isNull,
        reason:
            'Epic #351\'s first invariant: the photograph never leaves the '
            'device — only recognised text is sent',
      );
      expect(client.capturedMaxOutputTokens, isNotNull);
      expect(client.capturedResponseSchema, isNotNull);

      // The result: page 2's empty OCR is reported as unread, and at least
      // one dish name came from the real parser reading the real reply
      // against the real OCR text.
      expect(find.byKey(const Key('menu_unread_pages')), findsOneWidget);
      expect(find.text(MenuCopy.unreadPagesLine(const [2])), findsOneWidget);
      expect(find.text('אנטריקוט על הגריל'), findsOneWidget);
    },
  );

  testWidgets(
    'OCR unavailable never opens a camera and never calls the client',
    (tester) async {
      final client = _RecordingLlmChatClient();

      final app = await bootApp(
        onboarded: true,
        overrides: [
          photoPickerProvider.overrideWithValue(
            const _FixturePhotoPicker(['/tmp/unused.jpg']),
          ),
          textRecognitionServiceProvider.overrideWithValue(
            _FakeTextRecognizer(isAvailable: false)..gate.complete(),
          ),
          llmChatClientProvider.overrideWithValue(client),
        ],
      );
      await pumpApp(tester, app);

      await _openMenuPhotoTab(tester);

      expect(find.byKey(const Key('menu_pages_unavailable')), findsOneWidget);
      expect(find.byKey(const Key('menu_camera_problem')), findsNothing);
      expect(find.byKey(const Key('menu_analyse_pages_button')), findsNothing);
      expect(client.called, isFalse);
    },
  );
}
