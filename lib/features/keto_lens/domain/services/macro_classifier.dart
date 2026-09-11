import 'package:fantastic/features/keto_lens/domain/models/macro_verdict.dart';
import 'package:fantastic/features/keto_lens/domain/models/parsed_label.dart';

/// Judges a parsed label as a product-level keto verdict.
///
/// Synchronous and pure, like `IngredientClassifier`: no I/O, no network, no
/// product database. Thresholds live in `core/constants/` — an implementation
/// reads them, never redeclares them.
abstract interface class MacroClassifier {
  /// The verdict the panel supports.
  ///
  /// The label's ingredients participate **only** in the polyol adjustment,
  /// which cannot be attributed without them. They never move a band here —
  /// that is `IngredientClassifier`'s job, and the two verdicts are reduced by
  /// `LabelVerdict.combine`.
  ///
  /// Never throws: an unreadable panel is a [MacroJudgement.indeterminate]
  /// verdict carrying its reason, not an error for the caller to handle.
  MacroVerdict classify(ParsedLabel label);
}
