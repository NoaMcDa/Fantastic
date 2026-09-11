import 'dart:async';

import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_bottom_sheet.dart';
import 'package:fantastic/features/keto_lens/domain/models/parsed_label.dart';
import 'package:fantastic/features/keto_lens/domain/models/scan_result.dart';
import 'package:fantastic/features/keto_lens/presentation/widgets/verdict_badge_widget.dart';
import 'package:flutter/material.dart';

/// What a scan produced, as a modal bottom sheet.
///
/// Renders one of two things, and the type system enforces which: a verdict
/// for [ScanSucceeded], an explanation and a retry for [ScanFailed]. #83
/// returned a clean verdict for a failed scan, so this sheet would have put
/// a green tick on a label it could not read — `design/m6_preflight.md` §1.1
/// and the doc comment on [ScanResult].
class ScanResultSheet extends StatelessWidget {
  const ScanResultSheet({
    required this.result,
    required this.date,
    this.onRetry,
    super.key,
  });

  /// The scan to render.
  final ScanResult result;

  /// The day "הוסף ליומן" logs against.
  final DateTime date;

  /// Invoked after the sheet closes when the user asks to scan again.
  ///
  /// Null on a platform where scanning is not possible at all, which is how
  /// the retry button is suppressed for [ScanFailureReason.unavailable].
  final VoidCallback? onRetry;

  /// Opens the sheet as a modal over [context].
  ///
  /// Lives here, as `AddMealBottomSheet.show` does, so the sheet owns how it
  /// is presented. `isScrollControlled` is required: without it the sheet is
  /// capped at half the screen and a long flagged-ingredient list is
  /// unreachable. #84's hand-rolled `showModalBottomSheet` omitted it.
  static Future<void> show(
    BuildContext context, {
    required ScanResult result,
    required DateTime date,
    VoidCallback? onRetry,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        ScanResultSheet(result: result, date: date, onRetry: onRetry),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: switch (result) {
            // A sealed switch: a third ScanResult variant would fail to
            // compile here rather than fall through to a blank sheet.
            final ScanSucceeded success => _success(context, success),
            final ScanFailed failure => _failure(context, failure),
          },
        ),
      ),
    );
  }

  List<Widget> _success(BuildContext context, ScanSucceeded success) {
    final label = success.label;
    final verdict = success.verdict;

    return [
      Center(
        child: VerdictBadgeWidget(
          badge: verdict.badge,
          recognisedNothing: verdict.recognisedNothing,
        ),
      ),
      if (label.hasMacros) ...[
        const SizedBox(height: 20),
        _MacroStrip(label: label),
        const SizedBox(height: 8),
        Text(
          // The label's figures are per 100 g; a meal entry is what was
          // eaten. Nothing in the pipeline reads a serving size, so the
          // sheet says so rather than letting the prefill imply otherwise.
          'הערכים מהתווית — בדקו את גודל המנה לפני השמירה',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
      if (verdict.flaggedIngredients.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text(
          'רכיבים בעייתיים',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: VerdictBadgeWidget.colourFor(verdict.badge)),
        ),
        const SizedBox(height: 8),
        for (final ingredient in verdict.flaggedIngredients)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('• $ingredient'),
          ),
      ],
      const SizedBox(height: 24),
      FilledButton(
        key: const Key('add_to_diary_button'),
        onPressed: () => _addToDiary(context, label),
        child: const Text('הוסף ליומן'),
      ),
    ];
  }

  List<Widget> _failure(BuildContext context, ScanFailed failure) {
    final retryable = failure.reason != ScanFailureReason.unavailable;

    return [
      Icon(
        retryable ? Icons.document_scanner_outlined : Icons.no_photography,
        size: 40,
        color: AppTheme.accent,
      ),
      const SizedBox(height: 12),
      Text(
        failureTitle(failure.reason),
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Text(
        failureAdvice(failure.reason),
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      if (retryable && onRetry != null)
        FilledButton(
          key: const Key('retry_scan_button'),
          onPressed: () {
            Navigator.of(context).pop();
            onRetry!();
          },
          child: const Text('נסו שוב'),
        ),
      TextButton(
        key: const Key('dismiss_scan_button'),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('סגור'),
      ),
    ];
  }

  /// The headline for a failed scan.
  ///
  /// Exposed so the tests assert the same strings the sheet renders.
  @visibleForTesting
  static String failureTitle(ScanFailureReason reason) => switch (reason) {
    ScanFailureReason.unavailable => 'הסריקה זמינה באפליקציה לאייפון',
    ScanFailureReason.recognitionFailed => 'הסריקה נכשלה',
    ScanFailureReason.noTextFound => 'לא זוהה טקסט בתמונה',
    ScanFailureReason.notALabel => 'זו לא נראית תווית תזונה',
  };

  /// What to do about it — different per reason, which is the whole point
  /// of there being four.
  @visibleForTesting
  static String failureAdvice(ScanFailureReason reason) => switch (reason) {
    ScanFailureReason.unavailable =>
      'זיהוי הטקסט פועל על המכשיר בלבד, ולכן אינו זמין בדפדפן.',
    ScanFailureReason.recognitionFailed =>
      'משהו השתבש בזיהוי הטקסט. נסו לצלם שוב.',
    ScanFailureReason.noTextFound =>
      'התקרבו לתווית, החזיקו את המכשיר יציב וודאו שיש מספיק אור.',
    ScanFailureReason.notALabel =>
      'הפכו את האריזה וצלמו את טבלת הערכים התזונתיים בגב המוצר.',
  };

  void _addToDiary(BuildContext context, ParsedLabel label) {
    // The Navigator's own context outlives this sheet's, so the add-meal
    // sheet has somewhere to open after the pop.
    final navigator = Navigator.of(context);
    final host = navigator.context;
    navigator.pop();
    unawaited(
      AddMealBottomSheet.show(
        host,
        date: date,
        initialName: 'מוצר סרוק',
        // Null stays null rather than becoming 0: a macro the parser did
        // not find is unknown, and prefilling zero would have the user
        // save a fat-free tahini without noticing. The field is left blank
        // and the form's own validator asks for it.
        initialFatG: label.fatG,
        initialNetCarbsG: label.netCarbsG,
        initialProteinG: label.proteinG,
      ),
    );
  }
}

/// Fat / net carbs / protein, side by side.
class _MacroStrip extends StatelessWidget {
  const _MacroStrip({required this.label});

  final ParsedLabel label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Macro(name: 'שומן', grams: label.fatG),
        _Macro(name: 'פחמימות נטו', grams: label.netCarbsG),
        _Macro(name: 'חלבון', grams: label.proteinG),
      ],
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro({required this.name, required this.grams});

  final String name;
  final double? grams;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          grams == null ? '—' : '${_format(grams!)} ג',
          // Every digit run inside the RTL layout needs this, every time:
          // M3's handoff convention 6. Without it "12.5" renders "5.21".
          textDirection: TextDirection.ltr,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(name, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  /// Drops a pointless `.0` — a label saying `12 ג` reads better than
  /// `12.0 ג`, and the extra digit is not information the label gave.
  static String _format(double grams) =>
      grams == grams.roundToDouble() && grams.abs() < 1000
      ? grams.toStringAsFixed(0)
      : grams.toStringAsFixed(1);
}
