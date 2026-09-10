import 'dart:io';

import 'package:isar_community/isar.dart';

/// Opens a uniquely-named, in-memory-style Isar instance for a single test.
///
/// Every call gets its own database (named by microsecond timestamp), so
/// two contract tests running in parallel never share state. Pair with
/// [closeTestIsar] in `tearDown`.
Future<Isar> openTestIsar(List<CollectionSchema<dynamic>> schemas) async {
  await Isar.initializeIsarCore(download: true);
  return Isar.open(
    schemas,
    directory: Directory.systemTemp.path,
    name: 'test_${DateTime.now().microsecondsSinceEpoch}',
  );
}

/// Closes [isar] and deletes its on-disk files, leaving no leftovers in
/// the system temp directory.
Future<void> closeTestIsar(Isar isar) async {
  await isar.close(deleteFromDisk: true);
}
