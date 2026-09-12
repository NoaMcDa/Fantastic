@TestOn('vm')
library;

import 'dart:io';

import 'package:fantastic/core/constants/menu_verdict_rules.dart';
import 'package:fantastic/features/keto_lens/data/adapters/ocr_image_prep.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';
import 'package:fantastic/features/menu/application/menu_page_reader.dart';
import 'package:fantastic/features/menu/data/adapters/pdf_page_extractor_impl.dart';
import 'package:fantastic/features/menu/domain/services/pdf_page_extractor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:pdfrx/pdfrx.dart';

class _MockRecognizer extends Mock implements TextRecognitionService {}

/// `PdfrxPageExtractor` against real PDF fixtures, plus direct unit tests of
/// the legibility guard — the reason #405 exists.
///
/// ## Why the fixture-based tests can skip
///
/// `pdfrx` → `pdfrx_engine` → `pdfium_dart` downloads PDFium through Dart
/// native assets at build time (see the risk section on issue #405 and
/// `design/m16_menu_scanner_research.md` §12). A real app build (`flutter
/// build linux`, `flutter build web`, …) wires this correctly — verified
/// separately by this PR's `flutter build web` run. But `flutter test`'s
/// own native-asset resolution for this young Dart feature is not
/// guaranteed on every machine that runs this suite, exactly the situation
/// `tesseract_ffi_recognizer_test.dart` already documents for libtesseract.
/// [_probePdfiumLoads] checks for it directly and the fixture-based group
/// skips, loudly, if it is unavailable — never silently, and never by
/// failing the whole suite for an environment gap unrelated to this code.
///
/// The legibility guard itself needs none of this: [PdfrxPageExtractor.legibleTextOf]
/// is pure string logic and its tests always run.
Future<bool> _probePdfiumLoads() async {
  try {
    // A genuinely valid, empty PDF. The only way opening *this* file can
    // fail is the native module itself failing to load — never a legibility
    // or format problem, so any exception here is the environment gap, not
    // a bug in the adapter.
    await const PdfrxPageExtractor().extract('test/fixtures/zero_page.pdf');
    return true;
  } on Object {
    return false;
  }
}

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Required once, before the first `extract()` call: `pdfrx` otherwise asks
  // `path_provider` for a cache directory, and no platform channel answers
  // that under `flutter test`. A real app has a real cache directory; the
  // test suite only needs *a* writable one.
  Pdfrx.cacheDirectoryPath = Directory.systemTemp.path;

  final pdfiumAvailable = await _probePdfiumLoads();
  if (!pdfiumAvailable) {
    // A skip is silent by design, and silence is the wrong default here —
    // the same reasoning `tesseract_ffi_recognizer_test.dart` gives.
    // ignore: avoid_print
    print(
      '\n'
      '  ==========================================================\n'
      '  PDF EXTRACTION NOT EXERCISED — PDFium could not be loaded.\n'
      '\n'
      '  Every fixture-based test in pdf_page_extractor_impl_test.dart\n'
      '  is being SKIPPED. A green run therefore proves nothing about\n'
      '  real PDF text extraction: not the happy path, not the mixed-\n'
      '  page case, not the encrypted/corrupt-file handling. The\n'
      '  legibility guard itself is still covered directly — see the\n'
      '  first group in this file, which needs no native module.\n'
      '  ==========================================================\n',
    );
  }
  final String? fixtureSkipReason = pdfiumAvailable
      ? null
      : 'PDFium native module could not be loaded in this environment';

  group('PdfrxPageExtractor.legibleTextOf — the legibility guard', () {
    test('empty text has no usable text layer', () {
      expect(PdfrxPageExtractor.legibleTextOf(''), isNull);
    });

    test('whitespace-only text has no usable text layer', () {
      expect(PdfrxPageExtractor.legibleTextOf('   \n\t  '), isNull);
    });

    test('fewer than minExtractedLetters letters has no usable text layer, '
        'even when every letter is Hebrew', () {
      // 3 Hebrew letters, well under the 20-letter floor.
      expect(PdfrxPageExtractor.legibleTextOf('עוף'), isNull);
    });

    test('digits and punctuation alone never clear minExtractedLetters', () {
      // 20 digits, zero letters — a phone-number list or a page number
      // block is not a menu page.
      expect(PdfrxPageExtractor.legibleTextOf('12345678901234567890'), isNull);
    });

    test('exactly minExtractedLetters Hebrew letters, all Hebrew, is kept', () {
      final text = 'א' * MenuVerdictRules.minExtractedLetters;

      expect(PdfrxPageExtractor.legibleTextOf(text), text);
    });

    test(
      // The guard this issue exists for: plausible-looking letter soup that
      // is not Hebrew at all — the subset-font mojibake case.
      'letters below minHebrewLetterRatio has no usable text layer, even '
      'well above minExtractedLetters',
      () {
        final latinOnly = 'x' * 40;

        expect(PdfrxPageExtractor.legibleTextOf(latinOnly), isNull);
      },
    );

    test('a ratio just below minHebrewLetterRatio is rejected', () {
      // 9 Hebrew + 11 Latin = 20 letters, ratio 0.45 < 0.5.
      final text = ('א' * 9) + ('x' * 11);

      expect(PdfrxPageExtractor.legibleTextOf(text), isNull);
    });

    test('a ratio exactly at minHebrewLetterRatio is kept', () {
      // 10 Hebrew + 10 Latin = 20 letters, ratio exactly 0.5 — the guard
      // rejects strictly *below* the threshold, not at it.
      final text = ('א' * 10) + ('x' * 10);

      expect(PdfrxPageExtractor.legibleTextOf(text), text);
    });

    test(
      'a genuinely bilingual page (Hebrew majority, some English) is kept',
      () {
        const text = 'עוף בגריל עם ירקות טריים ותוספת אורז - Grilled chicken';

        expect(PdfrxPageExtractor.legibleTextOf(text), text);
      },
    );

    test('the five Hebrew final letters count toward the Hebrew ratio', () {
      // ך ם ן ף ץ sit inside the same contiguous Unicode block as the other
      // 22 letters, so a menu line ending in a final form must not be
      // undercounted.
      final text = 'ךםןףץ' * 4; // 20 letters, entirely Hebrew finals.

      expect(PdfrxPageExtractor.legibleTextOf(text), text);
    });

    test('the kept text is trimmed but internal formatting survives', () {
      final inner = 'שורה ראשונה\nשורה שנייה ${'א' * 20}';
      final padded = '  \n$inner\n  ';

      expect(PdfrxPageExtractor.legibleTextOf(padded), inner);
    });
  });

  group('PdfrxPageExtractor.isAvailable', () {
    test('is always true — pdfrx declares every platform', () {
      expect(const PdfrxPageExtractor().isAvailable, isTrue);
    });
  });

  test('pdfrx is imported in exactly one file under lib/', () {
    final importers = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final content = entity.readAsStringSync();
      if (content.contains("package:pdfrx/pdfrx.dart'")) {
        importers.add(entity.path);
      }
    }

    expect(importers, hasLength(1));
    expect(importers.single, endsWith('pdf_page_extractor_impl.dart'));
  });

  group('PdfUnreadableException', () {
    test('toString includes the reason', () {
      const exception = PdfUnreadableException('encrypted, no password');

      expect(exception.reason, 'encrypted, no password');
      expect(
        exception.toString(),
        'PdfUnreadableException: encrypted, no password',
      );
    });
  });

  group('PdfrxPageExtractor.extract against real fixture PDFs', () {
    const extractor = PdfrxPageExtractor();

    test('happy path: a text-layer Hebrew PDF extracts every page, and '
        'pagesWithoutTextLayer is empty', () async {
      final result = await extractor.extract(
        'test/fixtures/hebrew_menu_textlayer.pdf',
      );

      expect(result.pageCount, 3);
      expect(result.pagesWithoutTextLayer, isEmpty);
      expect(result.pages.keys, {1, 2, 3});
      for (final text in result.pages.values) {
        expect(text.trim(), isNotEmpty);
      }
    }, skip: fixtureSkipReason);

    test(
      'joined places each page under MenuPageReader.pageMarker(n), so a PDF '
      'and a photographed menu are indistinguishable to the prompt',
      () async {
        final result = await extractor.extract(
          'test/fixtures/hebrew_menu_textlayer.pdf',
        );

        final marker1 = result.joined.indexOf('--- עמוד 1 ---');
        final marker2 = result.joined.indexOf('--- עמוד 2 ---');
        final marker3 = result.joined.indexOf('--- עמוד 3 ---');

        expect(marker1, isNonNegative);
        expect(marker2, greaterThan(marker1));
        expect(marker3, greaterThan(marker2));
      },
      skip: fixtureSkipReason,
    );

    test(
      // Page 3 of this fixture is bilingual Hebrew/English — the guard must
      // still clear it, per the issue's own edge case.
      'a bilingual Hebrew/English menu page still passes the guard',
      () async {
        final result = await extractor.extract(
          'test/fixtures/hebrew_menu_textlayer.pdf',
        );

        expect(result.pages.containsKey(3), isTrue);
        expect(result.pagesWithoutTextLayer, isNot(contains(3)));
      },
      skip: fixtureSkipReason,
    );

    test(
      // Constructed with pikepdf by rewriting every Hebrew /ToUnicode
      // bfchar entry to a Latin-1 Supplement letter — not a real design-tool
      // export. It extracts as confident-looking letter soup (hundreds of
      // letters per page) with zero Hebrew, which is exactly the shape the
      // guard exists to catch.
      'a page of mojibake below minHebrewLetterRatio is treated as having '
      'no text layer',
      () async {
        final result = await extractor.extract(
          'test/fixtures/hebrew_menu_mojibake.pdf',
        );

        expect(result.pageCount, 3);
        expect(result.pages, isEmpty);
        expect(result.pagesWithoutTextLayer, [1, 2, 3]);
      },
      skip: fixtureSkipReason,
    );

    test('a scanned PDF (an image with no text layer at all) reports its one '
        'page as unread, and does not fail the extraction', () async {
      final result = await extractor.extract(
        'test/fixtures/hebrew_menu_scanned.pdf',
      );

      expect(result.pageCount, 1);
      expect(result.pages, isEmpty);
      expect(result.pagesWithoutTextLayer, [1]);
    }, skip: fixtureSkipReason);

    test(
      // Built by splicing a genuine text-layer page with a scanned
      // (image-only) page, so both outcomes are exercised in one document.
      'a mixed PDF reports the text-layer page and the page with no text '
      'layer correctly',
      () async {
        final result = await extractor.extract(
          'test/fixtures/hebrew_menu_mixed.pdf',
        );

        expect(result.pageCount, 2);
        expect(result.pages.keys, {1});
        expect(result.pagesWithoutTextLayer, [2]);
      },
      skip: fixtureSkipReason,
    );

    test(
      'a PDF with zero pages returns pageCount == 0 and does not throw',
      () async {
        final result = await extractor.extract('test/fixtures/zero_page.pdf');

        expect(result.pageCount, 0);
        expect(result.pages, isEmpty);
        expect(result.pagesWithoutTextLayer, isEmpty);
      },
      skip: fixtureSkipReason,
    );

    test('an encrypted PDF throws PdfUnreadableException, distinctly from a '
        'PDF with no text layer', () async {
      await expectLater(
        extractor.extract('test/fixtures/hebrew_menu_encrypted.pdf'),
        throwsA(isA<PdfUnreadableException>()),
      );
    }, skip: fixtureSkipReason);

    test('a file that is not a PDF throws PdfUnreadableException', () async {
      final dir = await Directory.systemTemp.createTemp(
        'pdf_page_extractor_test',
      );
      addTearDown(() => dir.delete(recursive: true));
      final notAPdf = File('${dir.path}/not_a_pdf.txt');
      await notAPdf.writeAsString('this is definitely not a PDF file');

      await expectLater(
        extractor.extract(notAPdf.path),
        throwsA(isA<PdfUnreadableException>()),
      );
    }, skip: fixtureSkipReason);

    test(
      // The two failure reasons must differ in substance, not merely in
      // being the same exception type — a user needs to be told "this file
      // is encrypted" and not "this file is not a PDF" interchangeably.
      'the encrypted-file reason and the not-a-PDF reason are distinct',
      () async {
        final dir = await Directory.systemTemp.createTemp(
          'pdf_page_extractor_test',
        );
        addTearDown(() => dir.delete(recursive: true));
        final notAPdf = File('${dir.path}/not_a_pdf.txt');
        await notAPdf.writeAsString('this is definitely not a PDF file');

        Future<String> reasonOf(String path) async {
          try {
            await extractor.extract(path);
          } on PdfUnreadableException catch (e) {
            return e.reason;
          }
          fail('expected extract($path) to throw PdfUnreadableException');
        }

        final encryptedReason = await reasonOf(
          'test/fixtures/hebrew_menu_encrypted.pdf',
        );
        final notAPdfReason = await reasonOf(notAPdf.path);

        expect(encryptedReason, isNot(notAPdfReason));
      },
      skip: fixtureSkipReason,
    );
  });

  group(
    'PdfrxPageExtractor.renderSizeFor — pure arithmetic, no PDFium needed',
    () {
      test('a portrait A4-shaped page renders pdfRenderWidthPx wide, aspect '
          'ratio preserved', () {
        // A4 in points: 595 x 842.
        final size = PdfrxPageExtractor.renderSizeFor(
          pageWidth: 595,
          pageHeight: 842,
        );

        expect(size.width, MenuVerdictRules.pdfRenderWidthPx);
        expect(size.height / size.width, closeTo(842 / 595, 0.001));
      });

      test('a landscape page is still exactly pdfRenderWidthPx wide', () {
        final size = PdfrxPageExtractor.renderSizeFor(
          pageWidth: 842,
          pageHeight: 595,
        );

        expect(size.width, MenuVerdictRules.pdfRenderWidthPx);
        expect(size.height, lessThan(size.width));
      });

      test(
        'a large-format (A3 poster) page still renders within OcrImagePrep\'s '
        'maxEdge and maxPixels caps',
        () {
          // A3 in points: 842 x 1191.
          final size = PdfrxPageExtractor.renderSizeFor(
            pageWidth: 842,
            pageHeight: 1191,
          );

          expect(size.width, lessThanOrEqualTo(OcrImagePrep.maxEdge));
          expect(size.height, lessThanOrEqualTo(OcrImagePrep.maxEdge));
          expect(
            size.width * size.height,
            lessThanOrEqualTo(OcrImagePrep.maxPixels),
          );
        },
      );

      test(
        // A narrow banner-shaped page: rendered naively at pdfRenderWidthPx
        // wide its height would land far past maxEdge. The clamp must fire,
        // and the page's own aspect ratio must survive it.
        'an extreme banner-shaped page is clamped to maxEdge on its long '
        'edge, never grown past it',
        () {
          final size = PdfrxPageExtractor.renderSizeFor(
            pageWidth: 100,
            pageHeight: 6000,
          );

          expect(size.height, lessThanOrEqualTo(OcrImagePrep.maxEdge));
          expect(
            size.width * size.height,
            lessThanOrEqualTo(OcrImagePrep.maxPixels),
          );
          expect(size.height / size.width, closeTo(60, 0.5));
        },
      );

      test('a tiny page is never upscaled past pdfRenderWidthPx', () {
        final size = PdfrxPageExtractor.renderSizeFor(
          pageWidth: 100,
          pageHeight: 100,
        );

        expect(
          size.width,
          lessThanOrEqualTo(MenuVerdictRules.pdfRenderWidthPx),
        );
      });
    },
  );

  group('PdfrxPageExtractor.renderPages', () {
    const extractor = PdfrxPageExtractor();

    test(
      // Runs unconditionally, with no PDFium at all: the empty-list guard
      // must return before the file is ever touched, so a nonexistent path
      // proves the point rather than merely being a convenient input — if
      // this ever tried to open the file it would throw
      // PdfUnreadableException instead of returning quietly.
      'an empty pages list returns an empty result and opens nothing',
      () async {
        final paths = await extractor.renderPages(
          'test/fixtures/does_not_exist.pdf',
          const [],
        );

        expect(paths, isEmpty);
      },
    );

    test(
      'the scanned fixture\'s one page renders to one existing PNG file',
      () async {
        final paths = await extractor.renderPages(
          'test/fixtures/hebrew_menu_scanned.pdf',
          [1],
        );

        expect(paths, hasLength(1));
        expect(File(paths.single).existsSync(), isTrue);
        expect(paths.single, endsWith('.png'));
      },
      skip: fixtureSkipReason,
    );

    test('the rendered image\'s width is pdfRenderWidthPx and its aspect '
        'ratio matches the source page', () async {
      final document = await PdfDocument.openFile(
        'test/fixtures/hebrew_menu_scanned.pdf',
      );
      final sourceAspect =
          document.pages.single.width / document.pages.single.height;
      await document.dispose();

      final paths = await extractor.renderPages(
        'test/fixtures/hebrew_menu_scanned.pdf',
        [1],
      );
      final decoded = img.decodePng(await File(paths.single).readAsBytes());

      expect(decoded, isNotNull);
      expect(decoded!.width, MenuVerdictRules.pdfRenderWidthPx);
      expect(decoded.width / decoded.height, closeTo(sourceAspect, 0.01));
    }, skip: fixtureSkipReason);

    test('multiple valid pages render in the order requested', () async {
      final paths = await extractor.renderPages(
        'test/fixtures/hebrew_menu_mixed.pdf',
        [1, 2],
      );

      expect(paths, hasLength(2));
      for (final path in paths) {
        expect(File(path).existsSync(), isTrue);
      }
    }, skip: fixtureSkipReason);

    test(
      // The mixed fixture's page 1 already has a good text layer; only
      // page 2 needs rasterising. Requesting only [2] must not touch page 1
      // at all.
      'requesting a subset of pages renders only that subset',
      () async {
        final paths = await extractor.renderPages(
          'test/fixtures/hebrew_menu_mixed.pdf',
          [2],
        );

        expect(paths, hasLength(1));
      },
      skip: fixtureSkipReason,
    );

    test(
      // Covers the same omission path a genuinely unrenderable page would
      // take: the loop simply never adds a path for it, and every other
      // requested page still comes back. An out-of-range number is the one
      // way to trigger that path deterministically against a real fixture.
      'a page number outside 1..pageCount is skipped, not thrown on, and '
      'the pages that are in range still render',
      () async {
        final paths = await extractor.renderPages(
          'test/fixtures/hebrew_menu_scanned.pdf',
          [0, 1, 99, -5],
        );

        expect(paths, hasLength(1));
      },
      skip: fixtureSkipReason,
    );

    test(
      'rendered files are written to a temporary directory, never the app '
      'documents directory — Epic #351 forbids persisting anything',
      () async {
        final paths = await extractor.renderPages(
          'test/fixtures/hebrew_menu_scanned.pdf',
          [1],
        );

        expect(paths, hasLength(1));
        expect(paths.single, startsWith(Directory.systemTemp.path));
      },
      skip: fixtureSkipReason,
    );

    test(
      'an encrypted PDF throws PdfUnreadableException from renderPages too',
      () async {
        await expectLater(
          extractor.renderPages('test/fixtures/hebrew_menu_encrypted.pdf', [1]),
          throwsA(isA<PdfUnreadableException>()),
        );
      },
      skip: fixtureSkipReason,
    );

    test('a file that is not a PDF throws PdfUnreadableException from '
        'renderPages too', () async {
      final dir = await Directory.systemTemp.createTemp(
        'pdf_page_extractor_render_test',
      );
      addTearDown(() => dir.delete(recursive: true));
      final notAPdf = File('${dir.path}/not_a_pdf.txt');
      await notAPdf.writeAsString('this is definitely not a PDF file');

      await expectLater(
        extractor.renderPages(notAPdf.path, [1]),
        throwsA(isA<PdfUnreadableException>()),
      );
    }, skip: fixtureSkipReason);

    test(
      'rendered pages, handed to a real MenuPageReader over a fake '
      'recogniser, produce the marker-joined text shape the prompt expects',
      () async {
        final paths = await extractor.renderPages(
          'test/fixtures/hebrew_menu_mixed.pdf',
          [1, 2],
        );
        expect(paths, hasLength(2));

        final recognizer = _MockRecognizer();
        when(() => recognizer.isAvailable).thenReturn(true);
        when(() => recognizer.recognise(paths[0]))
            .thenAnswer((_) async => 'עוף בגריל');
        when(() => recognizer.recognise(paths[1]))
            .thenAnswer((_) async => 'סלט קיסר');

        final reader = MenuPageReader(recognizer: recognizer);
        final result = await reader.read(paths);

        expect(result.pageCount, 2);
        expect(result.unreadPages, isEmpty);
        final marker1 = result.text.indexOf(MenuPageReader.pageMarker(1));
        final marker2 = result.text.indexOf(MenuPageReader.pageMarker(2));
        expect(marker1, isNonNegative);
        expect(marker2, greaterThan(marker1));
        expect(result.text, contains('עוף בגריל'));
        expect(result.text, contains('סלט קיסר'));
      },
      skip: fixtureSkipReason,
    );
  });
}
