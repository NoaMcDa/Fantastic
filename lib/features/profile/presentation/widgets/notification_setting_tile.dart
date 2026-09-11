import 'package:fantastic/core/constants/profile_copy.dart';
import 'package:fantastic/core/providers/notification_providers.dart';
import 'package:fantastic/core/services/notification_service.dart';
import 'package:fantastic/core/widgets/skeleton_box.dart';
import 'package:fantastic/features/profile/application/providers/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The one notification control in the app: reports the real OS state and can
/// ask for permission when it is not granted.
///
/// **Three states, not two.** A platform that cannot schedule a reminder is
/// not a platform where notifications are "off": web and Linux would show an
/// enable button that could never work. The unsupported copy borrows
/// `CameraScreen.unavailableAdvice`'s register — say what does not work, then
/// say the rest of the app does.
class NotificationSettingTile extends ConsumerStatefulWidget {
  const NotificationSettingTile({super.key});

  /// Apple HIG's minimum touch target.
  ///
  /// A third copy of this constant, after `_ScoreButton` and `_ScaleCell`.
  /// Left duplicated deliberately: hoisting it spans three features and four
  /// call sites, and bundling that here would make #310 non-atomic.
  static const double minTouchTarget = 44;

  @override
  ConsumerState<NotificationSettingTile> createState() =>
      _NotificationSettingTileState();
}

class _NotificationSettingTileState
    extends ConsumerState<NotificationSettingTile> {
  bool _requesting = false;

  /// Set once a request has come back refused, so the row can explain instead
  /// of simply flipping back to "off" and looking like the tap did nothing.
  bool _refused = false;

  /// Set when the request itself threw.
  ///
  /// **Caught here, unlike the read.** `NotificationService` deliberately
  /// lets a platform-channel failure propagate out of `isPermissionGranted`
  /// so a failed read is never mistaken for a real "off" (#309). A failed
  /// *request* is different: it is a user-initiated action on the app's one
  /// settings control, and letting it escape a tap handler is an unhandled
  /// error in the zone — it takes the frame down rather than telling anyone
  /// anything. The row says what it could not do instead.
  bool _requestFailed = false;

  @override
  Widget build(BuildContext context) {
    // A platform with nothing to schedule is answered without touching the
    // provider at all — there is no OS state to report.
    if (!NotificationService.supportsScheduling) {
      return const _Row(
        key: Key('notifications_unsupported'),
        icon: Icons.notifications_off_outlined,
        title: ProfileCopy.notificationsUnsupported,
        body: ProfileCopy.notificationsUnsupportedBody,
      );
    }

    final granted = ref.watch(notificationPermissionProvider);

    // `hasError` before `hasValue`: riverpod 3 reports a provider that failed
    // before ever producing a value as `AsyncLoading` *with* an error
    // attached, so a loading-first check leaves this row loading forever.
    //
    // One broken row must not take the tab down, so this says what it cannot
    // determine and the rest of the screen renders normally.
    if (granted.hasError) {
      return const _Row(
        key: Key('notifications_unknown'),
        icon: Icons.notifications_paused_outlined,
        title: ProfileCopy.notificationsOff,
        body: ProfileCopy.notificationsCheckFailed,
      );
    }

    if (!granted.hasValue) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeletonBox(width: 140, height: 18),
            SizedBox(height: 8),
            SkeletonBox(width: 220, height: 14),
          ],
        ),
      );
    }

    if (granted.requireValue) {
      return const _Row(
        key: Key('notifications_granted'),
        icon: Icons.notifications_active_outlined,
        title: ProfileCopy.notificationsOn,
        body: ProfileCopy.notificationsOnBody,
      );
    }

    return _Row(
      key: const Key('notifications_denied'),
      icon: Icons.notifications_off_outlined,
      title: ProfileCopy.notificationsOff,
      body: switch (true) {
        _ when _requestFailed => ProfileCopy.notificationsCheckFailed,
        _ when _refused => ProfileCopy.notificationsRefused,
        _ => ProfileCopy.notificationsOffBody,
      },
      action: TextButton(
        key: const Key('enable_notifications_button'),
        onPressed: _requesting ? null : _request,
        child: const Text(ProfileCopy.enableNotifications),
      ),
    );
  }

  Future<void> _request() async {
    setState(() {
      _requesting = true;
      _requestFailed = false;
    });
    try {
      final granted = await ref
          .read(notificationServiceProvider)
          .requestPermission();
      if (!mounted) return;
      // A refusal is not an error — `OnboardingService` already treats it
      // that way. It only changes what the row says.
      setState(() => _refused = !granted);
      // Re-read rather than trust the request's own answer: on Android the
      // OS-level channel can be off even after the grant, and
      // `isPermissionGranted` is the question the row is actually asking.
      ref.invalidate(notificationPermissionProvider);
    } on Object catch (_) {
      // `Object`, not `Exception`: a platform channel can hand back an
      // `Error`, and the row's answer is the same either way — it could not
      // be done, and the rest of the tab keeps working.
      if (mounted) {
        setState(() => _requestFailed = true);
      }
    } finally {
      // In a `finally`, not after the await: an exception out of the platform
      // channel would otherwise leave the button disabled for good
      // (`design/m6_handoff.md`).
      if (mounted) {
        setState(() => _requesting = false);
      }
    }
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(
      minHeight: NotificationSettingTile.minTouchTarget,
    ),
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(body),
      trailing: action,
    ),
  );
}
