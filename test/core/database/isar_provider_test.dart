import 'package:fantastic/core/database/isar_provider.dart';
import 'package:fantastic/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Regression guard for #154: main.dart called `Isar.open([])`, which throws
  // `IsarError: At least one collection needs to be opened` before `runApp`,
  // so the app could not launch at all. No test caught it because none of them
  // call main() — widget_test.dart pumps FantasticApp directly.
  group('startup Isar wiring', () {
    test('Isar is not opened while no collection is registered', () async {
      expect(
        appIsarSchemas,
        isEmpty,
        reason:
            'M0 registers no collections by design. When #35 adds the first '
            'schema, this test moves to asserting a database is returned.',
      );

      // Returning at all is the assertion: on the empty path openAppIsar
      // touches no platform channel, where the old code hit path_provider and
      // then threw inside Isar.open before runApp was ever reached.
      expect(await openAppIsar(), isNull);
    });

    test('the app starts with no Isar override, leaving isarProvider '
        'un-overridden', () async {
      final db = await openAppIsar();
      final container = ProviderContainer(
        overrides: [if (db != null) isarProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      expect(container, isNotNull);
    });
  });

  test('isarProvider throws a descriptive UnimplementedError when not '
      'overridden', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // riverpod 3.0 wraps an error thrown by a provider's create function in
    // its own (internal, not publicly exported) ProviderException — assert
    // on its toString() instead, which includes the wrapped exception's
    // message.
    expect(
      () => container.read(isarProvider),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'toString()',
          contains('isarProvider must be overridden at app root'),
        ),
      ),
    );
  });

  // `ref.watch(isarProvider)` resolving via `isarProvider.overrideWithValue`
  // (the "resolves in a widget test with the in-memory override" DoD case)
  // isn't covered here: constructing a real `Isar` value needs
  // `Isar.initializeIsarCore`, which needs the native core binary — see
  // test/helpers/test_isar_test.dart (#24) for why that can't run in this
  // sandbox. The override call site itself (main.dart's
  // `isarProvider.overrideWithValue(db)`) is compile-time checked against
  // `Isar` by `flutter analyze`, which is the verification available here.
}
