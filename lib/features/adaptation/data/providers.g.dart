// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The adaptation feature's repository wiring.
///
/// Returns the domain interface so consumers depend on the abstraction —
/// `streakStateProvider` (#59) subscribes to `StreakRepository.watch()`
/// through this, with no knowledge that sembast is underneath.

@ProviderFor(streakRepository)
const streakRepositoryProvider = StreakRepositoryProvider._();

/// The adaptation feature's repository wiring.
///
/// Returns the domain interface so consumers depend on the abstraction —
/// `streakStateProvider` (#59) subscribes to `StreakRepository.watch()`
/// through this, with no knowledge that sembast is underneath.

final class StreakRepositoryProvider
    extends
        $FunctionalProvider<
          StreakRepository,
          StreakRepository,
          StreakRepository
        >
    with $Provider<StreakRepository> {
  /// The adaptation feature's repository wiring.
  ///
  /// Returns the domain interface so consumers depend on the abstraction —
  /// `streakStateProvider` (#59) subscribes to `StreakRepository.watch()`
  /// through this, with no knowledge that sembast is underneath.
  const StreakRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'streakRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$streakRepositoryHash();

  @$internal
  @override
  $ProviderElement<StreakRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StreakRepository create(Ref ref) {
    return streakRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StreakRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StreakRepository>(value),
    );
  }
}

String _$streakRepositoryHash() => r'1d09a21d4afaa7a8b77b18a06a3ed28b84841a90';
