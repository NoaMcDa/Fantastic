import 'dart:async';

import 'package:fantastic/core/constants/menu_copy.dart';
import 'package:fantastic/core/services/llm/llm_chat_client.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/keto_lens/data/providers.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/document_picker.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/file_selector_document_picker.dart';
import 'package:fantastic/features/menu/data/providers.dart';
import 'package:fantastic/features/menu/domain/models/pdf_pages_text.dart';
import 'package:fantastic/features/menu/domain/services/pdf_page_extractor.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/fixtures/fixtures.dart';
import '../helpers/app_harness.dart';

/// #408 — the PDF half of the three input modes `MenuScannerScreen` offers,
/// and the last of the four PDF issues.
///
/// **This is the one place Epic #351's first invariant is checked for a PDF
/// from the outside**, exactly as `menu_photo_flow.dart` checks it for a
/// photograph. `MenuAnalyzer` is real (`RemoteMenuAnalyzer`): only the seams
/// at the edges are faked —
///
/// - [DocumentPicker] — no file dialog under the headless tester.
/// - [PdfPageExtractor] — `pdfrx` needs a real PDF file on disk; this flow
///   fakes the interface exactly as `menu_scanner_screen_test.dart` does,
///   rather than shipping a binary fixture through `integration_test/`.
/// - [TextRecognitionService] — the desktop OCR arm is `dart:ffi` against a
///   system `libtesseract`, which this container does not have.
/// - [LlmChatClient] — the app's one outbound network call. Faking it here,
///   rather than faking `MenuAnalyzer` above it, is what lets this flow run
///   `MenuPageReader`, `MenuAnalysisPrompt` and `MenuResponseParser` for real
///   and still make no network call.
///
/// The first test drives a **mixed** PDF — one page with a usable text
/// layer, one page rasterised and OCR'd — through one request, so both
/// halves of "a PDF is two problems wearing one file extension"
/// (`design/m16_menu_scanner_research.md` §12) are exercised together. The
/// second drives a text-layer-only PDF with OCR unavailable, proving the
/// mode is not gated behind it.
class _FixtureDocumentPicker implements DocumentPicker {
  const _FixtureDocumentPicker(this.path);

  final String? path;

  @override
  Future<String?> pickPdf() async => path;
}

class _FixturePdfPageExtractor implements PdfPageExtractor {
  const _FixturePdfPageExtractor({
    required this.pagesText,
    this.renderedPaths = const [],
  });

  @override
  bool get isAvailable => true;

  final PdfPagesText pagesText;
  final List<String> renderedPaths;

  @override
  Future<PdfPagesText> extract(String pdfPath) async => pagesText;

  @override
  Future<List<String>> renderPages(String pdfPath, List<int> pages) async =>
      renderedPaths;
}

/// OCR for the rendered page only — the same held-open-gate technique
/// `menu_photo_flow.dart`'s own fake uses, and for the same reason: a fake
/// that resolves inside one microtask drain never renders the intermediate
/// `קורא עמוד N מתוך M…` frame.
class _FakeTextRecognizer implements TextRecognitionService {
  @override
  final bool isAvailable = true;

  final Completer<void> gate = Completer<void>();
  final Map<String, String> textByPath = {};

  @override
  Future<String> recognise(String imagePath) async {
    await gate.future;
    return textByPath[imagePath] ?? '';
  }
}

/// No engine at all — the second test's whole point.
class _UnavailableTextRecognizer implements TextRecognitionService {
  @override
  bool get isAvailable => false;

  @override
  Future<String> recognise(String imagePath) async => '';
}

/// Records the one call `RemoteMenuAnalyzer` may make, and answers it.
class _RecordingLlmChatClient implements LlmChatClient {
  ChatResult response = const ChatSucceeded(MenuReplyFixture.grill);

  bool called = false;
  String? capturedUserPrompt;
  String? capturedImageBase64;

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
    return response;
  }
}

/// Opens the menu scanner's `קובץ PDF` tab from the lens tab.
Future<void> _openMenuPdfTab(WidgetTester tester) async {
  await goToTab(tester, 'tab_lens');
  await tapAt(tester, find.byKey(const Key('lens_mode_menu')));
  await tapAt(tester, find.text(MenuCopy.pdfFileTab));
}

