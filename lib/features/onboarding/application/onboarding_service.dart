import 'dart:math' as math;

import 'package:fantastic/core/providers/notification_providers.dart';
import 'package:fantastic/core/services/notification_service.dart';
import 'package:fantastic/features/adaptation/application/adaptation_phase_service.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:fantastic/features/adaptation/domain/repositories/streak_repository.dart';
import 'package:fantastic/features/adaptation/data/providers.dart';
import 'package:fantastic/features/onboarding/data/providers.dart';
import 'package:fantastic/features/onboarding/domain/models/biological_sex.dart';
import 'package:fantastic/features/onboarding/domain/models/keto_goal.dart';
import 'package:fantastic/features/onboarding/domain/models/macro_targets.dart';
import 'package:fantastic/features/onboarding/domain/models/onboarding_data.dart';
import 'package:fantastic/features/onboarding/domain/models/user_profile.dart';
import 'package:fantastic/features/onboarding/domain/repositories/user_profile_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_service.g.dart';

/// Turns the onboarding answers into macro targets, and commits the result.
///
/// Pure orchestration over repository interfaces and
/// [AdaptationPhaseService] — no Flutter widgets, no store types, and no
/// second copy of the phase thresholds.
class OnboardingService {
  const OnboardingService({
    required this.profileRepository,
    required this.streakRepository,
    required this.adaptationPhaseService,
    required this.notificationService,
  });

  // Public rather than private, following `MealLoggingService`: Dart forbids
  // a named parameter starting with an underscore, so a
  // `required X x` + `_x` field pairing cannot use an initializing formal and
  // trips `prefer_initializing_formals`.
  final UserProfileRepository profileRepository;
  final StreakRepository streakRepository;
  final AdaptationPhaseService adaptationPhaseService;
  final NotificationService notificationService;

  /// Mifflin-St Jeor's sedentary activity factor.
  ///
  /// The flow asks no activity question, and 1.2 is the floor — a target set
  /// too low leaves the user hungry and blaming keto, a target set too high
  /// stalls weight loss silently. Under-promising on activity is the safer
  /// error for a number the user can edit on the very next screen.
  static const double sedentaryActivityMultiplier = 1.2;

  /// The fraction of TDEE a [KetoGoal.weightLoss] user eats — a 20% deficit.
  static const double weightLossTdeeFactor = 0.8;

  /// The induction net-carb allowance, in grams.
  ///
  /// Calculated as fixed, then shown in an editable field on screen 4:
  /// #73 calls it "not user-adjustable" and #72 renders it editable, and the
  /// editable field wins — see `design/m4_preflight.md` §5.4.
  static const double inductionNetCarbsG = 20;

  /// Protein grams per kilogram of **total** body mass.
  ///
  /// #73's prose says "lean body mass"; nothing in the flow collects body
  /// fat, so lean mass is not computable and its own snippet uses total mass.
  /// Recorded in `design/m4_preflight.md` §6.5 as a product question, not a
  /// bug: 0.8 g/kg is at the low end of keto protein guidance.
  static const double proteinGramsPerKg = 0.8;

  /// Kilocalories per gram, by macro.
  static const double kcalPerGramFat = 9;
  static const double kcalPerGramCarb = 4;
  static const double kcalPerGramProtein = 4;

  /// The fat target never drops below this, in grams.
  ///
  /// Fat is the remainder after carbs and protein are taken out of TDEE, and
  /// a remainder can go negative. It does not, anywhere inside the validated
  /// input ranges — but "does not happen to" is not an invariant, and a
  /// negative or zero fat target would divide through every bar on the
  /// dashboard. #73's own edge case asserts positivity; this is what makes it
  /// true (`design/m4_preflight.md` §6.6).
  static const double minimumFatTargetG = 20;

