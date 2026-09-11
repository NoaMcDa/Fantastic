// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camera_controller_session.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How [CameraScreen] gets a camera.
///
/// Overridden in widget tests with a fake, which is what makes the screen's
/// permission, failure and capture paths testable with no device.

@ProviderFor(cameraSessionBuilder)
const cameraSessionBuilderProvider = CameraSessionBuilderProvider._();

/// How [CameraScreen] gets a camera.
///
/// Overridden in widget tests with a fake, which is what makes the screen's
/// permission, failure and capture paths testable with no device.

final class CameraSessionBuilderProvider
    extends
        $FunctionalProvider<
          CameraSessionBuilder,
          CameraSessionBuilder,
          CameraSessionBuilder
        >
    with $Provider<CameraSessionBuilder> {
  /// How [CameraScreen] gets a camera.
  ///
  /// Overridden in widget tests with a fake, which is what makes the screen's
  /// permission, failure and capture paths testable with no device.
  const CameraSessionBuilderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cameraSessionBuilderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cameraSessionBuilderHash();

  @$internal
  @override
  $ProviderElement<CameraSessionBuilder> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CameraSessionBuilder create(Ref ref) {
    return cameraSessionBuilder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CameraSessionBuilder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CameraSessionBuilder>(value),
    );
  }
}

String _$cameraSessionBuilderHash() =>
    r'8f89d2ca129f3f9f056ca0c9e642ebe9651d450f';
