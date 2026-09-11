import 'package:fantastic/features/diary/application/providers/symptom_providers.dart';
import 'package:fantastic/features/diary/domain/models/physical_symptom.dart';
import 'package:fantastic/features/diary/domain/models/symptom_log.dart';
import 'package:fantastic/features/diary/presentation/physical_symptom_copy.dart';
import 'package:fantastic/features/diary/presentation/symptom_scale.dart';
import 'package:fantastic/features/diary/presentation/widgets/symptom_log_sheet.dart';
import 'package:fantastic/core/widgets/empty_state_widget.dart';
import 'package:fantastic/features/diary/presentation/widgets/symptom_diary_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The diary's read-only view of a day's symptoms: one chip per scale, the
/// note if there is one, and a way in to edit.
///
/// The counterpart to `SymptomCheckInStrip`. The strip is the dashboard's
/// prompt for *today*; this is the record of *any* day, so it reads rather
/// than nudges — no per-scale tap targets, one edit affordance.
class SymptomDiarySection extends ConsumerWidget {
  const SymptomDiarySection({required this.date, super.key});

  /// Pass a date-only value — `symptomLogProvider` is a family keyed on it.
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logAsync = ref.watch(symptomLogProvider(date));

    // Failure before loading. riverpod 3 reports a provider that failed
    // before ever producing a value as `AsyncLoading` with an error attached,
    // so a loading-first check — `AsyncValue.when` included — never reaches
    // its error branch. See `design/m5_preflight.md` §1.2.
    final Widget body;
    if (logAsync.hasError) {
      body = const _Message('לא ניתן לטעון את התסמינים');
    } else if (logAsync.isLoading) {
      body = const SymptomDiarySkeleton();
    } else {
      final log = logAsync.value;
      body = log == null ? _Empty(date: date) : _Summary(date: date, log: log);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('תסמינים', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            body,
          ],
        ),
      ),
    );
  }
}

/// A day with nothing logged.
///
/// Keeps its call-to-action, unlike [EmptyMealsState]: there is no symptom FAB
/// for it to compete with, and the shared widget's optional `action` is how
/// that asymmetry is expressed rather than a second empty-state widget (#91).
class _Empty extends StatelessWidget {
  const _Empty({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) => EmptyStateWidget(
    // Already this feature's symptom iconography — see
    // `symptom_check_in_strip.dart`.
    icon: Icons.healing_outlined,
    // `ui_ux_design.md`'s empty-state line, minus its "today": this screen
    // renders any past day.
    headline: 'לא הוקלטו תסמינים',
    action: TextButton.icon(
      key: const Key('log_symptoms_button'),
      onPressed: () => SymptomLogSheet.show(context, date: date),
      icon: const Icon(Icons.add),
      label: const Text('רשום תסמינים'),
    ),
  );
}

/// A logged day: the four scale scores, the physical symptom chips, the note,
/// and an edit affordance.
class _Summary extends StatelessWidget {
  const _Summary({required this.date, required this.log});

  final DateTime date;
  final SymptomLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notes = log.notes;

    // Iterate PhysicalSymptom.values, not log.symptoms, so two days with the
    // same symptoms always render them in the same sequence regardless of the
    // set's insertion order — issue #293 §1.
    final activeSymptoms = [
      for (final symptom in PhysicalSymptom.values)
        if (log.symptoms.contains(symptom)) symptom,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score chips — one per SymptomScale (four total).
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final scale in SymptomScale.values)
              _ScoreChip(scale: scale, score: scale.scoreIn(log)),
          ],
        ),
        const SizedBox(height: 8),
        // Physical symptom chips — a second Wrap, not merged into the score
        // Wrap. Score chips carry a digit; symptom chips do not; interleaving
        // them produces a run where `רעב 3` sits beside `כאב ראש` with no
        // visual rule explaining the difference.
        if (activeSymptoms.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final symptom in activeSymptoms)
                _SymptomChip(symptom: symptom),
            ],
          )
        else
          // Record exists but no physical symptoms were marked — distinct from
          // the whole-day empty state `לא הוקלטו תסמינים` in `_Empty`, which
          // means the day has no record at all. Both must exist; they say
          // different things.
          Text(
            'לא דווחו תסמינים פיזיים',
            key: const Key('no_physical_symptoms'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (notes != null && notes.isNotEmpty) ...[
          const SizedBox(height: 8),
          // Shown, not just stored. A note the user can never see again is
          // one they will not write twice — and it is the field the issue
          // text dropped entirely (`design/m5_preflight.md` §1.3).
          Text(notes, style: theme.textTheme.bodySmall),
        ],
        TextButton.icon(
          key: const Key('edit_symptoms_button'),
          onPressed: () =>
              SymptomLogSheet.show(context, date: date, existing: log),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('עריכה'),
        ),
      ],
    );
  }
}

/// One scale and its score.
class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.scale, required this.score});

  final SymptomScale scale;
  final int score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Chip(
      key: Key('symptom_chip_${scale.name}'),
      visualDensity: VisualDensity.compact,
      avatar: Icon(scale.icon, size: 16),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(scale.label),
          const SizedBox(width: 4),
          Text(
            '$score',
            // A digit inside the RTL layout — m3_handoff.md convention 6.
            textDirection: TextDirection.ltr,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A read-only chip for a single [PhysicalSymptom] — icon and Hebrew label.
///
/// No digit, no severity: physical symptoms are either present or absent.
/// The score chips above show gradations; mixing them in one Wrap without a
/// visual rule explaining why some have digits and some do not would confuse.
class _SymptomChip extends StatelessWidget {
  const _SymptomChip({required this.symptom});

  final PhysicalSymptom symptom;

  @override
  Widget build(BuildContext context) => Chip(
    key: Key('diary_symptom_${symptom.name}'),
    visualDensity: VisualDensity.compact,
    avatar: Icon(symptom.icon, size: 16),
    label: Text(symptom.label),
  );
}

/// A one-line message in place of the content.
class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.bodyMedium);
}
