import 'package:fantastic/core/database/isar_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
