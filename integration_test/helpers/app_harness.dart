import 'package:fantastic/core/database/database_provider.dart';
import 'package:fantastic/core/observers/global_error_observer.dart';
import 'package:fantastic/features/onboarding/application/providers/onboarding_gate.dart';
import 'package:fantastic/features/onboarding/data/providers.dart';
import 'package:fantastic/features/onboarding/domain/models/user_profile.dart';
import 'package:fantastic/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
// Shown, not imported wholesale: both packages export a `Finder`, and this
// file uses `flutter_test`'s (`CLAUDE.md` §Testing).
import 'package:sembast/sembast.dart' show Database;
import 'package:sembast/sembast_memory.dart' show newDatabaseFactoryMemory;

import '../../test/fixtures/fixtures.dart';

/// How long a single settle may take before the test fails.
///
/// Never call a bare `pumpAndSettle()`: its timeout defaults to ten minutes,
/// so one stuck provider costs ten minutes per call rather than failing
/// (`design/m4_handoff.md`).
///
/// **The timeout is `pumpAndSettle`'s third positional argument, not its
/// first.** The first is the interval between pumps, so the obvious
/// `pumpAndSettle(Duration(milliseconds: 100))` bounds nothing at all — it
/// just makes every frame wait 100 ms of real time under the live binding,
/// which is why the flows below run in seconds rather than minutes now that
/// [_frameInterval] is one frame instead.
const Duration settleTimeout = Duration(seconds: 20);

/// One frame at 60 Hz. See [settleTimeout].
const Duration _frameInterval = Duration(milliseconds: 16);

/// A running app, and the container behind it.
///
/// [database] is exposed so a flow can seed or inspect storage the way the
/// app itself would — through the repositories, never by reaching past them.
class AppUnderTest {
  const AppUnderTest({required this.container, required this.database});

  final ProviderContainer container;
  final Database database;
}

/// Boots the app the way `main()` does, minus the three plugin-bound steps.
///
/// `main()` opens a real database through `path_provider`, initialises the
/// notification plugin, and wraps both in the `try` that renders
/// [StartupFailureApp]. None of the three can run headless, and the first
/// would make these tests share one on-device database. Everything else —
/// the router, the provider graph, the repositories, the widgets — is the
/// real thing (`design/m8_preflight.md` §1.2).
///
/// [onboarded] writes a [UserProfile] before the gate is seeded. The
/// existence of that record *is* the first-launch flag, so a flow that is
/// not about onboarding skips it by being a returning user, exactly as a
/// real install does. Flipping `onboardingGateProvider` instead would not
/// navigate — the router reads the gate but has no `refreshListenable`
/// (§6.7).
///
/// [database] carries an already-open database across a relaunch; pass the
/// one from a previous [bootApp] to prove data survives (`F2`).
Future<AppUnderTest> bootApp({
  bool onboarded = false,
  Database? database,
  List<Override> overrides = const [],
}) async {
  // Hebrew month names for the dashboard header. `main` does this too.
  await initializeDateFormatting('he');

  // A fresh factory per call, so two flows in one run cannot see each
  // other's records even though they name the same database.
  final db =
      database ?? await newDatabaseFactoryMemory().openDatabase('e2e.db');

  if (onboarded) {
    final seed = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(seed.dispose);
    await seed
        .read(userProfileRepositoryProvider)
        .save(UserProfileFixture.profile());
  }

  final container = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(db), ...overrides],
    // `main` registers this on its container, and the harness has to as
    // well or the global error snackbar is the one thing `main` does that no
    // flow can reach (#89). It is not plugin-bound, so it is not one of the
    // three steps this harness leaves out. The key is the same top-level one
    // `FantasticApp` hands to `MaterialApp.router`.
    observers: [GlobalErrorObserver(scaffoldMessengerKey)],
  );
  addTearDown(container.dispose);
  await seedOnboardingGate(container);

  return AppUnderTest(container: container, database: db);
}

/// Pumps [app] and settles it.
///
/// Pass `settle: false` when the app under test cannot reach a steady state
/// — notably when storage is broken, because riverpod 3 retries a failed
/// provider on an exponential backoff, so frames keep being scheduled for as
/// long as the backoff runs and [settle] times out (see
/// `integration_test/flows/storage_failure_flow.dart`).
Future<void> pumpApp(
  WidgetTester tester,
  AppUnderTest app, {
  bool settleAfter = true,
}) async {
  // A tap that lands on nothing is a warning, not a failure, and the test
  // then fails somewhere unrelated several steps later. Make it fatal where
  // it happens (`design/m8_preflight.md` §6.2).
  WidgetController.hitTestWarningShouldBeFatal = true;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: app.container,
      child: const FantasticApp(),
    ),
  );
  if (settleAfter) {
    await settle(tester);
  } else {
    await pumpFrames(tester);
  }
}

