import 'package:fantastic/features/onboarding/data/mappers/user_profile_mapper.dart';
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
    test('sex and goal are stored by name, not by ordinal', () {
      final record = UserProfileMapper.toRecord(
        UserProfileFixture.profile(
          sex: BiologicalSex.female,
          goal: KetoGoal.athleticPerformance,
        ),
      );

      expect(record['sex'], 'female');
      expect(record['goal'], 'athleticPerformance');
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
        expect(
          _roundTrip(UserProfileFixture.profile(goal: goal)).goal,
          goal,
          reason: 'KetoGoal.${goal.name} did not survive the codec',
        );
      }
    });

    test('an unknown stored name throws rather than defaulting', () {
      final record = Map<String, Object?>.from(
        UserProfileMapper.toRecord(UserProfileFixture.profile()),
      )..['goal'] = 'notAGoal';

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
          anyOf(isNull, isA<num>(), isA<String>(), isA<bool>()),
          reason: '${entry.key} is not a JSON-compatible sembast value',
        );
      }
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
}
