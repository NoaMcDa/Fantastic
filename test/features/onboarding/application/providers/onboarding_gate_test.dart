import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/onboarding/application/providers/onboarding_gate.dart';
import 'package:fantastic/features/onboarding/data/providers.dart';
import 'package:fantastic/features/onboarding/domain/models/user_profile.dart';
import 'package:fantastic/features/onboarding/domain/repositories/user_profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

void main() {
  late _MockUserProfileRepository repository;

  setUp(() => repository = _MockUserProfileRepository());

  ProviderContainer containerWith(Future<UserProfile?> Function() load) {
    when(repository.load).thenAnswer((_) => load());
    final container = ProviderContainer(
      overrides: [userProfileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('the gate itself', () {
    // False is the safe default: showing onboarding again is a nuisance,
    // skipping it leaves the user measured against targets they never set.
    test('starts closed', () {
      expect(
        containerWith(() async => null).read(onboardingGateProvider),
        isFalse,
      );
    });

    test('markCompleted opens it', () {
      final container = containerWith(() async => null);

      container.read(onboardingGateProvider.notifier).markCompleted();

      expect(container.read(onboardingGateProvider), isTrue);
    });

    // Screen 4 flips it once; a second launch seeds it again. Neither may
    // toggle it back.
    test('markCompleted twice leaves it open', () {
      final container = containerWith(() async => null);

      container.read(onboardingGateProvider.notifier)
        ..markCompleted()
        ..markCompleted();

      expect(container.read(onboardingGateProvider), isTrue);
    });

    // Synchronous, and that is the requirement — go_router's redirect reads
    // it without awaiting. An async gate awaited inside a redirect never
    // returns when the provider fails before its first value, which leaves
    // the app on a blank screen (`design/m4_preflight.md` §1.2).
    test('is a plain bool, readable without awaiting', () {
      expect(
        containerWith(() async => null).read(onboardingGateProvider),
        isA<bool>(),
      );
    });
  });

  group('seedOnboardingGate', () {
    // The record's existence *is* the flag. There is no separate boolean.
    test('leaves the gate closed when no profile is stored', () async {
      final container = containerWith(() async => null);

      await seedOnboardingGate(container);

      expect(container.read(onboardingGateProvider), isFalse);
    });

    test('opens the gate when a profile is stored', () async {
      final container = containerWith(() async => UserProfileFixture.profile());

      await seedOnboardingGate(container);

      expect(container.read(onboardingGateProvider), isTrue);
    });

    test('reads the profile exactly once', () async {
      final container = containerWith(() async => UserProfileFixture.profile());

      await seedOnboardingGate(container);

      verify(repository.load).called(1);
    });

    // It runs inside `main`'s try, beside the database open. A profile that
    // cannot be read means onboarding cannot be written either, and
    // silently re-running the flow would overwrite targets still on disk —
    // so the failure surfaces as StartupFailureApp rather than as a second
    // onboarding.
    test('a storage failure propagates rather than defaulting', () async {
      final container = containerWith(
        () async => throw const PersistenceException(
          'UserProfileRepository.load',
          'closed',
        ),
      );

      await expectLater(
        seedOnboardingGate(container),
        throwsA(isA<PersistenceException>()),
      );
      expect(container.read(onboardingGateProvider), isFalse);
    });
  });
}
