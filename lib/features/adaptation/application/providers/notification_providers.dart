import 'package:fantastic/core/providers/notification_providers.dart';
import 'package:fantastic/features/adaptation/application/streak_notification_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_providers.g.dart';

/// The daily streak reminder, over the one plugin instance.
///
/// keepAlive for the same reason `notificationPluginProvider` is: it wraps an
/// OS-level registration, not a value that can be recreated on demand.
@Riverpod(keepAlive: true)
StreakNotificationService streakNotificationService(Ref ref) =>
    StreakNotificationService(ref.watch(notificationPluginProvider));
