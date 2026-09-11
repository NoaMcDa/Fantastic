import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/domain/models/symptom_log.dart';
import 'package:fantastic/features/diary/domain/repositories/symptom_log_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'symptom_logging_service.g.dart';

/// The symptom diary's write and read path: one [SymptomLog] per calendar day.
///
/// Deliberately thinner than `MealLoggingService` — a symptom log rolls up
/// into nothing, so there is no aggregate to recalculate and no streak to
/// evaluate. What it does own is the score contract, and the reason that is
/// worth a service at all is subtle:
///
/// [SymptomLog]'s constructor asserts every score is 1–5, and its own doc
/// comment records that `assert` is compiled out in release builds, so *"the
/// data layer does not rely on these holding at runtime"*. This service is
/// what makes the range hold at runtime. In debug the constructor fires first
/// and this check never runs; in release the constructor is silent and this
/// check is the only thing between a bad score and the store.
///
/// Talks only to [SymptomLogRepository] — never to the store, per Epic #9's
/// architectural invariant.
class SymptomLoggingService {
  const SymptomLoggingService(this._repository);

  final SymptomLogRepository _repository;

  /// Lower and upper bound of every symptom scale, inclusive.
  ///
  /// Named here rather than repeated as literals so the sheet's segmented
  /// selector and this validation cannot disagree about how many options
  /// there are.
  static const int minScore = 1;
  static const int maxScore = 5;

  /// Upserts [log] for its calendar date. Returns the persisted copy, which
  /// carries the record's yyyyMMdd id.
  ///
  /// Throws [ArgumentError] if any of the four scores falls outside
  /// [minScore]–[maxScore]. A storage failure surfaces as the
  /// `PersistenceException` the repository threw — this service does not
  /// catch it, per `design/base_design.md` §Error Handling Contract.
  Future<SymptomLog> logSymptoms(SymptomLog log) {
    _validateScores(log);
    return _repository.save(log);
  }

  /// The log for [date], or null when the day has none.
  ///
  /// Null is "not logged yet", not a failure — callers render an empty state.
  ///
  /// The date is normalised to midnight before the query, so a caller holding
  /// a wall-clock time still reads the right day. (The repository keys on
  /// `SymptomLogMapper.dateIndex`, which ignores the time component anyway;
  /// normalising here means the service does not depend on that.)
  Future<SymptomLog?> symptomsForDate(DateTime date) =>
      _repository.findByDate(DateTime(date.year, date.month, date.day));

  void _validateScores(SymptomLog log) {
    _validateScore(log.energyScore, 'energyScore');
    _validateScore(log.clarityScore, 'clarityScore');
    _validateScore(log.hungerScore, 'hungerScore');
    _validateScore(log.moodScore, 'moodScore');
    // `log.symptoms` is deliberately unchecked: PhysicalSymptom is a closed
    // enum, so an out-of-range value is not constructible.
  }

  static void _validateScore(int score, String name) {
    if (score < minScore || score > maxScore) {
      throw ArgumentError.value(
        score,
        name,
        'symptom scores must be between $minScore and $maxScore',
      );
    }
  }
}

@riverpod
SymptomLoggingService symptomLoggingService(Ref ref) =>
    SymptomLoggingService(ref.watch(symptomLogRepositoryProvider));
