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
    // every existing record the day a value is inserted mid-enum.
    'sex': profile.sex.name,
    'age': profile.age,
    'weightKg': profile.weightKg,
    'heightCm': profile.heightCm,
    'goal': profile.goal.name,
    'fatTargetG': profile.targets.fatG,
    'netCarbsTargetG': profile.targets.netCarbsG,
    'proteinTargetG': profile.targets.proteinG,
    // Absolute milliseconds, never a `DateTime` (sembast rejects it at write
    // time) and never an ISO string (a lexicographic sort is chronological
    // only while every record shares one UTC offset).
    'ketoStartDate': profile.ketoStartDate?.millisecondsSinceEpoch,
  };

  static UserProfile fromRecord(Map<String, Object?> record) => UserProfile(
    sex: BiologicalSex.values.byName(record['sex']! as String),
    age: (record['age']! as num).toInt(),
    // Through `num`, never `as double`: a whole 70.0 comes back from
    // IndexedDB's JSON as an int and a direct cast throws.
    weightKg: (record['weightKg']! as num).toDouble(),
    heightCm: (record['heightCm']! as num).toDouble(),
    goal: KetoGoal.values.byName(record['goal']! as String),
    targets: MacroTargets(
      fatG: (record['fatTargetG']! as num).toDouble(),
      netCarbsG: (record['netCarbsTargetG']! as num).toDouble(),
      proteinG: (record['proteinTargetG']! as num).toDouble(),
    ),
    ketoStartDate: _dateOrNull(record['ketoStartDate']),
  );

  static DateTime? _dateOrNull(Object? millis) => millis == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch((millis as num).toInt());
}
