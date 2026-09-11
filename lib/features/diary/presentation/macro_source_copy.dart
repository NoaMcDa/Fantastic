import 'package:fantastic/features/diary/domain/models/macro_source.dart';
import 'package:flutter/material.dart';

/// The badge label, announcement and icon for each [MacroSource].
///
/// An extension rather than the free functions the issue sketched, because
/// the file it told us to follow — `physical_symptom_copy.dart`, in this same
/// directory — is an extension, and two files doing the same job in opposite
/// shapes is exactly the drift these conventions exist to stop. The rest of
/// that file's reasoning transfers unchanged: copy lives beside the enum it
/// describes, never hardcoded in a widget, and lives in `presentation/`
/// rather than `lib/core/constants/` because of [icon] — an `IconData` cannot
/// follow `PhaseCopy` into a Flutter-free file.
///
/// Every getter switches exhaustively rather than reading a map. A map with a
/// missing key compiles and fails at run time; a non-exhaustive switch over
/// an enum does not compile at all, so a fifth `MacroSource` breaks the build
/// here instead of quietly rendering nothing.
extension MacroSourceCopy on MacroSource {
  /// The short badge label, or null when the card shows nothing extra.
  ///
  /// **Null for [MacroSource.manual]**, and that is the point: a meal the
  /// user typed needs no explanation, most meals are typed, and a badge on
  /// every card is a badge nobody reads.
  ///
  /// The two estimated sources share a label but not a [description]. On a
  /// card "estimate" is the whole of what matters and text-versus-photo is
  /// noise; a screen reader and a long-press get the distinction.
  String? get badgeLabel => switch (this) {
    MacroSource.manual => null,
    MacroSource.scannedLabel => 'מתווית',
    MacroSource.estimatedFromText => 'הערכה',
    MacroSource.estimatedFromPhoto => 'הערכה',
  };

  /// What a screen reader announces, and what the tooltip says.
  ///
  /// The marker is meaningful rather than decorative — it is the difference
  /// between a figure that was read and one that was guessed — so it is
  /// announced, not hidden behind a glance.
  String? get badgeDescription => switch (this) {
    MacroSource.manual => null,
    MacroSource.scannedLabel => 'הערכים נקראו מתווית המוצר',
    MacroSource.estimatedFromText => 'הערכים חושבו מתיאור הארוחה',
    MacroSource.estimatedFromPhoto => 'הערכים חושבו מתמונת הארוחה',
  };

  /// The badge's icon, or null when there is no badge.
  ///
  /// Chosen through [MacroSource.isEstimate] rather than by re-listing the
  /// two estimated values: that question has one home, and asking it twice is
  /// how the diary and the badge would come to disagree about what an
  /// estimate is.
  IconData? get badgeIcon {
    if (badgeLabel == null) {
      return null;
    }
    return isEstimate ? Icons.auto_awesome_outlined : Icons.receipt_long;
  }
}
