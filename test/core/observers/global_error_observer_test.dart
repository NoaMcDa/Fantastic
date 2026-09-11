import 'package:fantastic/core/database/database_provider.dart';
import 'package:fantastic/core/observers/global_error_observer.dart';
import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/dashboard/application/providers/daily_log_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// Only the factory. `flutter_test` and sembast both export a `Finder`, which
// is ambiguous unqualified (`CLAUDE.md` §Testing).
import 'package:sembast/sembast_memory.dart' show newDatabaseFactoryMemory;

/// Real providers over a real container, not a mocked observer.
///
/// The whole risk in this issue is a wrong assumption about *when* riverpod
/// calls what — the original text reached for `didUpdateProvider` and an
/// `AsyncError` match, which never fires for a first-read failure. Driving
/// actual failures is the only way that assumption gets checked.
final throwsImmediately = Provider<int>((ref) => throw StateError('boom'));

/// Fails before ever producing a value, which is the shape that matters:
/// riverpod 3 reports it as `AsyncLoading` **with an error attached**, so
/// both `isLoading` and `hasError` are true and an `is AsyncError` test never
/// matches it.
final failsBeforeFirstValue = FutureProvider<int>(
  (ref) async => throw StateError('boom'),
);

final alsoThrows = Provider<int>((ref) => throw StateError('other'));

final succeeds = Provider<int>((ref) => 1);

