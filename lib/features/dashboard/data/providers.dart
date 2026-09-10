import 'package:fantastic/core/database/database_provider.dart';
import 'package:fantastic/features/dashboard/data/repositories/sembast_daily_log_repository.dart';
import 'package:fantastic/features/dashboard/domain/repositories/daily_log_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The dashboard feature's repository wiring.
///
/// `DailyLog` is a dashboard model, not a diary one: the diary owns individual
/// meals, the dashboard owns the per-day aggregate they roll up into.
///
/// Returns the domain interface so consumers depend on the abstraction.
@riverpod
DailyLogRepository dailyLogRepository(Ref ref) =>
    SembastDailyLogRepository(ref.watch(databaseProvider));
