import 'package:fantastic/features/diary/application/providers/symptom_providers.dart';
import 'package:fantastic/features/diary/application/symptom_logging_service.dart';
import 'package:fantastic/features/diary/domain/models/symptom_log.dart';
import 'package:fantastic/features/diary/presentation/symptom_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The day's symptom check-in: one 1–5 selector per [SymptomScale], an
/// optional note, and a save.
///
/// Opened from the dashboard strip and from the diary's symptom section. Both
/// pass the day's existing log when there is one, so the sheet opens on the
/// user's current answers rather than resetting them to the mid-scale
/// default.
class SymptomLogSheet extends ConsumerStatefulWidget {
  const SymptomLogSheet({
    required this.date,
    this.existing,
    this.focus,
    super.key,
  });

  /// The day being logged. Normalised to midnight before saving.
  final DateTime date;

  /// The stored log for [date], when the day already has one.
  ///
  /// Carries the note and the record id through an edit as well as the
  /// scores — see [buildSymptomLog].
  final SymptomLog? existing;

  /// The scale the user tapped to get here, highlighted on open.
  ///
  /// Epic #9's Definition of Done requires *"the correct pre-focused sheet"*;
  /// #76's text says any icon opens the same sheet regardless. The Epic is
  /// what a milestone closes against, so the tapped scale is carried in and
  /// marked. Null when the sheet was opened from a general "log symptoms"
  /// action, which has no particular scale.
  final SymptomScale? focus;

  /// Mid-scale starting point for a day with nothing logged.
  static const int defaultScore = 3;

  /// Opens the sheet as a modal over [context].
  ///
  /// Lives here, as `AddMealBottomSheet.show` does, so the sheet owns how it
  /// is presented — `isScrollControlled` is what lets it grow past half the
  /// screen and lift clear of the keyboard when the note field has focus.
  static Future<void> show(
    BuildContext context, {
    required DateTime date,
    SymptomLog? existing,
    SymptomScale? focus,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        SymptomLogSheet(date: date, existing: existing, focus: focus),
  );

  @override
  ConsumerState<SymptomLogSheet> createState() => _SymptomLogSheetState();
}

class _SymptomLogSheetState extends ConsumerState<SymptomLogSheet> {
  /// One score per scale, seeded from the stored log or the default.
  ///
  /// A map keyed on the enum rather than five `int` fields: five fields is
  /// five chances to wire the wrong one to the wrong row, which is the exact
  /// mistake the issue text made.
  late final Map<SymptomScale, int> _scores = {
    for (final scale in SymptomScale.values)
      scale: widget.existing == null
          ? SymptomLogSheet.defaultScore
          : scale.scoreIn(widget.existing!),
  };

  late final TextEditingController _notesController = TextEditingController(
    text: widget.existing?.notes ?? '',
  );

  bool _saving = false;
  String? _saveError;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      // Lifts the note field clear of the software keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'איך הרגשת היום?',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            for (final scale in SymptomScale.values)
              _ScaleRow(
                scale: scale,
                value: _scores[scale]!,
                highlighted: scale == widget.focus,
                onChanged: (score) => setState(() => _scores[scale] = score),
              ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('symptom_notes_field'),
              controller: _notesController,
              maxLines: 2,
              maxLength: _maxNotesLength,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'הערות (רשות)',
                alignLabelWithHint: true,
              ),
            ),
            if (_saveError != null) ...[
              const SizedBox(height: 4),
              Text(
                _saveError!,
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('save_symptoms_button'),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'שומר...' : 'שמור'),
            ),
          ],
        ),
      ),
    );
  }

  static const int _maxNotesLength = 280;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });

    final notes = _notesController.text.trim();
    final log = buildSymptomLog(
      date: widget.date,
      scores: _scores,
      // Both carried through from the record being edited. `save` upserts on
      // the date, so a log rebuilt without them drops the note the user typed
      // and re-keys nothing — see `design/m5_preflight.md` §1.3.
      id: widget.existing?.id,
      notes: notes.isEmpty ? null : notes,
    );

    try {
      await ref.read(symptomLoggingServiceProvider).logSymptoms(log);
    } on Object catch (_) {
      // Stays open with the user's answers intact. Closing on failure would
      // discard them and tell the user they were saved — the reasoning
      // `AddMealBottomSheet` already settled for the meal form.
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError = 'השמירה נכשלה, נסו שוב';
        });
      }
      return;
    }

    // Guards `ref` as well as `context`: using a disposed `WidgetRef` throws,
    // and the sheet can be dismissed while the save is in flight.
    if (!mounted) {
      return;
    }
    ref.invalidate(symptomLogProvider(widget.date));
    Navigator.of(context).pop();
  }
}

/// One scale: its label, and the 1–5 selector under it.
class _ScaleRow extends StatelessWidget {
  const _ScaleRow({
    required this.scale,
    required this.value,
    required this.highlighted,
    required this.onChanged,
  });

  final SymptomScale scale;
  final int value;

  /// The scale the user tapped to open the sheet.
  final bool highlighted;

  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      // The key sits on the decorated box, not on `_ScaleRow`, so a test can
      // read the decoration that carries the pre-focus highlight.
      key: Key('symptom_row_${scale.name}'),
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: highlighted
          ? BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(scale.icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(scale.label, style: theme.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 4),
          // A plain `Row`, not a scrollable one: five cells fit the narrowest
          // supported width, and a horizontal scroller inside an RTL layout
          // is the trap `m2_handoff.md` records. In RTL the first child lands
          // at the right, so the scale reads 1→5 right to left, the direction
          // a Hebrew reader scans.
          Row(
            children: [
              for (
                var score = SymptomLoggingService.minScore;
                score <= SymptomLoggingService.maxScore;
                score++
              )
                Expanded(
                  child: _ScoreButton(
                    key: Key('score_${scale.name}_$score'),
                    score: score,
                    selected: score == value,
                    onTap: () => onChanged(score),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One tappable value on a 1–5 scale.
class _ScoreButton extends StatelessWidget {
  const _ScoreButton({
    required this.score,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final int score;
  final bool selected;
  final VoidCallback onTap;

  /// Apple HIG's minimum, and the reason this is a button row rather than the
  /// `Slider` #77 specified — a slider thumb is smaller than this and shows
  /// no value.
  static const double minTouchTarget = 44;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: selected ? scheme.primary : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            height: minTouchTarget,
            alignment: Alignment.center,
            child: Text(
              '$score',
              // A digit inside an RTL layout.
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
