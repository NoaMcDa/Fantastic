import 'package:fantastic/features/onboarding/domain/models/activity_level.dart';
import 'package:fantastic/features/onboarding/domain/models/biological_sex.dart';
import 'package:fantastic/features/onboarding/domain/models/keto_goal.dart';
import 'package:fantastic/features/onboarding/domain/models/macro_targets.dart';
import 'package:fantastic/features/onboarding/domain/models/onboarding_data.dart';
import 'package:fantastic/features/onboarding/domain/models/user_profile.dart';

/// Test data for the onboarding value objects.
///
/// Deterministic throughout — the keto start date is fixed, never derived
/// from `DateTime.now()`.
///
/// **Every default is distinct.** `SymptomLogFixture` defaults every scale to
/// 3 and a mapper that crossed two fields still passed; these four
/// same-typed numbers (age 34, weight 78.5, height 176.0, and three targets)
/// share no value, so a codec that swapped weight for height fails here.
///
/// The goal parameter is a **set**, and defaults to a single goal: most tests
/// care about one, and the ones that care about several say so.
abstract final class UserProfileFixture {
  /// The fixed "already on keto since" date. 20 days before
  /// [defaultToday] — deep enough into phase 2 that a seeded streak is
  /// visibly not phase 1, and short of the 28-day phase-3 boundary.
  static final DateTime defaultKetoStartDate = DateTime(2026, 8, 22);

  /// The "today" seeding tests measure [defaultKetoStartDate] against.
  static final DateTime defaultToday = DateTime(2026, 9, 11, 10, 30);

  /// The default goal set.
  ///
  /// [KetoGoal.metabolicHealth] deliberately: it is the one goal that changes
  /// no arithmetic, so a test that does not mention goals is not silently
  /// getting a deficit or a carb bonus it did not ask for.
  static const Set<KetoGoal> defaultGoals = {KetoGoal.metabolicHealth};

  static MacroTargets targets({
    double fatG = 140,
    double netCarbsG = 20,
    double proteinG = 63,
  }) => MacroTargets(fatG: fatG, netCarbsG: netCarbsG, proteinG: proteinG);

  static PartialOnboardingData partial({
    BiologicalSex sex = BiologicalSex.female,
    int age = 34,
    double weightKg = 78.5,
    double heightCm = 176,
    ActivityLevel activityLevel = ActivityLevel.sedentary,
    DateTime? ketoStartDate,
  }) => PartialOnboardingData(
    sex: sex,
    age: age,
    weightKg: weightKg,
    heightCm: heightCm,
    activityLevel: activityLevel,
    ketoStartDate: ketoStartDate,
  );

  static OnboardingData data({
    BiologicalSex sex = BiologicalSex.female,
    int age = 34,
    double weightKg = 78.5,
    double heightCm = 176,
    ActivityLevel activityLevel = ActivityLevel.sedentary,
    Set<KetoGoal> goals = defaultGoals,
    DateTime? ketoStartDate,
  }) => OnboardingData(
    sex: sex,
    age: age,
    weightKg: weightKg,
    heightCm: heightCm,
    activityLevel: activityLevel,
    goals: goals,
    ketoStartDate: ketoStartDate,
  );

  static UserProfile profile({
    BiologicalSex? sex = BiologicalSex.female,
    int? age = 34,
    double? weightKg = 78.5,
    double? heightCm = 176,
    ActivityLevel activityLevel = ActivityLevel.sedentary,
    Set<KetoGoal> goals = defaultGoals,
    MacroTargets? targets,
    DateTime? ketoStartDate,
  }) => UserProfile(
    sex: sex,
    age: age,
    weightKg: weightKg,
    heightCm: heightCm,
    activityLevel: activityLevel,
    goals: goals,
    targets: targets ?? UserProfileFixture.targets(),
    ketoStartDate: ketoStartDate,
  );
}
