// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_logging_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mealLoggingService)
const mealLoggingServiceProvider = MealLoggingServiceProvider._();

final class MealLoggingServiceProvider
    extends
        $FunctionalProvider<
          MealLoggingService,
          MealLoggingService,
          MealLoggingService
        >
    with $Provider<MealLoggingService> {
  const MealLoggingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mealLoggingServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mealLoggingServiceHash();

  @$internal
  @override
  $ProviderElement<MealLoggingService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MealLoggingService create(Ref ref) {
    return mealLoggingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MealLoggingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MealLoggingService>(value),
    );
  }
}

String _$mealLoggingServiceHash() =>
    r'3c60bd7b5a370ac5c7bca1648629c302306b4e2d';
