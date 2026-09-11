import 'package:fantastic/core/error/persistence_guard.dart';
import 'package:fantastic/features/onboarding/data/mappers/user_profile_mapper.dart';
import 'package:fantastic/features/onboarding/domain/models/user_profile.dart';
import 'package:fantastic/features/onboarding/domain/repositories/user_profile_repository.dart';
import 'package:sembast/sembast.dart';

/// The store the single profile record lives in.
///
/// Public, and pinned in `test/core/database/store_names_test.dart`: sembast
/// creates a store on first write, so two features choosing one name silently
/// merges two collections and nothing else in the build catches it.
final userProfileStore = intMapStoreFactory.store('user_profile');

/// sembast-backed [UserProfileRepository].
///
/// Every method addresses the one singleton record directly — no queries, no
/// sorting. The key comes from [UserProfileMapper.singletonId] rather than a
/// second constant here, so the key the codec is documented against and the
/// key this class reads cannot drift apart.
///
/// Failures are wrapped so they leave as a `PersistenceException` rather than
/// a `DatabaseException` — [watch] included, since `macroTargetsProvider`
/// renders a stream error through `AsyncValue.error` just as it would a
/// failed future.
class SembastUserProfileRepository implements UserProfileRepository {
  const SembastUserProfileRepository(this._db);

  final Database _db;

  /// Null on a fresh database — the first-launch sentinel, not an error.
  /// `main` reads it to decide whether the onboarding gate opens.
  @override
  Future<UserProfile?> load() =>
      guardPersistence('SembastUserProfileRepository.load', () async {
        final record = await _record.get(_db);
        return record == null ? null : UserProfileMapper.fromRecord(record);
      });

  @override
  Future<UserProfile> save(UserProfile profile) =>
      guardPersistence('SembastUserProfileRepository.save', () async {
        final record = UserProfileMapper.toRecord(profile);
        await _record.put(_db, record);
        return UserProfileMapper.fromRecord(record);
      });

  /// `onSnapshot` reads the record as soon as it is listened to and emits it
  /// before any write — null while none exists. That immediate emission is
  /// what lets the dashboard's macro targets resolve without a separate
  /// [load], and what repaints them the moment screen 4 saves.
  @override
  Stream<UserProfile?> watch() =>
      guardPersistenceStream('SembastUserProfileRepository.watch', () {
        return _record
            .onSnapshot(_db)
            .map(
              (snapshot) => snapshot == null
                  ? null
                  : UserProfileMapper.fromRecord(snapshot.value),
            );
      });

  RecordRef<int, Map<String, Object?>> get _record =>
      userProfileStore.record(UserProfileMapper.singletonId);
}
