import 'package:fantastic/core/error/repository_exception.dart';

/// Runs [body], converting any storage failure into a [PersistenceException].
///
/// [operation] names the call site — `'SembastMealRepository.findByDate'` —
/// so an exception that reaches a log or an error screen identifies where it
/// came from without needing a stack trace.
///
/// The success path is untouched: this only intercepts a throw.
Future<T> guardPersistence<T>(
  String operation,
  Future<T> Function() body,
) async {
  try {
    return await body();
  } on Object catch (error, stackTrace) {
    // `Object`, not `Exception`, is deliberate. sembast's own
    // `DatabaseException` does implement `Exception`, but the guarded body also
    // holds the codec that decodes the stored record, and a bad cast or a
    // missing key there throws an `Error` — which an `on Exception` clause
    // would miss. Wrapping those too is the right call: a codec that throws on
    // stored data is itself a persistence-integrity failure.
    Error.throwWithStackTrace(
      _asRepositoryException(operation, error),
      stackTrace,
    );
  }
}

/// Stream counterpart of [guardPersistence], for `StreakRepository.watch()`.
///
/// Guards both halves of a stream's life: a synchronous throw while [body]
/// builds the stream — what a closed database does — and an error delivered on
/// the stream afterwards. Either reaches the subscriber as a
/// [PersistenceException], so `streakStateProvider` (#59) surfaces it through
/// `AsyncValue.error` exactly as it would a failed future.
Stream<T> guardPersistenceStream<T>(
  String operation,
  Stream<T> Function() body,
) {
  final Stream<T> source;
  try {
    source = body();
  } on Object catch (error, stackTrace) {
    return Stream<T>.error(
      _asRepositoryException(operation, error),
      stackTrace,
    );
  }

  return source.handleError((Object error, StackTrace stackTrace) {
    Error.throwWithStackTrace(
      _asRepositoryException(operation, error),
      stackTrace,
    );
  });
}

/// Wraps [error] unless it is already typed.
///
/// Passing an existing [RepositoryException] straight through means a guarded
/// call nested inside another guarded call never double-wraps, and a
/// deliberate `EntityNotFoundException` is never reclassified as a storage
/// failure.
RepositoryException _asRepositoryException(String operation, Object error) =>
    error is RepositoryException
    ? error
    : PersistenceException('$operation failed', error);
