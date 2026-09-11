import 'package:fantastic/features/menu/domain/models/menu_pages_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MenuPagesText.readNothing', () {
    test('is true for empty text', () {
      expect(const MenuPagesText(text: '', pageCount: 1).readNothing, isTrue);
    });

    test('is true for whitespace-only text', () {
      expect(
        const MenuPagesText(text: '   \n\t  ', pageCount: 1).readNothing,
        isTrue,
      );
    });

    test('is false when a page produced real text', () {
      expect(
        const MenuPagesText(text: 'סטייק', pageCount: 1).readNothing,
        isFalse,
      );
    });
  });

  group('MenuPagesText defaults', () {
    test('unreadPages defaults to empty and ocrUnavailable to false', () {
      const pages = MenuPagesText(text: 'סלט', pageCount: 1);

      expect(pages.unreadPages, isEmpty);
      expect(pages.ocrUnavailable, isFalse);
    });
  });

  group('MenuPagesText.copyWith', () {
    const pages = MenuPagesText(
      text: 'עמוד אחד',
      pageCount: 1,
      unreadPages: [2],
      ocrUnavailable: false,
    );

    test('replaces each field', () {
      final changed = pages.copyWith(
        text: 'עמוד אחר',
        pageCount: 3,
        unreadPages: [1, 2],
        ocrUnavailable: true,
      );

      expect(changed.text, 'עמוד אחר');
      expect(changed.pageCount, 3);
      expect(changed.unreadPages, [1, 2]);
      expect(changed.ocrUnavailable, isTrue);
    });

    test('with no argument preserves every field', () {
      expect(pages.copyWith(), pages);
    });
  });

  group('equality', () {
    test('two instances with equal-but-not-identical lists are equal', () {
      // Built as runtime locals rather than const literals: const would
      // canonicalise the two lists into one object and defeat the test.
      final firstPages = <int>[1];
      final secondPages = <int>[1];
      final a = MenuPagesText(
        text: 'סלט',
        pageCount: 2,
        unreadPages: firstPages,
      );
      final b = MenuPagesText(
        text: 'סלט',
        pageCount: 2,
        unreadPages: secondPages,
      );

      expect(identical(a.unreadPages, b.unreadPages), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when unreadPages differs', () {
      const a = MenuPagesText(text: 'סלט', pageCount: 2, unreadPages: [1]);
      const b = MenuPagesText(text: 'סלט', pageCount: 2, unreadPages: [2]);

      expect(a, isNot(b));
    });

    test('differs when ocrUnavailable differs', () {
      const a = MenuPagesText(text: '', pageCount: 0, ocrUnavailable: false);
      const b = MenuPagesText(text: '', pageCount: 0, ocrUnavailable: true);

      expect(a, isNot(b));
    });
  });
}
