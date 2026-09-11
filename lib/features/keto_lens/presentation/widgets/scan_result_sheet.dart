import 'dart:async';

import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_bottom_sheet.dart';
import 'package:fantastic/core/utils/numeric_input.dart';
import 'package:fantastic/features/keto_lens/domain/models/parsed_label.dart';
import 'package:fantastic/features/keto_lens/domain/models/serving_basis.dart';
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
            final ScanSucceeded success => [
              _SuccessBody(success: success, date: date),
            ],
            final ScanFailed failure => _failure(context, failure),
          },
        ),
      ),
    );
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
    ScanFailureReason.unavailable => 'הסורק אינו זמין במכשיר הזה',
    ScanFailureReason.recognitionFailed => 'הסריקה נכשלה',
    ScanFailureReason.noTextFound => 'לא זוהה טקסט בתמונה',
    ScanFailureReason.notALabel => 'זו לא נראית תווית תזונה',
  };

  /// What to do about it — different per reason, which is the whole point
  /// of there being four.
  @visibleForTesting
  static String failureAdvice(ScanFailureReason reason) => switch (reason) {
    ScanFailureReason.unavailable =>
      'מנוע זיהוי הטקסט לא זמין כאן. שאר האפליקציה עובדת כרגיל.',
    ScanFailureReason.recognitionFailed =>
      'משהו השתבש בזיהוי הטקסט. נסו לצלם שוב.',
    ScanFailureReason.noTextFound =>
      'התקרבו לתווית, החזיקו את המכשיר יציב וודאו שיש מספיק אור.',
    ScanFailureReason.notALabel =>
      'הפכו את האריזה וצלמו את טבלת הערכים התזונתיים בגב המוצר.',
  };

  /// What the macro figures are per, in Hebrew.
  ///
  /// The `unknown` string is M6's original caption, unchanged: #257's
  /// Definition of Done requires that an unreadable label keeps exactly the
  /// behaviour and the wording it had, because asking the user to check is
  /// still the right answer when the app cannot tell.
  @visibleForTesting
  static String basisCaption(ServingBasis basis) => switch (basis) {
    ServingBasis.per100g => 'הערכים בתווית הם ל-100 גרם',
    ServingBasis.per100ml => 'הערכים בתווית הם ל-100 מ"ל',
    ServingBasis.perServing => 'הערכים בתווית הם למנה אחת',
    ServingBasis.unknown => 'הערכים מהתווית — בדקו את גודל המנה לפני השמירה',
  };

  /// The amount field's label. Only reachable for a per-100 basis.
  @visibleForTesting
  static String amountLabel(ServingBasis basis) => switch (basis) {
    ServingBasis.per100ml => 'כמה מ"ל שתיתם?',
    _ => 'כמה גרם אכלתם?',
  };
}

/// The success half of the sheet, with the amount control that #257 added.
///
/// Stateful because the amount is user input. `ScanResultSheet` itself stays
/// stateless — the state is genuinely local to this body, and keeping it here
/// means the failure path has no state to reason about at all.
class _SuccessBody extends StatefulWidget {
  const _SuccessBody({required this.success, required this.date});

  final ScanSucceeded success;
  final DateTime date;

  @override
  State<_SuccessBody> createState() => _SuccessBodyState();
}

class _SuccessBodyState extends State<_SuccessBody> {
  late final TextEditingController _amount;

  ParsedLabel get _label => widget.success.label;

  @override
  void initState() {
    super.initState();
    // The label's own declared serving where it printed one, else 100 — which
    // is a no-op scale, so a user who ignores this field gets exactly the
    // behaviour that shipped in M6 rather than a surprise.
    _amount = TextEditingController(
      text: _formatGrams(_label.servingGrams ?? _referenceAmount),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  /// What the printed figures describe: 100 g, 100 ml, or one serving.
  double get _referenceAmount => 100;

  /// The multiplier applied to every macro before it reaches the diary.
  ///
  /// 1.0 unless the label said its figures are per 100 units *and* the user's
  /// amount parses. Both halves matter: an unreadable basis must not scale
  /// (#257's own Definition of Done says an `unknown` label keeps today's
  /// behaviour), and an empty or nonsense field must not silently log zero.
  double get _scale {
    if (!_label.basis.isPerHundred) return 1;
    final grams = NumericInput.positiveFinite(_amount.text);
    if (grams == null) return 1;
    return grams / _referenceAmount;
  }

  double? _scaled(double? value) => value == null ? null : value * _scale;

  @override
  Widget build(BuildContext context) {
    final verdict = widget.success.verdict;
    final scale = _scale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: VerdictBadgeWidget(
            badge: verdict.badge,
            recognisedNothing: verdict.recognisedNothing,
          ),
        ),
        if (_label.hasMacros) ...[
          const SizedBox(height: 20),
          // The strip shows what will be LOGGED, not what is printed, so the
          // number the user is about to save is the number in front of them.
          // The caption below says what it was scaled from.
          _MacroStrip(
            fatG: _scaled(_label.fatG),
            netCarbsG: _scaled(_label.netCarbsG),
            proteinG: _scaled(_label.proteinG),
          ),
          const SizedBox(height: 8),
          Text(
            key: const Key('scan_basis_caption'),
            ScanResultSheet.basisCaption(_label.basis),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (_label.basis.isPerHundred) ...[
            const SizedBox(height: 16),
            TextField(
              key: const Key('scan_amount_field'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              // Rebuild on every keystroke so the strip above tracks the
              // field. There is no Save-then-discover step.
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: ScanResultSheet.amountLabel(_label.basis),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
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
              child: Text('\u2022 $ingredient'),
            ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('add_to_diary_button'),
          onPressed: () => _addToDiary(context, scale),
          child: const Text('הוסף ליומן'),
        ),
      ],
    );
  }

  void _addToDiary(BuildContext context, double scale) {
    // The Navigator's own context outlives this sheet's, so the add-meal
    // sheet has somewhere to open after the pop.
    final navigator = Navigator.of(context);
    final host = navigator.context;
    navigator.pop();
    unawaited(
      AddMealBottomSheet.show(
        host,
        date: widget.date,
        initialName: 'מוצר סרוק',
        // Null stays null rather than becoming 0: a macro the parser did
        // not find is unknown, and prefilling zero would have the user
        // save a fat-free tahini without noticing. The field is left blank
        // and the form's own validator asks for it. Scaling preserves that —
        // null times anything is still null.
        initialFatG: _scaled(_label.fatG),
        initialNetCarbsG: _scaled(_label.netCarbsG),
        initialProteinG: _scaled(_label.proteinG),
      ),
    );
  }
}

/// Formats a gram figure for the amount field without a trailing `.0`.
String _formatGrams(double grams) =>
    grams == grams.roundToDouble() ? grams.round().toString() : '$grams';

/// Fat / net carbs / protein, side by side.
///
/// Takes three figures rather than a [ParsedLabel] because since #257 it shows
/// what will be *logged* — the label's numbers scaled to the amount eaten —
/// and a `ParsedLabel` holds only what was printed. Passing the label and
/// scaling in here would have put the multiplier in two places.
class _MacroStrip extends StatelessWidget {
  const _MacroStrip({
    required this.fatG,
    required this.netCarbsG,
    required this.proteinG,
  });

  final double? fatG;
  final double? netCarbsG;
  final double? proteinG;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Macro(name: 'שומן', grams: fatG),
        _Macro(name: 'פחמימות נטו', grams: netCarbsG),
        _Macro(name: 'חלבון', grams: proteinG),
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
