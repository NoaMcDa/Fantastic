// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The diary feature's repository wiring.
///
/// Both providers return the **domain interface**, not the Isar class, so a
/// consumer cannot reach past the abstraction to an Isar-specific method — the
/// layer rule enforced by the type system rather than by review.
///
/// `ref.watch(isarProvider)` yields an `Isar` directly: the provider is
/// synchronous, and throws a descriptive `UnimplementedError` if the app root
/// never overrode it.

@ProviderFor(mealRepository)
const mealRepositoryProvider = MealRepositoryProvider._();

/// The diary feature's repository wiring.
///
/// Both providers return the **domain interface**, not the Isar class, so a
/// consumer cannot reach past the abstraction to an Isar-specific method — the
/// layer rule enforced by the type system rather than by review.
///
/// `ref.watch(isarProvider)` yields an `Isar` directly: the provider is
/// synchronous, and throws a descriptive `UnimplementedError` if the app root
/// never overrode it.

final class MealRepositoryProvider
    extends $FunctionalProvider<MealRepository, MealRepository, MealRepository>
    with $Provider<MealRepository> {
  /// The diary feature's repository wiring.
  ///
  /// Both providers return the **domain interface**, not the Isar class, so a
  /// consumer cannot reach past the abstraction to an Isar-specific method — the
  /// layer rule enforced by the type system rather than by review.
  ///
  /// `ref.watch(isarProvider)` yields an `Isar` directly: the provider is
  /// synchronous, and throws a descriptive `UnimplementedError` if the app root
  /// never overrode it.
  const MealRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mealRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mealRepositoryHash();

  @$internal
  @override
  $ProviderElement<MealRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MealRepository create(Ref ref) {
    return mealRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MealRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MealRepository>(value),
    );
  }
}

String _$mealRepositoryHash() => r'2ce2aa09e15afc1a62541b27fb03964adc0a9fa0';

@ProviderFor(symptomLogRepository)
const symptomLogRepositoryProvider = SymptomLogRepositoryProvider._();

final class SymptomLogRepositoryProvider
    extends
        $FunctionalProvider<
          SymptomLogRepository,
          SymptomLogRepository,
          SymptomLogRepository
        >
    with $Provider<SymptomLogRepository> {
  const SymptomLogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'symptomLogRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$symptomLogRepositoryHash();

  @$internal
  @override
  $ProviderElement<SymptomLogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SymptomLogRepository create(Ref ref) {
    return symptomLogRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SymptomLogRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SymptomLogRepository>(value),
    );
  }
}

String _$symptomLogRepositoryHash() =>
    r'1f7f0d4250f8718601fbe8d74ca406ea451ce8ba';
