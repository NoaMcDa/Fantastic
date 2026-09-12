/// The app's illustrations, drawn as vectors rather than shipped as images.
///
/// `OnboardingScreen1` records why there is no `assets/images/*.png` here: a
/// placeholder binary "cannot be reviewed, it ignores the dark palette, and it
/// is replaced wholesale the day a real illustration exists". Drawing them
/// keeps all three properties — the geometry is diffable, the muted tones come
/// from the caller's theme, and they stay sharp at any size — and it adds no
/// dependency, which matters because a new package would mean regenerating
/// `pubspec.lock`.
///
/// Each painter works in the design space its artwork was drawn in and is
/// scaled to fit, so the coordinates below match the source drawing exactly.
/// They were generated from it rather than transcribed.
library;

import 'dart:math' as math;

import 'package:fantastic/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Scales a fixed design-space drawing to whatever size it is given.
abstract class _IllustrationPainter extends CustomPainter {
  const _IllustrationPainter();

  /// The coordinate space [paintDesign] draws in.
  Size get designSize;

  void paintDesign(Canvas canvas);

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / designSize.width);
    paintDesign(canvas);
    canvas.restore();
  }

  /// Draws [path] as a dashed stroke.
  ///
  /// Flutter has no dash support on [Paint], and the dashes carry meaning
  /// here: an unbroken ring reads as a drawn plate, a broken one as a space
  /// waiting to be filled.
  static void dashed(
    Canvas canvas,
    Path path,
    Paint paint, {
    double dash = 5,
    double gap = 9,
  }) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }
}

/// The keto plate on the onboarding welcome screen.
///
/// Four foods the app's own ingredient rules approve, arranged on a plate:
/// the ribeye is the app mark's own cut, so the first screen and the icon
/// read as one family.
class KetoPlateIllustration extends StatelessWidget {
  const KetoPlateIllustration({this.width = 240, super.key});

  final double width;

  static const Size _design = Size(320, 300);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: width * _design.height / _design.width,
    child: const CustomPaint(painter: _KetoPlatePainter()),
  );
}

class _KetoPlatePainter extends _IllustrationPainter {
  const _KetoPlatePainter();

  static const Color _meat = Color(0xFFE0342A);
  static const Color _eggWhite = Color(0xFFF2E8DC);
  static const Color _yolkLight = Color(0xFFFFC65C);
  static const Color _leafDark = Color(0xFF1E7D3A);
  static const Color _pit = Color(0xFF5C2E14);
  static const Color _rim = Color(0xFF3A3A3C);

  @override
  Size get designSize => KetoPlateIllustration._design;

