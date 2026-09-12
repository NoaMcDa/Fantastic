import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/dashboard/application/daily_targets_service.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:fantastic/features/dashboard/application/providers/daily_log_providers.dart';
import 'package:fantastic/features/dashboard/domain/repositories/daily_log_repository.dart';
import 'package:fantastic/features/onboarding/application/onboarding_service.dart';
import 'package:fantastic/features/onboarding/application/providers/user_profile_providers.dart';
import 'package:fantastic/features/onboarding/domain/mifflin_st_jeor.dart';
import 'package:fantastic/features/onboarding/domain/models/activity_level.dart';
import 'package:fantastic/features/onboarding/domain/models/biological_sex.dart';
import 'package:fantastic/features/onboarding/domain/models/keto_goal.dart';
import 'package:fantastic/features/onboarding/domain/models/macro_targets.dart';
import 'package:fantastic/features/onboarding/domain/models/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/fixtures.dart';

class _MockDailyLogRepository extends Mock implements DailyLogRepository {}

void main() {
  late _MockDailyLogRepository logs;
  late DailyTargetsService service;

  final date = DateTime(2026, 9, 12);

  setUpAll(() => registerFallbackValue(DailyLog(date: DateTime(2026))));

  setUp(() {
    logs = _MockDailyLogRepository();
    service = DailyTargetsService(dailyLogRepository: logs);

    when(() => logs.findByDate(any())).thenAnswer((_) async => null);
    when(() => logs.save(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as DailyLog,
    );
  });

  /// A profile whose BMR is a round 1730 kcal, so the bumps below are
  /// checkable by hand.
  UserProfile profileAt(
    ActivityLevel level, {
    Set<KetoGoal> goals = const {KetoGoal.metabolicHealth},
    MacroTargets? targets,
  }) => UserProfileFixture.profile(
    sex: BiologicalSex.male,
    age: 40,
    weightKg: 80,
    heightCm: 180,
    activityLevel: level,
    goals: goals,
    targets: targets,
  );

  DailyLog trainingLog() =>
      DailyLogFixture.fixture(date: date).copyWith(trainingDay: true);

  group('forDay', () {
    test('a rest day returns the base targets untouched', () {
      final profile = profileAt(ActivityLevel.moderate);

      expect(
        DailyTargetsService.forDay(
          profile: profile,
          log: DailyLogFixture.fixture(date: date),
        ),
        profile.targets,
      );
    });

    test('a day with no log at all returns the base targets', () {
      final profile = profileAt(ActivityLevel.moderate);

      expect(
        DailyTargetsService.forDay(profile: profile, log: null),
        profile.targets,
      );
    });

    test('a training day raises only fat', () {
      final profile = profileAt(ActivityLevel.moderate);

      final adjusted = DailyTargetsService.forDay(
        profile: profile,
        log: trainingLog(),
      );

      expect(adjusted.fatG, greaterThan(profile.targets.fatG));
      expect(adjusted.netCarbsG, profile.targets.netCarbsG);
      expect(adjusted.proteinG, profile.targets.proteinG);
    });

    test('the bump is one activity tier, converted to fat', () {
      final profile = profileAt(ActivityLevel.moderate);
      final bmr = MifflinStJeor.bmr(
        sex: BiologicalSex.male,
        age: 40,
        weightKg: 80,
        heightCm: 180,
      );
      final expected =
          (bmr *
              (ActivityLevel.active.multiplier -
                  ActivityLevel.moderate.multiplier)) /
          OnboardingService.kcalPerGramFat;

      final adjusted = DailyTargetsService.forDay(
        profile: profile,
        log: trainingLog(),
      );

      expect(adjusted.fatG - profile.targets.fatG, closeTo(expected, 1));
    });

    test('the bump is 20% smaller with weight loss among the goals', () {
      final plain = profileAt(ActivityLevel.moderate);
      final losing = profileAt(
        ActivityLevel.moderate,
        goals: {KetoGoal.weightLoss},
      );

      final plainBump =
          DailyTargetsService.forDay(profile: plain, log: trainingLog()).fatG -
          plain.targets.fatG;
      final losingBump =
          DailyTargetsService.forDay(profile: losing, log: trainingLog()).fatG -
          losing.targets.fatG;

      expect(
        losingBump,
        closeTo(plainBump * OnboardingService.weightLossTdeeFactor, 1),
      );
    });

    // There is no sixth tier to borrow, so the difference is zero.
    test('veryActive gets no bump', () {
      final profile = profileAt(ActivityLevel.veryActive);

      expect(
        DailyTargetsService.forDay(profile: profile, log: trainingLog()),
        profile.targets,
      );
    });

    // The base is whatever the user left on screen 4, which is not
    // necessarily what the calculator proposed. Recomputing here would
    // silently discard an edit they made on purpose.
    test('the bump sits on top of an edited fat target', () {
      final edited = profileAt(
        ActivityLevel.moderate,
        targets: UserProfileFixture.targets(fatG: 999),
      );
      final standard = profileAt(ActivityLevel.moderate);

      final editedBump =
          DailyTargetsService.forDay(profile: edited, log: trainingLog()).fatG -
          999;
      final standardBump =
          DailyTargetsService.forDay(
            profile: standard,
            log: trainingLog(),
          ).fatG -
          standard.targets.fatG;

      expect(editedBump, standardBump);
    });

    // A skipped flow (#262) leaves no biometrics, so there is no BMR to
    // compute a bump from.
    test('a profile with no biometrics gets the base targets', () {
      final skipped = UserProfile.skipped();

      expect(
        DailyTargetsService.forDay(profile: skipped, log: trainingLog()),
        skipped.targets,
      );
    });

    test('a partially filled profile is treated as having none', () {
      final half = UserProfileFixture.profile(weightKg: null);

      expect(
        DailyTargetsService.forDay(profile: half, log: trainingLog()),
        half.targets,
      );
    });
  });

  group('setTrainingDay', () {
    test('creates the day log when none exists', () async {
      await service.setTrainingDay(date, trained: true);

      final saved =
          verify(() => logs.save(captureAny())).captured.single as DailyLog;
      expect(saved.date, date);
      expect(saved.trainingDay, isTrue);
    });

    test('updates the existing log rather than replacing it', () async {
      final existing = DailyLogFixture.fixture(date: date);
      when(() => logs.findByDate(any())).thenAnswer((_) async => existing);

      await service.setTrainingDay(date, trained: true);

      final saved =
          verify(() => logs.save(captureAny())).captured.single as DailyLog;
      expect(saved, existing.copyWith(trainingDay: true));
    });

    // Flagging a day must not log it: an all-zero day is what
    // `AdaptationPhaseService` reads as unlogged, and going to the gym cannot
    // bank a day toward the streak.
    test('changes no macro total', () async {
      final existing = DailyLogFixture.fixture(date: date);
      when(() => logs.findByDate(any())).thenAnswer((_) async => existing);

      await service.setTrainingDay(date, trained: true);

      final saved =
          verify(() => logs.save(captureAny())).captured.single as DailyLog;
      expect(saved.totalFatG, existing.totalFatG);
      expect(saved.totalNetCarbsG, existing.totalNetCarbsG);
      expect(saved.totalProteinG, existing.totalProteinG);
      expect(saved.ketoRatioAvg, existing.ketoRatioAvg);
    });

    test('a day flagged before anything is eaten stays all-zero', () async {
      await service.setTrainingDay(date, trained: true);

      final saved =
          verify(() => logs.save(captureAny())).captured.single as DailyLog;
      expect(saved.totalFatG, 0);
      expect(saved.totalNetCarbsG, 0);
      expect(saved.totalProteinG, 0);
    });

    test('unmarking writes the flag back to false', () async {
      final existing = DailyLogFixture.fixture(date: date)
          .copyWith(trainingDay: true);
      when(() => logs.findByDate(any())).thenAnswer((_) async => existing);

      await service.setTrainingDay(date, trained: false);

      final saved =
          verify(() => logs.save(captureAny())).captured.single as DailyLog;
      expect(saved.trainingDay, isFalse);
    });

    test('normalises the date to midnight', () async {
      await service.setTrainingDay(
        DateTime(2026, 9, 12, 23, 41),
        trained: true,
      );

      verify(() => logs.findByDate(DateTime(2026, 9, 12))).called(1);
      final saved =
          verify(() => logs.save(captureAny())).captured.single as DailyLog;
      expect(saved.date, DateTime(2026, 9, 12));
    });

    test('a failed write propagates rather than reporting success', () async {
      when(() => logs.save(any())).thenThrow(
        const PersistenceException('DailyLogRepository.save', 'closed'),
      );

      await expectLater(
        service.setTrainingDay(date, trained: true),
        throwsA(isA<PersistenceException>()),
      );
    });
  });

  group('dailyTargetsProvider', () {
    ProviderContainer containerWith({
      required Stream<UserProfile?> profile,
      DailyLog? log,
      Object? logError,
    }) {
      final container = ProviderContainer(
        overrides: [
          onboardedProfileProvider.overrideWith((ref) => profile),
          todaysDailyLogProvider(date).overrideWith((ref) async {
            if (logError != null) {
              throw logError;
            }
            return log;
          }),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    /// Reads the provider with a listener held open, and lets the two async
    /// sources it composes settle first.
    Future<AsyncValue<MacroTargets>> read(ProviderContainer container) async {
      container.listen(dailyTargetsProvider(date), (_, _) {});
      await container.pump();
      return container.read(dailyTargetsProvider(date));
    }

    test('applies the training-day bump to the stored targets', () async {
      final profile = profileAt(ActivityLevel.moderate);
      final container = containerWith(
        profile: Stream.value(profile),
        log: trainingLog(),
      );

      expect(
        (await read(container)).requireValue,
        DailyTargetsService.forDay(profile: profile, log: trainingLog()),
      );
    });

    test('a rest day gets the profile targets unchanged', () async {
      final profile = profileAt(ActivityLevel.moderate);
      final container = containerWith(
        profile: Stream.value(profile),
        log: DailyLogFixture.fixture(date: date),
      );

      expect((await read(container)).requireValue, profile.targets);
    });

    // The same fallback `macroTargetsProvider` makes: a dashboard bar has to
    // show something before anyone has onboarded.
    test('no profile yields the default targets', () async {
      final container = containerWith(profile: Stream.value(null));

      expect((await read(container)).requireValue, MacroTargets.defaults);
    });

    // A profile that cannot be *read* is not a profile that says 150 g of
    // fat. Falling back to the defaults would show somebody a target they
    // never set, next to the number they are judged against.
    test('a failed profile read is an error, not the defaults', () async {
      final container = containerWith(
        profile: Stream<UserProfile?>.error(Exception('disk gone')),
      );

      final value = await read(container);
      expect(value.hasError, isTrue);
      expect(value.hasValue, isFalse);
    });

    test('a failed day read is an error too', () async {
      final container = containerWith(
        profile: Stream.value(profileAt(ActivityLevel.moderate)),
        logError: Exception('disk gone'),
      );

      expect((await read(container)).hasError, isTrue);
    });

    // riverpod 3 reports a provider that failed before ever producing a value
    // as `AsyncLoading` *with* an error attached, so the error check has to
    // come first or a reader spins forever (`design/m3_handoff.md`).
    test('reports loading while the day is still being read', () {
      final container = containerWith(
        profile: Stream.value(profileAt(ActivityLevel.moderate)),
      );
      container.listen(dailyTargetsProvider(date), (_, _) {});

      expect(container.read(dailyTargetsProvider(date)).isLoading, isTrue);
    });
  });
}
