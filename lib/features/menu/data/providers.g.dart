// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The on-device menu-page OCR loop.
///
/// Not `keepAlive`: unlike the stateless Keto Lens wiring it wraps, this
/// holds no compiled state worth keeping between scans, and a fresh instance
/// per listener costs nothing but a field assignment.

@ProviderFor(menuPageReader)
const menuPageReaderProvider = MenuPageReaderProvider._();

/// The on-device menu-page OCR loop.
///
/// Not `keepAlive`: unlike the stateless Keto Lens wiring it wraps, this
/// holds no compiled state worth keeping between scans, and a fresh instance
/// per listener costs nothing but a field assignment.

final class MenuPageReaderProvider
    extends $FunctionalProvider<MenuPageReader, MenuPageReader, MenuPageReader>
    with $Provider<MenuPageReader> {
  /// The on-device menu-page OCR loop.
  ///
  /// Not `keepAlive`: unlike the stateless Keto Lens wiring it wraps, this
  /// holds no compiled state worth keeping between scans, and a fresh instance
  /// per listener costs nothing but a field assignment.
  const MenuPageReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'menuPageReaderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$menuPageReaderHash();

  @$internal
  @override
  $ProviderElement<MenuPageReader> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MenuPageReader create(Ref ref) {
    return menuPageReader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MenuPageReader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MenuPageReader>(value),
    );
  }
}

String _$menuPageReaderHash() => r'430ac442fe9681d19ba5689a8f4092475b30770b';
