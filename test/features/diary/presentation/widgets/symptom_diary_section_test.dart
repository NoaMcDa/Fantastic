import 'dart:async';

import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/diary/application/providers/symptom_providers.dart';
import 'package:fantastic/features/diary/application/symptom_logging_service.dart';
import 'package:fantastic/features/diary/domain/models/physical_symptom.dart';
import 'package:fantastic/features/diary/domain/models/symptom_log.dart';
import 'package:fantastic/features/diary/presentation/physical_symptom_copy.dart';
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
      // `varied()` yields energy=1, clarity=2, hunger=3, mood=4.
      const expected = {
        SymptomScale.energy: 1,
        SymptomScale.clarity: 2,
        SymptomScale.hunger: 3,
        SymptomScale.mood: 4,
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

    testWidgets('renders exactly four score chips — not five', (tester) async {
      await pumpSection(tester, log: SymptomLogFixture.varied(date: date));
      await tester.pumpAndSettle();

      // SymptomScale has four values; there is no physical scale.
      expect(SymptomScale.values, hasLength(4));
      for (final scale in SymptomScale.values) {
        expect(
          find.byKey(Key('symptom_chip_${scale.name}')),
          findsOneWidget,
          reason: scale.name,
        );
      }
      // No chip keyed symptom_chip_physical — that field was replaced by a set.
      expect(find.byKey(const Key('symptom_chip_physical')), findsNothing);
    });

    testWidgets('labels the fourth chip mood, never brain fog', (tester) async {
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
          matching: find.text('4'),
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

    testWidgets(
      'shows only score chips and no-symptom text when there is no note and no symptoms',
      (tester) async {
        await pumpSection(tester, log: SymptomLogFixture.fixture(date: date));
        await tester.pumpAndSettle();

        // Four score chips; the empty symptom text; no note.
        expect(find.byType(Chip), findsNWidgets(4));
        expect(find.byKey(const Key('no_physical_symptoms')), findsOneWidget);
      },
    );

    group('physical symptom chips', () {
      testWidgets('renders a chip for each marked symptom', (tester) async {
        // varied() fixture has exactly muscleCramps in its symptom set.
        await pumpSection(tester, log: SymptomLogFixture.varied(date: date));
        await tester.pumpAndSettle();

        expect(
          find.byKey(Key('diary_symptom_${PhysicalSymptom.muscleCramps.name}')),
          findsOneWidget,
        );
        // `varied()` holds only muscleCramps — no other symptom chip.
        for (final symptom in PhysicalSymptom.values) {
          if (symptom == PhysicalSymptom.muscleCramps) continue;
          expect(
            find.byKey(Key('diary_symptom_${symptom.name}')),
            findsNothing,
            reason: symptom.name,
          );
        }
      });

      testWidgets(
        'symptom chip label comes from the extension, not hardcoded',
        (tester) async {
          await pumpSection(tester, log: SymptomLogFixture.varied(date: date));
          await tester.pumpAndSettle();

          final chip = find.byKey(
            Key('diary_symptom_${PhysicalSymptom.muscleCramps.name}'),
          );
          expect(
            find.descendant(
              of: chip,
              matching: find.text(PhysicalSymptom.muscleCramps.label),
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'renders chips in PhysicalSymptom.values order regardless of set insertion order',
        (tester) async {
          // worstDay() carries {headache, dizziness, muscleCramps, nausea} in
          // that Set insertion order. PhysicalSymptom.values order is:
          // halitosis, constipation, muscleCramps, headache, diarrhea,
          // dizziness, nausea, insomnia.
          // If the widget iterated the Set directly it would render
          // headache → dizziness → muscleCramps → nausea. In enum order it
          // renders muscleCramps → headache → dizziness → nausea. We verify the
          // first two chips are positioned correctly: muscleCramps appears before
          // headache (lower x in a LTR Wrap, or at least not after it).
          final log = SymptomLogFixture.worstDay(date: date);
          await pumpSection(tester, log: log);
          await tester.pumpAndSettle();

          // Build expected render order from enum values — mirrors the widget.
          final expectedOrder = [
            for (final s in PhysicalSymptom.values)
              if (log.symptoms.contains(s)) s,
          ];
          expect(expectedOrder, [
            PhysicalSymptom.muscleCramps,
            PhysicalSymptom.headache,
            PhysicalSymptom.dizziness,
            PhysicalSymptom.nausea,
          ]);

          // All four chips must be present.
          for (final s in expectedOrder) {
            expect(
              find.byKey(Key('diary_symptom_${s.name}')),
              findsOneWidget,
              reason: s.name,
            );
          }

          // Enum order: muscleCramps before headache. In RTL the first child of
          // a Wrap sits at the right edge (highest dx); later children step left.
          // If the widget iterated the Set instead, headache (inserted first into
          // the Set) would be the start-edge chip and have the largest dx.
          final muscleCrampsX = tester
              .getTopLeft(
                find.byKey(
                  Key('diary_symptom_${PhysicalSymptom.muscleCramps.name}'),
                ),
              )
              .dx;
          final headacheX = tester
              .getTopLeft(
                find.byKey(
                  Key('diary_symptom_${PhysicalSymptom.headache.name}'),
                ),
              )
              .dx;
          expect(
            muscleCrampsX,
            greaterThan(headacheX),
            reason:
                'muscleCramps (enum index 2, first rendered) must sit right of '
                'headache (enum index 3) in an RTL Wrap',
          );
        },
      );

      // Issue #293: record exists but no symptoms — distinct from no record.
      testWidgets(
        'shows "לא דווחו תסמינים פיזיים" when log has empty symptom set',
        (tester) async {
          await pumpSection(tester, log: SymptomLogFixture.fixture(date: date));
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('no_physical_symptoms')), findsOneWidget);
          expect(find.text('לא דווחו תסמינים פיזיים'), findsOneWidget);
        },
      );

      // The two empty states say different things — "logged, marked nothing"
      // and "never logged" — and collapsing them is wrong. One test each: a
      // second pumpSection in the same test reuses the ProviderScope's
      // container and keeps showing the first day.
      testWidgets('a logged day with no symptoms shows only the symptom empty '
          'state', (tester) async {
        await pumpSection(tester, log: SymptomLogFixture.fixture(date: date));
        await tester.pumpAndSettle();

        expect(find.text('לא דווחו תסמינים פיזיים'), findsOneWidget);
        expect(find.text('לא הוקלטו תסמינים'), findsNothing);
      });

      testWidgets('an unlogged day shows only the whole-day empty state', (
        tester,
      ) async {
        await pumpSection(tester);
        await tester.pumpAndSettle();

        expect(find.text('לא הוקלטו תסמינים'), findsOneWidget);
        expect(find.text('לא דווחו תסמינים פיזיים'), findsNothing);
      });

      testWidgets(
        'does not show no_physical_symptoms when symptoms are present',
        (tester) async {
          await pumpSection(tester, log: SymptomLogFixture.varied(date: date));
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('no_physical_symptoms')), findsNothing);
        },
      );
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
      // Four score chips + one symptom chip (muscleCramps from varied()).
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
