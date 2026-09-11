import 'package:fantastic/core/constants/add_meal_copy.dart';
import 'package:flutter/material.dart';

/// How the user wants to add this meal.
///
/// Exhaustive by construction: every `switch` over it is written with no
/// `default`, so adding a fourth way in fails to compile at each site that
/// has to handle it rather than silently doing nothing at one of them — the
/// property the sealed `ScanResult` switch in `ScanResultSheet` relies on.
enum AddMealMode {
  /// Type the macros. The path that has shipped since M2.
  manual,

  /// Describe the meal in words and let the estimator do the arithmetic.
  description,

  /// Photograph the plate or the label.
  photo,
}

/// The chooser: three ways into the same editable form.
///
/// **Owned by `AddMealFab` rather than by either host screen.** The dashboard
/// and the diary both host that button, and `design/user_bugs_handoff.md`
/// records what it cost when one of them had an affordance the other did not:
/// the diary's empty state told the reader to "הקש על + כדי להוסיף ארוחה"
/// while the diary had no `+` at all. Putting the chooser behind the shared
/// button means both hosts get all three modes by construction, and neither
/// can drift from the other.
///
/// Three list tiles rather than a segmented control: they are reachable
/// one-handed, each carries a subtitle saying what the mode actually does,
/// and they clear the touch-target minimum without custom sizing.
///
/// Owns no state and reads no provider — it takes a callback and returns a
/// value, exactly as `AddMealFab` does.
class AddMealModeSheet extends StatelessWidget {
  const AddMealModeSheet({required this.onSelected, super.key});

  /// Called with the chosen mode. Dismissing calls nothing.
  final ValueChanged<AddMealMode> onSelected;

  /// Minimum height of one mode tile.
  ///
  /// Comfortably over Apple's 44 pt floor even at the smallest text scale,
  /// where a two-line `ListTile` would otherwise shrink toward its content.
  static const double tileMinHeight = 56;

  /// Opens the chooser and resolves to the chosen mode, or null if the user
  /// dismissed it.
  static Future<AddMealMode?> show(BuildContext context) =>
      showModalBottomSheet<AddMealMode>(
        context: context,
        // Without this the sheet is capped at half the screen — the omission
        // #84 made, which `ScanResultSheet` documents.
        isScrollControlled: true,
        builder: (context) => AddMealModeSheet(
          onSelected: (mode) => Navigator.pop(context, mode),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                AddMealCopy.chooserTitle,
                key: const Key('add_meal_mode_title'),
                style: theme.textTheme.titleMedium,
              ),
            ),
            _tile(
              context,
              keyName: 'add_meal_mode_manual',
              icon: Icons.edit_outlined,
              title: AddMealCopy.manualTitle,
              subtitle: AddMealCopy.manualSubtitle,
              mode: AddMealMode.manual,
            ),
            _tile(
              context,
              keyName: 'add_meal_mode_description',
              icon: Icons.short_text,
              title: AddMealCopy.descriptionTitle,
              subtitle: AddMealCopy.descriptionSubtitle,
              mode: AddMealMode.description,
            ),
            _tile(
              context,
              keyName: 'add_meal_mode_photo',
              icon: Icons.photo_camera_outlined,
              title: AddMealCopy.photoTitle,
              subtitle: AddMealCopy.photoSubtitle,
              mode: AddMealMode.photo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required String keyName,
    required IconData icon,
    required String title,
    required String subtitle,
    required AddMealMode mode,
  }) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: tileMinHeight),
    child: ListTile(
      key: Key(keyName),
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () => onSelected(mode),
    ),
  );
}
