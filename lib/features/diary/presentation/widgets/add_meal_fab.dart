import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_bottom_sheet.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_description_sheet.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_mode_sheet.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_photo_sheet.dart';
import 'package:flutter/material.dart';

/// The app's add-a-meal affordance: a `+` that asks *how*, then opens the
/// matching sheet.
///
/// One widget rather than a `FloatingActionButton` written out at each call
/// site, because there is more than one screen a meal can be logged from and
/// they must not drift apart. The dashboard shipped with its own inline FAB in
/// M2 and the diary — the tab a user opens to work on a *day* — was left
/// without one, while both screens' empty state told the reader to
/// "הקש על + כדי להוסיף ארוחה". On the diary that instruction pointed at a
/// button that did not exist.
///
/// **The mode chooser lives here, not in either host screen**, for the same
/// reason: a mode offered on the dashboard and missing from the diary would
/// be that defect again, one layer up. Both hosts get all three by
/// construction.
///
/// It owns no state and reads no provider: it is a button that shows a sheet,
/// and the sheet owns the form, the service call and the refresh. Nothing
/// here touches the database.
class AddMealFab extends StatelessWidget {
  const AddMealFab({required this.date, super.key});

  /// The day the meal is logged against — today from the dashboard, the
  /// selected day from the diary. Pass a date-only value: the sheet hands it
  /// to providers that are families keyed on it.
  final DateTime date;

  /// Bottom padding a scrolling body needs so its last row is not covered.
  ///
  /// A `FloatingActionButton` floats over the body rather than displacing it,
  /// so every screen that hosts one has to clear it by hand. Named here, next
  /// to the button whose height it is derived from, so the two cannot drift.
  static const double bodyClearance = 80;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      // Named in Hebrew like every other user-visible string, and a tooltip
      // rather than a label: the icon is the affordance, this is what a
      // screen reader announces.
      tooltip: 'הוספת ארוחה',
      // Stated rather than inherited. It renders gold today only because
      // `ColorScheme.dark`'s `primaryContainer` getter falls back to
      // `primary`, which `AppTheme` happens to set to the accent — the M3 FAB
      // default reads `primaryContainer`. Naming both roles means the one
      // control the whole tracker depends on cannot lose its contrast to an
      // unrelated change in the colour scheme.
      backgroundColor: AppTheme.accent,
      foregroundColor: AppTheme.primary,
      onPressed: () => _choose(context),
      child: const Icon(Icons.add),
    );
  }

  /// Asks which mode, then opens it.
  ///
  /// The next sheet is shown from the **navigator's own context**, which
  /// outlives the chooser route that has just been popped —
  /// `ScanResultSheet._addToDiary` takes the same route out of the same
  /// problem.
  ///
  /// It is read *after* the `await`, not before, and that ordering is the
  /// whole point. A `BuildContext` captured before an asynchronous gap and
  /// used after it is `use_build_context_synchronously`, and the warning is
  /// not pedantry here: this widget is stateless, so there is no `mounted`
  /// to guard with. Holding the `NavigatorState` instead gives something
  /// that *does* answer `mounted`, and asking it for a context afterwards is
  /// a fresh read of a live element rather than a stale capture.
  Future<void> _choose(BuildContext context) async {
    final navigator = Navigator.of(context);
    final mode = await AddMealModeSheet.show(context);
    if (mode == null || !navigator.mounted) {
      return;
    }
    final host = navigator.context;
    // The analyzer wants the guard on the context that is actually used, not
    // on the state it came from, and it is right to: a mounted navigator can
    // still hand back an element that has since been unmounted.
    if (!host.mounted) {
      return;
    }
    // No `default`: a fourth mode must fail to compile here rather than
    // silently doing nothing when tapped.
    switch (mode) {
      case AddMealMode.manual:
        await AddMealBottomSheet.show(host, date: date);
      case AddMealMode.description:
        await AddMealDescriptionSheet.show(host, date: date);
      case AddMealMode.photo:
        await AddMealPhotoSheet.show(host, date: date);
    }
  }
}
