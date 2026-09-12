import 'package:fantastic/features/onboarding/domain/models/activity_level.dart';
import 'package:fantastic/features/onboarding/domain/models/biological_sex.dart';
import 'package:fantastic/features/onboarding/domain/models/keto_goal.dart';
import 'package:meta/meta.dart';

/// The answers collected on onboarding screen 2, before goals are chosen.
///
/// Carried to screen 3 as go_router `extra`. Two types rather than one
/// type with an empty goal set, so the flow cannot reach the calculator with
/// goals nobody picked: [withGoals] is the only way to produce an
/// [OnboardingData], and [OnboardingData] asserts its set is not empty.
///
/// **`extra` is not serialisable and does not survive a browser reload** —
/// reloading mid-flow restarts it at step 1. See `design/m4_preflight.md`
/// §3.2.
@immutable
class PartialOnboardingData {
  const PartialOnboardingData({
    required this.sex,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.activityLevel,
    this.ketoStartDate,
  });

  final BiologicalSex sex;
  final int age;
  final double weightKg;
  final double heightCm;

  /// How active an ordinary day is, chosen on screen 2.
  ///
  /// Feeds the BMR → TDEE step directly. M4 had no such answer and assumed
  /// [ActivityLevel.sedentary] for everyone.
  final ActivityLevel activityLevel;

  /// When the user says they started keto, from the "כבר בקטו?" toggle.
  ///
  /// Null means "starting today", which is also what a date of today or later
  /// means to the seeder — see `OnboardingService.completeOnboarding`.
  final DateTime? ketoStartDate;

  /// Completes the answers with the goals chosen on screen 3.
  ///
  /// [goals] must not be empty — screen 3 keeps its CTA disabled until at
  /// least one card is selected, and [OnboardingData] asserts it.
  OnboardingData withGoals(Set<KetoGoal> goals) => OnboardingData(
    sex: sex,
    age: age,
    weightKg: weightKg,
    heightCm: heightCm,
    activityLevel: activityLevel,
    goals: goals,
    ketoStartDate: ketoStartDate,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartialOnboardingData &&
          other.sex == sex &&
          other.age == age &&
          other.weightKg == weightKg &&
          other.heightCm == heightCm &&
          other.activityLevel == activityLevel &&
          other.ketoStartDate == ketoStartDate;

  @override
  int get hashCode =>
      Object.hash(sex, age, weightKg, heightCm, activityLevel, ketoStartDate);
}

/// Every answer the onboarding flow collects.
///
/// The input to `OnboardingService.calculateMacroTargets`, and the source of
/// everything but the targets on the saved `UserProfile`.
@immutable
class OnboardingData {
  OnboardingData({
    required this.sex,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.activityLevel,
    required Set<KetoGoal> goals,
    this.ketoStartDate,
  }) : assert(goals.isNotEmpty, 'a completed flow has at least one goal'),
       // Copied and sealed: the caller is screen 3, which holds the live set
       // it is still mutating as the user taps cards.
       goals = Set.unmodifiable(goals);

  final BiologicalSex sex;
  final int age;
  final double weightKg;
  final double heightCm;

  /// See [PartialOnboardingData.activityLevel].
  final ActivityLevel activityLevel;

  /// What the user wants keto to do for them — one or more, never none.
  ///
  /// A set rather than a single value because the reasons are not exclusive:
  /// somebody can want to lose weight *and* train well, and M4 made them drop
  /// one. Two goals change the arithmetic — [KetoGoal.weightLoss] applies the
  /// TDEE deficit, [KetoGoal.athleticPerformance] raises the net-carb target
  /// — and `OnboardingService` reads both with `contains`.
  final Set<KetoGoal> goals;

  /// See [PartialOnboardingData.ketoStartDate].
  final DateTime? ketoStartDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnboardingData &&
          other.sex == sex &&
          other.age == age &&
          other.weightKg == weightKg &&
          other.heightCm == heightCm &&
          other.activityLevel == activityLevel &&
          other.ketoStartDate == ketoStartDate &&
          other.goals.length == goals.length &&
          other.goals.containsAll(goals);

  @override
  int get hashCode => Object.hash(
    sex,
    age,
    weightKg,
    heightCm,
    activityLevel,
    ketoStartDate,
    // Unordered: two sets with the same members are the same answer however
    // the user tapped them in.
    Object.hashAllUnordered(goals),
  );
}
