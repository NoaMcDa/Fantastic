import 'package:fantastic/features/onboarding/domain/models/activity_level.dart';
import 'package:fantastic/features/onboarding/domain/models/biological_sex.dart';
import 'package:fantastic/features/onboarding/domain/models/keto_goal.dart';
import 'package:fantastic/features/onboarding/domain/models/macro_targets.dart';
import 'package:fantastic/features/onboarding/domain/models/onboarding_data.dart';
import 'package:meta/meta.dart';

/// What onboarding leaves behind: who the user is, what they are after, and
/// the macro targets they agreed to.
///
/// **The existence of this record is the first-launch flag.** There is no
/// separate `hasCompletedOnboarding` boolean to keep in sync with it — the
/// same sentinel convention `StreakRepository.load()` already documents, and
/// the reason `shared_preferences` is not a dependency of this project
/// (`design/m4_preflight.md` §4).
///
/// **The biometrics are nullable and the goal set may be empty, because the
/// flow can be skipped** (#262). A skipped install is a *completed* install
/// on default targets, not an ungated one, so it needs a record — and the
/// app genuinely does not know the four numbers behind that record. Storing
/// a sentinel age and weight instead would keep the model non-null at the
/// price of recording things about the user that are not true, which is
/// exactly what the profile tab would then read back to them. [OnboardingData]
/// is the type that still guarantees all of it, because a *completed* flow
/// really does have every answer.
///
/// Pure domain: no Flutter, no persistence package, no Riverpod. There is no
/// `id` field; the record is a singleton and the data layer pins it to a
/// fixed row.
@immutable
class UserProfile {
  UserProfile({
    required this.targets,
    required Set<KetoGoal> goals,
    required this.activityLevel,
    this.sex,
    this.age,
    this.weightKg,
    this.heightCm,
    this.ketoStartDate,
  }) : goals = Set.unmodifiable(goals);

  /// The profile a completed flow produces: the collected answers, plus the
  /// targets as the user left them on screen 4 — which are not necessarily
  /// the ones the calculator proposed.
  factory UserProfile.fromOnboarding(
    OnboardingData data,
    MacroTargets targets,
  ) => UserProfile(
    sex: data.sex,
    age: data.age,
    weightKg: data.weightKg,
    heightCm: data.heightCm,
    activityLevel: data.activityLevel,
    goals: data.goals,
    targets: targets,
    ketoStartDate: data.ketoStartDate,
  );

  /// The profile a *skipped* flow produces (#262): the default targets, no
  /// biometrics, no goals.
  ///
  /// Still a written record, and that is the whole point — the gate reads the
  /// record's existence, so a skip has to leave one behind or the user is
  /// bounced back into onboarding on the next launch.
  ///
  /// [ActivityLevel.sedentary] rather than null: it is the value every
  /// pre-activity-level record already reads as, it is the conservative tier
  /// (`ActivityCopy.defaultLevel`), and with no biometrics there is no BMR to
  /// multiply by it anyway.
  factory UserProfile.skipped({MacroTargets targets = MacroTargets.defaults}) =>
      UserProfile(
        targets: targets,
        goals: const {},
        activityLevel: ActivityLevel.sedentary,
      );

  /// Null on a skipped profile — see the class doc.
  final BiologicalSex? sex;
  final int? age;
  final double? weightKg;
  final double? heightCm;

  /// How active an ordinary day is. Drives the BMR → TDEE step in
  /// `OnboardingService.calculateMacroTargets` and the training-day bump in
  /// `DailyTargetsService.forDay`.
  final ActivityLevel activityLevel;

  /// What the user wants keto to do for them. One or more on a completed
  /// profile; **empty on a skipped one**, which is what the profile tab
  /// renders as `ProfileCopy.noGoalsChosen`.
  ///
  /// Deliberately not asserted non-empty here, unlike [OnboardingData]: an
  /// empty set is precisely what "skipped" means, and an assertion would make
  /// the skip unrepresentable.
  final Set<KetoGoal> goals;

  /// What the dashboard measures each day against, before any per-day
  /// adjustment. `DailyTargetsService.forDay` adds the training-day bump on
  /// top of these rather than recomputing them, so a target the user
  /// overtyped on screen 4 keeps their number.
  final MacroTargets targets;

  /// Retained so a later profile screen can show it and so the streak seed is
  /// auditable. Nothing recomputes the streak from it after onboarding.
  final DateTime? ketoStartDate;

  /// Whether all four Mifflin-St Jeor inputs are present.
  ///
  /// False for a skipped profile, and the one check every consumer that wants
  /// a BMR has to make first.
  bool get hasBiometrics =>
      sex != null && age != null && weightKg != null && heightCm != null;

  UserProfile copyWith({
    BiologicalSex? sex,
    int? age,
    double? weightKg,
    double? heightCm,
    ActivityLevel? activityLevel,
    Set<KetoGoal>? goals,
    MacroTargets? targets,
    DateTime? ketoStartDate,
    bool clearKetoStartDate = false,
  }) => UserProfile(
    sex: sex ?? this.sex,
    age: age ?? this.age,
    weightKg: weightKg ?? this.weightKg,
    heightCm: heightCm ?? this.heightCm,
    activityLevel: activityLevel ?? this.activityLevel,
    goals: goals ?? this.goals,
    targets: targets ?? this.targets,
    // The explicit flag, not a bare `null` — `StreakState.copyWith` learned
    // this the expensive way (`design/m3_preflight.md` §1.1).
    ketoStartDate: clearKetoStartDate
        ? null
        : ketoStartDate ?? this.ketoStartDate,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          other.sex == sex &&
          other.age == age &&
          other.weightKg == weightKg &&
          other.heightCm == heightCm &&
          other.activityLevel == activityLevel &&
          other.targets == targets &&
          other.ketoStartDate == ketoStartDate &&
          // Unordered, like [OnboardingData]: the same goals are the same
          // profile however they were tapped in.
          other.goals.length == goals.length &&
          other.goals.containsAll(goals);

  @override
  int get hashCode => Object.hash(
    sex,
    age,
    weightKg,
    heightCm,
    activityLevel,
    targets,
    ketoStartDate,
    Object.hashAllUnordered(goals),
  );
}
