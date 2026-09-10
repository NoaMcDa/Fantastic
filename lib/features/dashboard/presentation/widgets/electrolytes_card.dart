import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/dashboard/application/electrolyte_advice.dart';
import 'package:fantastic/features/dashboard/application/electrolyte_advisor.dart';
import 'package:fantastic/features/dashboard/application/providers/daily_log_providers.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
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

  @override
  ConsumerState<ElectrolytesCard> createState() => _ElectrolytesCardState();
}

class _ElectrolytesCardState extends ConsumerState<ElectrolytesCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final logAsync = ref.watch(todaysDailyLogProvider(widget.date));

    return logAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (log) => log == null
          ? const SizedBox.shrink()
          : _card(
              ref.watch(electrolyteAdvisorProvider).advise(widget.phase, log),
              log,
            ),
    );
  }

  Widget _card(ElectrolyteAdvice advice, DailyLog log) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('אלקטרוליטים'),
            subtitle: advice.hasAnyDeficit
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
