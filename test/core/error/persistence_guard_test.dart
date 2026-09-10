import 'dart:async';

import 'package:fantastic/core/error/persistence_guard.dart';
import 'package:fantastic/core/error/repository_exception.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for `IsarError`, which extends [Error] rather than [Exception] —
/// the property that forces the guard to catch `Object`.
class _FakeStoreError extends Error {
  _FakeStoreError(this.detail);

  final String detail;

  @override
  String toString() => 'FakeStoreError: $detail';
}

void main() {
  group('guardPersistence', () {
    test('returns the body result untouched on success', () async {
      expect(await guardPersistence('op', () async => 42), 42);
    });

    test('does not intercept a null result', () async {
      expect(await guardPersistence<int?>('op', () async => null), isNull);
    });

    test('wraps a thrown Error as a PersistenceException', () async {
      // The case that matters: IsarError extends Error, so an `on Exception`
      // clause would let every real storage failure through unwrapped.
      await expectLater(
        guardPersistence('op', () async => throw _FakeStoreError('closed')),
        throwsA(isA<PersistenceException>()),
      );
    });

    test('wraps a thrown Exception too', () async {
      await expectLater(
        guardPersistence('op', () async => throw const FormatException('bad')),
        throwsA(isA<PersistenceException>()),
      );
    });

    test('wraps a synchronous throw from the body', () async {
      await expectLater(
        guardPersistence('op', () => throw _FakeStoreError('sync')),
        throwsA(isA<PersistenceException>()),
      );
    });

    test('names the operation in the message', () async {
      await expectLater(
        guardPersistence(
          'IsarMealRepository.save',
          () async => throw _FakeStoreError('closed'),
        ),
        throwsA(
          isA<PersistenceException>().having(
            (e) => e.message,
            'message',
            'IsarMealRepository.save failed',
          ),
        ),
      );
    });

    test('retains the original error as the cause', () async {
      final original = _FakeStoreError('closed');

      await expectLater(
        guardPersistence('op', () async => throw original),
        throwsA(
          isA<PersistenceException>().having(
            (e) => e.cause,
            'cause',
            same(original),
          ),
        ),
      );
    });

    // Without this, a guarded call nested inside another would produce a
    // PersistenceException whose cause is a PersistenceException.
    test('does not re-wrap an existing RepositoryException', () async {
      const original = EntityNotFoundException('gone');

      await expectLater(
        guardPersistence('op', () async => throw original),
        throwsA(same(original)),
      );
    });

    test('nesting two guards wraps only once', () async {
      await expectLater(
        guardPersistence(
          'outer',
          () => guardPersistence(
            'inner',
            () async => throw _FakeStoreError('closed'),
          ),
        ),
        throwsA(
          isA<PersistenceException>()
              .having((e) => e.message, 'message', 'inner failed')
              .having((e) => e.cause, 'cause', isA<_FakeStoreError>()),
        ),
      );
    });

    test('preserves the original stack trace', () async {
      StackTrace? thrownFrom;
      late StackTrace caught;

      try {
        await guardPersistence('op', () async {
          thrownFrom = StackTrace.current;
          throw _FakeStoreError('closed');
        });
      } on PersistenceException catch (_, stackTrace) {
        caught = stackTrace;
      }

      // The frame the failure came from must still be identifiable — a guard
      // that rethrew bare would point only at the guard itself.
      expect(thrownFrom, isNotNull);
      expect(caught.toString(), contains('persistence_guard_test.dart'));
    });
  });

  group('guardPersistenceStream', () {
    test('passes through events on success', () async {
      expect(
        await guardPersistenceStream(
          'op',
          () => Stream.fromIterable([1, 2, 3]),
        ).toList(),
        [1, 2, 3],
      );
    });

    test('wraps an error delivered on the stream', () async {
      final stream = guardPersistenceStream(
        'op',
        () => Stream<int>.error(_FakeStoreError('mid-stream')),
      );

      await expectLater(stream, emitsError(isA<PersistenceException>()));
    });

    // A closed database throws when the stream is *built*, before any event —
    // so guarding only the delivered errors would miss the common case.
    test('wraps a synchronous throw while building the stream', () async {
      final stream = guardPersistenceStream<int>(
        'op',
        () => throw _FakeStoreError('closed'),
      );

      await expectLater(stream, emitsError(isA<PersistenceException>()));
    });

    test('delivers events before an error, then the wrapped error', () async {
      final controller = StreamController<int>();
      final stream = guardPersistenceStream('op', () => controller.stream);

      final received = expectLater(
        stream,
        emitsInOrder([1, emitsError(isA<PersistenceException>())]),
      );

      controller
        ..add(1)
        ..addError(_FakeStoreError('late failure'));
      await controller.close();
      await received;
    });

    test('does not re-wrap an existing RepositoryException', () async {
      const original = EntityNotFoundException('gone');

      await expectLater(
        guardPersistenceStream('op', () => Stream<int>.error(original)),
        emitsError(same(original)),
      );
    });

    test('names the operation in the message', () async {
      await expectLater(
        guardPersistenceStream(
          'IsarStreakRepository.watch',
          () => Stream<int>.error(_FakeStoreError('closed')),
        ),
        emitsError(
          isA<PersistenceException>().having(
            (e) => e.message,
            'message',
            'IsarStreakRepository.watch failed',
          ),
        ),
      );
    });
  });
}
