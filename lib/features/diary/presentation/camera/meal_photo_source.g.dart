// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_photo_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The composition root for the diary's photo capture.
///
/// `keepAlive` because `ImagePicker` is cheap to hold and rebuilding it per
/// sheet buys nothing — the same choice `photoPickerProvider` makes.
/// Overridden in widget tests with a fake: there is no camera and no gallery
/// in this environment.

@ProviderFor(mealPhotoSource)
const mealPhotoSourceProvider = MealPhotoSourceProvider._();

/// The composition root for the diary's photo capture.
///
/// `keepAlive` because `ImagePicker` is cheap to hold and rebuilding it per
/// sheet buys nothing — the same choice `photoPickerProvider` makes.
/// Overridden in widget tests with a fake: there is no camera and no gallery
/// in this environment.

final class MealPhotoSourceProvider
    extends
        $FunctionalProvider<MealPhotoSource, MealPhotoSource, MealPhotoSource>
    with $Provider<MealPhotoSource> {
  /// The composition root for the diary's photo capture.
  ///
  /// `keepAlive` because `ImagePicker` is cheap to hold and rebuilding it per
  /// sheet buys nothing — the same choice `photoPickerProvider` makes.
  /// Overridden in widget tests with a fake: there is no camera and no gallery
  /// in this environment.
  const MealPhotoSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mealPhotoSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mealPhotoSourceHash();

  @$internal
  @override
  $ProviderElement<MealPhotoSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MealPhotoSource create(Ref ref) {
    return mealPhotoSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MealPhotoSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MealPhotoSource>(value),
    );
  }
}

String _$mealPhotoSourceHash() => r'87b4b7c82c69458a7a4f9604b7c681099c5252e6';
