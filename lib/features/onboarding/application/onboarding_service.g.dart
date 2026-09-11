// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The onboarding use case, wired to its collaborators behind their
/// interfaces.

@ProviderFor(onboardingService)
const onboardingServiceProvider = OnboardingServiceProvider._();

/// The onboarding use case, wired to its collaborators behind their
/// interfaces.

final class OnboardingServiceProvider
    extends
        $FunctionalProvider<
          OnboardingService,
          OnboardingService,
          OnboardingService
        >
    with $Provider<OnboardingService> {
  /// The onboarding use case, wired to its collaborators behind their
  /// interfaces.
  const OnboardingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingServiceHash();

  @$internal
  @override
  $ProviderElement<OnboardingService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OnboardingService create(Ref ref) {
    return onboardingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingService>(value),
    );
  }
}

String _$onboardingServiceHash() => r'9756501dc5ef03a40313419d3aec830d9a531436';
