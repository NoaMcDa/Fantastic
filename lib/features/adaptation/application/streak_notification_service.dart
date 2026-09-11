import 'package:fantastic/core/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the daily "you have not logged anything yet" reminder.
///
/// One notification, repeating at [reminderHour] local time, cancelled and
/// rescheduled rather than added to — a stable id is what stops a reminder
/// accumulating one copy per launch.
class StreakNotificationService {
  const StreakNotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  /// Stable across launches, so rescheduling replaces rather than adds.
  static const int reminderId = 1;

  /// Late enough that a normal day is already logged, early enough to act on.
  static const int reminderHour = 20;

  /// The zone the reminder is scheduled in.
  ///
  /// Pinned rather than read from the device. `timezone` has no way to learn
  /// the device's IANA zone without another package, and an uninitialised
  /// `tz.local` is **UTC** — which would fire this at 22:00 or 23:00 Israel
  /// time, the bug being pinned here to avoid. The app is Hebrew-only and
  /// Israel-targeted, so this is right for its users today.
  ///
  /// Known limitation: a user abroad gets the reminder at Israeli 20:00.
  /// Fixing it properly means adding `flutter_timezone` and reading the
  /// device zone, which is not worth a dependency before anyone asks.
  static const String timeZone = 'Asia/Jerusalem';

  /// Hebrew copy. Two lines: what to do, and why it matters.
  static const String title = 'אל תשכחו לרשום את הארוחות של היום 🥑';
  static const String body = 'שמרו על הרצף — עוד לא נרשמה ארוחה היום';

  /// iOS and macOS present the same way, so they share one details object.
  static const DarwinNotificationDetails _darwinDetails =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

  /// Schedules, or reschedules, the daily reminder.
  ///
  /// A no-op wherever the platform cannot schedule a future notification,
  /// which is web *and* Linux — see [NotificationService.supportsScheduling].
  /// Web implements `zonedSchedule` as an unconditional `UnsupportedError`
  /// and Linux as an `UnimplementedError`; either one thrown here takes down
  /// `main`, because the reminder is scheduled before `runApp`.
  Future<void> scheduleDailyReminder() async {
    if (!NotificationService.supportsScheduling) {
      return;
    }

    // Cancel first: the id is stable, so this replaces any pending copy
    // rather than letting one accumulate per launch.
    await _plugin.cancel(id: reminderId);

    // Every parameter is named in v22; the issue's snippet passes the first
    // five positionally and does not compile.
    await _plugin.zonedSchedule(
      id: reminderId,
      title: title,
      body: body,
      scheduledDate: nextReminderAfter(tz.TZDateTime.now(_location)),
      notificationDetails: const NotificationDetails(
        iOS: _darwinDetails,
        macOS: _darwinDetails,
        // Android needs a channel; the id is stable because changing it
        // orphans the user's per-channel notification settings.
        android: AndroidNotificationDetails(
          'streak_reminder',
          'תזכורת יומית',
          channelDescription: 'תזכורת לרשום את הארוחות של היום',
          importance: Importance.defaultImportance,
        ),
        windows: WindowsNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // What makes the one scheduled instant repeat every day — on android,
      // iOS and macOS. **Windows drops it**: the umbrella plugin's
      // `TargetPlatform.windows` branch does not forward the argument, and
      // `flutter_local_notifications_windows` ignores it even when passed. So
      // on Windows this schedules exactly one toast, not a daily one.
      //
      // Not a crash and not worth a platform branch: `main` cancels and
      // reschedules on every launch, so a Windows user who opens the app gets
      // the next reminder armed each time. A Windows user who does not open
      // the app stops being reminded — which is the failure mode a reminder
      // can least afford, and the reason this is written down rather than
      // left to be rediscovered.
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() => _plugin.cancel(id: reminderId);

  /// The next [reminderHour] strictly after [now], in [now]'s zone.
  ///
  /// Strictly after: scheduling for an instant that has already passed — or
  /// for this exact second — is how a "daily" reminder fires immediately on
  /// an app opened at 20:00 and then goes quiet.
  @visibleForTesting
  static tz.TZDateTime nextReminderAfter(tz.TZDateTime now) {
    final today = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day,
      reminderHour,
    );
    return today.isAfter(now)
        ? today
        : tz.TZDateTime(
            now.location,
            now.year,
            now.month,
            now.day + 1,
            reminderHour,
          );
  }

  /// Loads the zone database once. Idempotent.
  ///
  /// `timezone` needs its database loaded before any `TZDateTime` exists, and
  /// nothing else in the app does it. Calling `initializeTimeZones` twice is
  /// harmless.
  static tz.Location get _location {
    tz_data.initializeTimeZones();
    return tz.getLocation(timeZone);
  }
}
