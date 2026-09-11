// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The diary feature's repository wiring.
///
/// Every provider returns the **domain interface**, not the sembast class, so
/// a consumer cannot reach past the abstraction to a store-specific method —
/// the layer rule enforced by the type system rather than by review.
///
/// `ref.watch(databaseProvider)` yields a `Database` directly: the provider is
/// synchronous, and throws a descriptive `UnimplementedError` if the app root
/// never overrode it.

@ProviderFor(mealRepository)
const mealRepositoryProvider = MealRepositoryProvider._();

/// The diary feature's repository wiring.
///
/// Every provider returns the **domain interface**, not the sembast class, so
/// a consumer cannot reach past the abstraction to a store-specific method —
/// the layer rule enforced by the type system rather than by review.
///
/// `ref.watch(databaseProvider)` yields a `Database` directly: the provider is
/// synchronous, and throws a descriptive `UnimplementedError` if the app root
/// never overrode it.

final class MealRepositoryProvider
    extends $FunctionalProvider<MealRepository, MealRepository, MealRepository>
    with $Provider<MealRepository> {
  /// The diary feature's repository wiring.
  ///
  /// Every provider returns the **domain interface**, not the sembast class, so
  /// a consumer cannot reach past the abstraction to a store-specific method —
  /// the layer rule enforced by the type system rather than by review.
  ///
  /// `ref.watch(databaseProvider)` yields a `Database` directly: the provider is
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

String _$mealRepositoryHash() => r'4f343bd434f6fd06f08dae9425f6949b1bb71474';

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
    r'f4e1b6a4f16b7f1f6f1c2499dd3bbe41a22a5227';

@ProviderFor(estimationSettingsRepository)
const estimationSettingsRepositoryProvider =
    EstimationSettingsRepositoryProvider._();

final class EstimationSettingsRepositoryProvider
    extends
        $FunctionalProvider<
          EstimationSettingsRepository,
          EstimationSettingsRepository,
          EstimationSettingsRepository
        >
    with $Provider<EstimationSettingsRepository> {
  const EstimationSettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'estimationSettingsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$estimationSettingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<EstimationSettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EstimationSettingsRepository create(Ref ref) {
    return estimationSettingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EstimationSettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EstimationSettingsRepository>(value),
    );
  }
}

String _$estimationSettingsRepositoryHash() =>
    r'7deaba295733e6c5919d03947b0f34609b88c47a';

@ProviderFor(estimationCredentials)
const estimationCredentialsProvider = EstimationCredentialsProvider._();

final class EstimationCredentialsProvider
    extends
        $FunctionalProvider<
          EstimationCredentials,
          EstimationCredentials,
          EstimationCredentials
        >
    with $Provider<EstimationCredentials> {
  const EstimationCredentialsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'estimationCredentialsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$estimationCredentialsHash();

  @$internal
  @override
  $ProviderElement<EstimationCredentials> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EstimationCredentials create(Ref ref) {
    return estimationCredentials(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EstimationCredentials value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EstimationCredentials>(value),
    );
  }
}

String _$estimationCredentialsHash() =>
    r'a07d858276222660e9f33d60828bf8127d7540f7';

/// The composition root for the estimator's transport, and **the only place
/// besides `open_router_client.dart` where a concrete provider is named**.
///
/// Adding our own backend later means a new implementation file and a new
/// branch here — never an edit anywhere above this line. Epic #312's OCP
/// invariant, enforced by the return type: this hands back the interface.
///
/// `ref.onDispose` closes the socket, so a test that overrides this with a
/// `MockClient` leaks nothing and a disposed container holds no connection.

@ProviderFor(llmChatClient)
const llmChatClientProvider = LlmChatClientProvider._();

/// The composition root for the estimator's transport, and **the only place
/// besides `open_router_client.dart` where a concrete provider is named**.
///
/// Adding our own backend later means a new implementation file and a new
/// branch here — never an edit anywhere above this line. Epic #312's OCP
/// invariant, enforced by the return type: this hands back the interface.
///
/// `ref.onDispose` closes the socket, so a test that overrides this with a
/// `MockClient` leaks nothing and a disposed container holds no connection.

