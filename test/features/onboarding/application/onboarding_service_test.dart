import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/core/services/notification_service.dart';
import 'package:fantastic/features/adaptation/application/adaptation_phase_service.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:fantastic/features/adaptation/domain/repositories/streak_repository.dart';
import 'package:fantastic/features/onboarding/application/onboarding_service.dart';
import 'package:fantastic/features/onboarding/domain/models/biological_sex.dart';
import 'package:fantastic/features/onboarding/domain/models/keto_goal.dart';
import 'package:fantastic/features/onboarding/domain/models/macro_targets.dart';
import 'package:fantastic/features/onboarding/domain/models/user_profile.dart';
import 'package:fantastic/features/onboarding/domain/repositories/user_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/fixtures.dart';

class _MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

class _MockStreakRepository extends Mock implements StreakRepository {}

class _MockNotificationService extends Mock implements NotificationService {}

void main() {
  late _MockUserProfileRepository profiles;
  late _MockStreakRepository streaks;
  late _MockNotificationService notifications;
  late OnboardingService service;

  setUpAll(() {
    registerFallbackValue(UserProfileFixture.profile());
    registerFallbackValue(StreakState.initial());
  });

  setUp(() {
    profiles = _MockUserProfileRepository();
    streaks = _MockStreakRepository();
    notifications = _MockNotificationService();
    service = OnboardingService(
      profileRepository: profiles,
      streakRepository: streaks,
      // The real state machine, not a mock: the phase a seeded streak lands
      // in is the thing under test, and a stubbed one would assert nothing.
      adaptationPhaseService: AdaptationPhaseService(streaks),
      notificationService: notifications,
    );

    when(() => profiles.save(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as UserProfile,
    );
    when(() => streaks.save(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as StreakState,
    );
    when(notifications.requestPermission).thenAnswer((_) async => true);
  });

  /// The saved streak, or null if nothing was written.
  StreakState? savedStreak() {
    final calls = verify(() => streaks.save(captureAny())).captured;
    return calls.isEmpty ? null : calls.single as StreakState;
  }

  group('calculateMacroTargets', () {
    // Mifflin-St Jeor, male: 10*80 + 6.25*180 - 5*40 + 5 = 1730 kcal BMR.
    // Sedentary TDEE 2076; a weight-loss deficit takes it to 1660.8.
    // Protein 64 g (256 kcal), net carbs 20 g (80 kcal) → 1324.8 kcal of fat
    // → 147 g.
    test('male, weight loss: the 20% deficit is applied', () {
      final targets = service.calculateMacroTargets(
        UserProfileFixture.data(
          sex: BiologicalSex.male,
          age: 40,
          weightKg: 80,
          heightCm: 180,
          goal: KetoGoal.weightLoss,
        ),
      );

      expect(targets.proteinG, 64);
      expect(targets.netCarbsG, OnboardingService.inductionNetCarbsG);
      expect(targets.fatG, 147);
    });

    // Same body, no deficit: TDEE 2076 → 1740 kcal of fat → 193 g.
    test('male, metabolic health: no deficit is applied', () {
      final targets = service.calculateMacroTargets(
        UserProfileFixture.data(
          sex: BiologicalSex.male,
          age: 40,
          weightKg: 80,
          heightCm: 180,
          goal: KetoGoal.metabolicHealth,
        ),
      );

      expect(targets.fatG, 193);
    });

    test('athletic performance gets no deficit either', () {
      final withDeficit = service.calculateMacroTargets(
        UserProfileFixture.data(goal: KetoGoal.weightLoss),
      );
      final without = service.calculateMacroTargets(
        UserProfileFixture.data(goal: KetoGoal.athleticPerformance),
      );
      final metabolic = service.calculateMacroTargets(
        UserProfileFixture.data(goal: KetoGoal.metabolicHealth),
      );

      expect(without.fatG, metabolic.fatG);
      expect(without.fatG, greaterThan(withDeficit.fatG));
    });

    // The two BMR constants differ by 166 kcal, so the same body gets a
    // measurably smaller fat target as female. A formula that used one branch
    // for both sexes would pass a single-sex test.
    test('female gets the -161 constant, not the +5 one', () {
      const args = (age: 40, weightKg: 80.0, heightCm: 180.0);
      final male = service.calculateMacroTargets(
        UserProfileFixture.data(
          sex: BiologicalSex.male,
          age: args.age,
          weightKg: args.weightKg,
          heightCm: args.heightCm,
          goal: KetoGoal.metabolicHealth,
        ),
      );
      final female = service.calculateMacroTargets(
        UserProfileFixture.data(
          sex: BiologicalSex.female,
          age: args.age,
          weightKg: args.weightKg,
          heightCm: args.heightCm,
          goal: KetoGoal.metabolicHealth,
        ),
      );

      expect(female.fatG, lessThan(male.fatG));
      // 166 kcal of BMR × 1.2 activity ÷ 9 kcal/g ≈ 22 g of fat.
      expect(male.fatG - female.fatG, closeTo(22, 1));
    });

    test('protein is 0.8 g per kg of body mass, rounded', () {
      expect(
        service
            .calculateMacroTargets(UserProfileFixture.data(weightKg: 78.5))
            .proteinG,
        63,
      );
    });

    test('net carbs are always the induction allowance', () {
      for (final goal in KetoGoal.values) {
        expect(
          service
              .calculateMacroTargets(UserProfileFixture.data(goal: goal))
              .netCarbsG,
          20,
        );
      }
    });

    // #73's own edge case. It holds by arithmetic here, but the floor is what
    // makes it an invariant rather than a coincidence — a negative or zero
    // target divides through every bar on the dashboard.
    test('a very light, very old user still gets a positive fat target', () {
      final targets = service.calculateMacroTargets(
        UserProfileFixture.data(
          sex: BiologicalSex.female,
          age: 120,
          weightKg: 40,
          heightCm: 140,
          goal: KetoGoal.weightLoss,
        ),
      );

      expect(targets.fatG, greaterThan(0));
    });

    test('the floor holds even when the remainder would go negative', () {
      // 10 kg at 10 cm is not a person; it is the only way to drive the
      // subtraction negative, and it proves the clamp rather than the luck.
      final targets = service.calculateMacroTargets(
        UserProfileFixture.data(
          sex: BiologicalSex.female,
          age: 120,
          weightKg: 10,
          heightCm: 10,
          goal: KetoGoal.weightLoss,
        ),
      );

      expect(targets.fatG, OnboardingService.minimumFatTargetG);
    });

    test('is pure — the same answers give the same targets', () {
      final data = UserProfileFixture.data();

      expect(
        service.calculateMacroTargets(data),
        service.calculateMacroTargets(data),
      );
    });
  });

  group('completeOnboarding', () {
    test(
      'saves a profile carrying the answers and the given targets',
      () async {
        final data = UserProfileFixture.data(
          sex: BiologicalSex.male,
          age: 41,
          weightKg: 91.2,
          heightCm: 183,
          goal: KetoGoal.weightLoss,
        );

        await service.completeOnboarding(
          data: data,
          // Edited by the user on screen 4 — not what the calculator proposed.
          targets: const MacroTargets(fatG: 200, netCarbsG: 25, proteinG: 90),
          now: UserProfileFixture.defaultToday,
        );

        final saved =
            verify(() => profiles.save(captureAny())).captured.single
                as UserProfile;
        expect(saved.sex, BiologicalSex.male);
        expect(saved.age, 41);
        expect(saved.goal, KetoGoal.weightLoss);
        expect(saved.targets.fatG, 200);
        expect(saved.targets.netCarbsG, 25);
      },
    );

    test('returns the saved profile', () async {
      final returned = await service.completeOnboarding(
        data: UserProfileFixture.data(),
        targets: UserProfileFixture.targets(),
        now: UserProfileFixture.defaultToday,
      );

      expect(returned.targets, UserProfileFixture.targets());
    });

    // The prompt nothing in M0–M3 ever fired. `NotificationService` sets every
    // Darwin request flag false at launch specifically so this is the first
    // time it is asked.
    test('asks for notification permission', () async {
      await service.completeOnboarding(
        data: UserProfileFixture.data(),
        targets: UserProfileFixture.targets(),
        now: UserProfileFixture.defaultToday,
      );

      verify(notifications.requestPermission).called(1);
    });

    test('a refused permission does not fail the flow', () async {
      when(notifications.requestPermission).thenAnswer((_) async => false);

      await expectLater(
        service.completeOnboarding(
          data: UserProfileFixture.data(),
          targets: UserProfileFixture.targets(),
          now: UserProfileFixture.defaultToday,
        ),
        completes,
      );
    });

    // Only the profile write can fail this method. Screen 4 reports any
    // throw as `השמירה נכשלה` and never opens the gate, so a throw from
    // either step below told the user their profile had not been saved when
    // it had, and trapped them on the last screen of the flow.
    test('a failed streak seed does not fail the flow', () async {
      when(() => streaks.save(any())).thenThrow(
        const PersistenceException('StreakRepository.save', 'closed'),
      );

      await expectLater(
        service.completeOnboarding(
          data: UserProfileFixture.data(
            ketoStartDate: UserProfileFixture.defaultToday.subtract(
              const Duration(days: 10),
            ),
          ),
          targets: UserProfileFixture.targets(),
          now: UserProfileFixture.defaultToday,
        ),
        completes,
      );

      verify(() => profiles.save(any())).called(1);
    });

    test('a throwing permission prompt does not fail the flow', () async {
      when(notifications.requestPermission).thenThrow(StateError('no plugin'));

      await expectLater(
        service.completeOnboarding(
          data: UserProfileFixture.data(),
          targets: UserProfileFixture.targets(),
          now: UserProfileFixture.defaultToday,
        ),
        completes,
      );
    });

    // The profile is the commit, and it still has to be reported when it is
    // the thing that failed — the fix above must not swallow this one too.
    test('a failed profile save still fails the flow', () async {
      when(() => profiles.save(any())).thenThrow(
        const PersistenceException('UserProfileRepository.save', 'closed'),
      );

      await expectLater(
        service.completeOnboarding(
          data: UserProfileFixture.data(),
          targets: UserProfileFixture.targets(),
          now: UserProfileFixture.defaultToday,
        ),
        throwsA(isA<PersistenceException>()),
      );
    });
  });

  group('streak seeding', () {
    // The crux of §1.3. Writing StreakState.initial() here changes no
    // behaviour — AdaptationPhaseService already substitutes it for a null
    // record — and destroys the "never had a compliant day" sentinel the
    // calendar and the ring are built on.
    test('writes nothing at all when no start date was given', () async {
      await service.completeOnboarding(
        data: UserProfileFixture.data(),
        targets: UserProfileFixture.targets(),
        now: UserProfileFixture.defaultToday,
      );

      verifyNever(() => streaks.save(any()));
    });

    test('writes nothing when the user started today', () async {
      await service.completeOnboarding(
        data: UserProfileFixture.data(
          ketoStartDate: UserProfileFixture.defaultToday,
        ),
        targets: UserProfileFixture.targets(),
        now: UserProfileFixture.defaultToday,
      );

      verifyNever(() => streaks.save(any()));
    });

    test('writes nothing for a start date in the future', () async {
      await service.completeOnboarding(
        data: UserProfileFixture.data(ketoStartDate: DateTime(2026, 10)),
        targets: UserProfileFixture.targets(),
        now: UserProfileFixture.defaultToday,
      );

      verifyNever(() => streaks.save(any()));
    });

    // 22 August to 11 September is 20 completed days — the 20 days *before*
    // today, leaving today still winnable.
    test('counts the days completed before today', () async {
      await service.completeOnboarding(
        data: UserProfileFixture.data(
          ketoStartDate: UserProfileFixture.defaultKetoStartDate,
        ),
        targets: UserProfileFixture.targets(),
        now: UserProfileFixture.defaultToday,
      );

      final seeded = savedStreak()!;
      expect(seeded.currentStreak, 20);
      expect(seeded.highestStreak, 20);
    });

    // If lastCompliantDate were today, the state machine would treat the day
    // as already banked and the first real meal would advance nothing.
    test('leaves today winnable: lastCompliantDate is yesterday', () async {
      await service.completeOnboarding(
        data: UserProfileFixture.data(
          ketoStartDate: UserProfileFixture.defaultKetoStartDate,
        ),
        targets: UserProfileFixture.targets(),
        now: UserProfileFixture.defaultToday,
      );

      expect(savedStreak()!.lastCompliantDate, DateTime(2026, 9, 10));
    });

    test('the seeded date is midnight, not the time of day', () async {
      await service.completeOnboarding(
        data: UserProfileFixture.data(
          ketoStartDate: DateTime(2026, 9, 1, 23, 45),
        ),
        targets: UserProfileFixture.targets(),
        now: DateTime(2026, 9, 11, 10, 30),
      );

      final date = savedStreak()!.lastCompliantDate!;
      expect(date.hour, 0);
      expect(date.minute, 0);
    });

    // A start date one day ago is a one-day streak, which is the smallest
    // thing worth writing.
    test('a single completed day is seeded', () async {
      await service.completeOnboarding(
        data: UserProfileFixture.data(ketoStartDate: DateTime(2026, 9, 10)),
        targets: UserProfileFixture.targets(),
        now: UserProfileFixture.defaultToday,
      );

      expect(savedStreak()!.currentStreak, 1);
    });

    // The phase comes from AdaptationPhaseService, so the 8/28 thresholds
    // exist in exactly one place. Three cases, one either side of each
    // boundary.
    test(
      'the phase follows the seeded streak through both boundaries',
      () async {
        Future<AdaptationPhase> phaseAfter(int completedDays) async {
          reset(streaks);
          when(() => streaks.save(any())).thenAnswer(
            (invocation) async =>
                invocation.positionalArguments.first as StreakState,
          );
          await service.completeOnboarding(
            data: UserProfileFixture.data(
              ketoStartDate: DateTime(2026, 9, 11 - completedDays),
            ),
            targets: UserProfileFixture.targets(),
            now: DateTime(2026, 9, 11, 10, 30),
          );
          return savedStreak()!.phase;
        }

        expect(await phaseAfter(7), AdaptationPhase.induction);
        expect(await phaseAfter(8), AdaptationPhase.fatAdapted);
        expect(await phaseAfter(27), AdaptationPhase.fatAdapted);
        expect(await phaseAfter(28), AdaptationPhase.deepKetosis);
      },
    );

    test('the seeded streak is not in a grace period', () async {
      await service.completeOnboarding(
        data: UserProfileFixture.data(
          ketoStartDate: UserProfileFixture.defaultKetoStartDate,
        ),
        targets: UserProfileFixture.targets(),
        now: UserProfileFixture.defaultToday,
      );

      final seeded = savedStreak()!;
      expect(seeded.inGracePeriod, isFalse);
      expect(seeded.gracePeriodEnd, isNull);
    });

    // Local dates across a DST boundary differ by 23 or 25 hours and `inDays`
    // truncates, so a naive subtraction loses or gains a day. Both ends are
    // rebuilt as UTC midnights to make the count purely calendrical.
    test('a run spanning a DST change counts whole calendar days', () async {
      // Israel moves its clocks back on the last Sunday of October.
      await service.completeOnboarding(
        data: UserProfileFixture.data(ketoStartDate: DateTime(2026, 10, 20)),
        targets: UserProfileFixture.targets(),
        now: DateTime(2026, 11, 3, 9),
      );

      expect(savedStreak()!.currentStreak, 14);
    });
  });
}
