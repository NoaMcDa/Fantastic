import 'package:fantastic/core/constants/keto_constants.dart';
import 'package:meta/meta.dart';

/// The daily macro goals the dashboard measures a day against.
///
/// Computed from the onboarding answers by
/// `OnboardingService.calculateMacroTargets`, then shown to the user and
/// editable before it is saved — a target the dashboard judges someone by has
/// to be one they agreed to.
///
/// There is no keto-ratio target here: the ratio is derived from the three
/// macros, and `KetoConstants.targetKetoRatioIdeal` is a protocol constant
/// rather than a personal goal.
@immutable
class MacroTargets {
  const MacroTargets({
    required this.fatG,
    required this.netCarbsG,
    required this.proteinG,
  });

  /// What the dashboard shows before anyone has onboarded.
  ///
  /// The single definition of the fallback: `MacroSummaryCard` read these
  /// `KetoConstants` values directly through M2 and M3, and reads them
  /// through here now, so "no profile yet" and "profile says so" cannot
  /// disagree about what a default is.
  static const MacroTargets defaults = MacroTargets(
    fatG: KetoConstants.defaultFatTargetG,
    netCarbsG: KetoConstants.defaultNetCarbTargetG,
    proteinG: KetoConstants.defaultProteinTargetG,
  );

  final double fatG;
  final double netCarbsG;
  final double proteinG;

  MacroTargets copyWith({double? fatG, double? netCarbsG, double? proteinG}) =>
      MacroTargets(
        fatG: fatG ?? this.fatG,
        netCarbsG: netCarbsG ?? this.netCarbsG,
        proteinG: proteinG ?? this.proteinG,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MacroTargets &&
          other.fatG == fatG &&
          other.netCarbsG == netCarbsG &&
          other.proteinG == proteinG;

  @override
  int get hashCode => Object.hash(fatG, netCarbsG, proteinG);

  @override
  String toString() =>
      'MacroTargets(fat: $fatG g, netCarbs: $netCarbsG g, protein: $proteinG g)';
}
