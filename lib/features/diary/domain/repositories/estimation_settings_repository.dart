import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/diary/domain/models/estimation_settings.dart';

/// Persistence contract for the singleton [EstimationSettings].
///
/// Exactly one record exists, so there are no collection queries and [save] is
/// always an upsert of that one row.
///
/// Methods return plain futures and throw on failure — see
/// `design/base_design.md` §Error Handling Contract.
abstract interface class EstimationSettingsRepository {
  /// The stored settings, or defaults on a fresh database.
  ///
  /// Returns `EstimationSettings()` rather than null when nothing has been
  /// written. Unlike `UserProfileRepository.load`, record-absence carries no
  /// meaning here — it is not a first-launch sentinel — and a nullable return
  /// would push a `?? const EstimationSettings()` into every caller.
  ///
  /// Throws [PersistenceException] if the store cannot be read.
  Future<EstimationSettings> load();

  /// Upserts the single record. Returns the saved copy.
  ///
  /// Throws [PersistenceException] if the store cannot be written.
  Future<EstimationSettings> save(EstimationSettings settings);
}
