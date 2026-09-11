import 'package:flutter/widgets.dart';

/// [instant]'s calendar date, with the time of day stripped.
///
/// The one definition. Every date-keyed provider family in the app is keyed on
/// a value of this shape, so a caller that builds its own midnight is a caller
/// that can get it subtly wrong.
DateTime dateOnly(DateTime instant) =>
    DateTime(instant.year, instant.month, instant.day);

/// Today's calendar date, with the time of day stripped.
DateTime todayDate() => dateOnly(DateTime.now());

/// A source of the current wall-clock instant.
///
/// The seam a widget takes when *what it renders* depends on the time rather
/// than only on what it was given — a countdown, or a window that has closed.
/// A test passes a fixed instant instead of sleeping.
///
/// An **instant**, never a date: [TodayTracker.now]'s doc records what
/// happened the one time a clock seam returned a stripped date, and the same
/// reasoning applies to anything named `Clock` here.
typedef Clock = DateTime Function();

/// Holds [today] for a screen and refreshes it when the app comes back to the
/// foreground on a later calendar day.
///
/// **Why this is not just `late final DateTime _today = todayDate()`.** iOS
/// suspends an app rather than killing it, so a `State` created at 23:50 is
/// still the live `State` at 00:15 — with a date field a day stale. The
/// dashboard would go on captioning itself yesterday, and worse, the writes it
/// launches (the symptom check-in, the meal sheet) would land on yesterday's
/// record while the strip says `תסמינים היום`.
///
/// The date is still cached rather than recomputed in `build`: the providers
/// are families keyed on it, and a fresh `DateTime` every frame would allocate
/// a new provider every frame and refetch forever. It changes only when the
/// calendar day actually has.
///
/// Known gap: an app left in the *foreground* across midnight is not covered —
/// no resume event fires. Closing that needs a timer, and a pending timer at
/// the end of a `testWidgets` body fails the test, which is a poor trade for
/// the rarer case.
mixin TodayTracker<T extends StatefulWidget> on State<T> {
  late DateTime _today = dateOnly(now());

  late final ResumeObserver _observer = ResumeObserver(refreshToday);

  /// Today at midnight, as of the last resume.
  DateTime get today => _today;

  /// The clock seam.
  ///
  /// Production reads the real one. A test overrides it to step the calendar
  /// without waiting for midnight, which is the only way to exercise the
  /// rollover at all.
  ///
  /// Returns a wall-clock **instant**, not a date. Stripping it to midnight is
  /// this mixin's own job and deliberately not overridable: the date-keyed
  /// provider families are keyed on the stripped value, so an override that
  /// forgot to strip would key them on a time of day and allocate a fresh
  /// provider on every resolve. An earlier draft of this seam returned the
  /// date and its first override made exactly that mistake.
  @protected
  DateTime now() => DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_observer);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_observer);
    super.dispose();
  }

  /// Called inside the `setState` that rolled [today] over, so a screen
  /// holding a date *derived* from it can follow in the same frame.
  ///
  /// [previous] is the date [today] just stopped being.
  @protected
  void onTodayChanged(DateTime previous) {}

  /// Re-reads the clock and rolls [today] over if the calendar day moved.
  ///
  /// A no-op otherwise, and that matters: the date-keyed provider families
  /// are keyed on this value, so rebuilding on every resume would refetch
  /// every one of them for nothing.
  @protected
  void refreshToday() {
    final current = dateOnly(now());
    if (current == _today) {
      return;
    }
    setState(() {
      final previous = _today;
      _today = current;
      onTodayChanged(previous);
    });
  }
}

/// Calls [onResumed] every time the app returns to the foreground.
///
/// A separate object rather than mixing `WidgetsBindingObserver` into the
/// `State`: [TodayTracker] would then have to be applied alongside it at every
/// use site, and a screen that forgot would compile and silently never
/// refresh.
///
/// Public only so a test can deliver a lifecycle event to it directly. The
/// binding's own `handleAppLifecycleStateChanged` is `@protected`, and calling
/// it from a test file is an analyzer warning — which this project's CI reads
/// as a failure.
@visibleForTesting
class ResumeObserver extends WidgetsBindingObserver {
  ResumeObserver(this.onResumed);

  final VoidCallback onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
}