  /// Personalised daily macro targets for [data].
  ///
  /// Pure and synchronous — the same answers always produce the same targets,
  /// and screen 4 calls it in `initState` without awaiting anything.
  ///
  /// Mifflin-St Jeor BMR → sedentary TDEE → a 20% deficit for
  /// [KetoGoal.weightLoss] → 20 g net carbs and 0.8 g/kg protein taken off
  /// the top → fat fills what is left.
  MacroTargets calculateMacroTargets(OnboardingData data) {
    final bmr = _basalMetabolicRate(data);
    var tdee = bmr * sedentaryActivityMultiplier;
    if (data.goal == KetoGoal.weightLoss) {
      tdee *= weightLossTdeeFactor;
    }

    final proteinG = (data.weightKg * proteinGramsPerKg).roundToDouble();
    final fatKcal =
        tdee -
        inductionNetCarbsG * kcalPerGramCarb -
        proteinG * kcalPerGramProtein;

    return MacroTargets(
      fatG: math.max(
        minimumFatTargetG,
        (fatKcal / kcalPerGramFat).roundToDouble(),
      ),
      netCarbsG: inductionNetCarbsG,
      proteinG: proteinG,
    );
  }

  /// Commits the finished flow: saves the profile, seeds the streak from a
  /// past start date, and asks for notification permission.
  ///
  /// [targets] is what the user left on screen 4, which is not necessarily
  /// what [calculateMacroTargets] proposed.
  ///
  /// **Saving the profile is what ends the first launch** — the gate reads
  /// the record's existence, so this write is the whole commit and it happens
  /// first. The two steps after it are best-effort extras, ordered so neither
  /// can lose the profile if it fails.
  ///
  /// [now] is injectable for tests; production passes nothing.
  Future<UserProfile> completeOnboarding({
    required OnboardingData data,
    required MacroTargets targets,
    DateTime? now,
  }) async {
    final saved = await profileRepository.save(
      UserProfile.fromOnboarding(data, targets),
    );

    await _seedStreak(data.ketoStartDate, now ?? DateTime.now());

    // The first moment the prompt is worth spending: the user has just told
    // the app what they want from it. `NotificationService.initialise` sets
    // every Darwin request flag false precisely so this can happen here
    // instead of at launch, and nothing called it until now
    // (`design/m3_handoff.md` §Notifications). A refusal is not an error.
    await notificationService.requestPermission();

    return saved;
  }

  /// Writes a streak that reflects a keto run already under way.
  ///
  /// **Nothing is written unless there is something to say.** A null start
  /// date, or one of today or later, leaves the record absent — and the
  /// absent record is `StreakRepository.load()`'s documented "never had a
  /// compliant day" sentinel, which `AdaptationPhaseService` already reads as
  /// `StreakState.initial()`. #73 writes `initial()` unconditionally, which
  /// changes no behaviour and destroys that distinction
  /// (`design/m4_preflight.md` §1.3).
  ///
  /// The streak counts days completed **before** today, and
  /// `lastCompliantDate` is yesterday, so today is still winnable: the user's
  /// first compliant meal advances the streak instead of finding the day
  /// already banked and doing nothing.
  Future<void> _seedStreak(DateTime? startDate, DateTime now) async {
    if (startDate == null) {
      return;
    }

    final completedDays = _wholeDaysBetween(startDate, now);
    if (completedDays <= 0) {
      return;
    }

    final seed = StreakState(
      currentStreak: completedDays,
      highestStreak: completedDays,
      lastCompliantDate: DateTime(now.year, now.month, now.day - 1),
    );
    // The phase comes from the state machine, never from a second copy of the
    // 8/28 thresholds (`design/m3_handoff.md` convention 1).
    await streakRepository.save(
      seed.copyWith(phase: adaptationPhaseService.currentPhase(seed)),
    );
  }

  double _basalMetabolicRate(OnboardingData data) {
    final shared = 10 * data.weightKg + 6.25 * data.heightCm - 5 * data.age;
    return switch (data.sex) {
      BiologicalSex.male => shared + 5,
      BiologicalSex.female => shared - 161,
    };
  }

  /// Whole calendar days from [from] to [to], ignoring the time of day.
  ///
  /// Both ends are rebuilt as UTC midnights before subtracting. Subtracting
  /// two *local* dates across a daylight-saving boundary gives a 23- or
  /// 25-hour difference, and `inDays` truncates — which would silently lose
  /// or gain a day of streak exactly once or twice a year.
  static int _wholeDaysBetween(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
}

/// The onboarding use case, wired to its collaborators behind their
/// interfaces.
@riverpod
OnboardingService onboardingService(Ref ref) => OnboardingService(
  profileRepository: ref.watch(userProfileRepositoryProvider),
  streakRepository: ref.watch(streakRepositoryProvider),
  adaptationPhaseService: ref.watch(adaptationPhaseServiceProvider),
  notificationService: ref.watch(notificationServiceProvider),
);
