import 'package:fantastic/features/onboarding/domain/models/biological_sex.dart';

/// The Mifflin-St Jeor basal metabolic rate, in kilocalories per day.
///
/// Pure Dart, and the single definition in the app. It lived as
/// `OnboardingService._basalMetabolicRate` while onboarding was its only
/// caller; `DailyTargetsService` is the second, and a second private copy of
/// an equation is how two answers to one question start disagreeing.
abstract final class MifflinStJeor {
  /// `10 × weightKg + 6.25 × heightCm − 5 × age`, then `+5` for
  /// [BiologicalSex.male] and `−161` for [BiologicalSex.female].
  ///
  /// Pure: the same inputs always give the same answer, and nothing here
  /// reads a clock or a store.
  static double bmr({
    required BiologicalSex sex,
    required int age,
    required double weightKg,
    required double heightCm,
  }) {
    final shared = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return switch (sex) {
      BiologicalSex.male => shared + 5,
      BiologicalSex.female => shared - 161,
    };
  }
}
