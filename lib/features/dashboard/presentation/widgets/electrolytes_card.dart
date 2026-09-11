import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/dashboard/application/electrolyte_advice.dart';
import 'package:fantastic/features/dashboard/application/electrolyte_advisor.dart';
import 'package:fantastic/features/dashboard/application/providers/daily_log_providers.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:fantastic/features/dashboard/presentation/widgets/electrolytes_card_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sodium, potassium and magnesium against their phase-appropriate targets.
///
/// Electrolyte depletion is what most of the keto-flu experience actually is,
/// so this is prominent during induction and collapsible once the user stops
/// needing it daily.
class ElectrolytesCard extends ConsumerStatefulWidget {
  const ElectrolytesCard({
    required this.date,
    this.phase = _defaultPhase,
    super.key,
  });

  /// Pass a date-only value — `todaysDailyLogProvider` is keyed on it.
  final DateTime date;

  /// The adaptation phase the targets are drawn from.
  ///
  /// Defaults to induction, the safest assumption: it carries the highest
  /// targets, so a user whose real phase is later sees a deficit warning they
  /// could ignore rather than missing one they needed. M3's
  /// `currentPhaseProvider` (#59) replaces the default by passing the real
  /// phase — a parameter rather than a hardcoded constant inside `build`, so
  /// that wiring is a one-line change and this stays testable across phases.
  final AdaptationPhase phase;

  static const AdaptationPhase _defaultPhase = AdaptationPhase.induction;

  /// Shown in place of the deficit warning on a day with no `DailyLog`.
  static const String emptyDayMessage = 'טרם נרשמו אלקטרוליטים היום';

  @override
  ConsumerState<ElectrolytesCard> createState() => _ElectrolytesCardState();
}

class _ElectrolytesCardState extends ConsumerState<ElectrolytesCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final logAsync = ref.watch(todaysDailyLogProvider(widget.date));

    // `hasError` first, and `AsyncValue.when` deliberately not used at all.
    //
    // riverpod 3 reports a provider that failed *before ever producing a
    // value* as `AsyncLoading` **with an error attached** — both flags are
    // true — and `when` is loading-first, so this card's `error:` branch was
    // never reached for a first-read failure. Both branches happened to
    // return `SizedBox.shrink()`, which is precisely why nobody saw it: the
    // bug was invisible until a branch grew content (#302).
    //
    // Says the read failed rather than rendering nothing: an empty day and a
    // broken store look identical otherwise, and mean opposite things.
    if (logAsync.hasError) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('לא ניתן לטעון את המדדים')),
        ),
      );
    }

    if (!logAsync.hasValue) {
      return const ElectrolytesCardSkeleton();
    }

    // A day with nothing logged has no `DailyLog` at all, and every total on
    // one already defaults to zero — so the three targets are worth showing
    // before anything is logged, which on induction morning is exactly when
    // the user needs them.
    final stored = logAsync.requireValue;
    final log = stored ?? DailyLog(date: widget.date);

    return _card(
      ref.watch(electrolyteAdvisorProvider).advise(widget.phase, log),
      log,
      isEmptyDay: stored == null,
    );
  }

  Widget _card(
    ElectrolyteAdvice advice,
    DailyLog log, {
    required bool isEmptyDay,
  }) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('אלקטרוליטים'),
            // On a day with nothing logged, three full deficit bars read as a
            // failure rather than as a target — the same misreading
            // `EmptyMealsState` documents for the macro bars. A stored
            // all-zero day is **not** this: the record exists, so the user
            // logged something and then emptied it.
            subtitle: isEmptyDay
                ? const Text(ElectrolytesCard.emptyDayMessage)
                : advice.hasAnyDeficit
                ? const Text('חסרים אלקטרוליטים')
                : null,
            trailing: IconButton(
              // Labelled so the control is not an unnamed glyph to a screen
              // reader, and so tests target intent rather than an icon.
              tooltip: _expanded ? 'כווץ' : 'הרחב',
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _gauges(advice, log),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            // Without this the collapsed and expanded children are both laid
            // out at full height during the transition, which overflows.
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  Widget _gauges(ElectrolyteAdvice advice, DailyLog log) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    child: Column(
      children: [
        _ElectrolyteGauge(
          label: 'נתרן',
          loggedMg: log.sodiumMg,
          targetMg: advice.sodiumTargetMg,
          deficit: advice.sodiumDeficit,
        ),
        _ElectrolyteGauge(
          label: 'אשלגן',
          loggedMg: log.potassiumMg,
          targetMg: advice.potassiumTargetMg,
          deficit: advice.potassiumDeficit,
        ),
        _ElectrolyteGauge(
          label: 'מגנזיום',
          loggedMg: log.magnesiumMg,
          targetMg: advice.magnesiumTargetMg,
          deficit: advice.magnesiumDeficit,
        ),
      ],
    ),
  );
}

/// One electrolyte: label, `logged / target` in mg, and a bar.
class _ElectrolyteGauge extends StatelessWidget {
  const _ElectrolyteGauge({
    required this.label,
    required this.loggedMg,
    required this.targetMg,
    required this.deficit,
  });

  final String label;
  final double loggedMg;
  final double targetMg;
  final bool deficit;

  double get _progress =>
      targetMg <= 0 ? 0 : (loggedMg / targetMg).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Colour is a second channel, not the only one: the "חסרים אלקטרוליטים"
    // subtitle and the numbers both carry the same information for anyone who
    // cannot distinguish the two colours.
    final color = deficit ? theme.colorScheme.error : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              Text(
                '${loggedMg.toStringAsFixed(0)}/'
                '${targetMg.toStringAsFixed(0)} מ״ג',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              color: color,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}
