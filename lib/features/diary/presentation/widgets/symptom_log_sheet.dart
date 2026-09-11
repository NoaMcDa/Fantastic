import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/diary/application/providers/symptom_providers.dart';
import 'package:fantastic/features/diary/application/symptom_logging_service.dart';
import 'package:fantastic/features/diary/domain/models/physical_symptom.dart';
import 'package:fantastic/features/diary/domain/models/symptom_log.dart';
import 'package:fantastic/features/diary/presentation/physical_symptom_copy.dart';
import 'package:fantastic/features/diary/presentation/symptom_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The day's symptom check-in: one 1–5 selector per [SymptomScale], a chip
/// grid of physical symptoms, an optional note, and a save.
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
    this.focusSymptoms = false,
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

  /// Set when the user tapped the physical-symptom row rather than a scale.
  ///
  /// A separate flag rather than a widened [focus]: physical symptoms stopped
  /// being a [SymptomScale], and there is exactly one non-scale target, so a
  /// sealed union would be more machinery than the problem has. Epic #9's
  /// Definition of Done requires the correct pre-focused sheet either way.
  final bool focusSymptoms;

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
    bool focusSymptoms = false,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => SymptomLogSheet(
      date: date,
      existing: existing,
      focus: focus,
      focusSymptoms: focusSymptoms,
    ),
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

  /// The symptoms the user has selected in this session.
  ///
  /// A fresh mutable copy, not `widget.existing!.symptoms` directly. Aliasing
  /// the persisted log's set and mutating it in place as the user taps would
  /// mean a cancelled sheet — one the user dismissed without saving — still
  /// changed the object the provider is holding. The copy is correct; the
  /// alias is a silent data mutation.
  late final Set<PhysicalSymptom> _symptoms = {...?widget.existing?.symptoms};

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
            const Divider(height: 24),
            // Physical-symptom chip grid.
            Container(
              key: const Key('symptom_section'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: widget.focusSymptoms
                  ? BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'סמנו מה שהרגשתם היום:',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  // `Wrap`, not `GridView`: the chips have variable width and
                  // the sheet is already inside a `SingleChildScrollView`,
                  // which a nested scrollable would fight. `Wrap` reflows
                  // correctly under RTL without extra work.
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final symptom in PhysicalSymptom.values)
                        FilterChip(
                          key: Key('symptom_filter_${symptom.name}'),
                          avatar: Icon(symptom.icon, size: 16),
                          label: Text(symptom.label),
                          selected: _symptoms.contains(symptom),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              _symptoms.add(symptom);
                            } else {
                              _symptoms.remove(symptom);
                            }
                          }),
                        ),
                    ],
                  ),
                  if (_symptoms.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      key: const Key('clear_symptoms_button'),
                      onPressed: () => setState(_symptoms.clear),
                      child: const Text('לא הרגשתי כלום מיוחד'),
                    ),
                  ],
                ],
              ),
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

    final service = ref.read(symptomLoggingServiceProvider);

    // The record this save is layered on top of.
    //
    // Usually the one the caller handed in. But the strip stays tappable when
    // its read **failed** or is still in flight, and in both cases it passes
    // `existing: null` — which does not mean the day is blank, only that its
    // contents are unknown. `save` upserts on the date, so trusting that null
    // would overwrite a stored day's note and scores with defaults: the very
    // data loss `design/m5_preflight.md` §1.3 was written about, surviving on
    // the failure path. One keyed record read settles it.
    var base = widget.existing;
    if (base == null) {
      try {
        base = await service.symptomsForDate(widget.date);
      } on Object catch (_) {
        // Still unreadable. Go ahead with the write the user asked for — a
        // store this broken will almost certainly reject it too, and the
        // catch below is what tells them.
      }
      if (!mounted) {
        return;
      }
    }

    final typed = _notesController.text.trim();
    // An empty field clears the note only when the user could see what they
    // were clearing. A note recovered just above was never on screen — the
    // sheet seeded its field from `widget.existing`, which was null — so an
    // empty field there is silence, not an instruction to delete it.
    final String? notes;
    if (typed.isNotEmpty) {
      notes = typed;
    } else if (widget.existing != null) {
      notes = null;
    } else {
      notes = base?.notes;
    }

    // `_symptoms` needs no equivalent of the notes dance above.
    //
    // For notes: an empty field when `widget.existing` was null means the
    // user never saw a note, so we silently preserve `base?.notes` rather
    // than treating the empty field as an instruction to clear it.
    //
    // For symptoms: `_symptoms` was seeded from `widget.existing?.symptoms`,
    // so when `widget.existing` was null, `_symptoms` started as an empty
    // set — the same state as `base?.symptoms` being empty. But unlike notes,
    // an empty symptom set *from a sheet the user actually saw* genuinely
    // means "felt nothing today" and should be stored as such. There is no
    // ambiguity between "the user cleared all chips" and "the sheet never
    // showed them" because `base` can only carry symptoms from a record the
    // user already logged, which by definition they have already seen. The
    // asymmetry is correct; do not add a recovery branch here.
    final log = buildSymptomLog(
      date: widget.date,
      scores: _scores,
      symptoms: _symptoms,
      // Both carried through from the record being edited. `save` upserts on
      // the date, so a log rebuilt without them drops the note the user typed
      // and re-keys nothing — see `design/m5_preflight.md` §1.3.
      id: base?.id,
      notes: notes,
    );

    try {
      await service.logSymptoms(log);
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
  ///
  /// `_ScaleCell` in `symptom_check_in_strip.dart` declares its own copy of
  /// this. Deliberately left duplicated: hoisting it is a shared-constant
  /// change across three features and would make #307 non-atomic.
  static const double minTouchTarget = 44;

  /// The width of the rounded outline both states carry.
  ///
  /// Applied to the selected state too, in `primary` over its own `primary`
  /// fill, so selecting a score cannot move the digit inside it.
  static const double borderWidth = 1.5;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      // Four points between cells rather than two: five outlined boxes two
      // points apart read as one segmented control, which is a different
      // affordance from five independent choices.
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: selected ? scheme.primary : scheme.surfaceContainerHighest,
        // `shape` rather than `borderRadius` — `Material` asserts if given
        // both. The border goes on the `Material` rather than on a wrapping
        // `Container` so the `InkWell`'s ripple stays clipped to the same
        // rounded rect; a `BoxDecoration` outside the `Material` would let
        // the ripple square off at the corners.
        //
        // Both states carry a border of the same width, so the digit never
        // shifts by a pixel between them. Only the unselected one is
        // *visible*: `surfaceContainerHighest` alone is within a few points
        // of the sheet behind it (#307).
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? scheme.primary : AppTheme.outline,
            width: borderWidth,
          ),
        ),
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
