import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/diary/application/symptom_logging_service.dart';
import 'package:fantastic/features/diary/domain/models/symptom_log.dart';
import 'package:fantastic/features/diary/presentation/symptom_scale.dart';
import 'package:fantastic/features/diary/presentation/widgets/symptom_log_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

class _MockSymptomLoggingService extends Mock
    implements SymptomLoggingService {}

void main() {
  final date = DateTime(2026, 9, 9);
  late _MockSymptomLoggingService service;

  setUpAll(() => registerFallbackValue(SymptomLogFixture.fixture()));

  setUp(() {
    service = _MockSymptomLoggingService();
    when(() => service.logSymptoms(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.single as SymptomLog,
    );
    // The sheet invalidates `symptomLogProvider` after a save; nothing in
    // this file listens to it, but a rebuild must not hit an unstubbed call.
    when(() => service.symptomsForDate(any())).thenAnswer((_) async => null);
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    SymptomLog? existing,
    SymptomScale? focus,
  }) => pumpApp(
    tester,
    SymptomLogSheet(date: date, existing: existing, focus: focus),
    overrides: [symptomLoggingServiceProvider.overrideWithValue(service)],
  );

  /// The log the most recent save attempt handed the service.
  ///
  /// `last`, not `single`: the retry test saves twice, and `verify` consumes
  /// every call recorded since the previous `verify` (`m3_handoff.md`).
  SymptomLog savedLog() =>
      verify(() => service.logSymptoms(captureAny())).captured.last
          as SymptomLog;

  // The sheet is taller than an 800x600 test window, so everything it
  // touches is scrolled into view first.
  Future<void> tapScore(
    WidgetTester tester,
    SymptomScale scale,
    int score,
  ) async {
    final button = find.byKey(Key('score_${scale.name}_$score'));
    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
  }

  Future<void> save(WidgetTester tester) async {
    final button = find.byKey(const Key('save_symptoms_button'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('renders a row for every scale, labelled correctly', (
    tester,
  ) async {
    await pumpSheet(tester);

    for (final scale in SymptomScale.values) {
      expect(
        find.byKey(Key('symptom_row_${scale.name}')),
        findsOneWidget,
        reason: '${scale.name} row',
      );
      expect(find.text(scale.label), findsOneWidget);
    }
  });

  // The issue text's fifth scale. See design/m5_preflight.md §1.1.
  testWidgets('labels the fifth scale mood, never brain fog', (tester) async {
    await pumpSheet(tester);

    expect(find.text('מצב רוח'), findsOneWidget);
    expect(find.textContaining('ערפל'), findsNothing);
  });

  testWidgets('offers exactly five scores per scale', (tester) async {
    await pumpSheet(tester);

    for (final scale in SymptomScale.values) {
      for (var score = 1; score <= 5; score++) {
        expect(find.byKey(Key('score_${scale.name}_$score')), findsOneWidget);
      }
      expect(find.byKey(Key('score_${scale.name}_6')), findsNothing);
    }
  });

  group('initial state', () {
    testWidgets('a new day starts every scale mid-scale', (tester) async {
      await pumpSheet(tester);
      await save(tester);

      final saved = savedLog();
      for (final scale in SymptomScale.values) {
        expect(scale.scoreIn(saved), SymptomLogSheet.defaultScore);
      }
    });

    // Distinct scores, so a sheet that seeded every row from `energyScore`
    // fails here instead of passing against an all-3s fixture.
    testWidgets('an existing log pre-fills every row from its own field', (
      tester,
    ) async {
      await pumpSheet(tester, existing: SymptomLogFixture.varied(date: date));
      await save(tester);

      final saved = savedLog();
      expect(saved.energyScore, 1);
      expect(saved.clarityScore, 2);
      expect(saved.hungerScore, 3);
      expect(saved.physicalScore, 4);
      expect(saved.moodScore, 5);
    });

    testWidgets('an existing note pre-fills the note field', (tester) async {
      await pumpSheet(
        tester,
        existing: SymptomLogFixture.varied(date: date, notes: 'ישנתי רע'),
      );

      expect(find.text('ישנתי רע'), findsOneWidget);
    });
  });

  group('saving', () {
    testWidgets('persists an adjusted score, not the default', (tester) async {
      await pumpSheet(tester);
      await tapScore(tester, SymptomScale.energy, 5);
      await save(tester);

      expect(savedLog().energyScore, 5);
    });

    // Tapping one row must not move another. Five fields is five chances to
    // cross two of them.
    testWidgets('adjusting one scale leaves the others alone', (tester) async {
      await pumpSheet(tester);
      await tapScore(tester, SymptomScale.mood, 1);
      await save(tester);

      final saved = savedLog();
      expect(saved.moodScore, 1);
      expect(saved.energyScore, SymptomLogSheet.defaultScore);
      expect(saved.clarityScore, SymptomLogSheet.defaultScore);
      expect(saved.hungerScore, SymptomLogSheet.defaultScore);
      expect(saved.physicalScore, SymptomLogSheet.defaultScore);
    });

    testWidgets('saves the day it was given, at midnight', (tester) async {
      await pumpSheet(tester);
      await save(tester);

      expect(savedLog().date, date);
    });

    testWidgets('saves a typed note', (tester) async {
      await pumpSheet(tester);
      final notes = find.byKey(const Key('symptom_notes_field'));
      await tester.ensureVisible(notes);
      await tester.pump();
      await tester.enterText(notes, 'כאב ראש');
      await save(tester);

      expect(savedLog().notes, 'כאב ראש');
    });

    // The data loss design/m5_preflight.md §1.3 found: #77 rebuilt the log
    // from the five sliders alone, and `save` upserts on the date.
    testWidgets('carries an existing note and id through an unrelated edit', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        existing: SymptomLogFixture.varied(
          id: 20260909,
          date: date,
          notes: 'ישנתי רע',
        ),
      );
      await tapScore(tester, SymptomScale.energy, 4);
      await save(tester);

      final saved = savedLog();
      expect(saved.notes, 'ישנתי רע');
      expect(saved.id, 20260909);
      expect(saved.energyScore, 4);
    });

    // The strip stays tappable when its read failed or is still in flight,
    // and in both cases it opens the sheet with `existing: null`. That is
    // "unknown", not "blank" — and `save` upserts on the date, so trusting
    // it wiped the stored note and id. `m5_preflight.md` §1.3 on the
    // failure path.
    testWidgets('recovers the stored id when opened without one', (
      tester,
    ) async {
      when(() => service.symptomsForDate(any())).thenAnswer(
        (_) async =>
            SymptomLogFixture.varied(id: 20260909, date: date, notes: 'כאב'),
      );

      await pumpSheet(tester);
      await save(tester);

      expect(savedLog().id, 20260909);
    });

    testWidgets('recovers a stored note it never showed the user', (
      tester,
    ) async {
      when(() => service.symptomsForDate(any())).thenAnswer(
        (_) async => SymptomLogFixture.varied(date: date, notes: 'כאב ראש'),
      );

      await pumpSheet(tester);
      await save(tester);

      expect(savedLog().notes, 'כאב ראש');
    });

    // Recovery must not outrank the user. A note they typed is the note.
    testWidgets('a typed note beats the recovered one', (tester) async {
      when(() => service.symptomsForDate(any())).thenAnswer(
        (_) async => SymptomLogFixture.varied(date: date, notes: 'ישן'),
      );

      await pumpSheet(tester);
      final notes = find.byKey(const Key('symptom_notes_field'));
      await tester.ensureVisible(notes);
      await tester.pump();
      await tester.enterText(notes, 'חדש');
      await save(tester);

      expect(savedLog().notes, 'חדש');
    });

    // A day with genuinely nothing stored still saves as a fresh record.
    testWidgets('saves a fresh log when nothing is stored', (tester) async {
      await pumpSheet(tester);
      await save(tester);

      final saved = savedLog();
      expect(saved.id, isNull);
      expect(saved.notes, isNull);
    });

    // The write is what the user asked for; a recovery read that fails is
    // not a reason to refuse it.
    testWidgets('still saves when the recovery read fails', (tester) async {
      when(() => service.symptomsForDate(any())).thenThrow(
        const PersistenceException('SymptomLogRepository.findByDate', 'closed'),
      );

      await pumpSheet(tester);
      await save(tester);

      expect(savedLog().id, isNull);
    });

    testWidgets('an emptied note is stored as null, not an empty string', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        existing: SymptomLogFixture.varied(date: date, notes: 'ישנתי רע'),
      );
      final notes = find.byKey(const Key('symptom_notes_field'));
      await tester.ensureVisible(notes);
      await tester.pump();
      await tester.enterText(notes, '   ');
      await save(tester);

      expect(savedLog().notes, isNull);
    });

    // Opened as a real modal route, so "closed" means the route is gone
    // rather than the root route having been popped out from under the app.
    testWidgets('closes after a successful save', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => SymptomLogSheet.show(context, date: date),
            child: const Text('open'),
          ),
        ),
        overrides: [symptomLoggingServiceProvider.overrideWithValue(service)],
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(SymptomLogSheet), findsOneWidget);

      await save(tester);

      expect(find.byType(SymptomLogSheet), findsNothing);
    });
  });

  group('failure', () {
    setUp(() {
      when(() => service.logSymptoms(any())).thenThrow(
        const PersistenceException(
          'SembastSymptomLogRepository.save',
          'disk full',
        ),
      );
    });

    // Closing on failure would discard the answers and tell the user they
    // were saved — the reasoning AddMealBottomSheet settled in M2.
    testWidgets('stays open and says so when the save fails', (tester) async {
      await pumpSheet(tester);
      await save(tester);

      expect(find.byType(SymptomLogSheet), findsOneWidget);
      expect(find.text('השמירה נכשלה, נסו שוב'), findsOneWidget);
    });

    testWidgets('keeps the entered answers after a failure', (tester) async {
      await pumpSheet(tester);
      await tapScore(tester, SymptomScale.energy, 5);
      final notes = find.byKey(const Key('symptom_notes_field'));
      await tester.ensureVisible(notes);
      await tester.pump();
      await tester.enterText(notes, 'כאב ראש');
      await save(tester);

      when(() => service.logSymptoms(any())).thenAnswer(
        (invocation) async =>
            invocation.positionalArguments.single as SymptomLog,
      );
      await save(tester);

      final saved = savedLog();
      expect(saved.energyScore, 5);
      expect(saved.notes, 'כאב ראש');
    });
  });

  group('pre-focus', () {
    // Epic #9's Definition of Done — "tapping a strip icon opens the correct
    // pre-focused sheet" — which #76's text explicitly refuses. The Epic is
    // what the milestone closes against.
    testWidgets('marks the scale the sheet was opened on', (tester) async {
      await pumpSheet(tester, focus: SymptomScale.hunger);

      final row = tester.widget<Container>(
        find.byKey(const Key('symptom_row_hunger')),
      );

      expect(row.decoration, isNotNull);
    });

    testWidgets('marks nothing when opened without a scale', (tester) async {
      await pumpSheet(tester);

      for (final scale in SymptomScale.values) {
        final row = tester.widget<Container>(
          find.byKey(Key('symptom_row_${scale.name}')),
        );
        expect(row.decoration, isNull, reason: scale.name);
      }
    });

    testWidgets('a focused sheet still edits every scale', (tester) async {
      await pumpSheet(tester, focus: SymptomScale.hunger);
      await tapScore(tester, SymptomScale.clarity, 1);
      await save(tester);

      expect(savedLog().clarityScore, 1);
    });
  });
}
