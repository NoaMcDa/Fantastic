import 'package:fantastic/features/onboarding/domain/models/biological_sex.dart';
import 'package:fantastic/features/onboarding/domain/models/keto_goal.dart';
import 'package:meta/meta.dart';

/// The answers collected on onboarding screen 2, before a goal is chosen.
///
/// Carried to screen 3 as go_router `extra`. Two types rather than one
/// nullable-goal type so the flow cannot reach the calculator with a goal
/// nobody picked: [withGoal] is the only way to produce an [OnboardingData],
/// and it takes a non-null [KetoGoal].
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
    this.ketoStartDate,
  });

  final BiologicalSex sex;
  final int age;
  final double weightKg;
  final double heightCm;

  /// When the user says they started keto, from the "כבר בקטו?" toggle.
  ///
  /// Null means "starting today", which is also what a date of today or later
  /// means to the seeder — see `OnboardingService.completeOnboarding`.
  final DateTime? ketoStartDate;

  /// Completes the answers with the goal chosen on screen 3.
  OnboardingData withGoal(KetoGoal goal) => OnboardingData(
    sex: sex,
    age: age,
    weightKg: weightKg,
    heightCm: heightCm,
    goal: goal,
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
          other.ketoStartDate == ketoStartDate;

  @override
  int get hashCode => Object.hash(sex, age, weightKg, heightCm, ketoStartDate);
}

/// Every answer the onboarding flow collects.
///
/// The input to `OnboardingService.calculateMacroTargets`, and the source of
/// everything but the targets on the saved `UserProfile`.
@immutable
class OnboardingData {
  const OnboardingData({
    required this.sex,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.goal,
    this.ketoStartDate,
  });

  final BiologicalSex sex;
  final int age;
  final double weightKg;
  final double heightCm;
  final KetoGoal goal;

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
          other.goal == goal &&
          other.ketoStartDate == ketoStartDate;

  @override
  int get hashCode =>
      Object.hash(sex, age, weightKg, heightCm, goal, ketoStartDate);
}
