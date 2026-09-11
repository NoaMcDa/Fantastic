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
/// Pure domain: no Flutter, no persistence package, no Riverpod. There is no
/// `id` field; the record is a singleton and the data layer pins it to a
/// fixed row.
@immutable
class UserProfile {
  const UserProfile({
    required this.sex,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.goal,
    required this.targets,
    this.ketoStartDate,
  });

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
    goal: data.goal,
    targets: targets,
    ketoStartDate: data.ketoStartDate,
  );

  final BiologicalSex sex;
  final int age;
  final double weightKg;
  final double heightCm;
  final KetoGoal goal;

  /// What the dashboard measures each day against.
  final MacroTargets targets;

  /// Retained so a later profile screen can show it and so the streak seed is
  /// auditable. Nothing recomputes the streak from it after onboarding.
  final DateTime? ketoStartDate;

  UserProfile copyWith({
    BiologicalSex? sex,
    int? age,
    double? weightKg,
    double? heightCm,
    KetoGoal? goal,
    MacroTargets? targets,
    DateTime? ketoStartDate,
    bool clearKetoStartDate = false,
  }) => UserProfile(
    sex: sex ?? this.sex,
    age: age ?? this.age,
    weightKg: weightKg ?? this.weightKg,
    heightCm: heightCm ?? this.heightCm,
    goal: goal ?? this.goal,
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
          other.goal == goal &&
          other.targets == targets &&
          other.ketoStartDate == ketoStartDate;

  @override
  int get hashCode =>
      Object.hash(sex, age, weightKg, heightCm, goal, targets, ketoStartDate);
}
