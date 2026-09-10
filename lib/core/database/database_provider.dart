import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sembast/sembast.dart';

part 'database_provider.g.dart';

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
@Riverpod(keepAlive: true)
Database database(Ref ref) => throw UnimplementedError(
  'databaseProvider must be overridden at app root with an opened Database',
);
