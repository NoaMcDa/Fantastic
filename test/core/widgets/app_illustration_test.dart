import 'package:fantastic/core/widgets/app_illustration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

const Color _muted = Color(0xFF8E8E93);

void main() {
  group('KetoPlateIllustration', () {
    testWidgets('keeps its design aspect ratio', (tester) async {
      await pumpApp(tester, const KetoPlateIllustration(width: 200));

      expect(
        tester.getSize(find.byType(KetoPlateIllustration)),
        const Size(200, 200 * 300 / 320),
      );
    });

    // #69 asks for an `Image.asset` of a file that does not exist. The whole
    // point of drawing it is that nothing is loaded.
    testWidgets('loads no image asset', (tester) async {
      await pumpApp(tester, const KetoPlateIllustration(width: 200));

      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('EmptyPlateIllustration', () {
    testWidgets('keeps its design aspect ratio', (tester) async {
      await pumpApp(
        tester,
        const EmptyPlateIllustration(color: _muted, width: 120),
      );

      expect(
        tester.getSize(find.byType(EmptyPlateIllustration)),
        const Size(120, 100),
      );
    });

    testWidgets('paints at a small size without throwing', (tester) async {
      await pumpApp(
        tester,
        const EmptyPlateIllustration(color: _muted, width: 24),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('UnrecordedScalesIllustration', () {
    testWidgets('keeps its design aspect ratio', (tester) async {
      await pumpApp(
        tester,
        const UnrecordedScalesIllustration(color: _muted, width: 120),
      );

      expect(
        tester.getSize(find.byType(UnrecordedScalesIllustration)),
        const Size(120, 100),
      );
    });

    testWidgets('paints at a small size without throwing', (tester) async {
      await pumpApp(
        tester,
        const UnrecordedScalesIllustration(color: _muted, width: 24),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
