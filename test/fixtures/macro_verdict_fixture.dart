import 'package:fantastic/features/keto_lens/domain/models/macro_verdict.dart';

/// Test data for [MacroVerdict].
///
/// Defaults are a clean product — 2 g of net carbs per 100 g — so a test that
/// is about something else does not accidentally assert on the macro band.
abstract final class MacroVerdictFixture {
  static MacroVerdict keto({
    double netCarbsPer100 = 2,
    double? servingNetCarbsG,
    bool basisAssumed = false,
    bool adjustedForPolyols = false,
  }) => MacroVerdict(
    judgement: MacroJudgement.keto,
    netCarbsPer100: netCarbsPer100,
    servingNetCarbsG: servingNetCarbsG,
    gramsToDailyBudget: 100 * 20 / netCarbsPer100,
    basisAssumed: basisAssumed,
    adjustedForPolyols: adjustedForPolyols,
  );

  static MacroVerdict moderation({
    double netCarbsPer100 = 12,
    double? servingNetCarbsG,
    bool basisAssumed = false,
  }) => MacroVerdict(
    judgement: MacroJudgement.moderation,
    netCarbsPer100: netCarbsPer100,
    servingNetCarbsG: servingNetCarbsG,
    gramsToDailyBudget: 100 * 20 / netCarbsPer100,
    basisAssumed: basisAssumed,
  );

  static MacroVerdict notKeto({
    double netCarbsPer100 = 34.2,
    double? servingNetCarbsG,
  }) => MacroVerdict(
    judgement: MacroJudgement.notKeto,
    netCarbsPer100: netCarbsPer100,
    servingNetCarbsG: servingNetCarbsG,
    gramsToDailyBudget: 100 * 20 / netCarbsPer100,
  );

  /// No verdict, and why. The state a panel-only crop or a mis-read leaves.
  static MacroVerdict indeterminate({
    MacroIndeterminacy reason = MacroIndeterminacy.noCarbRow,
  }) => MacroVerdict.indeterminate(reason);
}
