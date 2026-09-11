import 'package:fantastic/core/constants/keto_constants.dart';
import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/core/theme/keto_ratio_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bandFor', () {
    test('the ideal is met — the boundary is inclusive', () {
      expect(
        KetoRatioPalette.bandFor(KetoConstants.targetKetoRatioIdeal),
        KetoRatioBand.met,
      );
    });

    test('above the ideal is met', () {
      expect(KetoRatioPalette.bandFor(2.6), KetoRatioBand.met);
    });

    test('the minimum is approaching — the boundary is inclusive', () {
      expect(
        KetoRatioPalette.bandFor(KetoConstants.targetKetoRatioMin),
        KetoRatioBand.approaching,
      );
    });

    test('just under the minimum is below', () {
      expect(KetoRatioPalette.bandFor(1.49), KetoRatioBand.below);
    });

    test('zero is below', () {
      expect(KetoRatioPalette.bandFor(0), KetoRatioBand.below);
    });

    test('a negative ratio is below', () {
      expect(KetoRatioPalette.bandFor(-3), KetoRatioBand.below);
    });

    // Every comparison against NaN is false, so the chain falls through. That
    // is the right answer and it is checked rather than trusted: a NaN ratio
    // reading as "target met" is the failure `NumericInput.positiveFinite`
    // exists to prevent elsewhere.
    test('NaN is below, not met', () {
      expect(KetoRatioPalette.bandFor(double.nan), KetoRatioBand.below);
    });

    test('infinity is met', () {
      expect(KetoRatioPalette.bandFor(double.infinity), KetoRatioBand.met);
    });
  });

  test('colourFor, iconFor and labelFor agree with bandFor for every band', () {
    const expected = {
      KetoRatioBand.met: (2.6, AppTheme.success, Icons.check_circle_outline),
      KetoRatioBand.approaching: (1.7, AppTheme.caution, Icons.trending_up),
      KetoRatioBand.below: (0.9, AppTheme.danger, Icons.error_outline),
    };

    // Every band is covered, so adding a fourth fails here rather than
    // silently rendering the first one that matches.
    expect(expected.keys.toSet(), KetoRatioBand.values.toSet());

    final labels = <String>{};
    for (final entry in expected.entries) {
      final (ratio, colour, icon) = entry.value;
      expect(KetoRatioPalette.bandFor(ratio), entry.key, reason: '$ratio');
      expect(KetoRatioPalette.colourFor(ratio), colour, reason: '$ratio');
      expect(KetoRatioPalette.iconFor(ratio), icon, reason: '$ratio');
      labels.add(KetoRatioPalette.labelFor(ratio));
    }

    // Three distinct labels, so no two bands announce themselves the same.
    expect(labels, hasLength(KetoRatioBand.values.length));
  });

  test('the three icons are distinct glyphs, not three of one', () {
    final icons = {
      for (final ratio in [0.9, 1.7, 2.6]) KetoRatioPalette.iconFor(ratio),
    };
    expect(icons, hasLength(3));
  });
}
