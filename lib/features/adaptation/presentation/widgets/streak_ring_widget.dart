import 'dart:math' as math;

import 'package:fantastic/core/constants/keto_constants.dart';
import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/core/time/today_tracker.dart';
import 'package:fantastic/features/adaptation/application/adaptation_phase_service.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:fantastic/features/adaptation/application/providers/streak_providers.dart';
import 'package:fantastic/features/dashboard/application/keto_ratio_calculator.dart';
import 'package:fantastic/features/dashboard/application/providers/daily_log_providers.dart';
import 'package:fantastic/features/adaptation/presentation/widgets/streak_ring_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The dashboard's centrepiece: an arc that fills with the day's keto ratio,
/// with the streak day count in the middle.
///
/// Two numbers in one glyph, deliberately. The arc is *today* — how close the
/// day's ratio is to [KetoConstants.targetKetoRatioIdeal]. The number is
/// *history* — how many compliant days are behind it. A user checks the arc
/// several times a day and the number once.
class StreakRingWidget extends ConsumerWidget {
  const StreakRingWidget({
    required this.date,
    this.clock = DateTime.now,
    super.key,
  });

  /// Pass a date-only value — `todaysDailyLogProvider` is keyed on it, and a
  /// wall-clock time recomputed each build would refetch forever.
  final DateTime date;

  /// The clock seam, used only to ask whether a grace window has closed.
  ///
  /// Production reads the real one; a test places a window in the past
  /// without sleeping. A widget parameter rather than a provider: `CLAUDE.md`
  /// records that reconciliation is applied on write precisely so
  /// `DateTime.now()` never enters a provider. Reading the clock to decide
  /// what to *paint* persists nothing and does not change that.
  final Clock clock;

  /// Painted size. Fixed so the loading placeholder reserves exactly the
  /// space the ring will take and the dashboard does not jump when it lands.
  static const double diameter = 140;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakStateProvider);
    final logAsync = ref.watch(todaysDailyLogProvider(date));

    // Loading and failure both reserve the space rather than collapsing. The
    // streak is not worth an error message of its own — the macro card above
    // already reports a failed read, and two would say the same thing twice.
    //
    // Failure is checked first, and this order is load-bearing: riverpod 3
    // reports a provider that failed before ever producing a value as
    // `AsyncLoading` with an error attached, so both flags are true at once.
    // Checking `isLoading` first leaves a spinner turning forever on a
    // failure that has already happened.
    if (streakAsync.hasError || logAsync.hasError) {
      return const _RingSpace();
    }
    // `!hasValue`, not `isLoading` alone. A refresh — which is what
    // `invalidate(todaysDailyLogProvider)` after every meal write produces —
    // is `isLoading` *with the previous value still attached*, so the plain
    // check swapped the ring for a spinner on every save and then replayed
    // the 600 ms sweep from zero. Keep painting what is already known and let
    // the arc animate to the new value.
    if ((streakAsync.isLoading && !streakAsync.hasValue) ||
        (logAsync.isLoading && !logAsync.hasValue)) {
      return const StreakRingSkeleton();
    }

    final log = logAsync.value;
    final ratio = log == null
        ? 0.0
        : ref
              .watch(ketoRatioCalculatorProvider)
              .calculate(
                fat: log.totalFatG,
                netCarbs: log.totalNetCarbsG,
                protein: log.totalProteinG,
              );

    return _Ring(ratio: ratio, days: _days(streakAsync.value));
  }

  /// The streak the user actually still has.
  ///
  /// Reconciliation runs on write, not on read, so after a grace window
  /// closes the stored `currentStreak` is the **pre-breach** number until the
  /// next logged meal — a streak the user has already lost, shown as current,
  /// which then dropped without explanation the moment they logged anything
  /// (#308).
  ///
  /// **Only an expired window is the stale case.** `inGracePeriod` with a
  /// *future* `gracePeriodEnd` is the legitimate one and must show the real
  /// count: a breached day is not a skipped day, and that window is precisely
  /// what the breach bought. `AdaptationPhaseService.hasExpired` is asked
  /// rather than a comparison written here, so the display cannot drift from
  /// the write path that owns the rule.
  ///
  /// **Nothing is persisted.** This corrects the number on screen; the stored
  /// `StreakState` is untouched until the user's next logged meal, when
  /// `AdaptationPhaseService.recomputeFor` does the real work. The display and
  /// the store are deliberately allowed to disagree for that window.
  int _days(StreakState? streak) {
    if (streak == null) {
      return 0;
    }
    return AdaptationPhaseService.hasExpired(streak, clock())
        ? 0
        : streak.currentStreak;
  }
}

