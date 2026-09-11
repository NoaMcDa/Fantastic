// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The one plugin instance.
///
/// Kept alive: the plugin holds the OS-level registration made in
/// [NotificationService.initialise], and an auto-disposing provider would
/// hand out a fresh, uninitialised instance the moment nothing was listening.

@ProviderFor(notificationPlugin)
const notificationPluginProvider = NotificationPluginProvider._();

/// The one plugin instance.
///
/// Kept alive: the plugin holds the OS-level registration made in
/// [NotificationService.initialise], and an auto-disposing provider would
/// hand out a fresh, uninitialised instance the moment nothing was listening.

final class NotificationPluginProvider
    extends
        $FunctionalProvider<
          FlutterLocalNotificationsPlugin,
          FlutterLocalNotificationsPlugin,
          FlutterLocalNotificationsPlugin
        >
    with $Provider<FlutterLocalNotificationsPlugin> {
  /// The one plugin instance.
  ///
  /// Kept alive: the plugin holds the OS-level registration made in
  /// [NotificationService.initialise], and an auto-disposing provider would
  /// hand out a fresh, uninitialised instance the moment nothing was listening.
  const NotificationPluginProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationPluginProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationPluginHash();

  @$internal
  @override
  $ProviderElement<FlutterLocalNotificationsPlugin> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FlutterLocalNotificationsPlugin create(Ref ref) {
    return notificationPlugin(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlutterLocalNotificationsPlugin value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlutterLocalNotificationsPlugin>(
        value,
      ),
    );
  }
}

String _$notificationPluginHash() =>
    r'd8cefd98b7f7f8e4ae360eab025a1f3c7d7e2a2c';

/// Setup and permission, over [notificationPluginProvider].

@ProviderFor(notificationService)
const notificationServiceProvider = NotificationServiceProvider._();

/// Setup and permission, over [notificationPluginProvider].

final class NotificationServiceProvider
    extends
        $FunctionalProvider<
          NotificationService,
          NotificationService,
          NotificationService
        >
    with $Provider<NotificationService> {
  /// Setup and permission, over [notificationPluginProvider].
  const NotificationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationServiceHash();

  @$internal
  @override
  $ProviderElement<NotificationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationService create(Ref ref) {
    return notificationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationService>(value),
    );
  }
}

String _$notificationServiceHash() =>
    r'88220e318b3f9f52cf17c31f239608d6c0d51135';
