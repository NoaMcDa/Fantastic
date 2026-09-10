import 'package:fantastic/core/error/repository_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the sealed hierarchy', () {
    test('EntityNotFoundException is a RepositoryException', () {
      expect(const EntityNotFoundException('gone'), isA<RepositoryException>());
    });

    test('PersistenceException is a RepositoryException', () {
      expect(
        const PersistenceException('write failed', 'disk full'),
        isA<RepositoryException>(),
      );
    });

    // Implements Exception, not Error: a storage failure is a runtime
    // condition a caller may reasonably handle, and Dart's convention is that
    // Error means "programming bug, do not catch".
    test('both are Exceptions, not Errors', () {
      expect(const EntityNotFoundException('gone'), isA<Exception>());
      expect(
        const PersistenceException('write failed', 'disk full'),
        isA<Exception>(),
      );
      expect(const EntityNotFoundException('gone'), isNot(isA<Error>()));
    });

    test('the two subtypes are distinguishable from each other', () {
      const RepositoryException notFound = EntityNotFoundException('gone');

      expect(notFound, isNot(isA<PersistenceException>()));
    });
  });

  group('EntityNotFoundException', () {
    test('keeps its message', () {
      expect(
        const EntityNotFoundException('no log for 2026-09-09').message,
        'no log for 2026-09-09',
      );
    });

    test('toString names the type and the message', () {
      expect(
        const EntityNotFoundException('no log for 2026-09-09').toString(),
        'EntityNotFoundException: no log for 2026-09-09',
      );
    });
  });

  group('PersistenceException', () {
    test('keeps its message and cause', () {
      const cause = FormatException('bad record');
      const exception = PersistenceException('read failed', cause);

      expect(exception.message, 'read failed');
      expect(exception.cause, same(cause));
    });

    // The contract's presentation snippet renders a failure as
    // `ErrorState(message: error.toString())`, so this string is what a
    // developer sees first. Without the override it would read
    // "Instance of 'PersistenceException'".
    test('toString includes both the message and the cause', () {
      final rendered = const PersistenceException(
        'IsarMealRepository.save failed',
        'IsarError: instance closed',
      ).toString();

      expect(rendered, contains('IsarMealRepository.save failed'));
      expect(rendered, contains('IsarError: instance closed'));
    });

    test('accepts any Object as a cause, not only an Exception', () {
      // IsarError extends Error, so restricting `cause` to Exception would
      // exclude the very failures this type is built to carry.
      expect(
        PersistenceException('failed', StateError('boom')).cause,
        isA<Error>(),
      );
    });
  });
}
