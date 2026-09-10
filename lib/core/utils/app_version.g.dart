// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_version.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's current version string.
///
/// Also serves as the build_runner pipeline's canary: a minimal valid
/// `@riverpod` function, just enough to prove code generation resolves
/// end-to-end (issue #15).

@ProviderFor(appVersion)
const appVersionProvider = AppVersionProvider._();

/// The app's current version string.
///
/// Also serves as the build_runner pipeline's canary: a minimal valid
/// `@riverpod` function, just enough to prove code generation resolves
/// end-to-end (issue #15).

final class AppVersionProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// The app's current version string.
  ///
  /// Also serves as the build_runner pipeline's canary: a minimal valid
  /// `@riverpod` function, just enough to prove code generation resolves
  /// end-to-end (issue #15).
  const AppVersionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appVersionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appVersionHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return appVersion(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$appVersionHash() => r'b634d00cfcfff6bca6de2443628d996155e81051';
