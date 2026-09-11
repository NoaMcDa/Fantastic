import 'package:fantastic/features/diary/domain/models/macro_source.dart';
import 'package:fantastic/features/diary/presentation/macro_source_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('badgeLabel', () {
    // A meal the user typed needs no explanation, and a badge on every card
    // is a badge nobody reads.
    test('manual has none', () {
      expect(MacroSource.manual.badgeLabel, isNull);
    });

    test('a scanned label says so', () {
      expect(MacroSource.scannedLabel.badgeLabel, 'מתווית');
    });

    // On a card "estimate" is the whole of what matters; text-versus-photo is
    // noise there and detail in the announcement.
    test('both estimated sources share one label', () {
      expect(MacroSource.estimatedFromText.badgeLabel, 'הערכה');
      expect(MacroSource.estimatedFromPhoto.badgeLabel, 'הערכה');
    });
  });

  group('badgeDescription', () {
    test('manual has none', () {
      expect(MacroSource.manual.badgeDescription, isNull);
    });

    test('the two estimated sources are announced differently', () {
      expect(
        MacroSource.estimatedFromText.badgeDescription,
        'הערכים חושבו מתיאור הארוחה',
      );
      expect(
        MacroSource.estimatedFromPhoto.badgeDescription,
        'הערכים חושבו מתמונת הארוחה',
      );
    });

    test('a scanned label is announced as read, not estimated', () {
      expect(
        MacroSource.scannedLabel.badgeDescription,
        'הערכים נקראו מתווית המוצר',
      );
    });
  });

  group('badgeIcon', () {
    test('manual has none', () {
      expect(MacroSource.manual.badgeIcon, isNull);
    });

    // Asked through `isEstimate` rather than by re-listing the two estimated
    // values, so the badge and the diary cannot come to disagree about what
    // an estimate is.
    test('every estimate shares one icon, and a read label does not', () {
      expect(
        MacroSource.estimatedFromText.badgeIcon,
        MacroSource.estimatedFromPhoto.badgeIcon,
      );
      expect(
        MacroSource.scannedLabel.badgeIcon,
        isNot(MacroSource.estimatedFromText.badgeIcon),
      );
    });
  });

  // A fifth `MacroSource` must fail to compile in `macro_source_copy.dart`
  // rather than fall through to null. These assert the other half: that
  // nothing in the enum was left unhandled *today*.
  group('every source is handled', () {
    for (final source in MacroSource.values) {
      test(
        '${source.name} has a label iff it has a description and an icon',
        () {
          expect(
            source.badgeLabel == null,
            source.badgeDescription == null,
            reason:
                'a badge with no announcement is unusable to a screen reader',
          );
          expect(source.badgeLabel == null, source.badgeIcon == null);
        },
      );
    }

    test('exactly one source shows no badge', () {
      expect(MacroSource.values.where((s) => s.badgeLabel == null), [
        MacroSource.manual,
      ]);
    });

    test('no label is blank', () {
      for (final source in MacroSource.values) {
        final label = source.badgeLabel;
        if (label != null) {
          expect(label.trim(), isNotEmpty, reason: source.name);
        }
      }
    });

    test(
      'every icon is an outline-or-filled IconData, never a null fallback',
      () {
        for (final source in MacroSource.values.where(
          (s) => s != MacroSource.manual,
        )) {
          expect(source.badgeIcon, isA<IconData>(), reason: source.name);
        }
      },
    );
  });
}
