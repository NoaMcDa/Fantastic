import 'package:sembast/sembast_memory.dart';

/// Opens an isolated in-memory sembast database for a single test.
///
/// `newDatabaseFactoryMemory()` builds a *fresh factory* on every call rather
/// than handing back the shared `databaseFactoryMemory`, so two test files
/// running in the same isolate cannot see each other's records even though
/// they name the same database.
///
/// Pure Dart, and that is the point: unlike the `openTestIsar` helper this
/// replaces, it needs no `dart:io`, no `dart:ffi` and no native binary
/// resolved out of the pub cache, which is what makes the data-layer suite
/// runnable under `flutter test --platform chrome`.
Future<Database> openTestDatabase() =>
    newDatabaseFactoryMemory().openDatabase('test.db');

/// Closes [db], tolerating a database a test already closed.
///
/// The contract suites close the database themselves to inject a storage
/// failure (`breakStore`), and this still runs afterwards as their `tearDown`.
/// sembast exposes no public `isClosed`, so a second close is caught rather
/// than guarded against.
Future<void> closeTestDatabase(Database db) async {
  try {
    await db.close();
  } on DatabaseException {
    // Already closed by breakStore.
  }
}
