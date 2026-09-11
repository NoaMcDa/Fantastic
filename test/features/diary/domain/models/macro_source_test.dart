import 'package:fantastic/features/diary/domain/models/macro_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MacroSource.isEstimate', () {
    test('is true for both estimated values', () {
      expect(MacroSource.estimatedFromText.isEstimate, isTrue);
      expect(MacroSource.estimatedFromPhoto.isEstimate, isTrue);
    });

    test('is false for a typed meal', () {
      expect(MacroSource.manual.isEstimate, isFalse);
    });

    // A scanned panel is printed figures, not a guess. Badging it as an
    // estimate would be false, and a badge people learn to ignore is worse
    // than no badge.
    test('is false for a scanned label', () {
      expect(MacroSource.scannedLabel.isEstimate, isFalse);
    });
  });

  // Records store `.name`, so renaming a value is a data migration.
  test('the stored names are stable', () {
    expect(MacroSource.values.map((v) => v.name), [
      'manual',
      'scannedLabel',
      'estimatedFromText',
      'estimatedFromPhoto',
    ]);
  });
}
