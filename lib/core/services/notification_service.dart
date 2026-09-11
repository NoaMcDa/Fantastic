import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
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

  /// Whether this platform can schedule a notification for a future instant.
  ///
  /// Not the same question as "does the plugin support this platform". Linux
  /// has a full implementation that shows a notification *now* and throws
  /// `UnimplementedError: zonedSchedule() has not been implemented` for a
  /// future one; web throws `UnsupportedError` for the same call. Both would
  /// take the app down at launch, because `main` schedules the daily reminder
  /// before `runApp`.
  ///
  /// Asking a capability rather than checking `kIsWeb` is what keeps the next
  /// platform from repeating the bug: the answer is false by default and each
  /// platform has to earn a true.
  ///
  /// **Windows earned its true by inspection, not by inheritance.** It was
  /// listed here before anything had ever compiled for Windows, so it was
  /// checked the same way Linux was: `flutter_local_notifications_windows`
  /// 3.1.1 implements `zonedSchedule` for real — it renders the toast XML and
  /// calls `scheduleNotification` through its FFI bindings — and the umbrella
  /// plugin dispatches to it on `TargetPlatform.windows`. Nothing throws.
  ///
  /// One caveat that is a degradation and not a crash, so it does not change
  /// the answer here: the Windows path silently drops
  /// `matchDateTimeComponents`, so the daily reminder does not repeat on its
  /// own. See `StreakNotificationService.scheduleDailyReminder`.
  static bool get supportsScheduling {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS ||
      TargetPlatform.windows => true,
      TargetPlatform.linux || TargetPlatform.fuchsia => false,
    };
  }

  /// Prepares the plugin. Called once from `main`, before `runApp`.
  ///
  /// Returns whether the platform supports notifications at all, so a caller
  /// can skip offering a toggle it cannot honour.
  Future<bool> initialise() async {
    // Nothing this app does with notifications works without scheduling, so
    // on a platform that cannot schedule there is nothing to initialise. On
    // Linux that also avoids opening a session D-Bus connection the plugin
    // would then fail on in a headless or containerised session — an
    // unhandled async SocketException that no try/catch at the call site can
    // reach, because it happens inside the plugin's own background connect.
    if (!supportsScheduling) {
      return false;
    }
    // Permission is requested later, from [requestPermission] — asking on
    // first launch, before the user knows what the app is for, is how an app
    // gets a permanent no.
    // `settings:` is named in v22; the issue's snippet passes it positionally.
    //
    // Every platform this app is built for needs its own settings object. A
    // missing one is not a silent no-op: the plugin throws
    // `Invalid argument(s): Linux settings must be set when targeting Linux
    // platform` out of `initialize`, which `main` catches and renders as the
    // database error screen — so the app never reaches its first real frame.
    // Found by running the Linux desktop build; no test covers it, because
    // `flutter test` never calls `initialise`.
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: _darwin,
        macOS: _darwin,
        linux: LinuxInitializationSettings(defaultActionName: 'פתחו'),
        windows: WindowsInitializationSettings(
          appName: 'Fantastic',
          // CompanyName.ProductName, matching the iOS bundle identifier's
          // owner so the two agree on who ships this.
          appUserModelId: 'com.fantastic.fantastic',
          // Stable and arbitrary: Windows keys the app's notification
          // registration on it, so it must never change between releases.
          guid: '6f9619ff-8b86-d011-b42d-00cf4fc964ff',
        ),
      ),
    );
    return true;
  }

  /// iOS and macOS share one settings object: the permission policy is the
  /// same on both, and asking on first launch is how an app gets a permanent
  /// no. Permission is requested later, from [requestPermission].
  static const DarwinInitializationSettings _darwin =
      DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

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
