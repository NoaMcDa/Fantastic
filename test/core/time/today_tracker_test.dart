import 'package:fantastic/core/time/today_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A screen that holds a date the way `DashboardScreen` and `DiaryScreen` do,
/// with the clock under the test's control.
class _Host extends StatefulWidget {
  const _Host({required this.clock, super.key});

  /// Read on every resolve, so a test can step the calendar between frames.
  final DateTime Function() clock;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> with TodayTracker {
  /// Every rollover this State saw, oldest first.
  final List<DateTime> rollovers = [];

  @override
  DateTime now() => widget.clock();

  @override
  void onTodayChanged(DateTime previous) => rollovers.add(previous);

  /// What the resume observer calls. Public here so the test can stand in for
  /// it without touching the binding's `@protected` lifecycle entry point.
  void resume() => refreshToday();

  @override
  Widget build(BuildContext context) =>
      Text('${today.year}-${today.month}-${today.day}');
}

void main() {
  const key = ValueKey('host');

  // 23:50 — ten minutes before the rollover this whole file exists for.
  late DateTime clock;

  setUp(() => clock = DateTime(2026, 9, 11, 23, 50));

  Future<void> pumpHost(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: _Host(key: key, clock: () => clock),
    ),
  );

  _HostState state(WidgetTester tester) =>
      tester.state<_HostState>(find.byKey(key));

  Future<void> resume(WidgetTester tester) async {
    state(tester).resume();
    await tester.pump();
  }

  group('dateOnly', () {
    test('strips the time of day', () {
      final today = dateOnly(DateTime(2026, 9, 11, 23, 50, 30, 250));

      expect(today, DateTime(2026, 9, 11));
    });
  });

  group('todayDate', () {
    test('strips the time of day', () {
      final today = todayDate();

      expect(today.hour, 0);
      expect(today.minute, 0);
      expect(today.second, 0);
      expect(today.millisecond, 0);
    });

    test('is the current calendar day', () {
      final now = DateTime.now();
      final today = todayDate();

      expect(today.year, now.year);
      expect(today.month, now.month);
      expect(today.day, now.day);
    });
  });

  group('TodayTracker', () {
    testWidgets('resolves today at midnight on first build', (tester) async {
      await pumpHost(tester);

      expect(state(tester).today, DateTime(2026, 9, 11));
      expect(find.text('2026-9-11'), findsOneWidget);
    });

    // The whole point. iOS suspends rather than kills, so a State built at
    // 23:50 is still the live State at 00:15 — and this screen's date feeds
    // the writes it launches, not just its header.
    testWidgets('rolls over onto a later day', (tester) async {
      await pumpHost(tester);
      clock = DateTime(2026, 9, 12, 0, 15);
      await resume(tester);

      expect(state(tester).today, DateTime(2026, 9, 12));
      expect(find.text('2026-9-12'), findsOneWidget);
    });

    // The date-keyed providers are families keyed on this value, so a
    // rebuild on every resume would refetch every one of them for nothing.
    testWidgets('a refresh on the same day changes nothing', (tester) async {
      await pumpHost(tester);
      final before = state(tester).today;
      clock = DateTime(2026, 9, 11, 23, 59);
      await resume(tester);

      expect(identical(state(tester).today, before), isTrue);
      expect(state(tester).rollovers, isEmpty);
    });

    testWidgets('reports the date it stopped being', (tester) async {
      await pumpHost(tester);
      clock = DateTime(2026, 9, 12, 0, 15);
      await resume(tester);

      expect(state(tester).rollovers, [DateTime(2026, 9, 11)]);
    });

    // Called inside the same `setState`, so a screen holding a *derived*
    // date follows in the frame the rollover paints.
    testWidgets('reports the change before the next build', (tester) async {
      await pumpHost(tester);
      clock = DateTime(2026, 9, 12, 0, 15);
      state(tester).resume();

      expect(state(tester).rollovers, [DateTime(2026, 9, 11)]);
      await tester.pump();
    });

    testWidgets('survives being disposed while observing', (tester) async {
      await pumpHost(tester);
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

      expect(tester.takeException(), isNull);
    });
  });

  group('ResumeObserver', () {
    test('fires on resume', () {
      var fired = 0;
      final observer = ResumeObserver(() => fired++);

      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(fired, 1);
    });

    test('ignores every other lifecycle state', () {
      var fired = 0;
      final observer = ResumeObserver(() => fired++);

      for (final state in AppLifecycleState.values) {
        if (state != AppLifecycleState.resumed) {
          observer.didChangeAppLifecycleState(state);
        }
      }

      expect(fired, 0);
    });
  });
}
