import 'dart:async';

import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/onboarding/application/providers/user_profile_providers.dart';
import 'package:fantastic/features/onboarding/data/providers.dart';
import 'package:fantastic/features/onboarding/domain/models/macro_targets.dart';
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

  /// A container whose repository emits what [stream] builds, already
  /// subscribed to.
  ///
  /// A factory rather than a stream instance: an errored provider is rebuilt
  /// on the next read, and `watch()` handing back the same
  /// single-subscription stream twice throws "Stream has already been
  /// listened to", masking the error the test is about.
  ///
  /// The subscription is not optional either — `read(provider.future)` alone
  /// does not hold an auto-disposing provider, and `fireImmediately: true`
  /// does not stand in for it.
  ProviderContainer containerWith(Stream<UserProfile?> Function() stream) {
    when(repository.watch).thenAnswer((_) => stream());
    final container = ProviderContainer(
      overrides: [userProfileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(macroTargetsProvider, (_, _) {});
    return container;
  }

  test('falls back to the defaults before anyone has onboarded', () async {
    final container = containerWith(() => Stream<UserProfile?>.value(null));

    expect(
      await container.read(macroTargetsProvider.future),
      MacroTargets.defaults,
    );
  });

  test('resolves to the saved profile targets', () async {
    final targets = UserProfileFixture.targets(fatG: 210, proteinG: 92);
    final container = containerWith(
      () => Stream<UserProfile?>.value(
        UserProfileFixture.profile(targets: targets),
      ),
    );

    expect(await container.read(macroTargetsProvider.future), targets);
  });

  // The point of a stream over a one-shot read: screen 4's save reaches the
  // dashboard with nobody having to remember to invalidate anything.
  test('re-emits when the profile is written', () async {
    final controller = StreamController<UserProfile?>();
    addTearDown(controller.close);
    final container = containerWith(() => controller.stream);

    final seen = <MacroTargets>[];
    container.listen(
      macroTargetsProvider,
      (_, next) => next.whenData(seen.add),
    );

    controller.add(null);
    await container.pump();
    controller.add(
      UserProfileFixture.profile(targets: UserProfileFixture.targets(fatG: 99)),
    );
    await container.pump();

    expect(seen, [MacroTargets.defaults, UserProfileFixture.targets(fatG: 99)]);
  });

  // A profile that cannot be *read* is not a profile that is *absent*.
  // Falling back to the defaults here would show someone a goal they never
  // set, beside a number they are being judged against.
  test(
    'a storage failure propagates rather than becoming the defaults',
    () async {
      final container = containerWith(
        () => Stream<UserProfile?>.error(
          const PersistenceException('UserProfileRepository.watch', 'closed'),
        ),
      );

      // riverpod 3 reports a provider that failed before its first value as
      // AsyncLoading *with* an error attached, so `hasError` is the flag to
      // read — `runtimeType` is not AsyncError and an `isLoading` check first
      // would call this a spinner.
      await container.pump();
      final value = container.read(macroTargetsProvider);
      expect(value.hasError, isTrue);
      expect(value.error, isA<PersistenceException>());
      expect(value.hasValue, isFalse);
    },
  );
}
