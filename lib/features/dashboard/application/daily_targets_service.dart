import 'package:fantastic/features/dashboard/application/providers/daily_log_providers.dart';
import 'package:fantastic/features/dashboard/data/providers.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:fantastic/features/dashboard/domain/repositories/daily_log_repository.dart';
import 'package:fantastic/features/onboarding/application/onboarding_service.dart';
import 'package:fantastic/features/onboarding/application/providers/user_profile_providers.dart';
import 'package:fantastic/features/onboarding/domain/mifflin_st_jeor.dart';
import 'package:fantastic/features/onboarding/domain/models/keto_goal.dart';
import 'package:fantastic/features/onboarding/domain/models/macro_targets.dart';
import 'package:fantastic/features/onboarding/domain/models/user_profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'daily_targets_service.g.dart';

/// The targets a **particular day** is measured against.
///
/// The profile holds one set of targets, agreed once on onboarding screen 4.
/// A day the user trained on costs more energy than a day they did not, and
/// measuring both against the same number tells somebody who just trained
/// that they overate.
///
/// Pure orchestration over [DailyLogRepository] and the domain — no Flutter,
/// no store types, and no second copy of the Mifflin-St Jeor equation.
class DailyTargetsService {
  const DailyTargetsService({required this.dailyLogRepository});

  final DailyLogRepository dailyLogRepository;

  /// The targets [log]'s day is measured against.
  ///
  /// **Static, because it is pure.** It reads a profile and a log and returns
  /// a number; it touches no store. Leaving it an instance method would have
  /// made every reader of a day's targets construct a repository — and so
  /// open a database — to run arithmetic, which is exactly what broke the
  /// dashboard card's widget tests when it was one.
  ///
  /// **A delta on top of [UserProfile.targets], never a recompute.** The base
  /// is whatever the user left in the fields on screen 4, which is not
  /// necessarily what the calculator proposed — so recomputing from their
  /// biometrics here would quietly discard an edit they made deliberately.
  /// Adding the day's bump to their own number keeps it on every day.
  ///
  /// **Only fat moves.** On keto the extra energy a training day needs is
  /// fat: raising net carbs would eat into the very allowance the streak is
  /// measured on, and raising protein is a different (and unasked) product
  /// decision about muscle. Net carbs and protein come back untouched.
  ///
  /// Returns the base targets unchanged when there is nothing to add:
  ///
  /// - the day is not flagged as a training day, or has no log at all;
  /// - the profile has no biometrics — a skipped flow (#262) leaves no BMR to
  ///   compute a bump from;
  /// - the user is already [ActivityLevel.veryActive], whose training-day
  ///   tier is itself, so the difference is zero.
  static MacroTargets forDay({
    required UserProfile profile,
    required DailyLog? log,
  }) {
    if (log == null || !log.trainingDay || !profile.hasBiometrics) {
      return profile.targets;
    }

    final level = profile.activityLevel;
    final bmr = MifflinStJeor.bmr(
      sex: profile.sex!,
      age: profile.age!,
      weightKg: profile.weightKg!,
      heightCm: profile.heightCm!,
    );

    var extraKcal = bmr * (level.onTrainingDay.multiplier - level.multiplier);
    // The deficit applied to the base targets applies to the bump too —
    // otherwise a training day would hand a weight-loss user back the 20% the
    // calculator took off.
    if (profile.goals.contains(KetoGoal.weightLoss)) {
      extraKcal *= OnboardingService.weightLossTdeeFactor;
    }
    if (extraKcal <= 0) {
      return profile.targets;
    }

    return profile.targets.copyWith(
      fatG:
          profile.targets.fatG +
          (extraKcal / OnboardingService.kcalPerGramFat).roundToDouble(),
    );
  }

  /// Marks or unmarks [date] as a day the user trained on.
  ///
  /// Upserts that day's [DailyLog], **touching no macro total**: a day
  /// flagged before anything is eaten stays all-zero, which
  /// `AdaptationPhaseService` reads as unlogged. Saying you went to the gym
  /// cannot bank a day toward the streak.
  ///
  /// The date is normalised to midnight, matching
  /// [DailyLogRepository.findByDate].
  Future<void> setTrainingDay(DateTime date, {required bool trained}) async {
    final day = DateTime(date.year, date.month, date.day);
    final existing = await dailyLogRepository.findByDate(day);
    await dailyLogRepository.save(
      (existing ?? DailyLog(date: day)).copyWith(trainingDay: trained),
    );
  }
}

/// The per-day target calculator, wired to its repository interface.
@riverpod
DailyTargetsService dailyTargetsService(Ref ref) => DailyTargetsService(
  dailyLogRepository: ref.watch(dailyLogRepositoryProvider),
);

/// The targets for [date], with the training-day bump already applied.
///
/// What `MacroSummaryCard` reads in place of `macroTargetsProvider`.
///
/// **Composed by pattern-matching two `AsyncValue`s, never by awaiting
/// `.future`.** riverpod 3 reports a provider that fails *before ever
/// producing a value* as `AsyncLoading` **with an error attached**, and its
/// `.future` never completes — the trap that cost M3 three issues and M4 its
/// router. Errors are checked before loading here for the same reason.
///
/// A missing profile yields [MacroTargets.defaults], the same fallback
/// `macroTargetsProvider` makes; a *failed read* yields an error, because a
/// profile that cannot be read is not a profile that says 150 g of fat.
@riverpod
AsyncValue<MacroTargets> dailyTargets(Ref ref, DateTime date) {
  final profileAsync = ref.watch(onboardedProfileProvider);
  final logAsync = ref.watch(todaysDailyLogProvider(date));

  if (profileAsync.hasError) {
    return AsyncError(
      profileAsync.error!,
      profileAsync.stackTrace ?? StackTrace.empty,
    );
  }
  if (logAsync.hasError) {
    return AsyncError(logAsync.error!, logAsync.stackTrace ?? StackTrace.empty);
  }
  if (!profileAsync.hasValue || !logAsync.hasValue) {
    return const AsyncLoading();
  }

  final profile = profileAsync.requireValue;
  if (profile == null) {
    return const AsyncData(MacroTargets.defaults);
  }

  // The static calculation, not the provider: reading the service here would
  // pull in `DailyLogRepository`, and so the database, to do arithmetic.
  return AsyncData(
    DailyTargetsService.forDay(profile: profile, log: logAsync.requireValue),
  );
}
