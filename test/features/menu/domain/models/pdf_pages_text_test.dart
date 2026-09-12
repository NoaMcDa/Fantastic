import 'package:fantastic/features/menu/application/menu_page_reader.dart';
import 'package:fantastic/features/menu/domain/models/pdf_pages_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PdfPagesText.readNothing', () {
    test('is true when pages is empty', () {
      expect(const PdfPagesText(pages: {}, pageCount: 1).readNothing, isTrue);
    });

    test('is true when every page is whitespace-only', () {
      expect(
        const PdfPagesText(pages: {1: '   \n\t  '}, pageCount: 1).readNothing,
        isTrue,
      );
    });

    test('is false when a page produced real text', () {
      expect(
        const PdfPagesText(pages: {1: 'סטייק'}, pageCount: 1).readNothing,
        isFalse,
      );
    });
  });

  group('PdfPagesText defaults', () {
    test('pagesWithoutTextLayer defaults to empty', () {
      const pages = PdfPagesText(pages: {1: 'סלט'}, pageCount: 1);

      expect(pages.pagesWithoutTextLayer, isEmpty);
    });
  });

  group('PdfPagesText.joined', () {
    test('places each page under the same marker MenuPageReader writes', () {
      const pages = PdfPagesText(pages: {1: 'עמוד ראשון'}, pageCount: 1);

      expect(pages.joined, contains(MenuPageReader.pageMarker(1)));
      expect(pages.joined, contains('עמוד ראשון'));
    });

    test('orders pages by page number regardless of map insertion order', () {
      const pages = PdfPagesText(
        pages: {3: 'שלישי', 1: 'ראשון', 2: 'שני'},
        pageCount: 3,
      );

      final markerOne = pages.joined.indexOf(MenuPageReader.pageMarker(1));
      final markerTwo = pages.joined.indexOf(MenuPageReader.pageMarker(2));
      final markerThree = pages.joined.indexOf(MenuPageReader.pageMarker(3));

      expect(markerOne, lessThan(markerTwo));
      expect(markerTwo, lessThan(markerThree));
    });

    test('is empty when there are no pages', () {
      expect(const PdfPagesText(pages: {}, pageCount: 0).joined, isEmpty);
    });

    test('omits pages absent from the map, e.g. those with no text layer', () {
      const pages = PdfPagesText(
        pages: {1: 'עמוד ראשון'},
        pageCount: 2,
        pagesWithoutTextLayer: [2],
      );

      expect(pages.joined, isNot(contains(MenuPageReader.pageMarker(2))));
    });
  });

  group('PdfPagesText.copyWith', () {
    const pages = PdfPagesText(
      pages: {1: 'עמוד אחד'},
      pageCount: 1,
      pagesWithoutTextLayer: [2],
    );

    test('replaces each field', () {
      final changed = pages.copyWith(
        pages: {1: 'עמוד אחר'},
        pageCount: 3,
        pagesWithoutTextLayer: [1, 2],
      );

      expect(changed.pages, {1: 'עמוד אחר'});
      expect(changed.pageCount, 3);
      expect(changed.pagesWithoutTextLayer, [1, 2]);
    });

    test('with no argument preserves every field', () {
      expect(pages.copyWith(), pages);
    });
  });

  group('equality', () {
    test('two instances with equal-but-not-identical maps are equal', () {
      // Built as runtime locals rather than const literals: const would
      // canonicalise the two maps into one object and defeat the test.
      final firstPages = <int, String>{1: 'סלט'};
      final secondPages = <int, String>{1: 'סלט'};
      final a = PdfPagesText(pages: firstPages, pageCount: 1);
      final b = PdfPagesText(pages: secondPages, pageCount: 1);

      expect(identical(a.pages, b.pages), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when pages differs', () {
      const a = PdfPagesText(pages: {1: 'סלט'}, pageCount: 1);
      const b = PdfPagesText(pages: {1: 'מרק'}, pageCount: 1);

      expect(a, isNot(b));
    });

    test('differs when pageCount differs', () {
      const a = PdfPagesText(pages: {1: 'סלט'}, pageCount: 1);
      const b = PdfPagesText(pages: {1: 'סלט'}, pageCount: 2);

      expect(a, isNot(b));
    });

    test('differs when pagesWithoutTextLayer differs', () {
      const a = PdfPagesText(
        pages: {1: 'סלט'},
        pageCount: 2,
        pagesWithoutTextLayer: [2],
      );
      const b = PdfPagesText(
        pages: {1: 'סלט'},
        pageCount: 2,
        pagesWithoutTextLayer: [],
      );

      expect(a, isNot(b));
    });

    test('is not equal to an unrelated object', () {
      const a = PdfPagesText(pages: {1: 'סלט'}, pageCount: 1);

      // ignore: unrelated_type_equality_checks
      expect(a == 'not a PdfPagesText', isFalse);
    });

    test('is identical to itself', () {
      const a = PdfPagesText(pages: {1: 'סלט'}, pageCount: 1);

      expect(a, a);
    });
  });
}
