import 'package:fantastic/core/constants/electrolyte_constants.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/dashboard/application/electrolyte_advice.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'electrolyte_advisor.g.dart';

/// Turns a day's logged electrolytes into phase-appropriate targets and deficit
/// flags.
///
/// Stateless and pure — no I/O, no Flutter. Phase 1 carries the highest sodium
/// target because glycogen depletion drives rapid sodium excretion; later
/// phases retain electrolytes more efficiently and their targets drop.
///
/// Every threshold comes from [ElectrolyteConstants] rather than a table
/// defined here, so the numbers the dashboard shows and the numbers the design
/// documents specify cannot drift apart.
class ElectrolyteAdvisor {
  const ElectrolyteAdvisor();

  /// Targets for [phase], and whether [log] falls short of each.
  ///
  /// A deficit is *strictly* below target: logging exactly the target is met,
  /// not short. Logging nothing always registers as a deficit, since every
  /// target is above zero.
  ElectrolyteAdvice advise(AdaptationPhase phase, DailyLog log) {
    final targets = _targetsFor(phase);
    return ElectrolyteAdvice(
      sodiumTargetMg: targets.sodiumMg,
      potassiumTargetMg: targets.potassiumMg,
      magnesiumTargetMg: targets.magnesiumMg,
      sodiumDeficit: log.sodiumMg < targets.sodiumMg,
      potassiumDeficit: log.potassiumMg < targets.potassiumMg,
      magnesiumDeficit: log.magnesiumMg < targets.magnesiumMg,
    );
  }

  /// A switch rather than a map lookup: it is exhaustive over the enum, so
  /// adding a phase becomes a compile error here instead of a null assertion
  /// failing at runtime.
  ///
  /// `fatAdapted` and `deepKetosis` share one target set because
  /// [ElectrolyteConstants] defines a single `phase23` range for both — the
  /// design does not distinguish them on electrolytes.
  _ElectrolyteTargets _targetsFor(AdaptationPhase phase) => switch (phase) {
    AdaptationPhase.induction => const _ElectrolyteTargets(
      sodiumMg: ElectrolyteConstants.phase1SodiumMinMg,
      potassiumMg: ElectrolyteConstants.phase1PotassiumMinMg,
      magnesiumMg: ElectrolyteConstants.phase1MagnesiumMinMg,
    ),
    AdaptationPhase.fatAdapted ||
    AdaptationPhase.deepKetosis => const _ElectrolyteTargets(
      sodiumMg: ElectrolyteConstants.phase23SodiumMinMg,
      potassiumMg: ElectrolyteConstants.phase23PotassiumMinMg,
      magnesiumMg: ElectrolyteConstants.phase23MagnesiumMinMg,
    ),
  };
}

/// One phase's three minimums, grouped so [ElectrolyteAdvisor._targetsFor] can
/// return them together.
@immutable
class _ElectrolyteTargets {
  const _ElectrolyteTargets({
    required this.sodiumMg,
    required this.potassiumMg,
    required this.magnesiumMg,
  });

  final double sodiumMg;
  final double potassiumMg;
  final double magnesiumMg;
}

/// The advisor as a `const` singleton — it holds no state.
@riverpod
ElectrolyteAdvisor electrolyteAdvisor(Ref ref) => const ElectrolyteAdvisor();
