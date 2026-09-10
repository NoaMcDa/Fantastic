import 'package:fantastic/core/error/persistence_guard.dart';
import 'package:fantastic/features/adaptation/data/mappers/streak_state_mapper.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:fantastic/features/adaptation/domain/repositories/streak_repository.dart';
import 'package:sembast/sembast.dart';

/// The store the single streak record lives in.
///
/// Public for the same reason as `mealsStore`.
final streakStateStore = intMapStoreFactory.store('streak_state');

/// sembast-backed [StreakRepository].
///
/// Every method addresses the one singleton record directly — no queries, no
/// sorting. The key comes from [StreakStateMapper.singletonId] rather than a
/// second constant here, so the key the codec is documented against and the
/// key this class reads cannot drift apart.
///
/// Failures are wrapped so they surface as a `PersistenceException` rather
/// than a `DatabaseException` — [watch] included, since `streakStateProvider`
/// (#59) renders a stream error through `AsyncValue.error` just as it would a
/// failed future.
class SembastStreakRepository implements StreakRepository {
  const SembastStreakRepository(this._db);

  final Database _db;

  /// Null on a fresh database — the first-launch sentinel, not an error.
  /// `AdaptationPhaseService` (#57) responds by seeding `StreakState.initial`.
  @override
  Future<StreakState?> load() =>
      guardPersistence('SembastStreakRepository.load', () async {
        final record = await _record.get(_db);
        return record == null ? null : StreakStateMapper.fromRecord(record);
      });

  @override
  Future<StreakState> save(StreakState state) =>
      guardPersistence('SembastStreakRepository.save', () async {
        final record = StreakStateMapper.toRecord(state);
        await _record.put(_db, record);
        return StreakStateMapper.fromRecord(record);
      });

  /// `onSnapshot` reads the record as soon as it is listened to and emits it
  /// before any write — null while none exists. That immediate emission is
  /// load-bearing: without it a subscriber would see nothing until the first
  /// write, and `streakStateProvider` (#59) would have to pair every
  /// subscription with a separate [load].
  @override
  Stream<StreakState?> watch() =>
      guardPersistenceStream('SembastStreakRepository.watch', () {
        return _record
            .onSnapshot(_db)
            .map(
              (snapshot) => snapshot == null
                  ? null
                  : StreakStateMapper.fromRecord(snapshot.value),
            );
      });

  RecordRef<int, Map<String, Object?>> get _record =>
      streakStateStore.record(StreakStateMapper.singletonId);
}
