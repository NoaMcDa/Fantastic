import 'package:fantastic/core/constants/phase_copy.dart';
import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/adaptation/application/providers/streak_providers.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The current phase as a tappable chip, opening the phase detail screen.
///
/// Sits under the streak ring on the dashboard: the ring answers "how am I
/// doing today", this answers "where am I in the journey".
class PhaseBadgeWidget extends ConsumerWidget {
  const PhaseBadgeWidget({super.key});

  /// Where tapping the badge goes.
  ///
  /// Redirects onto the `/adaptation` tab — see `app_router.dart` for why the
  /// detail screen is the tab rather than a second copy pushed over it.
  static const String route = '/adaptation/phase';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phaseAsync = ref.watch(currentPhaseProvider);

    // Failure before loading: riverpod 3 reports a provider that failed
    // before producing a value as AsyncLoading *with* an error, so checking
    // isLoading first leaves the placeholder chip up forever.
    if (phaseAsync.hasError) {
      return const SizedBox.shrink();
    }
    final phase = phaseAsync.value;
    if (phase == null) {
      // A chip-shaped placeholder rather than a spinner or nothing: the
      // badge is one line in a column, and collapsing it would jump the
      // dashboard when the phase lands.
      return const Chip(label: Text('...'));
    }

    return ActionChip(
      key: const Key('phase_badge'),
      label: Text(
        PhaseCopy.names[phase]!,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: colourFor(phase),
      // The chip's own colour is the signal; a border would compete with it.
      side: BorderSide.none,
      onPressed: () => context.push(route),
    );
  }

  /// The phase's colour.
  ///
  /// Drawn from [AppTheme] rather than the raw hex the issue lists, so the
  /// badge tracks the palette every other widget uses. The progression reads
  /// as one: the caution amber of induction, through the app's own accent,
  /// to the success green of deep ketosis.
  @visibleForTesting
  static Color colourFor(AdaptationPhase phase) => switch (phase) {
    AdaptationPhase.induction => AppTheme.caution,
    AdaptationPhase.fatAdapted => AppTheme.accent,
    AdaptationPhase.deepKetosis => AppTheme.success,
  };
}
