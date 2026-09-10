import 'dart:io';

import 'package:fantastic/features/diary/data/schemas/isar_meal_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import 'test_isar.dart';

void main() {
  // Regression guard for the `download: true` version of this helper, which
  // re-fetched Isar Core from binaries.isar-community.dev on every run and so
  // failed the whole suite wherever that host is blocked. The fix is to load
  // the binary that isar_community_flutter_libs already installs — assert that
  // binary is really on disk, rather than inferring it from a passing open().
  test('the Isar Core binary resolves from the installed package, with no '
      'network access', () async {
    final path = await resolveBundledIsarCorePath();

    expect(
      path,
      isNotNull,
      reason:
          'isar_community_flutter_libs must ship a native binary for this '
          'platform — that is what makes `flutter test` work offline.',
    );
    expect(File(path!).existsSync(), true);
  });

  test('openTestIsar rejects an empty schema list', () async {
    // Isar refuses an instance with no collections. This is why the helper
    // takes a required list, and why #154's main.dart skips Isar.open while
    // appIsarSchemas is empty.
    await expectLater(
      openTestIsar([]),
      throwsA(
        isA<IsarError>().having(
          (error) => error.message,
          'message',
          contains('At least one collection'),
        ),
      ),
    );
  });

  // Restored by #35. These could not exist until a real collection did — see
  // design/m1_handoff.md §7.
  group('instance lifecycle', () {
    test('openTestIsar returns an open instance', () async {
      final isar = await openTestIsar([IsarMealEntrySchema]);

      expect(isar.isOpen, true);

      await closeTestIsar(isar);
    });

    test('two sequential calls return different instances', () async {
      final first = await openTestIsar([IsarMealEntrySchema]);
      final second = await openTestIsar([IsarMealEntrySchema]);

      expect(first.name, isNot(second.name));

      await closeTestIsar(first);
      await closeTestIsar(second);
    });

    test('a closed instance cannot be reused', () async {
      final isar = await openTestIsar([IsarMealEntrySchema]);
      await closeTestIsar(isar);

      expect(isar.isOpen, false);
    });

    test(
      'instances are isolated — one does not see the other\'s writes',
      () async {
        final first = await openTestIsar([IsarMealEntrySchema]);
        final second = await openTestIsar([IsarMealEntrySchema]);

        await first.writeTxn(
          () => first.isarMealEntrys.put(
            IsarMealEntry()
              ..mealName = 'only-in-first'
              ..fatG = 20
              ..netCarbsG = 5
              ..proteinG = 15
              ..timestamp = DateTime(2026, 9, 9)
              ..ingredients = const []
              ..dateIndex = 20260909,
          ),
        );

        expect(await first.isarMealEntrys.count(), 1);
        expect(await second.isarMealEntrys.count(), 0);

        await closeTestIsar(first);
        await closeTestIsar(second);
      },
    );
  });
}
