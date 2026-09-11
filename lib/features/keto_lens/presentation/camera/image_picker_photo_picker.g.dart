// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_picker_photo_picker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How [CameraScreen] imports a photo.
///
/// Overridden in widget tests with a fake.

@ProviderFor(photoPicker)
const photoPickerProvider = PhotoPickerProvider._();

/// How [CameraScreen] imports a photo.
///
/// Overridden in widget tests with a fake.

final class PhotoPickerProvider
    extends $FunctionalProvider<PhotoPicker, PhotoPicker, PhotoPicker>
    with $Provider<PhotoPicker> {
  /// How [CameraScreen] imports a photo.
  ///
  /// Overridden in widget tests with a fake.
  const PhotoPickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoPickerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoPickerHash();

  @$internal
  @override
  $ProviderElement<PhotoPicker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PhotoPicker create(Ref ref) {
    return photoPicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhotoPicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhotoPicker>(value),
    );
  }
}

String _$photoPickerHash() => r'b71d30bec047cf99e031ecba15124a094c433ac0';