  @override
  void paintDesign(Canvas canvas) {
    const centre = Offset(160, 150);

    canvas
      ..drawCircle(
        centre,
        134,
        Paint()..color = AppTheme.accent.withValues(alpha: 0.07),
      )
      ..drawCircle(centre, 112, Paint()..color = AppTheme.surface)
      ..drawCircle(
        centre,
        112,
        Paint()
          ..color = _rim
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      )
      ..drawCircle(
        centre,
        94,
        Paint()
          ..color = _rim.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

    _ribeye(canvas);
    _egg(canvas);
    _avocado(canvas);
    _greens(canvas);

    // Olive oil, in the open band between the two rows of food. On the meat
    // it reads as a stray dot rather than a drizzle.
    for (final (offset, radius, alpha) in const [
      (Offset(166, 176), 4.5, 0.85),
      (Offset(190, 167), 3.0, 0.65),
    ]) {
      canvas.drawCircle(
        offset,
        radius,
        Paint()..color = AppTheme.accent.withValues(alpha: alpha),
      );
    }
  }

  void _ribeye(Canvas canvas) {
    canvas
      ..save()
      ..translate(118, 110)
      ..rotate(-8 * math.pi / 180);

    final cut = Path()
      ..moveTo(-44, 6)
      ..cubicTo(-44, -14, -30, -28, -10, -34)
      ..cubicTo(16, -42, 50, -41, 70, -32)
      ..cubicTo(88, -25, 96, -12, 92, 2)
      ..cubicTo(97, 16, 92, 30, 76, 40)
      ..cubicTo(64, 46, 51, 43, 39, 47)
      ..cubicTo(24, 52, 8, 50, -5, 48)
      ..cubicTo(-25, 45, -40, 31, -44, 6)
      ..close();

    final fatCap = Path()
      ..moveTo(-44, 6)
      ..cubicTo(-44, -14, -30, -28, -10, -34)
      ..cubicTo(16, -42, 50, -41, 70, -32)
      ..cubicTo(88, -25, 96, -12, 92, 2)
      ..cubicTo(87, -6, 84, -13, 76, -18)
      ..cubicTo(61, -27, 44, -29, 27, -28)
      ..cubicTo(10, -26, -2, -21, -12, -15)
      ..cubicTo(-21, -9, -31, -5, -38, -3)
      ..cubicTo(-41, -1, -43, 1, -44, 6)
      ..close();

    final marbling = Paint()
      ..color = _eggWhite.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas
      ..drawPath(cut, Paint()..color = _meat)
      ..drawPath(fatCap, Paint()..color = AppTheme.accent)
      ..drawPath(
        Path()
          ..moveTo(-16, 14)
          ..cubicTo(-4, 6, 14, 4, 30, 8),
        marbling,
      )
      ..drawPath(
        Path()
          ..moveTo(-10, 30)
          ..cubicTo(4, 24, 22, 23, 38, 26),
        marbling,
      )
      ..restore();
  }

  void _egg(Canvas canvas) {
    canvas
      ..save()
      ..translate(212, 118)
      ..drawPath(
        Path()
          ..moveTo(0, -32)
          ..cubicTo(20, -34, 36, -22, 38, -4)
          ..cubicTo(40, 14, 28, 30, 8, 33)
          ..cubicTo(-12, 36, -30, 26, -34, 8)
          ..cubicTo(-38, -12, -20, -30, 0, -32)
          ..close(),
        Paint()..color = _eggWhite,
      )
      ..drawCircle(const Offset(2, 0), 15, Paint()..color = AppTheme.accent)
      ..drawCircle(
        const Offset(-3, -5),
        5,
        Paint()..color = _yolkLight.withValues(alpha: 0.85),
      )
      ..restore();
  }

  void _avocado(Canvas canvas) {
    canvas
      ..save()
      ..translate(116, 200)
      ..rotate(12 * math.pi / 180)
      ..drawOval(
        Rect.fromCenter(center: Offset.zero, width: 68, height: 84),
        Paint()..color = _leafDark,
      )
      ..drawOval(
        Rect.fromCenter(center: Offset.zero, width: 52, height: 68),
        Paint()..color = AppTheme.success,
      )
      ..drawOval(
        Rect.fromCenter(center: const Offset(0, 2), width: 26, height: 30),
        Paint()..color = _pit,
      )
      ..restore();
  }

  void _greens(Canvas canvas) {
    final vein = Paint()
      ..color = _leafDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas
      ..save()
      ..translate(208, 202)
      ..drawPath(
        Path()
          ..moveTo(-18, 16)
          ..cubicTo(-22, -2, -8, -16, 22, -20)
          ..cubicTo(18, 6, 4, 18, -18, 16)
          ..close(),
        Paint()..color = AppTheme.success,
      )
      ..drawPath(
        Path()
          ..moveTo(-18, 16)
          ..cubicTo(-6, 6, 6, -4, 22, -20),
        vein,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _KetoPlatePainter oldDelegate) => false;
}

/// A day with no meals: an empty plate, its centre waiting to be filled.
///
/// The gold `+` echoes the subtitle's "tap +", which points at the screen's
/// FAB. It is drawn, not a button — [EmptyStateWidget] deliberately offers no
/// action of its own here, and two affordances would compete.
class EmptyPlateIllustration extends StatelessWidget {
  const EmptyPlateIllustration({
    required this.color,
    this.width = 96,
    super.key,
  });

  /// The muted tone, passed in so the drawing follows the theme exactly as the
  /// [Icon] it replaced did.
  final Color color;

  final double width;

  static const Size _design = Size(240, 200);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: width * _design.height / _design.width,
    child: CustomPaint(painter: _EmptyPlatePainter(color)),
  );
}

class _EmptyPlatePainter extends _IllustrationPainter {
  const _EmptyPlatePainter(this.color);

