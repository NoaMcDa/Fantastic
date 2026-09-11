import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/core/time/today_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reports a provider failure that no screen reports for itself.
///
/// Every screen that can fail already says so in its own words, and that is
/// the right primary treatment — this does not replace it. What was missing
/// is the transient case: a write that fails, or a provider that fails
/// somewhere the user is not looking, which reached riverpod as an
/// `AsyncValue.error` and then showed nothing at all.
///
/// ## Why it listens on three hooks and tests `hasError`
///
/// `providerDidFail` alone is not enough, and this was established by
/// measurement rather than from the documentation. It fires for a *hard*
/// error — a `Provider` whose create throws, a bare `Stream.error`. It does
/// **not** fire for this app's repositories over a broken store: those
/// settle at `AsyncLoading` *with an error attached*, a soft error, and
/// riverpod only reports `$ResultError` states through that hook. Measured:
/// 17 calls across the unit suite, **zero** in the end-to-end flow that
/// drives the whole app over a closed database, while `didUpdateProvider`
/// carried the error every time.
///
/// So this is the four-milestone bug in a fourth disguise
/// (`design/mvp_handoff.md`), and this time inside the error reporter
/// itself. Both of the obvious single-hook answers miss the commonest
/// failure in the app:
///
/// - `providerDidFail` alone — misses every soft error, which is all of them
///   here.
/// - `didUpdateProvider` + `if (value is AsyncError)` — the original issue's
///   code, and the forbidden pattern: the value is `AsyncLoading`, so the
///   match never succeeds.
///
/// The rule the project already wrote down is the answer: **check
/// `hasError`, never match an `AsyncError()` pattern.** All three hooks funnel
/// into one report, and the suppression window below is what keeps the
/// overlap between them to a single snackbar.
///
/// Knows about a messenger key and a duration. No feature imports, no
/// opinion about which providers are "already reported".
///
/// `final` because riverpod 3's `ProviderObserver` is an `abstract base
/// class`: a subtype must be one of base, final or sealed. Nothing here is
/// meant to be extended anyway.
final class GlobalErrorObserver extends ProviderObserver {
  GlobalErrorObserver(
    this._messengerKey, {
    this.suppressFor = _defaultWindow,
    this.clock = DateTime.now,
  });

  final GlobalKey<ScaffoldMessengerState> _messengerKey;

  /// How long after a report another failure is swallowed.
  ///
  /// Injectable so a test can assert the de-duplication without sleeping.
  final Duration suppressFor;

  /// The clock the window is measured against.
  ///
  /// Injectable for the same reason `GracePeriodBanner` takes one (#308), and
  /// here it is load-bearing for the tests rather than only convenient:
  /// `testWidgets` runs under a fake clock, so `tester.pump(duration)`
  /// advances the binding's time and not `DateTime.now()`'s. A test that
  /// waited out a real window would have to `Future.delayed` for real
  /// seconds, which under the test binding never completes at all.
  final Clock clock;

  /// The spec's figure — `design/tasks.md:412`. The original issue body said
  /// three seconds and the two have disagreed since M0; four is the one
  /// written down.
  static const Duration visibleFor = Duration(seconds: 4);

  /// Comfortably longer than [visibleFor], so a snackbar cannot be replaced
  /// by its own successor while the user is still reading it.
  static const Duration _defaultWindow = Duration(seconds: 5);

  /// Generic, and generic on purpose: an exception's `toString` is a
  /// developer's sentence, and a stack trace in front of a user is worse than
  /// silence.
  static const String message = 'אירעה שגיאה. נסו שוב.';

  DateTime? _lastReportedAt;

  /// A hard error: the create threw, or an un-wrapped stream errored.
  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) => _report(context, error, stackTrace);

  /// A provider that was *added* already carrying an error.
  @override
  void didAddProvider(ProviderObserverContext context, Object? value) =>
      _reportIfFailed(context, value);

  /// The soft-error path, and the one that actually fires in this app.
  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) => _reportIfFailed(context, newValue);

  /// Reports [value] if it is an [AsyncValue] carrying an error.
  ///
  /// `hasError`, never `value is AsyncError`. A provider that failed before
  /// ever producing a value is `AsyncLoading` with an error attached — both
  /// flags true — so the pattern match silently never fires, which is the
  /// failure mode this whole class exists to end.
  void _reportIfFailed(ProviderObserverContext context, Object? value) {
    if (value is! AsyncValue || !value.hasError) {
      return;
    }
    _report(context, value.error!, value.stackTrace ?? StackTrace.empty);
  }

  void _report(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    // For a developer, and only for a developer.
    debugPrint('provider failed: ${context.provider} — $error\n$stackTrace');

    final now = clock();
    final last = _lastReportedAt;
    if (last != null && now.difference(last) < suppressFor) {
      return;
    }

    // Null before the first frame, and null entirely under
    // `StartupFailureApp`, which mounts no messenger. A no-op, never a
    // throw: an error reporter that throws while reporting an error is the
    // worst failure mode available here.
    final messenger = _messengerKey.currentState;
    if (messenger == null) {
      return;
    }

    _lastReportedAt = now;
    // Clears anything already queued, so a backlog cannot outlive the problem
    // that produced it.
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          key: Key('global_error_snackbar'),
          backgroundColor: AppTheme.danger,
          duration: visibleFor,
          content: Text(message, style: TextStyle(color: Colors.white)),
        ),
      );
  }
}
