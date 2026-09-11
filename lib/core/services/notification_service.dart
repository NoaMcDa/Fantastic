import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Plugin setup and the notification-permission prompt.
///
/// Every method is a no-op on web, and the reason is not that the plugin
/// lacks a web implementation — `flutter_local_notifications_web` 1.0.0 ships
/// one. It is what that implementation does: `initialize` **registers its own
/// service worker at runtime, replacing Flutter's**, which for an app that
/// bundles CanvasKit locally so it boots offline is not a trade worth making
/// for a reminder. `zonedSchedule` then throws `UnsupportedError` on web
/// regardless, so nothing is actually lost.
///
/// The branch lives here rather than at the call site so `main` and the
/// onboarding flow stay platform-blind.
class NotificationService {
  const NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  /// Prepares the plugin. Called once from `main`, before `runApp`.
  ///
  /// Returns whether the platform supports notifications at all, so a caller
  /// can skip offering a toggle it cannot honour.
  Future<bool> initialise() async {
    if (kIsWeb) {
      return false;
    }
    // Permission is requested later, from [requestPermission] — asking on
    // first launch, before the user knows what the app is for, is how an app
    // gets a permanent no.
    // `settings:` is named in v22; the issue's snippet passes it positionally.
    await _plugin.initialize(
      settings: const InitializationSettings(
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    return true;
  }

  /// Shows the OS permission prompt. Returns whether it was granted.
  ///
  /// Called after onboarding (M4) or from profile settings, never at launch.
  /// `flutter_local_notifications` asks the OS itself; the issue's technology
  /// table lists `permission_handler` for this and never uses it, so that
  /// package is not a dependency (`design/m3_preflight.md` §5.5).
  Future<bool> requestPermission() async {
    if (kIsWeb) {
      return false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final granted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return granted ?? false;
  }
}
