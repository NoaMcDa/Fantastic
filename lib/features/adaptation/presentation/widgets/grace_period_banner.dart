import 'dart:async';

import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/adaptation/application/adaptation_phase_service.dart';
import 'package:fantastic/features/adaptation/application/providers/streak_providers.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A warning shown while the user is inside the 24-hour grace period, with
/// the time left before the streak resets.
///
/// Occupies no space at all when there is nothing to warn about, so it can be
/// placed unconditionally at the top of a screen.
class GracePeriodBanner extends ConsumerStatefulWidget {
  const GracePeriodBanner({super.key});

  @override
  ConsumerState<GracePeriodBanner> createState() => _GracePeriodBannerState();
}

class _GracePeriodBannerState extends ConsumerState<GracePeriodBanner> {
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Runs the countdown only while it is on screen.
  ///
  /// Called from `build`, which is safe — starting or cancelling a timer is
  /// not a state mutation. A timer left running while the banner is hidden
  /// would rebuild a `SizedBox.shrink` once a minute for the life of the app,
  /// which is the common case: most days have no grace period at all.
  void _tickWhile({required bool visible}) {
    if (visible && _ticker == null) {
      _ticker = Timer.periodic(
        const Duration(minutes: 1),
        (_) => setState(() {}),
      );
    } else if (!visible) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final streak = ref.watch(streakStateProvider).value;
    final endsAt = _graceEnd(streak);

    _tickWhile(visible: endsAt != null);
    if (endsAt == null) {
      return const SizedBox.shrink();
    }

    return _Banner(remaining: endsAt.difference(DateTime.now()));
  }

  /// When the open grace period ends, or null if there is none.
  ///
  /// Loading and failure both read as "no banner". A storage failure is the
  /// wrong moment to tell someone their streak is about to reset — the claim
  /// would be unfounded, and the screens this sits on report a failed read
  /// themselves.
  static DateTime? _graceEnd(StreakState? streak) {
    if (streak == null || !streak.inGracePeriod) {
      return null;
    }
    return streak.gracePeriodEnd;
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: AppTheme.danger,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'הרצף שלך בסכנה — ${GracePeriodBannerText.describe(remaining)} עד לאיפוס',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

/// How the banner words the time remaining.
///
/// Its own class rather than a private static, so the wording rules can be
/// asserted at every handover point without pumping a widget and waiting out
/// a clock.
abstract final class GracePeriodBannerText {
  /// The time left, in the largest unit that still says something useful.
  ///
  /// Hours until under an hour is left, then minutes. The issue's
  /// `remaining.inHours` alone truncates, so it reads "0 שעות" for the last
  /// fifty-nine minutes — exactly the stretch where the number matters most.
  ///
  /// Clamped at [AdaptationPhaseService.gracePeriod], because a clock moved
  /// backwards should not promise more time than a grace period can hold, and
  /// at zero, because an expired window is not negative time: the reset lands
  /// on the next evaluation, and until then this reads "פחות מדקה".
  static String describe(Duration remaining) {
    if (remaining >= AdaptationPhaseService.gracePeriod) {
      return '${AdaptationPhaseService.gracePeriod.inHours} שעות';
    }
    if (remaining.inHours >= 1) {
      final hours = remaining.inHours;
      return hours == 1 ? 'שעה' : '$hours שעות';
    }
    if (remaining.inMinutes >= 1) {
      final minutes = remaining.inMinutes;
      return minutes == 1 ? 'דקה' : '$minutes דקות';
    }
    return 'פחות מדקה';
  }
}
