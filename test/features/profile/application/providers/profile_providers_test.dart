import 'package:fantastic/core/providers/notification_providers.dart';
import 'package:fantastic/core/services/notification_service.dart';
import 'package:fantastic/features/onboarding/data/providers.dart';
import 'package:fantastic/features/onboarding/domain/models/user_profile.dart';
import 'package:fantastic/features/onboarding/domain/repositories/user_profile_repository.dart';
import 'package:fantastic/features/profile/application/providers/profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

class _MockNotificationService extends Mock implements NotificationService {}

void main() {
  late _MockUserProfileRepository repository;
  late _MockNotificationService notifications;

  setUp(() {
    repository = _MockUserProfileRepository();
    notifications = _MockNotificationService();
  });

  ProviderContainer containerWith() {
    final container = ProviderContainer(
      overrides: [
        userProfileRepositoryProvider.overrideWithValue(repository),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Reads `userProfileProvider` with a listener held open for the duration.
  ///
  /// The provider auto-disposes, and reading `.future` alone subscribes and
  /// releases in the same turn — riverpod then disposes it while it is still
  /// loading and the future completes with `Bad state: … disposed during
  /// loading state`. A widget holds the subscription in the real app; this
  /// stands in for it.
  Future<UserProfile?> heldRead(ProviderContainer container) {
    container.listen(userProfileProvider, (_, _) {});
    return container.read(userProfileProvider.future);
  }

  group('userProfileProvider', () {
    test('emits the stored profile', () async {
      final profile = UserProfileFixture.profile();
      when(repository.watch).thenAnswer((_) => Stream.value(profile));

      expect(await heldRead(containerWith()), same(profile));
    });

    // The distinction the screen is built on: null is the first-launch
    // sentinel, not a default to substitute for. `macroTargetsProvider`
    // deliberately does the opposite, and that is why this one exists.
    test('passes a null profile through rather than defaulting it', () async {
      when(repository.watch)
          .thenAnswer((_) => Stream<UserProfile?>.value(null));

      expect(await heldRead(containerWith()), isNull);
    });

    test(
      'propagates a read failure rather than reporting an absent profile',
      () async {
        when(
          repository.watch,
        ).thenAnswer((_) => Stream<UserProfile?>.error(StateError('broken')));

        expect(
          containerWith().read(userProfileProvider.future),
          throwsA(isA<StateError>()),
        );
      },
    );
  });

  group('notificationPermissionProvider', () {
    test('reports the service answer', () async {
      when(notifications.isPermissionGranted).thenAnswer((_) async => true);

      expect(
        await containerWith().read(notificationPermissionProvider.future),
        isTrue,
      );
    });

    test('reports a denial', () async {
      when(notifications.isPermissionGranted).thenAnswer((_) async => false);

      expect(
        await containerWith().read(notificationPermissionProvider.future),
        isFalse,
      );
    });

    // Never the prompt. Asking in order to find out spends the one dialog iOS
    // allows for the life of an install, which is the whole reason
    // `isPermissionGranted` was added (#309).
    test('never requests permission', () async {
      when(notifications.isPermissionGranted).thenAnswer((_) async => false);

      await containerWith().read(notificationPermissionProvider.future);

      verifyNever(notifications.requestPermission);
    });
  });
}