void main() {
  testWidgets(
    "a mixed PDF's text layer and its rasterised page are both read on the "
    'device; only recognised text reaches the client — the PDF itself '
    'never leaves it',
    (tester) async {
      const pdfPath = '/tmp/menu.pdf';
      const renderedPage2Path = '/tmp/pdf-rendered-page-2.png';
      const renderedPage3Path = '/tmp/pdf-rendered-page-3.png';
      final recognizer = _FakeTextRecognizer()
        ..textByPath[renderedPage2Path] = 'קינוח שוקולד ₪28'
        ..textByPath[renderedPage3Path] = 'תה מנטה ₪14';
      final client = _RecordingLlmChatClient();

      final app = await bootApp(
        onboarded: true,
        overrides: [
          documentPickerProvider.overrideWithValue(
            const _FixtureDocumentPicker(pdfPath),
          ),
          pdfPageExtractorProvider.overrideWithValue(
            const _FixturePdfPageExtractor(
              pagesText: PdfPagesText(
                pages: {1: HebrewMenuFixture.grill},
                pageCount: 3,
                pagesWithoutTextLayer: [2, 3],
              ),
              // Two rasterised pages, not one — `MenuScannerScreen`'s
              // `page < of` check (shared with the photo mode, unchanged by
              // this issue) only shows `_ReadingPageIndicator` while a page
              // remains after the current one, so a single-image OCR call
              // would skip straight to the generic `_AnalysingIndicator`
              // and never exercise the row this test means to prove is
              // reused rather than reinvented.
              renderedPaths: [renderedPage2Path, renderedPage3Path],
            ),
          ),
          textRecognitionServiceProvider.overrideWithValue(recognizer),
          llmChatClientProvider.overrideWithValue(client),
        ],
      );
      await pumpApp(tester, app);

      await _openMenuPdfTab(tester);
      await tapAt(tester, find.byKey(const Key('menu_pdf_pick_button')));

      expect(find.byKey(const Key('menu_pdf_filename')), findsOneWidget);
      expect(find.text('menu.pdf'), findsOneWidget);

      // Tapped without `tapAt`'s trailing `settle`, the same technique
      // `menu_photo_flow.dart` uses: the recognizer's gate is still open, and
      // a bare `pump()` is what lets the intermediate reading-page frame be
      // observed rather than raced past it.
      await tester.ensureVisible(
        find.byKey(const Key('menu_analyse_pdf_button')),
      );
      await tester.tap(find.byKey(const Key('menu_analyse_pdf_button')));
      await tester.pump();

      expect(find.byKey(const Key('menu_reading_page')), findsOneWidget);
      expect(find.text(MenuCopy.readingPageLabel(1, 2)), findsOneWidget);
      expect(
        client.called,
        isFalse,
        reason:
            'OCR of the rasterised pages must finish before the client '
            'is ever reached',
      );

      recognizer.gate.complete();
      await settle(tester);

      // **The invariant.** The client received the extracted text and the
      // OCR'd text, and nothing that came from the PDF file itself.
      expect(client.called, isTrue);
      expect(
        client.capturedUserPrompt,
        contains(HebrewMenuFixture.grill.trim()),
        reason: "the PDF's own text layer must reach the model as text",
      );
      expect(
        client.capturedUserPrompt,
        contains('קינוח שוקולד ₪28'),
        reason:
            'a rasterised page, once OCR\'d, must reach the model as '
            'text too',
      );
      expect(
        client.capturedUserPrompt,
        contains('תה מנטה ₪14'),
        reason: 'so must the second rasterised page',
      );
      expect(
        client.capturedImageBase64,
        isNull,
        reason:
            "Epic #351's first invariant, for a PDF: the file never leaves "
            'the device — only extracted or recognised text is sent',
      );

      expect(find.text('אנטריקוט על הגריל'), findsOneWidget);
    },
  );

  testWidgets('a text-layer PDF analyses with no OCR at all, even with no '
      'recognition engine present — the mode is not behind the OCR gate', (
    tester,
  ) async {
    const pdfPath = '/tmp/text-menu.pdf';
    final client = _RecordingLlmChatClient();

    final app = await bootApp(
      onboarded: true,
      overrides: [
        documentPickerProvider.overrideWithValue(
          const _FixtureDocumentPicker(pdfPath),
        ),
        pdfPageExtractorProvider.overrideWithValue(
          const _FixturePdfPageExtractor(
            pagesText: PdfPagesText(
              pages: {1: HebrewMenuFixture.grill},
              pageCount: 1,
            ),
          ),
        ),
        textRecognitionServiceProvider.overrideWithValue(
          _UnavailableTextRecognizer(),
        ),
        llmChatClientProvider.overrideWithValue(client),
      ],
    );
    await pumpApp(tester, app);

    await _openMenuPdfTab(tester);
    await tapAt(tester, find.byKey(const Key('menu_pdf_pick_button')));
    await tapAt(tester, find.byKey(const Key('menu_analyse_pdf_button')));

    await waitFor(tester, () async => client.called);

    expect(client.capturedImageBase64, isNull);
    expect(find.byKey(const Key('menu_failure')), findsNothing);
    expect(find.text('אנטריקוט על הגריל'), findsOneWidget);
  });
}