final class LlmChatClientProvider
    extends $FunctionalProvider<LlmChatClient, LlmChatClient, LlmChatClient>
    with $Provider<LlmChatClient> {
  /// The composition root for the estimator's transport, and **the only place
  /// besides `open_router_client.dart` where a concrete provider is named**.
  ///
  /// Adding our own backend later means a new implementation file and a new
  /// branch here — never an edit anywhere above this line. Epic #312's OCP
  /// invariant, enforced by the return type: this hands back the interface.
  ///
  /// `ref.onDispose` closes the socket, so a test that overrides this with a
  /// `MockClient` leaks nothing and a disposed container holds no connection.
  const LlmChatClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'llmChatClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$llmChatClientHash();

  @$internal
  @override
  $ProviderElement<LlmChatClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LlmChatClient create(Ref ref) {
    return llmChatClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LlmChatClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LlmChatClient>(value),
    );
  }
}

String _$llmChatClientHash() => r'21a8e5e47514333775d167fc8858870586260f42';

/// The composition root for estimation, and the only place a concrete
/// estimator is named.
///
/// A backend that owns the prompt as well becomes a second `MacroEstimator`
/// implementation selected here — no edit anywhere above this line. Returns
/// the interface for the same reason every repository provider does.
/// Reads a picked photo's bytes.
///
/// A provider of its own, rather than a `const` inside the estimator, so a
/// test can supply bytes without a file system and the browser build never
/// needs `dart:io` to be conditionally exported.

@ProviderFor(photoBytesReader)
const photoBytesReaderProvider = PhotoBytesReaderProvider._();

/// The composition root for estimation, and the only place a concrete
/// estimator is named.
///
/// A backend that owns the prompt as well becomes a second `MacroEstimator`
/// implementation selected here — no edit anywhere above this line. Returns
/// the interface for the same reason every repository provider does.
/// Reads a picked photo's bytes.
///
/// A provider of its own, rather than a `const` inside the estimator, so a
/// test can supply bytes without a file system and the browser build never
/// needs `dart:io` to be conditionally exported.

final class PhotoBytesReaderProvider
    extends
        $FunctionalProvider<
          PhotoBytesReader,
          PhotoBytesReader,
          PhotoBytesReader
        >
    with $Provider<PhotoBytesReader> {
  /// The composition root for estimation, and the only place a concrete
  /// estimator is named.
  ///
  /// A backend that owns the prompt as well becomes a second `MacroEstimator`
  /// implementation selected here — no edit anywhere above this line. Returns
  /// the interface for the same reason every repository provider does.
  /// Reads a picked photo's bytes.
  ///
  /// A provider of its own, rather than a `const` inside the estimator, so a
  /// test can supply bytes without a file system and the browser build never
  /// needs `dart:io` to be conditionally exported.
  const PhotoBytesReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoBytesReaderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoBytesReaderHash();

  @$internal
  @override
  $ProviderElement<PhotoBytesReader> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PhotoBytesReader create(Ref ref) {
    return photoBytesReader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhotoBytesReader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhotoBytesReader>(value),
    );
  }
}

String _$photoBytesReaderHash() => r'4a8ccd760e813ad8b4d2536891c85df4cb0146c0';

@ProviderFor(macroEstimator)
const macroEstimatorProvider = MacroEstimatorProvider._();

final class MacroEstimatorProvider
    extends $FunctionalProvider<MacroEstimator, MacroEstimator, MacroEstimator>
    with $Provider<MacroEstimator> {
  const MacroEstimatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'macroEstimatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$macroEstimatorHash();

  @$internal
  @override
  $ProviderElement<MacroEstimator> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MacroEstimator create(Ref ref) {
    return macroEstimator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MacroEstimator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MacroEstimator>(value),
    );
  }
}

String _$macroEstimatorHash() => r'd88776d0e5a45d0188f2b16862f2eb3477d7f5f7';
