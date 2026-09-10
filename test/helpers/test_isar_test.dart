import 'package:flutter_test/flutter_test.dart';

import 'test_isar.dart';

void main() {
  test('openTestIsar returns an open Isar instance', () async {
    final isar = await openTestIsar([]);
    expect(isar.isOpen, true);
    await closeTestIsar(isar);
  });

  test('two sequential calls return different instances', () async {
    final first = await openTestIsar([]);
    final second = await openTestIsar([]);

    expect(first.name, isNot(second.name));

    await closeTestIsar(first);
    await closeTestIsar(second);
  });

  test('a closed instance cannot be reused', () async {
    final isar = await openTestIsar([]);
    await closeTestIsar(isar);

    expect(isar.isOpen, false);
  });
}
