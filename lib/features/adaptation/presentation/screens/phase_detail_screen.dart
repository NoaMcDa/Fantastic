import 'package:fantastic/core/constants/phase_copy.dart';
import 'package:fantastic/features/adaptation/application/providers/streak_providers.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/adaptation/presentation/widgets/grace_period_banner.dart';
import 'package:fantastic/features/adaptation/presentation/widgets/phase_description_card.dart';
import 'package:fantastic/features/adaptation/presentation/widgets/streak_calendar_widget.dart';
import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/adaptation/presentation/widgets/phase_detail_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// The adaptation tab: where the user is in the three-phase journey, what the
/// current phase asks of them, and the month behind them.
///
/// Replaces the `/adaptation` placeholder. Reached from the tab bar, and from
/// the dashboard's phase badge via `/adaptation/phase`.
class PhaseDetailScreen extends ConsumerStatefulWidget {
  const PhaseDetailScreen({super.key});

  @override
  ConsumerState<PhaseDetailScreen> createState() => _PhaseDetailScreenState();
}

class _PhaseDetailScreenState extends ConsumerState<PhaseDetailScreen> {
  /// This month, resolved once.
  ///
  /// Held in state and stripped to the first of the month rather than read in
  /// `build`: `monthlyDailyLogsProvider` is a family keyed on it, and a fresh
  /// wall-clock value each build would allocate a new provider every frame.
  /// The same trap `DashboardScreen` documents for its date.
  late final DateTime _month = _thisMonth();

  static DateTime _thisMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final phaseAsync = ref.watch(currentPhaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('מסע ההסתגלות')),
      // Error is checked *before* loading, and on `hasError` rather than by
      // matching `AsyncError`. riverpod 3 reports a provider that failed
      // before ever producing a value as `AsyncLoading` with an error
      // attached — `isLoading` and `hasError` are both true — so either an
      // `AsyncLoading()` pattern or an `isLoading`-first branch shows a
      // spinner that never stops.
      body: switch (phaseAsync) {
        // Unlike the streak ring, this screen has nothing else on it: saying
        // nothing would leave the user staring at a blank page.
        final phase when phase.hasError => const Center(
          child: Text('לא ניתן לטעון את הנתונים'),
        ),
        final phase when phase.isLoading && !phase.hasValue =>
          const PhaseDetailSkeleton(),
        _ => _Body(phase: phaseAsync.requireValue, month: _month),
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.phase, required this.month});

  final AdaptationPhase phase;
  final DateTime month;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.only(bottom: 24),
    children: [
      // Placed first and unconditionally: it is zero-height when there is no
      // grace period, and it is the most urgent thing on the screen when
      // there is.
      const GracePeriodBanner(),
      const SizedBox(height: 8),
      for (final step in AdaptationPhase.values)
        _PhaseStepTile(
          phase: step,
          state: _PhaseStepState.of(step, phase),
          isLast: step == AdaptationPhase.values.last,
        ),
      const Divider(height: 32),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _monthTitle(month),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            StreakCalendarWidget(month: month),
          ],
        ),
      ),
    ],
  );

  /// `ספטמבר 2026`, falling back to the locale-independent format if Hebrew
  /// date symbols were never initialised — the same guard
  /// `DashboardScreen` uses, for the same reason: a month heading is not
  /// worth crashing a screen over.
  static String _monthTitle(DateTime month) {
    try {
      return DateFormat('MMMM yyyy', 'he').format(month);
    } on Object catch (_) {
      return DateFormat('MMMM yyyy').format(month);
    }
  }
}

/// Where a step sits relative to the phase the user is in.
enum _PhaseStepState {
  completed,
  active,
  locked;

  /// [step]'s state for a user currently in [current].
  ///
  /// Compares declaration order, which `AdaptationPhase` documents as the
  /// progression order. Derived from the current phase rather than from the
  /// streak count: the two would otherwise be two answers to one question,
  /// and only `AdaptationPhaseService` should be answering it.
  static _PhaseStepState of(AdaptationPhase step, AdaptationPhase current) {
    if (step.index < current.index) {
      return _PhaseStepState.completed;
    }
    return step == current ? _PhaseStepState.active : _PhaseStepState.locked;
  }
}

class _PhaseStepTile extends StatelessWidget {
  const _PhaseStepTile({
    required this.phase,
    required this.state,
    required this.isLast,
  });

  final AdaptationPhase phase;
  final _PhaseStepState state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final active = state == _PhaseStepState.active;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepMarker(state: state, drawConnector: !isLast),
              const SizedBox(width: 12),
              Expanded(
                child: Opacity(
                  // A locked phase is shown, not hidden: seeing what is ahead
                  // is the point of a roadmap. Dimmed so it reads as future.
                  opacity: state == _PhaseStepState.locked ? 0.45 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        PhaseCopy.names[phase]!,
                        style: active
                            ? text.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              )
                            : text.titleMedium,
                      ),
                      Text(PhaseCopy.dayRanges[phase]!, style: text.labelSmall),
                      const SizedBox(height: 2),
                      Text(PhaseCopy.summaries[phase]!, style: text.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Only the active phase expands. Three descriptions at once would
          // bury the one that applies.
          if (active)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: PhaseDescriptionCard(phase: phase),
            ),
          if (!isLast) const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// The circle, and the line running down to the next step.
class _StepMarker extends StatelessWidget {
  const _StepMarker({required this.state, required this.drawConnector});

  final _PhaseStepState state;
  final bool drawConnector;

  static const double _size = 28;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, colour) = switch (state) {
      _PhaseStepState.completed => (Icons.check, AppTheme.success),
      _PhaseStepState.active => (Icons.play_arrow, AppTheme.accent),
      _PhaseStepState.locked => (Icons.lock, scheme.surfaceContainerHighest),
    };

    return Column(
      children: [
        Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
          child: Icon(
            icon,
            size: 16,
            color: state == _PhaseStepState.locked
                ? scheme.onSurfaceVariant
                : Colors.white,
          ),
        ),
        if (drawConnector)
          Container(
            width: 2,
            height: 24,
            color: scheme.surfaceContainerHighest,
          ),
      ],
    );
  }
}