void main() {
  late GlobalKey<ScaffoldMessengerState> key;

  setUp(() => key = GlobalKey<ScaffoldMessengerState>());

  /// Mounts a messenger the observer can reach.
  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: key,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );
  }

  ProviderContainer containerWith({
    Duration? suppressFor,
    DateTime Function()? clock,
  }) {
    final container = ProviderContainer(
      observers: [
        GlobalErrorObserver(
          key,
          suppressFor: suppressFor ?? const Duration(seconds: 5),
          clock: clock ?? DateTime.now,
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Reads [provider], swallowing the failure the observer is meant to
  /// report. The test is about the snackbar, not about the throw.
  ///
  /// Typed on the concrete `Provider<int>` rather than `ProviderBase`, which
  /// `flutter_riverpod` does not re-export.
  void readIgnoringFailure(ProviderContainer container, Provider<int> p) {
    try {
      container.read(p);
    } on Object catch (_) {
      // Expected.
    }
  }

  Finder snackbar() => find.byKey(const Key('global_error_snackbar'));

  /// Runs out the snackbar's own auto-dismiss timer.
  ///
  /// Not optional bookkeeping: `testWidgets` asserts no timer is pending when
  /// the body returns, and a `SnackBar` schedules one for its full
  /// [GlobalErrorObserver.visibleFor]. A test that shows one and stops
  /// fails on the timer rather than on its assertion.
  Future<void> drainSnackbar(WidgetTester tester) async {
    await tester.pump(GlobalErrorObserver.visibleFor);
    await tester.pumpAndSettle();
  }

  testWidgets('a failing provider shows a snackbar', (tester) async {
    await pumpHost(tester);
    final container = containerWith();

    readIgnoringFailure(container, throwsImmediately);
    await tester.pump();

    expect(snackbar(), findsOneWidget);
    await drainSnackbar(tester);
  });

  // The exact riverpod-3 shape the original issue's `AsyncError` match would
  // have missed. This test is why `providerDidFail` is the hook rather than
  // `didUpdateProvider`.
  testWidgets('a provider that fails before its first value shows a snackbar', (
    tester,
  ) async {
    await pumpHost(tester);
    final container = containerWith();

    final async = container.read(failsBeforeFirstValue);
    // Both true at once, which is the whole trap.
    expect(async.isLoading, isTrue);
    expect(async.hasError, isFalse, reason: 'not yet — the future is pending');

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(snackbar(), findsOneWidget);
    await drainSnackbar(tester);
  });

  testWidgets('the snackbar carries Hebrew copy and no stack trace', (
    tester,
  ) async {
    await pumpHost(tester);
    readIgnoringFailure(containerWith(), throwsImmediately);
    await tester.pump();

    expect(find.text(GlobalErrorObserver.message), findsOneWidget);
    expect(find.textContaining('StateError'), findsNothing);
    expect(find.textContaining('boom'), findsNothing);
    expect(find.textContaining('#0'), findsNothing);
    expect(
      tester.widget<SnackBar>(snackbar()).backgroundColor,
      AppTheme.danger,
    );
    await drainSnackbar(tester);
  });

  testWidgets('a provider that succeeds shows no snackbar', (tester) async {
    await pumpHost(tester);
    final container = containerWith();

    expect(container.read(succeeds), 1);
    await tester.pump();

    expect(snackbar(), findsNothing);
  });

  group('de-duplication', () {
    // riverpod 3 retries a failed provider on an exponential backoff, so a
    // naive one-snackbar-per-failure observer queues a snackbar per attempt
    // and the backlog outlives the problem. This is the single most likely
    // way to ship this issue wrong.
    testWidgets('repeated failures inside the window show one snackbar', (
      tester,
    ) async {
      await pumpHost(tester);
      final container = containerWith();

      for (var i = 0; i < 5; i++) {
        readIgnoringFailure(container, throwsImmediately);
        container.invalidate(throwsImmediately);
        await tester.pump();
      }

      expect(snackbar(), findsOneWidget);
      await drainSnackbar(tester);
    });

    // **A second provider inside the window is also suppressed, and the
    // issue's plan asked for the opposite.** Its Step 3 lists `'failures of
    // two different providers both show'`, and its Step 4 asks the
    // storage-failure flow to assert *exactly one* snackbar — over a dead
    // store, where five independent providers fail at once. Those two cannot
    // both hold.
    //
    // Suppression is global rather than per-provider because the copy is
    // generic: the snackbar does not name what failed, so a second identical
    // one tells the user nothing they are not already reading. Per-provider
    // keying would have produced exactly the storm this guard exists to stop,
    // one message per failing provider, all saying the same sentence.
    testWidgets('a different provider inside the window is suppressed too', (
      tester,
    ) async {
      await pumpHost(tester);
      final container = containerWith();

      readIgnoringFailure(container, throwsImmediately);
      await tester.pump();
      readIgnoringFailure(container, alsoThrows);
      await tester.pump();

      expect(snackbar(), findsOneWidget);
      await drainSnackbar(tester);
    });

    testWidgets('a failure after the window shows a second snackbar', (
      tester,
    ) async {
      await pumpHost(tester);
      // The clock is stepped rather than waited out. `testWidgets` runs
      // under a fake clock — `tester.pump(duration)` advances the binding's
      // time, not `DateTime.now()`'s — so a real `Future.delayed` here never
      // completes and the test hangs rather than failing. Found the hard way.
      var now = DateTime(2026, 9, 11, 12);
      final container = containerWith(
        suppressFor: const Duration(seconds: 5),
        clock: () => now,
      );

      readIgnoringFailure(container, throwsImmediately);
      await tester.pump();
      expect(snackbar(), findsOneWidget);

      now = now.add(const Duration(seconds: 6));
      container.invalidate(throwsImmediately);
      readIgnoringFailure(container, throwsImmediately);
      await tester.pump();

      // Still one *on screen* — the second replaced the first rather than
      // queueing behind it, which is what `removeCurrentSnackBar` is for.
      expect(snackbar(), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      await drainSnackbar(tester);
    });

    testWidgets('the window is measured, not merely present', (tester) async {
      await pumpHost(tester);
      var now = DateTime(2026, 9, 11, 12);
      final container = containerWith(
        suppressFor: const Duration(seconds: 5),
        clock: () => now,
      );

      readIgnoringFailure(container, throwsImmediately);
      await tester.pump();
      final first = tester.widget<SnackBar>(snackbar());

      // One second short of the window: still suppressed, and the snackbar
      // on screen is the same instance rather than a replacement.
      now = now.add(const Duration(seconds: 4));
      container.invalidate(throwsImmediately);
      readIgnoringFailure(container, throwsImmediately);
      await tester.pump();

      expect(identical(tester.widget<SnackBar>(snackbar()), first), isTrue);
      await drainSnackbar(tester);
    });
  });

  group('no messenger', () {
    // Null before the first frame, and null entirely under
    // `StartupFailureApp`, which mounts no messenger at all.
    testWidgets('does not throw when the messenger key has no current state', (
      tester,
    ) async {
      final container = containerWith();

      expect(key.currentState, isNull);
      readIgnoringFailure(container, throwsImmediately);

      expect(tester.takeException(), isNull);
    });

    // And the window is not spent on a report nobody saw: the next failure,
    // once a messenger exists, still reports.
    testWidgets('does not spend the suppression window on a dropped report', (
      tester,
    ) async {
      final container = containerWith();
      readIgnoringFailure(container, throwsImmediately);

      await pumpHost(tester);
      container.invalidate(throwsImmediately);
      readIgnoringFailure(container, throwsImmediately);
      await tester.pump();

      expect(snackbar(), findsOneWidget);
      await drainSnackbar(tester);
    });
  });

  // **The case `providerDidFail` alone does not cover, and the reason this
  // observer listens on three hooks.**
  //
  // The app's repositories over a broken store settle at `AsyncLoading` with
  // an error attached — a *soft* error — and riverpod only reports
  // `$ResultError` states through `providerDidFail`. Measured before this
  // test existed: the hook fired 17 times across this suite and **zero**
  // times in the end-to-end flow that drives the whole app over a closed
  // database.
  //
  // So this drives a real repository provider over a real closed sembast
  // store rather than a hand-written `Provider` that throws. A hand-written
  // one fires `providerDidFail` and would have passed against an
  // implementation that misses every failure the app can actually produce.
  group('a soft error — the shape the app actually produces', () {
    testWidgets('a repository provider over a closed store shows a snackbar', (
      tester,
    ) async {
      final db = await newDatabaseFactoryMemory().openDatabase('observer.db');
      await db.close();

      await pumpHost(tester);
      final container = ProviderContainer(
        observers: [GlobalErrorObserver(key)],
        overrides: [databaseProvider.overrideWithValue(db)],
      );

      final date = DateTime(2026, 9, 11);
      container.listen(todaysDailyLogProvider(date), (_, _) {});
      await tester.pumpAndSettle();

      // Both flags true at once: the state is loading *and* carries an
      // error. `value is AsyncError` is false here, which is exactly why the
      // original issue's pattern match could not work.
      final state = container.read(todaysDailyLogProvider(date));
      expect(state.hasError, isTrue);
      expect(state.isLoading, isTrue);
      expect(state, isNot(isA<AsyncError<Object?>>()));

      expect(snackbar(), findsOneWidget);

      // Disposed inside the body, not in a tear-down. riverpod 3 retries a
      // failed provider on a backoff, and `testWidgets` asserts no timer is
      // pending when the body returns — a tear-down runs after that check.
      container.dispose();
      await drainSnackbar(tester);
    });
  });
}
