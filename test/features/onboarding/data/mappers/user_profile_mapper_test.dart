import 'package:fantastic/features/onboarding/data/mappers/user_profile_mapper.dart';
import 'package:fantastic/features/onboarding/domain/models/activity_level.dart';
import 'package:fantastic/features/onboarding/domain/models/macro_targets.dart';
import 'package:fantastic/features/onboarding/domain/models/biological_sex.dart';
import 'package:fantastic/features/onboarding/domain/models/keto_goal.dart';
import 'package:fantastic/features/onboarding/domain/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';

/// The singleton takes no key, so a round-trip is just the two codec halves.
UserProfile _roundTrip(UserProfile original) =>
    UserProfileMapper.fromRecord(UserProfileMapper.toRecord(original));

void main() {
  group('enum encoding', () {
    test('sex, activity and goals are stored by name, not by ordinal', () {
      final record = UserProfileMapper.toRecord(
        UserProfileFixture.profile(
          sex: BiologicalSex.female,
          activityLevel: ActivityLevel.moderate,
          goals: {KetoGoal.athleticPerformance},
        ),
      );

      expect(record['sex'], 'female');
      expect(record['activityLevel'], 'moderate');
      expect(record['goals'], ['athleticPerformance']);
    });

    test('goals are written in display order, whatever order they went in', () {
      Object? goalsOf(Set<KetoGoal> goals) => UserProfileMapper.toRecord(
        UserProfileFixture.profile(goals: goals),
      )['goals'];

      // Two sets with the same members must produce byte-identical records,
      // so the list is ordered by `GoalCopy.order` rather than by iteration.
      expect(
        goalsOf({KetoGoal.athleticPerformance, KetoGoal.weightLoss}),
        goalsOf({KetoGoal.weightLoss, KetoGoal.athleticPerformance}),
      );
      expect(goalsOf({KetoGoal.athleticPerformance, KetoGoal.weightLoss}), [
        'weightLoss',
        'athleticPerformance',
      ]);
    });

    test('every activity level round-trips', () {
      for (final level in ActivityLevel.values) {
        expect(
          _roundTrip(UserProfileFixture.profile(activityLevel: level))
              .activityLevel,
          level,
          reason: 'ActivityLevel.${level.name} did not survive the codec',
        );
      }
    });

    test('every BiologicalSex round-trips', () {
      for (final sex in BiologicalSex.values) {
        expect(
          _roundTrip(UserProfileFixture.profile(sex: sex)).sex,
          sex,
          reason: 'BiologicalSex.${sex.name} did not survive the codec',
        );
      }
    });

    test('every KetoGoal round-trips', () {
      for (final goal in KetoGoal.values) {
        expect(_roundTrip(UserProfileFixture.profile(goals: {goal})).goals, {
          goal,
        }, reason: 'KetoGoal.${goal.name} did not survive the codec');
      }
    });

    test('an unknown stored goal throws rather than defaulting', () {
      final record = Map<String, Object?>.from(
        UserProfileMapper.toRecord(UserProfileFixture.profile()),
      )..['goals'] = ['notAGoal'];

      expect(() => UserProfileMapper.fromRecord(record), throwsArgumentError);
    });

    test('an unknown stored activity level throws rather than defaulting', () {
      final record = Map<String, Object?>.from(
        UserProfileMapper.toRecord(UserProfileFixture.profile()),
      )..['activityLevel'] = 'notALevel';

      expect(() => UserProfileMapper.fromRecord(record), throwsArgumentError);
    });
  });

  group('round-trip', () {
    // Every default in the fixture is a distinct number, so a codec that
    // crossed weight with height, or fat with protein, fails here. An
    // all-equal fixture would let it through — see `CLAUDE.md` §Testing.
    test('preserves every field', () {
      final original = UserProfileFixture.profile(
        ketoStartDate: UserProfileFixture.defaultKetoStartDate,
      );

      expect(_roundTrip(original), original);
    });

    test('a null keto start date round-trips as null', () {
      expect(_roundTrip(UserProfileFixture.profile()).ketoStartDate, isNull);
    });

    test('the nested targets survive the flattening', () {
      final restored = _roundTrip(
        UserProfileFixture.profile(
          targets: UserProfileFixture.targets(
            fatG: 171,
            netCarbsG: 22,
            proteinG: 68,
          ),
        ),
      );

      expect(restored.targets.fatG, 171);
      expect(restored.targets.netCarbsG, 22);
      expect(restored.targets.proteinG, 68);
    });
  });

  group('the emitted record is sembast-legal', () {
    test('every value is null, num, String or bool', () {
      final record = UserProfileMapper.toRecord(
        UserProfileFixture.profile(
          ketoStartDate: UserProfileFixture.defaultKetoStartDate,
        ),
      );

      for (final entry in record.entries) {
        expect(
          entry.value,
          // `goals` is a list of enum names, and a JSON-compatible list is
          // legal sembast. It is the first such value in the app, which is
          // why this allow-list is where that decision is recorded — the
          // element type is asserted below rather than taken on trust.
          anyOf(
            isNull,
            isA<num>(),
            isA<String>(),
            isA<bool>(),
            isA<List<String>>(),
          ),
          reason: '${entry.key} is not a JSON-compatible sembast value',
        );
      }
      expect(record['goals'], isA<List<String>>());
    });

    test('the start date is absolute milliseconds, not a DateTime', () {
      final record = UserProfileMapper.toRecord(
        UserProfileFixture.profile(
          ketoStartDate: UserProfileFixture.defaultKetoStartDate,
        ),
      );

      expect(
        record['ketoStartDate'],
        UserProfileFixture.defaultKetoStartDate.millisecondsSinceEpoch,
      );
      expect(record['ketoStartDate'], isNot(isA<DateTime>()));
    });
  });

  // IndexedDB hands a whole 78.0 back as an int. Every number is decoded
  // through `num` for exactly this; a direct `as double` cast throws.
  group('decodes an int where a double was written', () {
    test('weight, height and the three targets survive', () {
      final record = <String, Object?>{
        'sex': 'male',
        'age': 40,
        'weightKg': 78,
        'heightCm': 180,
        'goal': 'weightLoss',
        'fatTargetG': 150,
        'netCarbsTargetG': 20,
        'proteinTargetG': 62,
        'ketoStartDate': null,
      };

      final profile = UserProfileMapper.fromRecord(record);

      expect(profile.weightKg, 78.0);
      expect(profile.heightCm, 180.0);
      expect(profile.targets.fatG, 150.0);
      expect(profile.targets.proteinG, 62.0);
    });
  });

  // There is no migration step in this app: whatever is on disk is read by
  // the codec as it stands. Each of these is a record an install really has.
  group('records written by an earlier version', () {
    Map<String, Object?> current() => Map<String, Object?>.from(
      UserProfileMapper.toRecord(UserProfileFixture.profile()),
    );

    test('a single `goal` string reads as a one-element set', () {
      final legacy = current()
        ..remove('goals')
        ..['goal'] = 'weightLoss';

      expect(UserProfileMapper.fromRecord(legacy).goals, {KetoGoal.weightLoss});
    });

    test('an unknown single `goal` still throws', () {
      final legacy = current()
        ..remove('goals')
        ..['goal'] = 'notAGoal';

      expect(() => UserProfileMapper.fromRecord(legacy), throwsArgumentError);
    });

    // 1.2 is exactly the factor those targets were computed with, so this is
    // not a guess — it is what the record already meant.
    test('a missing activity level reads as sedentary', () {
      final legacy = current()..remove('activityLevel');

      expect(
        UserProfileMapper.fromRecord(legacy).activityLevel,
        ActivityLevel.sedentary,
      );
    });

    test('the whole pre-#431 shape decodes', () {
      final legacy = <String, Object?>{
        'sex': 'male',
        'age': 40,
        'weightKg': 80.0,
        'heightCm': 180.0,
        'goal': 'metabolicHealth',
        'fatTargetG': 193.0,
        'netCarbsTargetG': 20.0,
        'proteinTargetG': 64.0,
        'ketoStartDate': null,
      };

      final profile = UserProfileMapper.fromRecord(legacy);

      expect(profile.sex, BiologicalSex.male);
      expect(profile.age, 40);
      expect(profile.activityLevel, ActivityLevel.sedentary);
      expect(profile.goals, {KetoGoal.metabolicHealth});
      expect(profile.targets.fatG, 193);
    });
  });

  // #262: a skipped flow leaves a record with targets and nothing else.
  group('a skipped profile', () {
    test('round-trips with no biometrics and no goals', () {
      final restored = _roundTrip(UserProfile.skipped());

      expect(restored.hasBiometrics, isFalse);
      expect(restored.sex, isNull);
      expect(restored.age, isNull);
      expect(restored.weightKg, isNull);
      expect(restored.heightCm, isNull);
      expect(restored.goals, isEmpty);
      expect(restored.targets, MacroTargets.defaults);
    });

    test('its record is still sembast-legal', () {
      final record = UserProfileMapper.toRecord(UserProfile.skipped());

      for (final entry in record.entries) {
        expect(
          entry.value,
          anyOf(
            isNull,
            isA<num>(),
            isA<String>(),
            isA<bool>(),
            isA<List<String>>(),
          ),
          reason: '${entry.key} is not a JSON-compatible sembast value',
        );
      }
    });
  });
}
