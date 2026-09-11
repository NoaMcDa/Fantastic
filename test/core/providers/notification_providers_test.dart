import 'package:fantastic/core/providers/notification_providers.dart';
import 'package:fantastic/core/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProviderContainer container() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('resolves a plugin instance', () {
    expect(
      container().read(notificationPluginProvider),
      isA<FlutterLocalNotificationsPlugin>(),
    );
  });

  test('resolves a service', () {
    expect(
      container().read(notificationServiceProvider),
      isA<NotificationService>(),
    );
  });

  // The plugin holds the OS-level registration made during initialise. An
  // auto-disposing provider would hand out a fresh, uninitialised instance
  // the moment nothing was listening, and every later call would go nowhere.
  test('the plugin survives having no listeners', () {
    final c = container();

    final first = c.read(notificationPluginProvider);

    expect(c.read(notificationPluginProvider), same(first));
  });
}
