import 'package:fantastic/features/diary/application/providers/symptom_providers.dart';
import 'package:fantastic/features/diary/presentation/symptom_scale.dart';
import 'package:fantastic/features/diary/presentation/widgets/symptom_log_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The dashboard's five-second check-in: one cell per [SymptomScale] showing
/// today's score, each opening [SymptomLogSheet] focused on the scale tapped.
///
/// A day with nothing logged shows five empty cells rather than hiding — the
/// prompt to log is the point, and a strip that appeared only once there was
/// something to show would never be seen by the user who has not started.
class SymptomCheckInStrip extends ConsumerWidget {
  const SymptomCheckInStrip({required this.date, super.key});

  /// Pass a date-only value — `symptomLogProvider` is a family keyed on it,
  /// and a wall-clock time recomputed each build would refetch forever.
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logAsync = ref.watch(symptomLogProvider(date));

    // Failure is checked before loading, and the order is load-bearing:
    // riverpod 3 reports a provider that failed before ever producing a value
    // as `AsyncLoading` with an error attached, so both flags are true at
    // once. A loading-first check — `AsyncValue.when` included, which is
    // written loading-first — leaves the placeholder up forever. See
    // `design/m5_preflight.md` §1.2.
    //
    // A failed *read* still leaves the cells tappable: the user can log the
    // day even when the day's stored answers could not be fetched, and
    // refusing the write because the read failed would be the worse outcome.
    final failed = logAsync.hasError;
    final loading = !failed && logAsync.isLoading;
    final log = logAsync.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Text('תסמינים היום', style: theme.textTheme.titleSmall),
                  const Spacer(),
                  if (failed)
                    // Says the read failed rather than passing an unlogged
                    // day off as fact — they mean opposite things.
                    Text(
                      'לא ניתן לטעון',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final scale in SymptomScale.values)
                  Expanded(
                    child: _ScaleCell(
                      scale: scale,
                      score: log == null ? null : scale.scoreIn(log),
                      loading: loading,
                      onTap: () => SymptomLogSheet.show(
                        context,
                        date: date,
                        existing: log,
                        focus: scale,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One scale's cell: its icon, its short label, and its score as dots.
class _ScaleCell extends StatelessWidget {
  const _ScaleCell({
    required this.scale,
    required this.score,
    required this.loading,
    required this.onTap,
  });

  final SymptomScale scale;

  /// Null when the day has no log — the cell reads as unlogged.
  final int? score;

  final bool loading;

  final VoidCallback onTap;

  /// Apple HIG's minimum touch target.
  static const double minTouchTarget = 44;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final logged = score != null;

    return Semantics(
      button: true,
      label: logged ? '${scale.label} $score' : scale.label,
      child: InkWell(
        key: Key('symptom_cell_${scale.name}'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: _ScaleCell.minTouchTarget - 16,
                child: Icon(
                  scale.icon,
                  size: 24,
                  color: logged ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
              Text(
                scale.shortLabel,
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // The loading state reserves exactly the dots' height, so the
              // strip does not jump when the read lands.
              SizedBox(
                height: _ScoreDots.diameter,
                child: loading ? null : _ScoreDots(scale: scale, score: score),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A 1–5 score as five dots, [score] of them filled.
///
/// Dots rather than a numeral: five cells share the screen width, and a
/// filled count reads as a rating at a glance without a digit run to get the
/// direction of. In RTL the first dot lands at the right, so a score fills
/// from the right — the direction a Hebrew reader starts from.
class _ScoreDots extends StatelessWidget {
  const _ScoreDots({required this.scale, required this.score});

  final SymptomScale scale;

  /// Null renders five empty dots: the day is not logged.
  final int? score;

  static const double diameter = 6;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var dot = 1; dot <= 5; dot++)
          Container(
            // Keyed so a test can read which dots are filled, rather than
            // re-deriving the score from the provider it was given. A strip
            // that drew every cell from `energyScore` passes the second kind
            // of assertion and fails this one.
            key: Key('symptom_dot_${scale.name}_$dot'),
            width: diameter,
            height: diameter,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: score != null && dot <= score!
                  ? scheme.primary
                  : scheme.surfaceContainerHighest,
            ),
          ),
      ],
    );
  }
}
