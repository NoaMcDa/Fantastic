import 'package:fantastic/features/keto_lens/domain/models/ingredient_verdict.dart';
import 'package:fantastic/features/keto_lens/domain/models/parsed_label.dart';
import 'package:meta/meta.dart';

/// The outcome of one run of the scan pipeline.
///
/// ## Why this is sealed, and not a label plus a verdict
///
/// #83 modelled a scan as a `ParsedLabel` and an `IngredientVerdict`, always
/// both, and returned `ParsedLabel()` with a `cleanKeto` verdict when
/// anything went wrong — *"users see a clean verdict for unrecognisable
/// labels rather than an error screen"*.
///
/// That is backwards, and it is the most dangerous defect the M6 audit found.
/// The user is standing in a shop holding a product, and the app has just
/// told them it is clean keto **because it could not read the label**.
/// Nothing in the returned value distinguished that from a genuine clean
/// verdict.
///
/// A sealed hierarchy makes the distinction unignorable: a `switch` over
/// [ScanResult] does not compile until the failure case is handled.
/// `design/m6_preflight.md` §1.1.
@immutable
sealed class ScanResult {
  const ScanResult();
}

/// A scan that read a label and reached a verdict.
@immutable
final class ScanSucceeded extends ScanResult {
  const ScanSucceeded({required this.label, required this.verdict});

  /// What was extracted from the label.
  final ParsedLabel label;

  /// What the ingredients classify as.
  final IngredientVerdict verdict;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanSucceeded &&
          other.label == label &&
          other.verdict == verdict;

  @override
  int get hashCode => Object.hash(label, verdict);
}

/// A scan that did not reach a verdict.
///
/// Carries [rawText] so a mis-read is diagnosable from a bug report, and so
/// the result sheet can offer to show the user what the camera actually saw.
@immutable
final class ScanFailed extends ScanResult {
  const ScanFailed({required this.reason, this.rawText = ''});

  /// What went wrong. The UI's copy and its retry affordance both key off
  /// this.
  final ScanFailureReason reason;

  /// Whatever OCR returned, if it ran at all. Empty otherwise.
  final String rawText;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanFailed && other.reason == reason && other.rawText == rawText;

  @override
  int get hashCode => Object.hash(reason, rawText);
}

/// Why a scan did not reach a verdict.
///
/// Four cases rather than one because the right thing to tell the user
/// differs, and so does whether retrying is worth offering.
enum ScanFailureReason {
  /// OCR cannot run on this platform at all — the browser.
  ///
  /// Not worth retrying. The UI should not have offered the scan.
  unavailable,

  /// OCR ran and failed: a missing plugin, a corrupt image, a platform
  /// error. Worth retrying.
  recognitionFailed,

  /// OCR succeeded and found no text.
  ///
  /// The camera was pointed at something blank, or the shot was too blurred
  /// to resolve any glyph. "Hold steady and get closer" is the useful thing
  /// to say.
  noTextFound,

  /// OCR found text, but nothing in it looked like a nutrition label — no
  /// macro row and no ingredient list.
  ///
  /// Usually the front of the pack rather than the back. "Turn the product
  /// over" is the useful thing to say.
  notALabel,
}
