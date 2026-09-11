import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/keto_lens/domain/models/verdict_badge.dart';
import 'package:fantastic/features/keto_lens/presentation/widgets/verdict_badge_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  Chip chipOf(WidgetTester tester) => tester.widget<Chip>(find.byType(Chip));

  group('VerdictBadgeWidget variants', () {
    testWidgets('cleanKeto renders green with the clean label', (tester) async {
      await pumpApp(
        tester,
        const VerdictBadgeWidget(badge: VerdictBadge.cleanKeto),
      );

      expect(find.text('קטו נקי'), findsOneWidget);
      expect(chipOf(tester).backgroundColor, AppTheme.success);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('caution renders amber with the caution label', (tester) async {
      await pumpApp(
        tester,
        const VerdictBadgeWidget(badge: VerdictBadge.cautionQuantityDependent),
      );

      expect(find.text('זהירות — תלוי כמות'), findsOneWidget);
      expect(chipOf(tester).backgroundColor, AppTheme.caution);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('nonKeto renders red with the refusal label', (tester) async {
      await pumpApp(
        tester,
        const VerdictBadgeWidget(badge: VerdictBadge.nonKeto),
      );

      expect(find.text('לא קטו'), findsOneWidget);
      expect(chipOf(tester).backgroundColor, AppTheme.danger);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('every badge value renders', (tester) async {
      // A value added to the enum without a case here would throw at
      // build time rather than at compile time, since the switches are
      // expressions over an enum and stay exhaustive - this catches the
      // case where someone adds a value and a default arm together.
      for (final badge in VerdictBadge.values) {
        await pumpApp(tester, VerdictBadgeWidget(badge: badge));

        expect(find.byType(Chip), findsOneWidget, reason: '$badge');
        expect(find.byKey(const Key('verdict_badge')), findsOneWidget);
      }
    });
  });

  group('VerdictBadgeWidget does not over-claim', () {
    testWidgets('a clean badge with nothing recognised says so', (
      tester,
    ) async {
      // A wheat-flour wafer: no rule matched, in either direction. Green
      // is right - nothing bad was found - but "clean keto" is not.
      await pumpApp(
        tester,
        const VerdictBadgeWidget(
          badge: VerdictBadge.cleanKeto,
          recognisedNothing: true,
        ),
      );

      expect(find.text('לא נמצאו רכיבים בעייתיים'), findsOneWidget);
      expect(find.text('קטו נקי'), findsNothing);
    });

    testWidgets('the flag is ignored for a flagged verdict', (tester) async {
      // A flagged verdict recognised something by definition.
      await pumpApp(
        tester,
        const VerdictBadgeWidget(
          badge: VerdictBadge.nonKeto,
          recognisedNothing: true,
        ),
      );

      expect(find.text('לא קטו'), findsOneWidget);
    });
  });

  group('VerdictBadgeWidget colour choices', () {
    test('every colour comes from AppTheme, not a raw hex', () {
      // Not `const`: Color overrides == without a primitive equality, so
      // a const Set of them does not compile.
      final palette = <Color>{
        AppTheme.success,
        AppTheme.caution,
        AppTheme.danger,
      };

      for (final badge in VerdictBadge.values) {
        expect(palette, contains(VerdictBadgeWidget.colourFor(badge)));
      }
    });

    test('no two badges share a colour', () {
      final colours = VerdictBadge.values
          .map(VerdictBadgeWidget.colourFor)
          .toSet();

      expect(colours, hasLength(VerdictBadge.values.length));
    });

    test('no two badges share an icon', () {
      // Colour alone must not carry the verdict.
      final icons = VerdictBadge.values.map(VerdictBadgeWidget.iconFor).toSet();

      expect(icons, hasLength(VerdictBadge.values.length));
    });

    test('the ink on the yellow caution fill is dark, not white', () {
      // #FFD60A with white text is unreadable.
      expect(
        VerdictBadgeWidget.inkFor(VerdictBadge.cautionQuantityDependent),
        AppTheme.primary,
      );
    });

    test('every label is non-empty and in Hebrew', () {
      final hebrew = RegExp(r'[֐-׿]');

      for (final badge in VerdictBadge.values) {
        final label = VerdictBadgeWidget.labelFor(badge);

        expect(label, isNotEmpty);
        expect(hebrew.hasMatch(label), isTrue, reason: label);
      }
      expect(
        hebrew.hasMatch(
          VerdictBadgeWidget.labelFor(
            VerdictBadge.cleanKeto,
            recognisedNothing: true,
          ),
        ),
        isTrue,
      );
    });

    test('no two badges share a label', () {
      final labels = VerdictBadge.values
          .map((b) => VerdictBadgeWidget.labelFor(b))
          .toSet();

      expect(labels, hasLength(VerdictBadge.values.length));
    });
  });
}
