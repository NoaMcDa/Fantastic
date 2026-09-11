import 'dart:async';

import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/diary/application/providers/symptom_providers.dart';
import 'package:fantastic/features/diary/application/symptom_logging_service.dart';
import 'package:fantastic/features/diary/domain/models/symptom_log.dart';
import 'package:fantastic/features/diary/presentation/symptom_scale.dart';
import 'package:fantastic/features/diary/presentation/widgets/symptom_diary_section.dart';
import 'package:fantastic/features/diary/presentation/widgets/symptom_log_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

class _MockSymptomLoggingService extends Mock
    implements SymptomLoggingService {}

void main() {
  final date = DateTime(2026, 9, 7);
  late _MockSymptomLoggingService service;

  setUpAll(() => registerFallbackValue(SymptomLogFixture.fixture()));

  setUp(() {
    service = _MockSymptomLoggingService();
    when(() => service.logSymptoms(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.single as SymptomLog,
    );
  });

  Future<void> pumpSection(
    WidgetTester tester, {
    SymptomLog? log,
    Object? error,
    Completer<SymptomLog?>? pending,
  }) => pumpApp(
    tester,
    SymptomDiarySection(date: date),
    overrides: [
      symptomLoggingServiceProvider.overrideWithValue(service),
      symptomLogProvider(date).overrideWith((ref) {
        if (pending != null) {
          return pending.future;
        }
        if (error != null) {
          throw error;
        }
        return Future.value(log);
      }),
    ],
  );

  testWidgets('is headed תסמינים', (tester) async {
    await pumpSection(tester);
    await tester.pumpAndSettle();

    expect(find.text('תסמינים'), findsOneWidget);
  });

  group('a day with no log', () {
    testWidgets('says nothing was logged and offers to log it', (tester) async {
      await pumpSection(tester);
      await tester.pumpAndSettle();

      expect(find.text('לא הוקלטו תסמינים'), findsOneWidget);
      expect(find.byKey(const Key('log_symptoms_button')), findsOneWidget);
      expect(find.byKey(const Key('edit_symptoms_button')), findsNothing);
    });

    testWidgets('renders no score chips', (tester) async {
      await pumpSection(tester);
      await tester.pumpAndSettle();

      for (final scale in SymptomScale.values) {
        expect(find.byKey(Key('symptom_chip_${scale.name}')), findsNothing);
      }
    });

    testWidgets('the log button opens an empty sheet', (tester) async {
      await pumpSection(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('log_symptoms_button')));
      await tester.pumpAndSettle();

      final sheet = tester.widget<SymptomLogSheet>(
        find.byType(SymptomLogSheet),
      );
      expect(sheet.existing, isNull);
      expect(sheet.date, date);
    });
  });

  group('a logged day', () {
    testWidgets('renders one chip per scale, each from its own field', (
      tester,
    ) async {
      await pumpSection(tester, log: SymptomLogFixture.varied(date: date));
      await tester.pumpAndSettle();

      // Distinct scores, so a section that read every chip from
      // `energyScore` fails here rather than passing against an all-3s
      // fixture (`design/m5_preflight.md` §1.1).
      const expected = {
        SymptomScale.energy: 1,
        SymptomScale.clarity: 2,
        SymptomScale.hunger: 3,
        SymptomScale.physical: 4,
        SymptomScale.mood: 5,
      };

      for (final entry in expected.entries) {
        final chip = find.byKey(Key('symptom_chip_${entry.key.name}'));
        expect(chip, findsOneWidget, reason: entry.key.name);
        expect(
          find.descendant(of: chip, matching: find.text(entry.key.label)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: chip, matching: find.text('${entry.value}')),
          findsOneWidget,
          reason: '${entry.key.name} shows ${entry.value}',
        );
      }
    });

    testWidgets('labels the fifth chip mood, never brain fog', (tester) async {
      await pumpSection(tester, log: SymptomLogFixture.varied(date: date));
      await tester.pumpAndSettle();

      expect(find.text('מצב רוח'), findsOneWidget);
      expect(find.textContaining('ערפל'), findsNothing);
    });

    // A digit run inside the RTL layout — m3_handoff.md convention 6.
    testWidgets('renders each score left-to-right', (tester) async {
      await pumpSection(tester, log: SymptomLogFixture.varied(date: date));
      await tester.pumpAndSettle();

      final score = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('symptom_chip_mood')),
          matching: find.text('5'),
        ),
      );
      expect(score.textDirection, TextDirection.ltr);
    });

    testWidgets('offers an edit, not a log', (tester) async {
      await pumpSection(tester, log: SymptomLogFixture.varied(date: date));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit_symptoms_button')), findsOneWidget);
      expect(find.byKey(const Key('log_symptoms_button')), findsNothing);
      expect(find.text('לא הוקלטו תסמינים'), findsNothing);
    });

    testWidgets('the edit button opens the sheet pre-filled', (tester) async {
      final stored = SymptomLogFixture.varied(id: 20260907, date: date);
      await pumpSection(tester, log: stored);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit_symptoms_button')));
      await tester.pumpAndSettle();

      final sheet = tester.widget<SymptomLogSheet>(
        find.byType(SymptomLogSheet),
      );
      expect(sheet.existing, stored);
      expect(sheet.date, date);
    });

    // Shown, not merely stored. A note the user can never read back is one
    // they will not write twice — and it is the field #77 dropped entirely.
    testWidgets('shows the day\'s note', (tester) async {
      await pumpSection(
        tester,
        log: SymptomLogFixture.varied(date: date, notes: 'ישנתי רע'),
      );
      await tester.pumpAndSettle();

      expect(find.text('ישנתי רע'), findsOneWidget);
    });

    testWidgets('shows nothing extra when there is no note', (tester) async {
      await pumpSection(tester, log: SymptomLogFixture.varied(date: date));
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsNWidgets(5));
    });
  });

  group('while loading', () {
    testWidgets('shows a spinner and no chips', (tester) async {
      final pending = Completer<SymptomLog?>();
      await pumpSection(tester, pending: pending);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Chip), findsNothing);

      pending.complete(SymptomLogFixture.varied(date: date));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(Chip), findsNWidgets(5));
    });
  });

  group('when the read fails', () {
    const failure = PersistenceException(
      'SembastSymptomLogRepository.findByDate',
      'closed',
    );

    // The spinner must be gone. riverpod 3 reports a never-valued failure as
    // `AsyncLoading` with an error attached, so a loading-first widget spins
    // forever and a test that only checks for the message passes anyway.
    testWidgets('reports the failure instead of spinning forever', (
      tester,
    ) async {
      await pumpSection(tester, error: failure);
      await tester.pump();

      expect(find.text('לא ניתן לטעון את התסמינים'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    // A failed read and an empty day mean opposite things.
    testWidgets('does not pass the failure off as an unlogged day', (
      tester,
    ) async {
      await pumpSection(tester, error: failure);
      await tester.pump();

      expect(find.text('לא הוקלטו תסמינים'), findsNothing);
    });
  });
}
