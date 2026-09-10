import 'package:fantastic/core/constants/electrolyte_constants.dart';
import 'package:fantastic/core/constants/phase_copy.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:flutter/material.dart';
// `intl` exports a TextDirection of its own, which shadows dart:ui's and
// makes the `TextDirection.ltr` below fail to resolve.
import 'package:intl/intl.dart' hide TextDirection;

/// What to expect in [phase], and the electrolyte intake it calls for.
///
/// Static content: no provider, no I/O. The copy comes from [PhaseCopy] and
/// the numbers from [ElectrolyteConstants], so neither is a literal here.
class PhaseDescriptionCard extends StatelessWidget {
  const PhaseDescriptionCard({required this.phase, super.key});

  final AdaptationPhase phase;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(PhaseCopy.descriptions[phase]!, style: text.bodyMedium),
            const SizedBox(height: 16),
            Text('המלצות אלקטרוליטים ליום', style: text.labelLarge),
            const SizedBox(height: 8),
            for (final target in _targetsFor(phase))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _TargetRow(target: target),
              ),
          ],
        ),
      ),
    );
  }

  /// The phase's three ranges, drawn from [ElectrolyteConstants].
  ///
  /// A switch rather than a map, exhaustive over the enum, so adding a phase
  /// is a compile error here instead of a null assertion at runtime — the
  /// same reasoning `ElectrolyteAdvisor._targetsFor` gives.
  ///
  /// That advisor covers the same ground for the dashboard gauges, but it
  /// deliberately keeps only each range's *minimum*: a gauge needs the
  /// threshold below which the user is short, and the upper bound is a
  /// ceiling rather than a goal. This card is the one place that shows the
  /// range, so it reads the constants itself. Both read the same source, so
  /// the numbers cannot drift.
  static List<_ElectrolyteTarget> _targetsFor(AdaptationPhase phase) =>
      switch (phase) {
        AdaptationPhase.induction => const [
          _ElectrolyteTarget(
            'נתרן',
            ElectrolyteConstants.phase1SodiumMinMg,
            ElectrolyteConstants.phase1SodiumMaxMg,
          ),
          _ElectrolyteTarget(
            'אשלגן',
            ElectrolyteConstants.phase1PotassiumMinMg,
            ElectrolyteConstants.phase1PotassiumMaxMg,
          ),
          _ElectrolyteTarget(
            'מגנזיום',
            ElectrolyteConstants.phase1MagnesiumMinMg,
            ElectrolyteConstants.phase1MagnesiumMaxMg,
          ),
        ],
        // One set for both, because ElectrolyteConstants defines a single
        // `phase23` range: the design does not distinguish them here.
        AdaptationPhase.fatAdapted || AdaptationPhase.deepKetosis => const [
          _ElectrolyteTarget(
            'נתרן',
            ElectrolyteConstants.phase23SodiumMinMg,
            ElectrolyteConstants.phase23SodiumMaxMg,
          ),
          _ElectrolyteTarget(
            'אשלגן',
            ElectrolyteConstants.phase23PotassiumMinMg,
            ElectrolyteConstants.phase23PotassiumMaxMg,
          ),
          _ElectrolyteTarget(
            'מגנזיום',
            ElectrolyteConstants.phase23MagnesiumMinMg,
            ElectrolyteConstants.phase23MagnesiumMaxMg,
          ),
        ],
      };
}

/// One mineral's daily range.
@immutable
class _ElectrolyteTarget {
  const _ElectrolyteTarget(this.name, this.minMg, this.maxMg);

  final String name;
  final double minMg;
  final double maxMg;
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({required this.target});

  final _ElectrolyteTarget target;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme.bodySmall;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(target.name, style: text),
        // The range is a digit run, so it is given its own direction — inside
        // the RTL layout '3,000–5,000' would otherwise render reversed.
        Text(
          '${_mg(target.minMg)}–${_mg(target.maxMg)} מ״ג',
          style: text,
          textDirection: TextDirection.ltr,
        ),
      ],
    );
  }

  /// Whole milligrams with a thousands separator. The constants are `double`
  /// to match `DailyLog`'s fields; no target is a fraction of a milligram.
  static String _mg(double value) =>
      NumberFormat.decimalPattern().format(value.round());
}
