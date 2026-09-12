import 'package:fantastic/features/dashboard/application/providers/daily_log_providers.dart';
import 'package:fantastic/features/dashboard/presentation/widgets/macro_summary_card.dart';
import 'package:fantastic/features/diary/application/meal_logging_service.dart';
import 'package:fantastic/features/diary/application/providers/meal_providers.dart';
import 'package:fantastic/features/diary/presentation/screens/diary_day_screen.dart';
import 'package:fantastic/features/diary/presentation/screens/diary_screen.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_bottom_sheet.dart';
import 'package:fantastic/features/onboarding/application/providers/user_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

class _MockMealLoggingService extends Mock implements MealLoggingService {}

void main() {
  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime dayBefore(int days) {
    final t = today();
    return DateTime(t.year, t.month, t.day - days);
  }

  late _MockMealLoggingService loggingService;

  setUp(() => loggingService = _MockMealLoggingService());

  /// Overrides every date the strip can reach, so tapping any chip resolves.
  List<Override> overridesForAllDays() => [
    for (var i = 0; i < DiaryScreen.visibleDays; i++) ...[
      todaysDailyLogProvider(dayBefore(i)).overrideWith((ref) async => null),
      todaysMealsProvider(dayBefore(i)).overrideWith((ref) async => []),
    ],
    mealLoggingServiceProvider.overrideWithValue(loggingService),
    // MacroSummaryCard measures the day against the onboarding profile
    // (#73), and against the day's own training flag on top of it (#431);
    // without an override it reaches for a database.
    onboardedProfileProvider.overrideWith((ref) => Stream.value(null)),
  ];

  Future<void> pumpDiary(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesForAllDays(),
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: DiaryScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The date the embedded day view is currently showing.
  DateTime shownDate(WidgetTester tester) =>
      tester.widget<DiaryDayScreen>(find.byType(DiaryDayScreen)).date;

  group('date strip', () {
    testWidgets('offers 30 days', (tester) async {
      await pumpDiary(tester);

      // The strip is a lazy horizontal list, so only the visible chips are
      // built. Its itemCount is what the assertion is really about.
      final list = tester.widget<ListView>(find.byType(ListView));
      expect(list.semanticChildCount, DiaryScreen.visibleDays);
    });

    testWidgets('scrolls horizontally', (tester) async {
      await pumpDiary(tester);

      final list = tester.widget<ListView>(find.byType(ListView));
      expect(list.scrollDirection, Axis.horizontal);
    });

    // In RTL a horizontal list already begins at the right edge, so today —
    // the first item — lands there without `reverse`. Setting `reverse: true`
    // as the issue specifies would push it to the left instead.
    testWidgets('does not reverse: RTL already puts today first', (
      tester,
    ) async {
      await pumpDiary(tester);

      final list = tester.widget<ListView>(find.byType(ListView));
      expect(list.reverse, isFalse);
    });

    testWidgets('starts on today', (tester) async {
      await pumpDiary(tester);

      expect(shownDate(tester), today());
    });
  });

  group('selection', () {
    testWidgets('tapping a past day shows that day', (tester) async {
      await pumpDiary(tester);

      await tester.tap(find.text('${dayBefore(2).day}').first);
      await tester.pumpAndSettle();

      expect(shownDate(tester), dayBefore(2));
    });

    testWidgets('the day view rebuilds for the newly selected date', (
      tester,
    ) async {
      await pumpDiary(tester);

      await tester.tap(find.text('${dayBefore(1).day}').first);
      await tester.pumpAndSettle();

      final macro = tester.widget<MacroSummaryCard>(
        find.byType(MacroSummaryCard),
      );
      expect(macro.date, dayBefore(1));
    });

    testWidgets('tapping today again keeps showing today', (tester) async {
      await pumpDiary(tester);

      await tester.tap(find.text('${today().day}').first);
      await tester.pumpAndSettle();

      expect(shownDate(tester), today());
      expect(tester.takeException(), isNull);
    });

    testWidgets('selecting one day then another lands on the second', (
      tester,
    ) async {
      await pumpDiary(tester);

      await tester.tap(find.text('${dayBefore(1).day}').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('${dayBefore(3).day}').first);
      await tester.pumpAndSettle();

      expect(shownDate(tester), dayBefore(3));
    });
  });

  group('chips', () {
    testWidgets('every chip meets the 44pt minimum touch target', (
      tester,
    ) async {
      await pumpDiary(tester);

      for (final element in find.byType(InkWell).evaluate()) {
        final size = tester.getSize(find.byWidget(element.widget));
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(44));
      }
    });

    testWidgets('shows a Hebrew weekday initial with each date', (
      tester,
    ) async {
      await pumpDiary(tester);

      // Whichever day today is, its initial must be one of the seven.
      const initials = {'א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש'};
      final rendered = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .toSet();

      expect(rendered.intersection(initials), isNotEmpty);
    });
  });

  // The Diary tab is where a user goes to work on a day, and it shipped with
  // no way to add a meal to one — while the empty state inside it read
  // "הקש על + כדי להוסיף ארוחה". The only `+` on the screen logged symptoms.
  group('add-meal FAB', () {
    testWidgets('is present on a day with nothing logged', (tester) async {
      await pumpDiary(tester);

      expect(find.byKey(const Key('add_meal_fab_diary')), findsOneWidget);
    });

    testWidgets('opens the add-meal sheet', (tester) async {
      await pumpDiary(tester);

      await tester.tap(find.byKey(const Key('add_meal_fab_diary')));
      await tester.pumpAndSettle();
      // The `+` opens the mode chooser now (#322); manual entry is one
      // tile behind it. Asserted on this host separately from the other,
      // because a capability reachable from one screen and not the other
      // is the defect `design/user_bugs_handoff.md` records.
      await tester.tap(find.byKey(const Key('add_meal_mode_manual')));
      await tester.pumpAndSettle();

      expect(find.byType(AddMealBottomSheet), findsOneWidget);
    });

    testWidgets('the sheet targets today when today is selected', (
      tester,
    ) async {
      await pumpDiary(tester);

      await tester.tap(find.byKey(const Key('add_meal_fab_diary')));
      await tester.pumpAndSettle();
      // The `+` opens the mode chooser now (#322); manual entry is one
      // tile behind it. Asserted on this host separately from the other,
      // because a capability reachable from one screen and not the other
      // is the defect `design/user_bugs_handoff.md` records.
      await tester.tap(find.byKey(const Key('add_meal_mode_manual')));
      await tester.pumpAndSettle();

      final sheet = tester.widget<AddMealBottomSheet>(
        find.byType(AddMealBottomSheet),
      );
      expect(sheet.date, today());
    });

    // The whole reason this screen exists: a meal added here belongs to the
    // day the chip strip is showing, not to today.
    testWidgets('the sheet targets the selected past day', (tester) async {
      await pumpDiary(tester);

      await tester.tap(find.text('${dayBefore(3).day}').first);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_meal_fab_diary')));
      await tester.pumpAndSettle();
      // The `+` opens the mode chooser now (#322); manual entry is one
      // tile behind it. Asserted on this host separately from the other,
      // because a capability reachable from one screen and not the other
      // is the defect `design/user_bugs_handoff.md` records.
      await tester.tap(find.byKey(const Key('add_meal_mode_manual')));
      await tester.pumpAndSettle();

      final sheet = tester.widget<AddMealBottomSheet>(
        find.byType(AddMealBottomSheet),
      );
      expect(sheet.date, dayBefore(3));
    });

    // It does not carry the dashboard's key: the tab shell keeps the
    // outgoing screen mounted during a tab change, so one shared key would
    // match twice mid-transition.
    testWidgets('does not reuse the dashboard FAB key', (tester) async {
      await pumpDiary(tester);

      expect(find.byKey(const Key('add_meal_fab')), findsNothing);
    });
  });

  testWidgets('renders the title', (tester) async {
    await pumpDiary(tester);

    expect(find.text('יומן'), findsOneWidget);
  });

  testWidgets('lays out without overflowing a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpDiary(tester);

    expect(tester.takeException(), isNull);
  });
}
