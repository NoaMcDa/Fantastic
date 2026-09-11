import 'package:fantastic/core/widgets/skeleton_box.dart';
import 'package:fantastic/features/adaptation/presentation/screens/phase_detail_screen.dart';
import 'package:fantastic/features/dashboard/presentation/widgets/electrolytes_card.dart';
import 'package:fantastic/features/dashboard/presentation/widgets/electrolytes_card_skeleton.dart';
import 'package:fantastic/features/diary/presentation/widgets/meal_list_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart' show newDatabaseFactoryMemory;

import '../helpers/app_harness.dart';

/// F11 — a broken store is diagnosable, not a spinner.
///
/// This is the failure mode that cost four milestones in four disguises:
/// riverpod 3 reports a provider that failed *before ever producing a value*
/// as `AsyncLoading` **with an error attached**, so any widget checking
/// `isLoading` before `hasError` shows its loading state forever
/// (`design/mvp_handoff.md`). Three shipped widgets were fixed for it and
/// two more still use the loading-first `.when` pattern.
///
/// Asserting on what *distinguishes* the states is the whole point: a test
/// that only checked "no meals are listed" passes in both.
void main() {
  testWidgets('a store that cannot be read says so instead of pretending', (
    tester,
  ) async {
    final db = await newDatabaseFactoryMemory().openDatabase('broken.db');
    final app = await bootApp(onboarded: true, database: db);

    // Every read from here on throws a real DatabaseException from inside
    // the repository — the same trick the contract suites use for
    // `breakStore`.
    await db.close();

    // **Not settled.** riverpod 3 retries a failed provider on an
    // exponential backoff, so a broken store keeps scheduling frames and the
    // tree never goes quiet: `pumpAndSettle` times out rather than
    // returning. Pumping a fixed number of frames is the honest way to look
    // at a screen that is, by construction, still retrying.
    await pumpApp(tester, app, settleAfter: false);

    // The macro card states the failure rather than showing an empty day —
    // "no meals logged" would be a lie the user acts on.
    //
    // Pumped until it appears rather than for a fixed number of frames: the
    // first read has to fail before anything can report it, and a frame
    // count races that.
    await pumpUntil(
      tester,
      find.text('לא ניתן לטעון את הנתונים'),
      reason: 'the dashboard never reported the storage failure',
    );
    expect(find.text('לא ניתן לטעון את הנתונים'), findsOneWidget);
    // And so does the symptom strip, in its narrower cell.
    expect(find.text('לא ניתן לטעון'), findsOneWidget);
    // Neither shows the empty state.
    expect(find.text('לא נרשמו ארוחות להיום'), findsNothing);

    // This expectation has flipped. It used to assert `findsOneWidget` as a
    // characterization of `design/m8_preflight.md` Part 10 defect 2 —
    // `MealListSection` was the last widget still using the loading-first
    // `.when` pattern, so on a storage failure it spun forever beside two
    // siblings that reported the error correctly. It now checks `hasError`
    // before `hasValue` like they do.
    await pumpUntil(
      tester,
      find.descendant(
        of: find.byType(MealListSection),
        matching: find.text('לא ניתן לטעון את הארוחות'),
      ),
      reason: 'the meal list never reported the storage failure',
    );
    expect(
      find.descendant(
        of: find.byType(MealListSection),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
      reason: 'MealListSection spun instead of reporting the failure',
    );
    // Extended rather than replaced (#88): riverpod 3 retries a failed
    // provider on a backoff, so a screen over a dead store would otherwise
    // skeleton forever — the same defect in a new coat.
    expect(
      find.descendant(
        of: find.byType(MealListSection),
        matching: find.byType(SkeletonBox),
      ),
      findsNothing,
      reason: 'MealListSection skeletoned instead of reporting the failure',
    );

    // The electrolytes card sits at the bottom of the dashboard, below the
    // fold. A `SliverList` builds its children lazily even from a
    // `SliverChildListDelegate`, so until the viewport reaches it the card
    // has **no element at all** (`design/m5_handoff.md`) — scrolling is what
    // makes the next three assertions about the card rather than about the
    // scroll offset. Dragged rather than `scrollUntilVisible`, which settles
    // internally and would time out against the retrying providers.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await pumpFrames(tester);

    // It reports the failure rather than vanishing. Before #302 all three of
    // its branches rendered `SizedBox.shrink()`, so a broken store and an
    // ordinary empty day were indistinguishable — and neither put anything
    // on screen.
    await waitFor(
      tester,
      () async => find.text('לא ניתן לטעון את המדדים').evaluate().isNotEmpty,
      reason: 'the electrolytes card never reported the storage failure',
    );
    expect(
      find.descendant(
        of: find.byType(ElectrolytesCard),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
      reason: 'ElectrolytesCard spun instead of reporting the failure',
    );
    expect(
      find.byType(ElectrolytesCardSkeleton),
      findsNothing,
      reason: 'ElectrolytesCard skeletoned instead of reporting the failure',
    );

    // The global error snackbar (#89). A unit test cannot make this
    // assertion: riverpod 3 retries a failed provider on an exponential
    // backoff, so over a dead store several providers fail repeatedly and a
    // naive one-snackbar-per-failure observer queues a backlog that outlives
    // the problem. **Exactly one, after the retries have had time to run.**
    await pumpUntil(
      tester,
      find.byKey(const Key('global_error_snackbar')),
      reason: 'no snackbar was raised for the failing providers',
    );
    await pumpFrames(tester, count: 60);
    expect(
      find.byType(SnackBar),
      findsOneWidget,
      reason: 'the retry backoff queued a snackbar per attempt',
    );

    // The add-meal button is still there over a dead store. It is the only
    // way to log a meal from this screen, so it must not be behind any
    // provider — least of all one that is retrying.
    expect(find.byKey(const Key('add_meal_fab')), findsOneWidget);

    // The adaptation tab degrades the same way rather than hanging.
    //
    // Everything here is scoped to `PhaseDetailScreen`. The shell keeps the
    // outgoing tab mounted while the new one comes in, so an unscoped
    // finder can match the dashboard that is still on its way out — and
    // with providers retrying, "whatever is on screen right now" is not a
    // stable thing to assert against.
    await tester.tap(find.byKey(const Key('tab_adaptation')));
    await pumpUntil(
      tester,
      find.descendant(
        of: find.byType(PhaseDetailScreen),
        matching: find.text('לא ניתן לטעון את הנתונים'),
      ),
      reason: 'the adaptation tab never reported the storage failure',
    );
    expect(
      find.descendant(
        of: find.byType(PhaseDetailScreen),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsNothing,
    );
    // Extended rather than replaced (#88): convention 9 is that the loading
    // indicator is absent, and a skeleton is now what that indicator is.
    expect(
      find.descendant(
        of: find.byType(PhaseDetailScreen),
        matching: find.byType(SkeletonBox),
      ),
      findsNothing,
      reason: 'PhaseDetailScreen skeletoned instead of reporting the failure',
    );
  });
}
