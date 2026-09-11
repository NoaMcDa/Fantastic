import 'package:fantastic/features/adaptation/application/providers/streak_providers.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/adaptation/presentation/widgets/phase_badge_widget.dart';
import 'package:fantastic/features/adaptation/presentation/widgets/streak_ring_widget.dart';
import 'package:fantastic/features/dashboard/presentation/widgets/electrolytes_card.dart';
import 'package:fantastic/features/dashboard/presentation/widgets/macro_summary_card.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_bottom_sheet.dart';
import 'package:fantastic/features/diary/presentation/widgets/meal_list_section.dart';
import 'package:fantastic/features/diary/presentation/widgets/symptom_check_in_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// The app's home screen: today's macros, meals and electrolytes.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  /// Today, resolved once.
  ///
  /// Held in state and stripped to midnight rather than calling
  /// `DateTime.now()` in `build`. The date-keyed providers are families keyed
  /// on this value, so a fresh wall-clock time each build would allocate a new
  /// provider every frame and refetch forever.
  late final DateTime _date = _today();

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            centerTitle: false,
            title: Text(
              _formatHebrewDate(_date),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                MacroSummaryCard(date: _date),
                const SizedBox(height: 16),
                Center(child: StreakRingWidget(date: _date)),
                const SizedBox(height: 8),
                const Center(child: PhaseBadgeWidget()),
                const SizedBox(height: 16),
                MealListSection(date: _date),
                const SizedBox(height: 16),
                SymptomCheckInStrip(date: _date),
                const SizedBox(height: 16),
                // The phase the targets are drawn from, at last: M2 shipped
                // this card with a parameter defaulting to induction and a
                // comment saying M3 would pass the real value here.
                ElectrolytesCard(
                  date: _date,
                  phase:
                      ref.watch(currentPhaseProvider).value ??
                      AdaptationPhase.induction,
                ),
                // Clears the FAB, which would otherwise cover the last row.
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('add_meal_fab'),
        tooltip: 'הוספת ארוחה',
        onPressed: () => AddMealBottomSheet.show(context, date: _date),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// `יום רביעי, 9 בספטמבר 2026`.
///
/// Falls back to the locale-independent format if Hebrew date symbols were
/// never initialised. `DateFormat` with an explicit locale throws when its
/// symbol data is missing, and a date header is not worth crashing the home
/// screen over — a test that pumps this widget without
/// `initializeDateFormatting` would otherwise fail on the formatting rather
/// than on whatever it meant to assert.
String _formatHebrewDate(DateTime date) {
  try {
    return DateFormat('EEEE, d MMMM yyyy', 'he').format(date);
  } on Object catch (_) {
    return DateFormat('EEEE, d MMMM yyyy').format(date);
  }
}
