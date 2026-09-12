import 'dart:math' as math;

import 'package:fantastic/core/constants/keto_constants.dart';
import 'package:fantastic/core/providers/notification_providers.dart';
import 'package:fantastic/core/services/notification_service.dart';
import 'package:fantastic/features/adaptation/application/adaptation_phase_service.dart';
import 'package:fantastic/features/adaptation/data/providers.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:fantastic/features/adaptation/domain/repositories/streak_repository.dart';
import 'package:fantastic/features/onboarding/data/providers.dart';
import 'package:fantastic/features/onboarding/domain/mifflin_st_jeor.dart';
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

  /// The fraction of TDEE a [KetoGoal.weightLoss] user eats — a 20% deficit.
  ///
  /// Applied when weight loss is **one of** the goals, not only when it is
  /// the sole goal: somebody who wants to lose weight and train well still
  /// wants the deficit.
  static const double weightLossTdeeFactor = 0.8;

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
  /// Mifflin-St Jeor BMR → TDEE at the user's own activity factor → a 20%
  /// deficit when [KetoGoal.weightLoss] is among the goals → [netCarbTargetFor]
  /// grams of net carbs and 0.8 g/kg of protein taken off the top → fat fills
  /// what is left.
  ///
  /// **The activity factor is the user's answer, not a constant.** M4
  /// multiplied every BMR by a fixed 1.2 because the flow asked no activity
  /// question; screen 2 asks one now, and a user who trains is no longer
  /// handed a sedentary person's targets (`design/m4_handoff.md` §Known gaps).
  MacroTargets calculateMacroTargets(OnboardingData data) {
    final bmr = MifflinStJeor.bmr(
      sex: data.sex,
      age: data.age,
      weightKg: data.weightKg,
      heightCm: data.heightCm,
    );
    var tdee = bmr * data.activityLevel.multiplier;
    if (data.goals.contains(KetoGoal.weightLoss)) {
      tdee *= weightLossTdeeFactor;
    }

    final netCarbsG = netCarbTargetFor(data);
    final proteinG = (data.weightKg * proteinGramsPerKg).roundToDouble();
    // The carb target is subtracted here too, so a higher one costs exactly
    // its own energy in fat rather than being added on top of the day.
    final fatKcal =
        tdee - netCarbsG * kcalPerGramCarb - proteinG * kcalPerGramProtein;

    return MacroTargets(
      fatG: math.max(
        minimumFatTargetG,
        (fatKcal / kcalPerGramFat).roundToDouble(),
      ),
      netCarbsG: netCarbsG,
      proteinG: proteinG,
    );
  }

  /// The net-carb target for [data], in whole grams.
  ///
  /// **Always inside `[KetoConstants.inductionNetCarbsG,
  /// KetoConstants.maxCompliantNetCarbsG]`** — 20 g to 50 g. That clamp is
  /// the invariant and the reason this method exists: the calculator must
  /// never propose a target that is itself a streak breach, whatever the
  /// table says.
  ///
  /// Until now this was the constant 20, returned unchanged for everybody
  /// while fat and protein were computed from the person. The only
  /// personalisation available was to overtype it on screen 4 with no
  /// guidance about what a sensible number for *this* user is.
  ///
  /// Activity sets the starting point; athletic performance adds
  /// [KetoConstants.athleticPerformanceNetCarbBonusG]; weight loss caps at
  /// [KetoConstants.weightLossNetCarbCapG] and wins when both are chosen.
  /// Still only a *default* — screen 4 renders it in an editable field and
  /// the user's number is what gets saved (`design/m4_preflight.md` §5.4).
  double netCarbTargetFor(OnboardingData data) {
    var grams = KetoConstants.netCarbTargetByActivity[data.activityLevel]!;

    if (data.goals.contains(KetoGoal.athleticPerformance)) {
      grams += KetoConstants.athleticPerformanceNetCarbBonusG;
    }
    // After the bonus, deliberately: the cap is a ceiling on the result, not
    // an alternative starting point.
    if (data.goals.contains(KetoGoal.weightLoss)) {
      grams = math.min(grams, KetoConstants.weightLossNetCarbCapG);
    }

    return grams
        .clamp(
          KetoConstants.inductionNetCarbsG,
          KetoConstants.maxCompliantNetCarbsG,
        )
        .roundToDouble();
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
  /// **Best-effort means caught, not merely last.** Only the profile write can
  /// fail this method. A streak seed or a permission prompt that threw used to
  /// propagate, and screen 4 reports any throw as `השמירה נכשלה` — so a broken
  /// `streak_state` store told the user their profile had not been saved when
  /// it had, and left the gate shut, trapping them on the last screen of the
  /// flow for the rest of the session. The profile was on disk the whole time,
  /// which is why the next cold start let them straight in.
  ///
  /// What a swallowed seed costs is one pre-filled streak: the user starts
  /// from zero instead of from their real start date. That is worth far less
  /// than the flow completing.
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

    await _seedStreakAndPrompt(data.ketoStartDate, now);
    return saved;
  }

  /// Commits a **skipped** flow (#262): a profile carrying
  /// [MacroTargets.defaults], no biometrics and no goals.
  ///
  /// A skip is an ordinary completion whose answers are defaults, so
  /// everything downstream — the gate, `macroTargetsProvider`,
  /// `MacroSummaryCard` — needs no special case at all. What makes it a
  /// completion rather than an escape is that it **writes a record**: the
  /// gate reads the record's existence, so a skip that stored nothing would
  /// send the user back into onboarding on the next launch.
  ///
  /// Fails for exactly one reason, like [completeOnboarding]: the profile
  /// write. There is no start date to seed a streak from, and the permission
  /// prompt is still a best-effort extra.
  Future<UserProfile> skipOnboarding() async {
    final saved = await profileRepository.save(UserProfile.skipped());
    await _seedStreakAndPrompt(null, null);
    return saved;
  }

  /// The two best-effort steps both commit paths take, neither of which may
  /// fail the flow. See [completeOnboarding]'s doc for why each is caught.
  Future<void> _seedStreakAndPrompt(DateTime? startDate, DateTime? now) async {
    try {
      await _seedStreak(startDate, now ?? DateTime.now());
    } on Object catch (_) {
      // Deliberately swallowed — see the doc comment. The streak simply
      // starts at zero, which is what it would have done for a user who did
      // not report a past start date at all.
    }

    try {
      // The first moment the prompt is worth spending: the user has just told
      // the app what they want from it. `NotificationService.initialise` sets
      // every Darwin request flag false precisely so this can happen here
      // instead of at launch, and nothing called it until now
      // (`design/m3_handoff.md` §Notifications). A refusal is not an error.
      await notificationService.requestPermission();
    } on Object catch (_) {
      // Nor is an unavailable plugin. Notifications are an extra on top of a
      // finished profile, never a reason to fail one.
    }
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
