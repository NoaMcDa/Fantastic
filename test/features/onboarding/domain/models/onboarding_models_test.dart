import 'package:fantastic/core/constants/keto_constants.dart';
import 'package:fantastic/features/onboarding/domain/models/biological_sex.dart';
import 'package:fantastic/features/onboarding/domain/models/activity_level.dart';
import 'package:fantastic/features/onboarding/domain/models/keto_goal.dart';
import 'package:fantastic/features/onboarding/domain/models/macro_targets.dart';
import 'package:fantastic/features/onboarding/domain/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';

void main() {
  group('MacroTargets', () {
    test('defaults are the KetoConstants the dashboard used before M4', () {
      expect(MacroTargets.defaults.fatG, KetoConstants.defaultFatTargetG);
      expect(
        MacroTargets.defaults.netCarbsG,
        KetoConstants.defaultNetCarbTargetG,
      );
      expect(
        MacroTargets.defaults.proteinG,
        KetoConstants.defaultProteinTargetG,
      );
    });

    test('two targets with the same numbers are equal', () {
      expect(
        UserProfileFixture.targets(),
        equals(UserProfileFixture.targets()),
      );
      expect(
        UserProfileFixture.targets().hashCode,
        UserProfileFixture.targets().hashCode,
      );
    });

    // Each field separately, because an `==` that compared only two of three
    // would pass a test that varied the third alone.
    test('a difference in any single macro breaks equality', () {
      expect(
        UserProfileFixture.targets(fatG: 141),
        isNot(UserProfileFixture.targets()),
      );
      expect(
        UserProfileFixture.targets(netCarbsG: 25),
        isNot(UserProfileFixture.targets()),
      );
      expect(
        UserProfileFixture.targets(proteinG: 64),
        isNot(UserProfileFixture.targets()),
      );
    });

    test('copyWith replaces only what it is given', () {
      final edited = UserProfileFixture.targets().copyWith(fatG: 200);

      expect(edited.fatG, 200);
      expect(edited.netCarbsG, UserProfileFixture.targets().netCarbsG);
      expect(edited.proteinG, UserProfileFixture.targets().proteinG);
    });

    test('toString names all three macros', () {
      expect(UserProfileFixture.targets().toString(), contains('140'));
      expect(UserProfileFixture.targets().toString(), contains('63'));
    });
  });

  group('PartialOnboardingData.withGoals', () {
    test('carries every answer through and adds the goals', () {
      final partial = UserProfileFixture.partial(
        sex: BiologicalSex.male,
        age: 41,
        weightKg: 91.2,
        heightCm: 183,
        activityLevel: ActivityLevel.active,
        ketoStartDate: UserProfileFixture.defaultKetoStartDate,
      );

      final complete = partial.withGoals({KetoGoal.athleticPerformance});

      expect(complete.sex, BiologicalSex.male);
      expect(complete.age, 41);
      expect(complete.weightKg, 91.2);
      expect(complete.heightCm, 183);
      expect(complete.activityLevel, ActivityLevel.active);
      expect(complete.ketoStartDate, UserProfileFixture.defaultKetoStartDate);
      expect(complete.goals, {KetoGoal.athleticPerformance});
    });

    test('a null start date stays null', () {
      expect(
        UserProfileFixture.partial().withGoals({
          KetoGoal.weightLoss,
        }).ketoStartDate,
        isNull,
      );
    });

    test('equality covers every field', () {
      expect(UserProfileFixture.partial(), UserProfileFixture.partial());
      expect(
        UserProfileFixture.partial(age: 35),
        isNot(UserProfileFixture.partial()),
      );
      expect(
        UserProfileFixture.partial().hashCode,
        UserProfileFixture.partial().hashCode,
      );
    });
  });

  group('OnboardingData', () {
    test('equality covers the goal and the start date', () {
      expect(UserProfileFixture.data(), UserProfileFixture.data());
      expect(
        UserProfileFixture.data(goals: {KetoGoal.weightLoss}),
        isNot(UserProfileFixture.data()),
      );
      expect(
        UserProfileFixture.data(
          ketoStartDate: UserProfileFixture.defaultKetoStartDate,
        ),
        isNot(UserProfileFixture.data()),
      );
      expect(
        UserProfileFixture.data().hashCode,
        UserProfileFixture.data().hashCode,
      );
    });
  });

  group('UserProfile.fromOnboarding', () {
    test('takes the biometrics from the answers and the targets as given', () {
      final profile = UserProfile.fromOnboarding(
        UserProfileFixture.data(
          sex: BiologicalSex.male,
          age: 41,
          weightKg: 91.2,
          heightCm: 183,
          goals: {KetoGoal.weightLoss},
          ketoStartDate: UserProfileFixture.defaultKetoStartDate,
        ),
        UserProfileFixture.targets(fatG: 199),
      );

      expect(profile.sex, BiologicalSex.male);
      expect(profile.age, 41);
      expect(profile.weightKg, 91.2);
      expect(profile.heightCm, 183);
      expect(profile.goals, {KetoGoal.weightLoss});
      expect(profile.ketoStartDate, UserProfileFixture.defaultKetoStartDate);
      // The user's edit, not the calculator's proposal.
      expect(profile.targets.fatG, 199);
    });
  });

  group('UserProfile.copyWith', () {
    test('replaces only what it is given', () {
      final edited = UserProfileFixture.profile().copyWith(age: 50);

      expect(edited.age, 50);
      expect(edited.weightKg, UserProfileFixture.profile().weightKg);
      expect(edited.targets, UserProfileFixture.profile().targets);
    });

    // The M3 lesson: a bare null cannot express "set this back to null", and
    // the assertion has to be on the cleared field itself.
    test('clearKetoStartDate clears it; a bare null does not', () {
      final withDate = UserProfileFixture.profile(
        ketoStartDate: UserProfileFixture.defaultKetoStartDate,
      );

      expect(withDate.copyWith().ketoStartDate, isNotNull);
      expect(withDate.copyWith(clearKetoStartDate: true).ketoStartDate, isNull);
    });

    test('equality covers every field', () {
      expect(UserProfileFixture.profile(), UserProfileFixture.profile());
      expect(
        UserProfileFixture.profile(heightCm: 177),
        isNot(UserProfileFixture.profile()),
      );
      expect(
        UserProfileFixture.profile(
          targets: UserProfileFixture.targets(fatG: 1),
        ),
        isNot(UserProfileFixture.profile()),
      );
      expect(
        UserProfileFixture.profile().hashCode,
        UserProfileFixture.profile().hashCode,
      );
    });
  });

  group('goal sets', () {
    // A *completed* flow always has at least one goal — screen 3 keeps its
    // CTA disabled until one is chosen — so the assertion belongs here and
    // not on `UserProfile`, where an empty set is what "skipped" means.
    test('OnboardingData rejects an empty goal set', () {
      expect(
        () => UserProfileFixture.data(goals: const {}),
        throwsA(isA<AssertionError>()),
      );
    });

    test('UserProfile accepts an empty goal set', () {
      expect(UserProfile.skipped().goals, isEmpty);
    });

    test('goal-set equality is order-independent', () {
      expect(
        UserProfileFixture.data(
          goals: {KetoGoal.weightLoss, KetoGoal.athleticPerformance},
        ),
        UserProfileFixture.data(
          goals: {KetoGoal.athleticPerformance, KetoGoal.weightLoss},
        ),
      );
      expect(
        UserProfileFixture.profile(
          goals: {KetoGoal.weightLoss, KetoGoal.athleticPerformance},
        ).hashCode,
        UserProfileFixture.profile(
          goals: {KetoGoal.athleticPerformance, KetoGoal.weightLoss},
        ).hashCode,
      );
    });

    test('a different goal set is a different profile', () {
      expect(
        UserProfileFixture.profile(goals: {KetoGoal.weightLoss}),
        isNot(
          UserProfileFixture.profile(
            goals: {KetoGoal.weightLoss, KetoGoal.metabolicHealth},
          ),
        ),
      );
    });

    // Screen 3 keeps mutating the set it is holding as the user taps, so the
    // value objects seal what they are given.
    test('the stored set cannot be mutated through the caller', () {
      final live = {KetoGoal.weightLoss};
      final data = UserProfileFixture.data(goals: live);

      live.add(KetoGoal.metabolicHealth);

      expect(data.goals, {KetoGoal.weightLoss});
      expect(() => data.goals.add(KetoGoal.metabolicHealth), throwsA(anything));
    });
  });

  group('a skipped profile', () {
    test('carries the default targets and no answers', () {
      final skipped = UserProfile.skipped();

      expect(skipped.targets, MacroTargets.defaults);
      expect(skipped.hasBiometrics, isFalse);
      expect(skipped.goals, isEmpty);
      expect(skipped.activityLevel, ActivityLevel.sedentary);
    });

    test('hasBiometrics is false when any one of the four is missing', () {
      expect(UserProfileFixture.profile().hasBiometrics, isTrue);
      expect(UserProfileFixture.profile(sex: null).hasBiometrics, isFalse);
      expect(UserProfileFixture.profile(age: null).hasBiometrics, isFalse);
      expect(UserProfileFixture.profile(weightKg: null).hasBiometrics, isFalse);
      expect(UserProfileFixture.profile(heightCm: null).hasBiometrics, isFalse);
    });
  });
}
