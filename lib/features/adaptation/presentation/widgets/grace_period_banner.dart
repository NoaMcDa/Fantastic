import 'dart:async';

import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/core/time/today_tracker.dart';
import 'package:fantastic/features/adaptation/application/adaptation_phase_service.dart';
import 'package:fantastic/features/adaptation/application/providers/streak_providers.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the 24-hour grace period is doing: a countdown while it runs, a
/// notice once it has closed.
///
/// Occupies no space at all when there is nothing to say, so it can be placed
/// unconditionally at the top of a screen.
///
/// **Two states, because reconciliation runs on write and not on read.**
/// Nothing persists the reset until the user's next logged meal, so a window
/// that closed six hours ago is still `inGracePeriod: true` on the record.
/// The banner used to report that as a live countdown and
/// [GracePeriodBannerText.describe] fell through to `'פחות מדקה'` for any
/// duration under a minute, negative included — so the user was told their
/// streak would reset within the minute, indefinitely, and both halves of
/// that were false: the window was gone and the reset had not happened
/// either (#308).
///
/// **The expired state is not hidden.** Vanishing is how the user learns
/// nothing, and the number on the ring changing later with no explanation is
/// the failure this issue is fixing rather than reproducing.
class GracePeriodBanner extends ConsumerStatefulWidget {
  const GracePeriodBanner({this.clock = DateTime.now, super.key});

  /// The clock seam. Production reads the real one; a test places a window in
  /// the past without sleeping.
  ///
  /// A widget parameter rather than a provider, deliberately: `CLAUDE.md`
  /// records that reconciliation is applied on write precisely so that
  /// `DateTime.now()` never enters a provider and every widget test that
  /// stubs a `StreakState` stays deterministic. Reading the clock to decide
  /// what to *paint* does not persist anything and does not change that.
  final Clock clock;

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
    final now = widget.clock();

    // Only a live countdown needs the ticker. The expired notice says the
    // same thing every minute, and a timer rebuilding an unchanging widget
    // for the life of the app is what the comment on [_tickWhile] warns
    // against.
    final counting = endsAt != null && !endsAt.isBefore(now);
    _tickWhile(visible: counting);

    if (endsAt == null) {
      return const SizedBox.shrink();
    }

    // `AdaptationPhaseService.hasExpired` rather than a second comparison
    // written here: the write path already owns this question, and two
    // definitions of "is the window still open" is how the display and the
    // store would come to disagree.
    if (AdaptationPhaseService.hasExpired(streak!, now)) {
      return const _ExpiredNotice();
    }

    return _Banner(remaining: endsAt.difference(now));
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

/// The closed-window notice.
///
/// Caution rather than danger, with dark text on it: the red countdown means
/// "act now", and this means "that has already happened". The colour carries
/// the difference so the two are not one banner whose text quietly changed.
class _ExpiredNotice extends StatelessWidget {
  const _ExpiredNotice();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('grace_period_expired'),
    width: double.infinity,
    color: AppTheme.caution,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: const Row(
      children: [
        Icon(Icons.restart_alt, color: AppTheme.primary),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            GracePeriodBannerText.expiredNotice,
            style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Banner extends StatelessWidget {
  const _Banner({required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('grace_period_countdown'),
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
  /// at zero, where it reads [expired] rather than a duration — the reset
  /// itself still lands on the next evaluation, but saying "less than a
  /// minute" for a window that closed hours ago is a claim, not a rounding.
  static String describe(Duration remaining) {
    // Expired, not "less than a minute". The old fall-through told a user
    // whose window closed hours ago that their streak would reset within the
    // minute, and went on telling them so until they logged something (#308).
    // The banner renders [_ExpiredNotice] rather than a countdown in that
    // case, so this is the guard for any other caller — and for a window that
    // closes between one tick and the next.
    if (remaining <= Duration.zero) {
      return expired;
    }
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

  /// What a closed window reads as.
  static const String expired = 'הסתיימה';

  /// The whole sentence the expired banner paints.
  ///
  /// Not a countdown, so it is not worded or styled as one: the streak is
  /// already lost and the only useful thing left to say is how to start
  /// another.
  static const String expiredNotice =
      'תקופת החסד הסתיימה — רשמו ארוחה תואמת כדי להתחיל רצף חדש';
}