/// A [StreakRingWidget.diameter] box, optionally holding [child].
class _RingSpace extends StatelessWidget {
  const _RingSpace({this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: StreakRingWidget.diameter,
    child: child == null ? null : Center(child: child),
  );
}

class _Ring extends StatelessWidget {
  const _Ring({required this.ratio, required this.days});

  final double ratio;
  final int days;

  @override
  Widget build(BuildContext context) {
    final fill = StreakRingPainter.fillFor(ratio);
    final colour = StreakRingPainter.colourFor(ratio);

    return _RingSpace(
      // Animates the fill rather than the ratio, so the arc always sweeps at
      // one speed regardless of how far past the target the ratio went.
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: fill),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, animatedFill, child) => CustomPaint(
          size: const Size.square(StreakRingWidget.diameter),
          painter: StreakRingPainter(
            fill: animatedFill,
            colour: colour,
            trackColour: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: child,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$days',
                style: Theme.of(context).textTheme.headlineMedium,
                // A bare digit run, so it reads left-to-right inside the RTL
                // layout — '12' must not render as '21'.
                textDirection: TextDirection.ltr,
              ),
              Text(
                days == 1 ? 'יום' : 'ימים',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws the track and the filled arc.
///
/// Public, and its two rules are static, so a widget test can assert the fill
/// fraction and the colour directly instead of reading pixels back off a
/// rendered canvas.
@visibleForTesting
class StreakRingPainter extends CustomPainter {
  const StreakRingPainter({
    required this.fill,
    required this.colour,
    required this.trackColour,
  });

  /// How much of the ring is filled, in `[0, 1]`.
  final double fill;
  final Color colour;
  final Color trackColour;

  static const double _strokeWidth = 12;

  /// The ring is full at [KetoConstants.targetKetoRatioIdeal] and stays full
  /// above it — a ratio of 6 is not six times as good as 2, and an arc that
  /// kept growing would have nowhere to go.
  static double fillFor(double ratio) =>
      (ratio / KetoConstants.targetKetoRatioIdeal).clamp(0.0, 1.0);

  /// Green at or above the ideal, amber from the minimum up to it, red below.
  ///
  /// Both boundaries are inclusive at the top of their band, matching the
  /// convention everywhere else in the app: hitting a target meets it. The
  /// thresholds are `KetoConstants`, not the 1.0/2.0 the issue names — 1.5 is
  /// what `targetKetoRatioMin` has said since M0.
  static Color colourFor(double ratio) {
    if (ratio >= KetoConstants.targetKetoRatioIdeal) {
      return AppTheme.success;
    }
    if (ratio >= KetoConstants.targetKetoRatioMin) {
      return AppTheme.caution;
    }
    return AppTheme.danger;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - _strokeWidth) / 2,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, stroke..color = trackColour);
    if (fill > 0) {
      // From twelve o'clock, clockwise. Clockwise even in RTL: a progress
      // ring is read as a clock face, not as text, and mirroring it would
      // make it read as counting down.
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * fill,
        false,
        stroke..color = colour,
      );
    }
  }

  @override
  bool shouldRepaint(StreakRingPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.colour != colour ||
      oldDelegate.trackColour != trackColour;
}
