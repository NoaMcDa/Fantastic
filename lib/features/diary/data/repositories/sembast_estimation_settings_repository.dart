import 'package:fantastic/core/error/persistence_guard.dart';
import 'package:fantastic/features/diary/data/mappers/estimation_settings_mapper.dart';
import 'package:fantastic/features/diary/domain/models/estimation_settings.dart';
import 'package:fantastic/features/diary/domain/repositories/estimation_settings_repository.dart';
import 'package:sembast/sembast.dart';

/// The store the single settings record lives in.
///
/// Public, and pinned in `test/core/database/store_names_test.dart`: sembast
/// creates a store on first write, so two features choosing one name silently
/// merges two collections and nothing else in the build catches it.
///
/// **Its own store, not `user_profile`.** That record's existence is the
/// first-launch sentinel — see [EstimationSettings].
final estimationSettingsStore = intMapStoreFactory.store('estimation_settings');

/// sembast-backed [EstimationSettingsRepository].
///
/// Both methods address the one singleton record directly — no queries, no
/// sorting. The key comes from [EstimationSettingsMapper.singletonId] rather
/// than a second constant here, so the key the codec is documented against and
/// the key this class reads cannot drift apart.
///
/// Failures are wrapped so they leave as a `PersistenceException` rather than a
/// `DatabaseException`. The guard's message names the method and never the
/// record, so a stored key cannot reach a log through a failure path.
class SembastEstimationSettingsRepository
    implements EstimationSettingsRepository {
  const SembastEstimationSettingsRepository(this._db);

  final Database _db;

  /// Defaults on a fresh database — absence means "not configured yet", which
  /// is what `EstimationSettings()` already says.
  @override
  Future<EstimationSettings> load() =>
      guardPersistence('SembastEstimationSettingsRepository.load', () async {
        final record = await _record.get(_db);
        return record == null
            ? const EstimationSettings()
            : EstimationSettingsMapper.fromRecord(record);
      });

  @override
  Future<EstimationSettings> save(EstimationSettings settings) =>
      guardPersistence('SembastEstimationSettingsRepository.save', () async {
        final record = EstimationSettingsMapper.toRecord(settings);
        await _record.put(_db, record);
        return EstimationSettingsMapper.fromRecord(record);
      });

  RecordRef<int, Map<String, Object?>> get _record =>
      estimationSettingsStore.record(EstimationSettingsMapper.singletonId);
}
