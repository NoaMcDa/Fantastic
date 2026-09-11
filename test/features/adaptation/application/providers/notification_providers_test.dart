import 'package:fantastic/features/adaptation/application/providers/notification_providers.dart';
import 'package:fantastic/features/adaptation/application/streak_notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProviderContainer container() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('resolves a StreakNotificationService', () {
    expect(
      container().read(streakNotificationServiceProvider),
      isA<StreakNotificationService>(),
    );
  });

  // keepAlive for the same reason the plugin provider is: it wraps an
  // OS-level registration, not a value that can be rebuilt on demand.
  test('survives having no listeners', () {
    final c = container();

    final first = c.read(streakNotificationServiceProvider);

    expect(c.read(streakNotificationServiceProvider), same(first));
  });
}
