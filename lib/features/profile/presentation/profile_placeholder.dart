import 'package:flutter/material.dart';

/// Placeholder for the 5th MVP tab ("/profile", per #17/#19).
///
/// Not one of the 7 canonical features listed in `design/architecture.md`
/// / `CLAUDE.md` — added because #17's/#19's own 5-tab Definition of Done
/// (Home/Lens/Diary/Adaptation/Profile) has no home among those 7
/// otherwise. See the #22 PR description for the full reasoning.
class ProfilePlaceholder extends StatelessWidget {
  const ProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('פרופיל')));
}