/// Relaunches the app against the same storage.
///
/// A second `pumpWidget` of the same widget type updates the tree rather
/// than replacing it, and trips a framework assertion when the container
/// changes — so pump an empty frame in between. A relaunch has to be a
/// relaunch (`design/m4_handoff.md`).
Future<AppUnderTest> relaunchApp(WidgetTester tester, AppUnderTest app) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await settle(tester);
  final relaunched = await bootApp(database: app.database);
  await pumpApp(tester, relaunched);
  return relaunched;
}

/// Settles, pumping a frame at a time, bounded by [settleTimeout].
Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
  _frameInterval,
  EnginePhase.sendSemanticsUpdate,
  settleTimeout,
);

/// Pumps [count] frames without waiting for the tree to go quiet.
///
/// The escape hatch from [settle] for a screen that never settles.
Future<void> pumpFrames(WidgetTester tester, {int count = 10}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(_frameInterval);
  }
}

/// Pumps until [finder] matches at least [atLeast] widgets, or fails.
///
/// For a screen that never goes quiet, where [settle] cannot be used: a
/// fixed number of frames races whatever the screen is waiting for, and the
/// assertion after it passes or fails on timing rather than on behaviour.
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int atLeast = 1,
  Duration timeout = const Duration(seconds: 10),
  String? reason,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (finder.evaluate().length >= atLeast) {
      return;
    }
    await tester.pump(_frameInterval);
  }
  fail(reason ?? 'no match for $finder within $timeout');
}

/// Pumps until [condition] holds, or fails the test after [timeout].
///
/// For assertions about *storage* after a UI action. The two are not the
/// same instant: `MealListSection` removes a dismissed row optimistically
/// and deletes in the background (`design/m2_handoff.md`), so reading the
/// repository on the next frame can still see the meal. Pumping alone does
/// not help — the work is real async under the live binding, not a pending
/// frame — which is why this polls.
Future<void> waitFor(
  WidgetTester tester,
  Future<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 5),
  String? reason,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (await condition()) {
      return;
    }
    await tester.pump(_frameInterval);
  }
  fail(reason ?? 'condition did not hold within $timeout');
}

/// Taps [finder], scrolling it into view first.
///
/// A widget can be found and still not be tappable: below the fold of a
/// modal sheet, the hit test lands on whatever is painted over it.
Future<void> tapAt(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await settle(tester);
  await tester.tap(finder);
  await settle(tester);
}

/// Enters [text] into the field keyed [key].
Future<void> enterInto(WidgetTester tester, String key, String text) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, text);
  await settle(tester);
}

/// The current text of the text field keyed [key].
///
/// For asserting on a prefilled form: the value lives in the field's
/// controller, not in a `Text` widget, so `find.text` does not see it.
///
/// Read off the `EditableText` underneath rather than off the field widget,
/// because the app uses both `TextFormField` (inside a `Form`) and plain
/// `TextField` (the scan sheet's amount), and a cast to either one throws on
/// the other.
String fieldText(WidgetTester tester, String key) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(EditableText),
      ),
    )
    .controller
    .text;

/// Switches to the tab keyed [tabKey] (`tab_home`, `tab_lens`, …).
///
/// By key, never by label: `'יומן'` is both the diary tab's label and
/// `DiaryScreen`'s app-bar title, and `find.text` would match both.
Future<void> goToTab(WidgetTester tester, String tabKey) async {
  await tester.tap(find.byKey(Key(tabKey)));
  await settle(tester);
}

/// Scrolls the dashboard (or any `CustomScrollView`) down by [pixels].
///
/// Necessary, not cosmetic: a sliver child below the fold has no element at
/// all, so `find.text` on a meal row returns zero rather than "off-screen"
/// (`design/m5_handoff.md`).
Future<void> scrollDown(WidgetTester tester, {double pixels = 400}) async {
  await tester.drag(find.byType(CustomScrollView).first, Offset(0, -pixels));
  await settle(tester);
}
