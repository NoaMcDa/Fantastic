// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The onboarding feature's repository wiring.
///
/// Returns the domain interface so consumers depend on the abstraction —
/// `OnboardingService` and `macroTargetsProvider` both reach the profile
/// through this, with no knowledge that sembast is underneath.

@ProviderFor(userProfileRepository)
const userProfileRepositoryProvider = UserProfileRepositoryProvider._();

/// The onboarding feature's repository wiring.
///
/// Returns the domain interface so consumers depend on the abstraction —
/// `OnboardingService` and `macroTargetsProvider` both reach the profile
/// through this, with no knowledge that sembast is underneath.

final class UserProfileRepositoryProvider
    extends
        $FunctionalProvider<
          UserProfileRepository,
          UserProfileRepository,
          UserProfileRepository
        >
    with $Provider<UserProfileRepository> {
  /// The onboarding feature's repository wiring.
  ///
  /// Returns the domain interface so consumers depend on the abstraction —
  /// `OnboardingService` and `macroTargetsProvider` both reach the profile
  /// through this, with no knowledge that sembast is underneath.
  const UserProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userProfileRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userProfileRepositoryHash();

  @$internal
  @override
  $ProviderElement<UserProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UserProfileRepository create(Ref ref) {
    return userProfileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserProfileRepository>(value),
    );
  }
}

String _$userProfileRepositoryHash() =>
    r'560e0c59afe7d1fee4d3a1a07b33ceae5abd1983';
