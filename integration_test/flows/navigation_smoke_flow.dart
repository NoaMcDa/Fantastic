import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

/// F10 (#100) — every tab opens, and every tab says what it is.
///
/// "No assertion needed — if it throws, the test fails" (#100) is only half
/// right: an exception inside a provider is caught by riverpod and painted
/// as an error state, so a screen can be thoroughly broken without anything
/// being thrown. Each tab therefore asserts its own marker.
void main() {
  testWidgets('all six tabs open and render their own screen', (tester) async {
    await pumpApp(tester, await bootApp(onboarded: true));

    // Home is where the app starts.
    expect(find.byKey(const Key('add_meal_fab')), findsOneWidget);

    await goToTab(tester, 'tab_lens');
    // Headless there is no camera, so the lens lands on its problem state.
    // On a device this is the viewfinder instead — assert that the screen
    // resolved to *one* of its three legitimate states rather than to
    // nothing, which is what a crashed screen looks like.
    expect(
      find.byKey(const Key('lens_camera_problem')).evaluate().length +
          find.byKey(const Key('lens_unavailable')).evaluate().length +
          find.byKey(const Key('capture_button')).evaluate().length,
      1,
    );

    await goToTab(tester, 'tab_diary');
    expect(find.widgetWithText(AppBar, 'יומן'), findsOneWidget);

    await goToTab(tester, 'tab_adaptation');
    expect(find.widgetWithText(AppBar, 'מסע ההסתגלות'), findsOneWidget);

    // #119's sixth tab. `goToTab` taps by `Key`, so a tab moving index is
    // invisible to it — without an explicit hop here this flow would stay
    // green while silently no longer covering a sixth of the tab bar
    // (`design/user_bugs_handoff.md`).
    await goToTab(tester, 'tab_recipe');
    expect(find.byKey(const Key('recipe_paste_field')), findsOneWidget);

    await goToTab(tester, 'tab_profile');
    expect(find.text('פרופיל'), findsWidgets);

    await goToTab(tester, 'tab_home');
    expect(find.byKey(const Key('add_meal_fab')), findsOneWidget);
  });
}
