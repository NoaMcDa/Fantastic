import 'package:fantastic/core/constants/activity_copy.dart';
import 'package:fantastic/features/onboarding/domain/models/activity_level.dart';
import 'package:fantastic/features/onboarding/domain/models/biological_sex.dart';
import 'package:fantastic/features/onboarding/domain/models/onboarding_data.dart';
import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../helpers/pump_onboarding.dart';

void main() {
  // The start-date tile formats its date with an explicit 'he' locale, and
  // `DateFormat` throws without the symbol data loaded — exactly as `main`
  // loads it before `runApp`.
  setUpAll(() => initializeDateFormatting('he'));

  Future<void> fillValidAnswers(WidgetTester tester) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'גיל'), '34');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'משקל (ק״ג)'),
      '78.5',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'גובה (ס״מ)'),
      '176',
    );
    await tester.pump();
  }

  /// Scrolls [finder] into view before tapping it.
  ///
  /// The screen grew an activity selector, so the "כבר בקטו?" switch and the
  /// date tile below it now sit past the bottom of the default 800x600 test
  /// viewport. They are built — the `Column` under the `SingleChildScrollView`
  /// builds eagerly, deliberately — but a tap on a widget outside the viewport
  /// does not reach it.
  Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tapNext(WidgetTester tester) async {
    await tester.tap(find.text('הבא'));
    await tester.pumpAndSettle();
  }

  group('layout', () {
    testWidgets('renders the sex selector and three numeric fields', (
      tester,
    ) async {
      await pumpOnboarding(tester, const OnboardingScreen2());

      expect(find.byType(SegmentedButton<BiologicalSex>), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'גיל'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'משקל (ק״ג)'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'גובה (ס״מ)'), findsOneWidget);
    });

    // Every digit run inside the RTL layout needs this, or "176" is typed
    // and read back reordered.
    testWidgets('every numeric field lays its digits out left to right', (
      tester,
    ) async {
      await pumpOnboarding(tester, const OnboardingScreen2());

      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields, hasLength(3));
      for (final field in fields) {
        expect(field.textDirection, TextDirection.ltr);
      }
    });
  });

  group('validation', () {
    testWidgets('an empty age is rejected and nothing navigates', (
      tester,
    ) async {
      await pumpOnboarding(tester, const OnboardingScreen2());

      await tapNext(tester);

      expect(find.text('יש להזין גיל'), findsOneWidget);
      expect(lastPushedLocation, isNull);
    });

    testWidgets('an age below the minimum is rejected', (tester) async {
      await pumpOnboarding(tester, const OnboardingScreen2());
      await fillValidAnswers(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'גיל'), '5');

      await tapNext(tester);

      expect(find.textContaining('גיל חייב להיות'), findsOneWidget);
      expect(lastPushedLocation, isNull);
    });

    testWidgets('a negative weight is rejected', (tester) async {
      await pumpOnboarding(tester, const OnboardingScreen2());
      await fillValidAnswers(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'משקל (ק״ג)'),
        '-80',
      );

      await tapNext(tester);

      expect(find.text('יש להזין משקל'), findsOneWidget);
      expect(lastPushedLocation, isNull);
    });

    // `double.tryParse('Infinity')` succeeds and is not `< 0`, so a naive
    // validator lets it through and every macro figure derived from the
    // weight becomes Infinity.
    testWidgets('Infinity as a weight is rejected', (tester) async {
      await pumpOnboarding(tester, const OnboardingScreen2());
      await fillValidAnswers(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'משקל (ק״ג)'),
        'Infinity',
      );

      await tapNext(tester);

      expect(lastPushedLocation, isNull);
    });

    // The regression guard, and it is structural on purpose. A `ListView`
    // builds lazily and disposes children it has scrolled past; a disposed
    // `TextFormField` deregisters itself from the enclosing `Form`, so
    // `validate()` returns true for a field nobody filled and `_onNext`
    // parses an empty controller. Whether that reproduces depends on the
    // viewport, the text scale and the cache extent — none of which a test
    // at a fixed 800x600 pins down. What can be pinned down is that the
    // fields are not under a lazy list at all.
    testWidgets('no lazy list sits between the Form and its fields', (
      tester,
    ) async {
      await pumpOnboarding(tester, const OnboardingScreen2());

      expect(
        find.descendant(of: find.byType(Form), matching: find.byType(ListView)),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(Form),
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a scrolled-away empty field is still validated', (
      tester,
    ) async {
      await pumpOnboarding(tester, const OnboardingScreen2());
      await tester.enterText(
        find.widgetWithText(TextFormField, 'גובה (ס״מ)'),
        '176',
      );
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await tester.pump();

      await tapNext(tester);

      expect(find.text('יש להזין גיל'), findsOneWidget);
      expect(lastPushedLocation, isNull);
    });
  });

  group('navigation', () {
    testWidgets('valid answers navigate to step 3 with the data', (
      tester,
    ) async {
      await pumpOnboarding(tester, const OnboardingScreen2());
      await fillValidAnswers(tester);

      await tapNext(tester);

      expect(lastPushedLocation, '/onboarding/3');
      final data = lastPushedExtra! as PartialOnboardingData;
      expect(data.age, 34);
      expect(data.weightKg, 78.5);
      expect(data.heightCm, 176);
    });

    testWidgets('the selected sex is carried through', (tester) async {
      await pumpOnboarding(tester, const OnboardingScreen2());
      await fillValidAnswers(tester);

      await tester.tap(find.text('זכר'));
      await tester.pumpAndSettle();
      await tapNext(tester);

      expect(
        (lastPushedExtra! as PartialOnboardingData).sex,
        BiologicalSex.male,
      );
    });

    testWidgets('no start date is carried when the toggle is off', (
      tester,
    ) async {
      await pumpOnboarding(tester, const OnboardingScreen2());
      await fillValidAnswers(tester);

      await tapNext(tester);

      expect((lastPushedExtra! as PartialOnboardingData).ketoStartDate, isNull);
    });
  });

  // Epic #8's Definition of Done requires the streak to be seeded from a
  // past start date, `ui_ux_design.md` §1b specifies this toggle, and #70's
  // own text has neither.
  group('the "כבר בקטו?" toggle', () {
    testWidgets('is off by default and hides the date row', (tester) async {
      await pumpOnboarding(tester, const OnboardingScreen2());

      expect(find.text('כבר בקטו?'), findsOneWidget);
      expect(find.text('תאריך התחלה'), findsNothing);
    });

    testWidgets('reveals the date row when switched on', (tester) async {
      await pumpOnboarding(tester, const OnboardingScreen2());

      await scrollAndTap(tester, find.byType(SwitchListTile));

      expect(find.text('תאריך התחלה'), findsOneWidget);
      expect(find.text('בחרו תאריך'), findsOneWidget);
    });

    testWidgets('a chosen date is shown and carried to step 3', (tester) async {
      await pumpOnboarding(tester, const OnboardingScreen2());
      await fillValidAnswers(tester);
      await scrollAndTap(tester, find.byType(SwitchListTile));

      await scrollAndTap(tester, find.text('בחרו תאריך'));
      // The picker opens on today, which is always selectable. Its confirm
      // button is localised — 'אישור' under the Hebrew locale the app runs
      // in, not 'OK'.
      await tester.tap(find.text('אישור'));
      await tester.pumpAndSettle();

      expect(find.text('בחרו תאריך'), findsNothing);

      await tapNext(tester);
      expect(
        (lastPushedExtra! as PartialOnboardingData).ketoStartDate,
        isNotNull,
      );
    });

    // Switching the toggle back off is a retraction, not a silent keep — a
    // stale date would seed a streak the user just said they do not have.
    testWidgets('switching back off clears the date', (tester) async {
      await pumpOnboarding(tester, const OnboardingScreen2());
      await fillValidAnswers(tester);
      await scrollAndTap(tester, find.byType(SwitchListTile));
      await scrollAndTap(tester, find.text('בחרו תאריך'));
      await tester.tap(find.text('אישור'));
      await tester.pumpAndSettle();

      await scrollAndTap(tester, find.byType(SwitchListTile));
      await scrollAndTap(tester, find.byType(SwitchListTile));

      expect(find.text('בחרו תאריך'), findsOneWidget);

      await tapNext(tester);
      expect((lastPushedExtra! as PartialOnboardingData).ketoStartDate, isNull);
    });
  });

  // #431's second bullet: the flow asked no activity question at all, so
  // every user's BMR was multiplied by the sedentary 1.2.
  group('the activity question', () {
    testWidgets('renders one segment per level', (tester) async {
      await pumpOnboarding(tester, const OnboardingScreen2());

      expect(find.byType(SegmentedButton<ActivityLevel>), findsOneWidget);
      for (final level in ActivityLevel.values) {
        expect(
          find.byKey(Key('activity_${level.name}')),
          findsOneWidget,
          reason: 'no segment for ${level.name}',
        );
      }
    });

    // The conservative tier: a target set too high stalls weight loss
    // silently, and the user can correct it on this very screen.
    testWidgets('starts on the conservative tier', (tester) async {
      await pumpOnboarding(tester, const OnboardingScreen2());

      final selector = tester.widget<SegmentedButton<ActivityLevel>>(
        find.byType(SegmentedButton<ActivityLevel>),
      );
      expect(selector.selected, {ActivityCopy.defaultLevel});
      expect(ActivityCopy.defaultLevel, ActivityLevel.sedentary);
    });

    // Five Hebrew labels do not fit one segmented button on a phone, so the
    // segments carry icons and the chosen tier is spelled out underneath.
    // Without that the screen would show the user five pictures and no words.
    testWidgets('spells out the chosen tier in words', (tester) async {
      // Read by key rather than by text: 'פעיל' is a substring of the
      // question above the control ('כמה אתם פעילים?'), so a text finder
      // matches two widgets and says nothing about which one moved.
      String caption(WidgetTester tester) => tester
          .widget<Text>(find.byKey(const Key('activity_level_caption')))
          .data!;

      await pumpOnboarding(tester, const OnboardingScreen2());

      expect(
        caption(tester),
        contains(ActivityCopy.titles[ActivityLevel.sedentary]),
      );

      await tester.tap(find.byKey(const Key('activity_active')));
      await tester.pumpAndSettle();

      expect(
        caption(tester),
        contains(ActivityCopy.titles[ActivityLevel.active]),
      );
      expect(
        caption(tester),
        contains(ActivityCopy.subtitles[ActivityLevel.active]),
      );
    });

    testWidgets('the chosen level reaches step 3', (tester) async {
      await pumpOnboarding(tester, const OnboardingScreen2());
      await fillValidAnswers(tester);

      await tester.tap(find.byKey(const Key('activity_moderate')));
      await tester.pumpAndSettle();
      await tapNext(tester);

      expect(
        (lastPushedExtra! as PartialOnboardingData).activityLevel,
        ActivityLevel.moderate,
      );
    });

    testWidgets('an untouched selector still sends sedentary', (tester) async {
      await pumpOnboarding(tester, const OnboardingScreen2());
      await fillValidAnswers(tester);
      await tapNext(tester);

      expect(
        (lastPushedExtra! as PartialOnboardingData).activityLevel,
        ActivityLevel.sedentary,
      );
    });

    // An icon on its own says nothing to a screen reader.
    testWidgets('every segment carries a label for assistive tech', (
      tester,
    ) async {
      await pumpOnboarding(tester, const OnboardingScreen2());

      for (final level in ActivityLevel.values) {
        final icon = tester.widget<Icon>(
          find.byKey(Key('activity_${level.name}')),
        );
        expect(
          icon.semanticLabel,
          ActivityCopy.titles[level],
          reason: 'no semantic label on ${level.name}',
        );
      }
    });
  });
}
