import 'package:meta/meta.dart';

/// Phase-appropriate electrolyte targets and whether the day falls short of
/// them.
///
/// Targets are the **minimum** of the phase's documented range in
/// `ElectrolyteConstants` — the threshold below which the user is short, which
/// is what a gauge and a deficit flag both need. The upper bound of each range
/// is an intake ceiling, not a goal, so it is not carried here.
///
/// Values are `double` to match `DailyLog`'s fields and the constants
/// themselves; milligrams are not inherently whole numbers and converting at
/// this boundary would only introduce rounding.
@immutable
class ElectrolyteAdvice {
  const ElectrolyteAdvice({
    required this.sodiumTargetMg,
    required this.potassiumTargetMg,
    required this.magnesiumTargetMg,
    required this.sodiumDeficit,
    required this.potassiumDeficit,
    required this.magnesiumDeficit,
  });

  final double sodiumTargetMg;
  final double potassiumTargetMg;
  final double magnesiumTargetMg;

  final bool sodiumDeficit;
  final bool potassiumDeficit;
  final bool magnesiumDeficit;

  /// True when any one of the three is short — what the card's summary badge
  /// renders from.
  bool get hasAnyDeficit =>
      sodiumDeficit || potassiumDeficit || magnesiumDeficit;
}
