import 'package:fantastic/core/database/database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';

import '../../helpers/test_database.dart';

void main() {
  group('databaseProvider', () {
    test('throws a descriptive UnimplementedError when not overridden', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // riverpod 3 wraps an error thrown by a provider's create function in
      // its own non-exported ProviderException, so assert on toString()
      // rather than on the type.
      expect(
        () => container.read(databaseProvider),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString()',
            contains('databaseProvider must be overridden at app root'),
          ),
        ),
      );
    });

    // The Isar provider this replaces could never be covered this way — a real
    // `Isar` needed the native core binary. sembast's memory factory is pure
    // Dart, so the override path is now testable end to end.
    test('resolves to the overridden database', () async {
      final db = await openTestDatabase();
      addTearDown(() => closeTestDatabase(db));

      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      expect(container.read(databaseProvider), same(db));
      expect(container.read(databaseProvider), isA<Database>());
    });
  });
}
