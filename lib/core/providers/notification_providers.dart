import 'package:fantastic/core/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_providers.g.dart';

/// The one plugin instance.
///
/// Kept alive: the plugin holds the OS-level registration made in
/// [NotificationService.initialise], and an auto-disposing provider would
/// hand out a fresh, uninitialised instance the moment nothing was listening.
@Riverpod(keepAlive: true)
FlutterLocalNotificationsPlugin notificationPlugin(Ref ref) =>
    FlutterLocalNotificationsPlugin();

/// Setup and permission, over [notificationPluginProvider].
@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) =>
    NotificationService(ref.watch(notificationPluginProvider));
