import 'package:fantastic/features/diary/application/providers/symptom_providers.dart';
import 'package:fantastic/features/diary/domain/models/symptom_log.dart';
import 'package:fantastic/features/diary/presentation/symptom_scale.dart';
import 'package:fantastic/features/diary/presentation/widgets/symptom_log_sheet.dart';
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
      body = const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
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
class _Empty extends StatelessWidget {
  const _Empty({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // `ui_ux_design.md`'s empty-state line, minus its "today": this
        // screen renders any past day.
        Text(
          'לא הוקלטו תסמינים',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton.icon(
          key: const Key('log_symptoms_button'),
          onPressed: () => SymptomLogSheet.show(context, date: date),
          icon: const Icon(Icons.add),
          label: const Text('רשום תסמינים'),
        ),
      ],
    );
  }
}

/// A logged day: the five scores, the note, and an edit affordance.
class _Summary extends StatelessWidget {
  const _Summary({required this.date, required this.log});

  final DateTime date;
  final SymptomLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notes = log.notes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final scale in SymptomScale.values)
              _ScoreChip(scale: scale, score: scale.scoreIn(log)),
          ],
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

/// A one-line message in place of the content.
class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.bodyMedium);
}
