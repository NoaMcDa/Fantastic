import 'package:fantastic/features/keto_lens/domain/models/parsed_label.dart';

/// Turns raw OCR text into structured nutritional fields.
///
/// Synchronous by design: parsing is pure CPU work with no I/O, so returning a
/// `Future` would force every caller into an `async` boundary for nothing.
///
/// Declaring this in the domain layer keeps `ScanOrchestrator` (M6)
/// independent of the Hebrew regex that implements it, and lets the
/// orchestrator's tests mock parsing instead of running OCR.
abstract interface class LabelParser {
  /// Parses [ocrText] (raw ML Kit output) into structured nutritional fields.
  ///
  /// Returns a [ParsedLabel] with null fields for anything that could not be
  /// extracted. **Never throws** — garbled or empty input yields a label with
  /// all nulls and `hasMacros == false`, which the caller renders as a failed
  /// scan rather than an error state.
  ///
  /// The target label format is
  /// `שומן Xגר פחמימות Yגר מתוכם סיבים Zגר חלבון Wגר`, where net carbs is
  /// Y − Z per `CLAUDE.md`'s Net Carbs rule.
  ParsedLabel parse(String ocrText);
}
