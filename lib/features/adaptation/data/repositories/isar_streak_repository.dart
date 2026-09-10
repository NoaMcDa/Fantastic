import 'package:fantastic/core/error/persistence_guard.dart';
import 'package:fantastic/features/adaptation/data/mappers/streak_state_mapper.dart';
import 'package:fantastic/features/adaptation/data/schemas/isar_streak_state.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:fantastic/features/adaptation/domain/repositories/streak_repository.dart';
import 'package:isar_community/isar.dart';

/// Isar-backed [StreakRepository].
///
/// Every method addresses the one singleton row directly — no queries, no
/// indexes. The row id comes from [StreakStateMapper.singletonId] rather than
/// a second constant here, so the value the mapper writes and the value this
/// class reads cannot drift apart.
///
/// Failures are wrapped so they surface as a `PersistenceException` rather than
/// an `IsarError` — [watch] included, since `streakStateProvider` (#59) renders
/// a stream error through `AsyncValue.error` just as it would a failed future.
class IsarStreakRepository implements StreakRepository {
  const IsarStreakRepository(this._isar);

  final Isar _isar;

  /// Null on a fresh database — the first-launch sentinel, not an error.
  /// `AdaptationPhaseService` (#57) responds by seeding `StreakState.initial`.
  @override
  Future<StreakState?> load() =>
      guardPersistence('IsarStreakRepository.load', () async {
        final schema = await _isar.isarStreakStates.get(
          StreakStateMapper.singletonId,
        );
        return schema == null ? null : StreakStateMapper.toDomain(schema);
      });

  @override
  Future<StreakState> save(StreakState state) =>
      guardPersistence('IsarStreakRepository.save', () async {
        // The mapper pins every record to the singleton row, so `put` always
        // overwrites and a duplicate is structurally impossible.
        final schema = StreakStateMapper.toIsar(state);
        await _isar.writeTxn(() => _isar.isarStreakStates.put(schema));
        return StreakStateMapper.toDomain(schema);
      });

  /// `fireImmediately: true` is load-bearing: without it a subscriber sees
  /// nothing until the first write, and `streakStateProvider` (#59) would have
  /// to pair every subscription with a separate [load].
  @override
  Stream<StreakState?> watch() =>
      guardPersistenceStream('IsarStreakRepository.watch', () {
        return _isar.isarStreakStates
            .watchObject(StreakStateMapper.singletonId, fireImmediately: true)
            .map(
              (schema) =>
                  schema == null ? null : StreakStateMapper.toDomain(schema),
            );
      });
}
