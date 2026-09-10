// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The opened sembast [Database], injected at the app root.
///
/// Synchronous and `keepAlive`, so `ref.watch(databaseProvider)` in a
/// feature's `data/providers.dart` yields a `Database` directly with no
/// `.requireValue` and no re-open on rebuild.
///
/// The body throws rather than opening anything: opening is asynchronous and
/// platform-dependent (`openAppDatabase()` in `database_factory.dart`), so
/// `main.dart` does it once before `runApp` and overrides this provider with
/// the result. Leaving the un-overridden body as a throw is deliberate — a
/// widget test that pumps the app without supplying storage surfaces the
/// mistake as a descriptive error through `AsyncValue.error` instead of
/// silently reading an empty database.
///
/// There is no schema registration list to maintain: sembast stores are
/// created on first write, and each feature's repository declares its own
/// `StoreRef` next to the codec that fills it.

@ProviderFor(database)
const databaseProvider = DatabaseProvider._();

/// The opened sembast [Database], injected at the app root.
///
/// Synchronous and `keepAlive`, so `ref.watch(databaseProvider)` in a
/// feature's `data/providers.dart` yields a `Database` directly with no
/// `.requireValue` and no re-open on rebuild.
///
/// The body throws rather than opening anything: opening is asynchronous and
/// platform-dependent (`openAppDatabase()` in `database_factory.dart`), so
/// `main.dart` does it once before `runApp` and overrides this provider with
/// the result. Leaving the un-overridden body as a throw is deliberate — a
/// widget test that pumps the app without supplying storage surfaces the
/// mistake as a descriptive error through `AsyncValue.error` instead of
/// silently reading an empty database.
///
/// There is no schema registration list to maintain: sembast stores are
/// created on first write, and each feature's repository declares its own
/// `StoreRef` next to the codec that fills it.

final class DatabaseProvider
    extends $FunctionalProvider<Database, Database, Database>
    with $Provider<Database> {
  /// The opened sembast [Database], injected at the app root.
  ///
  /// Synchronous and `keepAlive`, so `ref.watch(databaseProvider)` in a
  /// feature's `data/providers.dart` yields a `Database` directly with no
  /// `.requireValue` and no re-open on rebuild.
  ///
  /// The body throws rather than opening anything: opening is asynchronous and
  /// platform-dependent (`openAppDatabase()` in `database_factory.dart`), so
  /// `main.dart` does it once before `runApp` and overrides this provider with
  /// the result. Leaving the un-overridden body as a throw is deliberate — a
  /// widget test that pumps the app without supplying storage surfaces the
  /// mistake as a descriptive error through `AsyncValue.error` instead of
  /// silently reading an empty database.
  ///
  /// There is no schema registration list to maintain: sembast stores are
  /// created on first write, and each feature's repository declares its own
  /// `StoreRef` next to the codec that fills it.
  const DatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseHash();

  @$internal
  @override
  $ProviderElement<Database> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Database create(Ref ref) {
    return database(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Database value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Database>(value),
    );
  }
}

String _$databaseHash() => r'96228e4b139ba61a936a34de9bd709f65f3fbd7d';
