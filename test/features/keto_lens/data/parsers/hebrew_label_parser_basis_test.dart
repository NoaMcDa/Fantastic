import 'package:fantastic/features/keto_lens/data/parsers/hebrew_label_parser.dart';
import 'package:fantastic/features/keto_lens/domain/models/serving_basis.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';

/// Serving-basis parsing — the half of #257 that decides whether the sheet is
/// allowed to scale anything.
///
/// Kept in its own file rather than folded into `hebrew_label_parser_test.dart`
/// because the question it answers is different: that suite asks "did we read
/// the right number", this one asks "do we know what the number is *per*".
/// Getting the second wrong is the more dangerous failure — a correctly-read
/// figure scaled against the wrong basis is wrong by a factor of three and
/// looks entirely plausible.
void main() {
  const parser = HebrewLabelParser();

  group('serving basis', () {
    test('reads ל-100 גרם as per100g', () {
      expect(
        parser.parse(HebrewLabelFixture.tahini).basis,
        ServingBasis.per100g,
      );
    });

    test('reads a geresh gram abbreviation as per100g', () {
      // The pointed wafer writes `ל-100 גרם` in its header but `גר׳` in its
      // rows; the header is what the basis comes from.
      expect(
        parser.parse(HebrewLabelFixture.pointedWafer).basis,
        ServingBasis.per100g,
      );
    });

    test('reads ל-100 מ"ל as per100ml', () {
      expect(
        parser.parse(HebrewLabelFixture.per100ml).basis,
        ServingBasis.per100ml,
      );
    });

    test('reads למנה as perServing', () {
      expect(
        parser.parse(HebrewLabelFixture.perServingOnly).basis,
        ServingBasis.perServing,
      );
    });

    test('a two-column label is unknown, not a guess', () {
      // The whole point of the enum. Both `ל-100 גרם` and `למנה` appear, so
      // there is no way to know which column any number came from — and
      // choosing one would silently log a figure that is wrong by whatever
      // ratio the serving happens to be.
      expect(
        parser.parse(HebrewLabelFixture.twoColumnBasis).basis,
        ServingBasis.unknown,
      );
    });

    test('a label with no basis at all is unknown', () {
      expect(
        parser.parse(HebrewLabelFixture.unreadable).basis,
        ServingBasis.unknown,
      );
    });

    test('unknown is the default, so nothing that predates #257 scales', () {
      // Guards the migration promise: every ParsedLabel built without a basis
      // — every older fixture, and the parser's own never-throws failure path
      // — keeps M6's behaviour exactly.
      expect(parser.parse('').basis, ServingBasis.unknown);
    });
  });

  group('serving size', () {
    test('reads גודל מנה as servingGrams', () {
      expect(
        parser.parse(HebrewLabelFixture.per100gWithServing).servingGrams,
        30,
      );
    });

    test('a declared serving weight does not make the basis perServing', () {
      // `גודל מנה` contains the letters `ל מנה`. If the per-serving pattern
      // matched across that space, the most useful label in the corpus — one
      // that declares BOTH a per-100 g basis and its serving weight — would
      // be read as already-per-serving and never scaled. That is the failure
      // this assertion exists for.
      final label = parser.parse(HebrewLabelFixture.per100gWithServing);

      expect(label.basis, ServingBasis.per100g);
      expect(label.servingGrams, 30);
    });

    test('is read even when the basis is unknown', () {
      // A two-column label is exactly where the declared weight is most worth
      // showing the user, even though nothing may be scaled by it.
      expect(parser.parse(HebrewLabelFixture.twoColumnBasis).servingGrams, 25);
    });

    test('is null when no serving row was printed', () {
      expect(parser.parse(HebrewLabelFixture.tahini).servingGrams, isNull);
    });
  });

  group('real OCR output', () {
    // Captured engine output rather than hand-written text — see
    // `RealOcrFixture`. A basis rule that only works on strings a person typed
    // is not a basis rule.
    test('every captured label resolves to per100g', () {
      for (final text in [
        RealOcrFixture.tahini,
        RealOcrFixture.proteinBar,
        RealOcrFixture.pointedWafer,
      ]) {
        expect(parser.parse(text).basis, ServingBasis.per100g);
      }
    });
  });
}