  final Color color;

  @override
  Size get designSize => EmptyPlateIllustration._design;

  @override
  void paintDesign(Canvas canvas) {
    const centre = Offset(120, 100);
    final cutlery = Paint()..color = color.withValues(alpha: 0.5);

    canvas
      ..drawCircle(centre, 66, Paint()..color = AppTheme.surface)
      ..drawCircle(
        centre,
        66,
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

    _IllustrationPainter.dashed(
      canvas,
      Path()..addOval(Rect.fromCircle(center: centre, radius: 44)),
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    final plus = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas
      ..drawLine(const Offset(120, 88), const Offset(120, 112), plus)
      ..drawLine(const Offset(108, 100), const Offset(132, 100), plus);

    // Fork: three tines, the shoulder that joins them, then the handle.
    for (final x in const [27.0, 34.0, 41.0]) {
      canvas.drawRRect(
        RRect.fromLTRBR(x, 50, x + 4.5, 72, const Radius.circular(2.25)),
        cutlery,
      );
    }
    canvas
      ..drawRRect(
        RRect.fromLTRBR(27, 68, 45.5, 79, const Radius.circular(5.5)),
        cutlery,
      )
      ..drawRRect(
        RRect.fromLTRBR(32.5, 77, 40, 121, const Radius.circular(3.75)),
        cutlery,
      )
      // Knife: blade, then handle.
      ..drawPath(
        Path()
          ..moveTo(200, 50)
          ..cubicTo(209.5, 60, 211.5, 78, 209, 95)
          ..lineTo(199, 95)
          ..lineTo(199, 52)
          ..cubicTo(199, 50.5, 199.5, 49.5, 200, 50)
          ..close(),
        cutlery,
      )
      ..drawRRect(
        RRect.fromLTRBR(199.5, 94, 207, 122, const Radius.circular(3.75)),
        cutlery,
      );
  }

  @override
  bool shouldRepaint(covariant _EmptyPlatePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// A day with no symptoms logged: the five scales, each an unfilled dot.
///
/// Five because that is how many scales [SymptomLog] carries, so the drawing
/// says what is missing rather than decorating the absence. The rightmost is
/// accented because right is where the row starts in Hebrew.
class UnrecordedScalesIllustration extends StatelessWidget {
  const UnrecordedScalesIllustration({
    required this.color,
    this.width = 96,
    super.key,
  });

  /// The muted tone, from the caller's theme.
  final Color color;

  final double width;

  static const Size _design = Size(240, 200);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: width * _design.height / _design.width,
    child: CustomPaint(painter: _UnrecordedScalesPainter(color)),
  );
}

class _UnrecordedScalesPainter extends _IllustrationPainter {
  const _UnrecordedScalesPainter(this.color);

  final Color color;

  @override
  Size get designSize => UnrecordedScalesIllustration._design;

  @override
  void paintDesign(Canvas canvas) {
    final card = RRect.fromLTRBR(34, 52, 206, 148, const Radius.circular(18));

    canvas
      ..drawRRect(card, Paint()..color = AppTheme.surface)
      ..drawRRect(
        card,
        Paint()
          ..color = color.withValues(alpha: 0.42)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

    final unfilled = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (final x in const [58.0, 89.0, 120.0, 151.0]) {
      canvas.drawCircle(Offset(x, 94), 11, unfilled);
    }
    canvas.drawCircle(
      const Offset(182, 94),
      11,
      Paint()
        ..color = AppTheme.accent.withValues(alpha: 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    _IllustrationPainter.dashed(
      canvas,
      Path()
        ..moveTo(56, 124)
        ..lineTo(184, 124),
      Paint()
        ..color = color.withValues(alpha: 0.33)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _UnrecordedScalesPainter oldDelegate) =>
      oldDelegate.color != color;
}
