/// Typed failures a repository may throw.
///
/// The contract is set out in `design/base_design.md` §Error Handling Contract:
/// repositories **throw** rather than returning a `Result<T>`, services let the
/// exception propagate without catching to convert, and presentation reads it
/// as `AsyncValue.error` from the provider that wrapped the call. That document
/// also records why `Result<T>` was rejected — riverpod's `AsyncValue` already
/// models failure at the boundary where the UI consumes a repository call, and
/// a second channel underneath it means every provider unwraps one to populate
/// the other.
///
/// Deliberately import-free. `domain/` may not see Flutter or the persistence
/// package, and these
/// types are part of the interface it declares.
library;

/// Base type for every repository failure.
///
/// Sealed, so a caller can switch over the failure modes exhaustively and the
/// analyzer will flag the switch when a new one is added. Implements
/// [Exception] rather than extending [Error]: a storage failure is a runtime
/// condition a caller may reasonably handle, not a programming bug.
sealed class RepositoryException implements Exception {
  const RepositoryException(this.message);

  /// Human-readable description of what failed. Safe to show a developer;
  /// not localised, so it is not UI copy.
  final String message;
}

/// A record the caller required to exist was absent.
///
/// **No MVP repository method throws this.** Every one of them treats absence
/// as a valid outcome by explicit contract — the finders return null or an
/// empty list, `StreakRepository.load` returns null as the first-launch
/// sentinel, and the deletes are documented no-ops.
///
/// It exists for callers that need "absent is an error" semantics, most likely
/// an application-layer service updating a record it requires to be there. Add
/// the throw site when a real caller needs it, rather than changing a finder's
/// documented null-means-absent behaviour.
final class EntityNotFoundException extends RepositoryException {
  const EntityNotFoundException(super.message);

  @override
  String toString() => 'EntityNotFoundException: $message';
}

/// The underlying store failed — a write that could not commit, a read from a
/// closed or corrupt database, a disk error.
///
/// [cause] is the original failure, kept so a log or a bug report can show what
/// the storage engine actually said. Callers should not type-check it: it is an
/// implementation detail of whichever backing store threw, and depending on it
/// re-introduces the leak this type exists to close.
final class PersistenceException extends RepositoryException {
  const PersistenceException(super.message, this.cause);

  /// The original error from the storage engine.
  final Object cause;

  /// Includes [cause]: the contract's presentation snippet renders a failure as
  /// `ErrorState(message: error.toString())`, so whatever this returns is what
  /// a developer sees first when something goes wrong.
  @override
  String toString() => 'PersistenceException: $message (caused by: $cause)';
}
