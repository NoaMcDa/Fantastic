// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The daily streak reminder, over the one plugin instance.
///
/// keepAlive for the same reason `notificationPluginProvider` is: it wraps an
/// OS-level registration, not a value that can be recreated on demand.

@ProviderFor(streakNotificationService)
const streakNotificationServiceProvider = StreakNotificationServiceProvider._();

/// The daily streak reminder, over the one plugin instance.
///
/// keepAlive for the same reason `notificationPluginProvider` is: it wraps an
/// OS-level registration, not a value that can be recreated on demand.

final class StreakNotificationServiceProvider
    extends
        $FunctionalProvider<
          StreakNotificationService,
          StreakNotificationService,
          StreakNotificationService
        >
    with $Provider<StreakNotificationService> {
  /// The daily streak reminder, over the one plugin instance.
  ///
  /// keepAlive for the same reason `notificationPluginProvider` is: it wraps an
  /// OS-level registration, not a value that can be recreated on demand.
  const StreakNotificationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'streakNotificationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$streakNotificationServiceHash();

  @$internal
  @override
  $ProviderElement<StreakNotificationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StreakNotificationService create(Ref ref) {
    return streakNotificationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StreakNotificationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StreakNotificationService>(value),
    );
  }
}

String _$streakNotificationServiceHash() =>
    r'8fa221285a21e41b7a38d7c654489d51fa520172';
