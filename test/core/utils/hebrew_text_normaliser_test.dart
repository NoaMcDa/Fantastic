import 'package:fantastic/core/utils/hebrew_text_normaliser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HebrewTextNormaliser.normalise strips what OCR adds', () {
    test('removes niqqud so a pointed word matches its plain spelling', () {
      // shin + shin-dot, vav + dagesh, mem + qamats, final nun.
      const pointed = 'שׁוּמָן';
      const plain = 'שומן';

      expect(HebrewTextNormaliser.normalise(pointed), plain);
    });

    test('removes cantillation marks', () {
      const cantillated = 'דבר֒ים';

      expect(HebrewTextNormaliser.normalise(cantillated), 'דברים');
    });

    test('removes the bidi marks ML Kit wraps around digit runs', () {
      const wrapped = 'שומן ‏12‎ גר';

      expect(HebrewTextNormaliser.normalise(wrapped), 'שומן 12 גר');
    });

    test('folds every geresh variant onto a plain apostrophe', () {
      for (final geresh in ['׳', '’', '‘', 'ʼ']) {
        expect(
          HebrewTextNormaliser.normalise('גר$geresh'),
          "גר'",
          reason: 'U+${geresh.codeUnitAt(0).toRadixString(16)} not folded',
        );
      }
    });

    test('folds every gershayim variant onto a plain quote', () {
      for (final gershayim in ['״', '“', '”']) {
        expect(HebrewTextNormaliser.normalise('מ$gershayimג'), 'מ"ג');
      }
    });

    test('turns a decimal comma into a decimal point', () {
      expect(HebrewTextNormaliser.normalise('22,5'), '22.5');
    });

    test('leaves a comma that separates two words alone', () {
      // The separator the ingredient list is split on must survive.
      expect(HebrewTextNormaliser.normalise('מלח, מים'), 'מלח, מים');
    });

    test('replaces a maqaf with a space rather than deleting it', () {
      // Deleting it would weld two words into one unmatchable token.
      expect(HebrewTextNormaliser.normalise('שמן־זית'), 'שמן זית');
    });

    test('collapses spaces and a no-break space but keeps newlines', () {
      expect(HebrewTextNormaliser.normalise('a    b\nc   d'), 'a b\nc d');
    });

    test('normalises every line-break flavour to a newline', () {
      expect(HebrewTextNormaliser.normalise('a\r\nb\rc d'), 'a\nb\nc\nd');
    });

    test('trims each line as well as the whole string', () {
      expect(HebrewTextNormaliser.normalise('  a  \n   b   \n  '), 'a\nb');
    });

    test('is idempotent', () {
      const messy = '  שׁוּמָן ‏22,5‎  גר׳ ';
      final once = HebrewTextNormaliser.normalise(messy);

      expect(HebrewTextNormaliser.normalise(once), once);
    });

    test('an empty string normalises to an empty string', () {
      expect(HebrewTextNormaliser.normalise(''), '');
    });
  });

  group('HebrewTextNormaliser.stripPrefix', () {
    test('strips the conjunction from a prefixed ingredient', () {
      // "ve-shemen" -> "shemen"
      expect(HebrewTextNormaliser.stripPrefix('ושמן'), 'שמן');
    });

    test('strips each of the seven inseparable prefixes', () {
      for (final prefix in HebrewTextNormaliser.prefixLetters) {
        // A five-letter stem, so the length guard never fires.
        const stem = 'קנולה';

        expect(HebrewTextNormaliser.stripPrefix('$prefix$stem'), stem);
      }
    });

    test('leaves a token whose first letter is not a prefix', () {
      expect(HebrewTextNormaliser.stripPrefix('קנולה'), 'קנולה');
    });

    test('leaves a short word whose first letter only looks like a prefix', () {
      // "melah" (salt) must not become "lah".
      const salt = 'מלח';

      expect(HebrewTextNormaliser.stripPrefix(salt), salt);
    });

    test('strips at most one letter', () {
      // Two prefixes glued on; only the outer one comes off, because a
      // second strip is as likely to eat a stem letter as a prefix.
      const doubled = 'ובשמן';

      expect(HebrewTextNormaliser.stripPrefix(doubled), 'בשמן');
    });

    test('leaves an empty token', () {
      expect(HebrewTextNormaliser.stripPrefix(''), '');
    });
  });
}
