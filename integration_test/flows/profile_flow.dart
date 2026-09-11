import 'package:fantastic/core/constants/profile_copy.dart';
import 'package:fantastic/core/utils/numeric_input.dart';
import 'package:fantastic/features/onboarding/data/providers.dart';
import 'package:fantastic/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

/// F12 (#310) — the Profile tab shows what onboarding computed.
///
/// The tab rendered a single Hebrew word until this issue, and the targets a
/// user agrees to in their first thirty seconds were visible nowhere
/// afterwards (`design/m4_handoff.md`).
void main() {
  testWidgets('the profile tab shows the targets onboarding saved', (
    tester,
  ) async {
    // `onboarded: true` writes a real `UserProfile` through the repository,
    // exactly as the flow itself does — so what this asserts is the stored
    // record travelling back out through the real provider graph, not a
    // fixture handed to a widget.
    final app = await bootApp(onboarded: true);
    await pumpApp(tester, app);

    final saved = await app.container
        .read(userProfileRepositoryProvider)
        .load();

    await goToTab(tester, 'tab_profile');

    // The placeholder was a bare `Text('פרופיל')` with no `Scaffold` of its
    // own; the tab label carries the same word, so the screen type is what
    // distinguishes "the profile screen is up" from "a tab is selected".
    expect(find.byType(ProfileScreen), findsOneWidget);

    expect(
      find.descendant(
        of: find.byKey(const Key('profile_target_fat')),
        matching: find.text(GramsText.format(saved!.targets.fatG)),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('profile_target_net_carbs')),
        matching: find.text(GramsText.format(saved.targets.netCarbsG)),
      ),
      findsOneWidget,
    );

    // The read-only boundary is on screen, not only in a doc comment. It
    // sits below the fold, and a `ListView` child below the fold has no
    // element at all (`design/m5_handoff.md`) — so it has to be scrolled to
    // rather than merely looked for.
    await tester.scrollUntilVisible(
      find.text(ProfileCopy.readOnlyNote),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await settle(tester);
    expect(find.text(ProfileCopy.readOnlyNote), findsOneWidget);

    // Neither failure state, on a store that works.
    expect(find.byKey(const Key('profile_load_failed')), findsNothing);
    expect(find.byKey(const Key('profile_not_onboarded')), findsNothing);
  });
}
