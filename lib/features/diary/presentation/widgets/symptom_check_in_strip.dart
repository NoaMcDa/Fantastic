import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/diary/application/providers/symptom_providers.dart';
import 'package:fantastic/features/diary/domain/models/physical_symptom.dart';
import 'package:fantastic/features/diary/domain/models/symptom_log.dart';
import 'package:fantastic/features/diary/presentation/physical_symptom_copy.dart';
import 'package:fantastic/features/diary/presentation/symptom_scale.dart';
import 'package:fantastic/features/diary/presentation/widgets/symptom_log_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The dashboard's five-second check-in: one cell per [SymptomScale] showing
/// today's score, each opening [SymptomLogSheet] focused on the scale tapped,
/// plus a chip row below showing the day's marked physical symptoms.
///
/// A day with nothing logged shows four empty cells and an empty chip row
/// rather than hiding — the prompt to log is the point, and a strip that
/// appeared only once there was something to show would never be seen by the
/// user who has not started.
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
                    // Flexible, not a bare Text: composed inside
                    // `DashboardScreen`'s padded card, the title and this
                    // message together do not fit the row at a 320px
                    // viewport (measured 82px over — see #409). `Flexible`
                    // with an ellipsis lets the message concede width to the
                    // title instead of overflowing; the strip's own
                    // isolated 320px test never caught this because it gives
                    // the Row the full viewport width, with none of the
                    // dashboard's `EdgeInsets.all(16)` or the card's own
                    // padding subtracted.
                    Flexible(
                      child: Text(
                        'לא ניתן לטעון',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
            const Divider(height: 16),
            _SymptomChipRow(date: date, log: log, loading: loading),
          ],
        ),
      ),
    );
  }
}

/// The chip row showing the day's marked physical symptoms.
///
/// Shows a leading healing icon, one read-only [Chip] per marked symptom
/// (in [PhysicalSymptom.values] order, not set insertion order), and a
/// trailing ＋ [IconButton] that opens [SymptomLogSheet] pre-focused on the
/// symptom section.
///
/// States:
/// - **loading** — reserves the row's height and renders nothing, so the
///   card does not jump when the read lands. Mirrors [_ScaleCell]'s approach.
/// - **not logged or logged with empty set** — icon, muted "ללא תסמינים פיזיים"
///   text, and the ＋ button. Both states look identical on the dashboard;
///   the nuance lives in the sheet.
/// - **logged with symptoms** — one chip per marked symptom in enum order.
/// - **read failed** — stays fully tappable. A failed read must not block the
///   write; the same reasoning at `symptom_check_in_strip.dart:32` applies.
class _SymptomChipRow extends StatelessWidget {
  const _SymptomChipRow({
    required this.date,
    required this.log,
    required this.loading,
  });

  final DateTime date;

  /// Null when the day has no log or when the read failed.
  final SymptomLog? log;

  final bool loading;

  /// The height to reserve while loading, matching the chip row's natural
  /// height so the card does not jump when the read lands.
  static const double _reservedHeight = 32;

  @override
  Widget build(BuildContext context) {
    // Reserve height during loading so the card does not jump.
    if (loading) {
      return const SizedBox(height: _reservedHeight);
    }

    final theme = Theme.of(context);
    final log = this.log;

    // Chips are built in PhysicalSymptom.values order, never set order.
    // Set iteration is insertion order: two days with identical symptoms would
    // otherwise render them in different sequences depending on which was added
    // first. Filtering the canonical enum order produces a stable layout.
    final markedSymptoms = log == null
        ? <PhysicalSymptom>[]
        : PhysicalSymptom.values.where(log.symptoms.contains).toList();

    final hasSymptoms = markedSymptoms.isNotEmpty;

    // Build the semantics label for the whole row so a screen-reader user
    // hears the list of symptoms rather than N unlabelled chips.
    final semanticsLabel = hasSymptoms
        ? 'תסמינים פיזיים: ${markedSymptoms.map((s) => s.label).join(', ')}'
        : 'ללא תסמינים פיזיים';

    return Semantics(
      label: semanticsLabel,
      child: Row(
        children: [
          Icon(
            Icons.healing_outlined,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: hasSymptoms
                ? Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final symptom in markedSymptoms)
                        Chip(
                          key: Key('strip_symptom_${symptom.name}'),
                          // ExcludeSemantics so the row-level Semantics label
                          // is the single readable unit rather than each chip
                          // announcing itself separately.
                          label: ExcludeSemantics(
                            child: Text(
                              symptom.label,
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                          avatar: ExcludeSemantics(
                            child: Icon(symptom.icon, size: 14),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  )
                : Text(
                    'ללא תסמינים פיזיים',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
          Semantics(
            label: 'הוספת תסמינים פיזיים',
            button: true,
            excludeSemantics: true,
            child: IconButton(
              key: const Key('add_symptoms_button'),
              icon: const Icon(Icons.add),
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              onPressed: () => SymptomLogSheet.show(
                context,
                date: date,
                existing: log,
                focusSymptoms: true,
              ),
            ),
          ),
        ],
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

  /// The ring an unfilled dot is drawn as.
  static const double ringWidth = 1.2;

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
            // A disc when filled, a ring when not (#307). It used to be a
            // disc either way, distinguished only by
            // `surfaceContainerHighest` — which on this palette is within a
            // few points of the card behind it, so an unfilled dot was not
            // so much low-contrast as absent, and a 2-of-5 score and an
            // unlogged scale looked the same.
            //
            // Ring versus disc rather than two fills because these are 6pt
            // apart at 6pt across: shape survives that, and a colour pair
            // this small does not (`design/m6_handoff.md` convention 8 —
            // colour is never the only signal).
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: score != null && dot <= score!
                  ? scheme.primary
                  : Colors.transparent,
              border: score != null && dot <= score!
                  ? null
                  : Border.all(color: AppTheme.outline, width: ringWidth),
            ),
          ),
      ],
    );
  }
}
