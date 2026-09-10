import 'package:fantastic/core/database/database_provider.dart';
import 'package:fantastic/features/adaptation/data/repositories/sembast_streak_repository.dart';
import 'package:fantastic/features/adaptation/domain/repositories/streak_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The adaptation feature's repository wiring.
///
/// Returns the domain interface so consumers depend on the abstraction —
/// `streakStateProvider` (#59) subscribes to `StreakRepository.watch()`
/// through this, with no knowledge that sembast is underneath.
@riverpod
StreakRepository streakRepository(Ref ref) =>
    SembastStreakRepository(ref.watch(databaseProvider));
