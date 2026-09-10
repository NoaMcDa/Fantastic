import 'dart:io';

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

  test('openTestIsar initialises Isar Core before validating schemas', () async {
    // Reaching Isar's own "you gave me no collections" complaint proves
    // initialisation already succeeded: the pre-fix helper never got this far,
    // it died first on an HttpException fetching the native binary. This is
    // the closest M0 can get to opening a real instance — the milestone
    // defines no collections by design (Epic #4 excludes domain models), and
    // Isar refuses to open an instance without at least one.
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

  // Instance-lifecycle coverage — open, isolation between instances, and
  // use-after-close — needs a real collection to open against, so it lands
  // with M1's first Isar schema (#35) rather than here. See #147.
}
