import 'package:fantastic/core/constants/goal_copy.dart';
import 'package:fantastic/features/onboarding/domain/models/activity_level.dart';
import 'package:fantastic/features/onboarding/domain/models/biological_sex.dart';
import 'package:fantastic/features/onboarding/domain/models/keto_goal.dart';
import 'package:fantastic/features/onboarding/domain/models/macro_targets.dart';
import 'package:fantastic/features/onboarding/domain/models/user_profile.dart';

/// Converts between [UserProfile] and its sembast record shape.
///
/// Called only by `SembastUserProfileRepository` — never from `domain/` or
/// `presentation/`, which must not see a persistence shape at all.
///
/// There is exactly one record, at [singletonId], so this codec takes no key.
///
/// **[fromRecord] reads three record shapes, because this app has no
/// migration step.** An install that onboarded before the goal set existed
/// has a single `goal` string and no `goals` list; one that onboarded before
/// the activity question has no `activityLevel`; one that skipped the flow
/// (#262) has no biometrics at all. Each case is read as what it meant when
/// it was written, and every one of them is covered by a test.
abstract final class UserProfileMapper {
  /// The record every profile write is pinned to. There is exactly one.
  static const int singletonId = 0;

  /// The targets are flattened into the record rather than nested as a map.
  ///
  /// A nested map is legal sembast, but a flat record is what every other
  /// codec in the app emits, and it keeps a future query on a single target
  /// possible without reaching through a sub-map.
  static Map<String, Object?> toRecord(UserProfile profile) => {
    // By `name`, never by ordinal: a stored ordinal silently reinterprets
    // every existing record the day a value is inserted mid-enum. Null on a
    // skipped profile, which knows none of these four.
    'sex': profile.sex?.name,
    'age': profile.age,
    'weightKg': profile.weightKg,
    'heightCm': profile.heightCm,
    'activityLevel': profile.activityLevel.name,
    // A list of names, ordered by `GoalCopy.order` rather than by the set's
    // own iteration order, so two profiles with the same goals write
    // byte-identical records. A JSON-compatible list is legal sembast; this
    // is the first codec in the app to need one.
    //
    // The pre-multi-goal `goal` key is deliberately not written alongside it:
    // one fact, one place. [fromRecord] still reads the old key.
    'goals': [
      for (final goal in GoalCopy.order)
        if (profile.goals.contains(goal)) goal.name,
    ],
    'fatTargetG': profile.targets.fatG,
    'netCarbsTargetG': profile.targets.netCarbsG,
    'proteinTargetG': profile.targets.proteinG,
    // Absolute milliseconds, never a `DateTime` (sembast rejects it at write
    // time) and never an ISO string (a lexicographic sort is chronological
    // only while every record shares one UTC offset).
    'ketoStartDate': profile.ketoStartDate?.millisecondsSinceEpoch,
  };

  static UserProfile fromRecord(Map<String, Object?> record) => UserProfile(
    sex: record['sex'] == null
        ? null
        : BiologicalSex.values.byName(record['sex']! as String),
    // Through `num`, never `as double`: a whole 70.0 comes back from
    // IndexedDB's JSON as an int and a direct cast throws.
    age: (record['age'] as num?)?.toInt(),
    weightKg: (record['weightKg'] as num?)?.toDouble(),
    heightCm: (record['heightCm'] as num?)?.toDouble(),
    // A record written before the activity question existed had its targets
    // computed with the 1.2 factor, so sedentary is not a guess — it is what
    // that record already meant.
    activityLevel: record['activityLevel'] == null
        ? ActivityLevel.sedentary
        : ActivityLevel.values.byName(record['activityLevel']! as String),
    goals: _goalsFrom(record),
    targets: MacroTargets(
      fatG: (record['fatTargetG']! as num).toDouble(),
      netCarbsG: (record['netCarbsTargetG']! as num).toDouble(),
      proteinG: (record['proteinTargetG']! as num).toDouble(),
    ),
    ketoStartDate: _dateOrNull(record['ketoStartDate']),
  );

  /// The goal set, from either the current `goals` list or the single `goal`
  /// string written before multi-select shipped.
  ///
  /// An unknown name still throws rather than defaulting — a goal the app
  /// cannot name is a record it does not understand, and quietly substituting
  /// one would show the user a goal they never chose.
  static Set<KetoGoal> _goalsFrom(Map<String, Object?> record) {
    final stored = record['goals'];
    if (stored is List) {
      return {
        for (final name in stored) KetoGoal.values.byName(name! as String),
      };
    }
    final single = record['goal'];
    return single == null
        // Neither key: a skipped profile (#262) chose no goals.
        ? const {}
        : {KetoGoal.values.byName(single as String)};
  }

  static DateTime? _dateOrNull(Object? millis) => millis == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch((millis as num).toInt());
}
