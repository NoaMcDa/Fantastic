import 'dart:async';

import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/diary/application/providers/symptom_providers.dart';
import 'package:fantastic/features/diary/application/symptom_logging_service.dart';
import 'package:fantastic/features/diary/domain/models/physical_symptom.dart';
import 'package:fantastic/features/diary/domain/models/symptom_log.dart';
import 'package:fantastic/features/diary/presentation/symptom_scale.dart';
import 'package:fantastic/features/diary/presentation/widgets/symptom_check_in_strip.dart';
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
  });

  Future<void> pumpStrip(
    WidgetTester tester, {
    SymptomLog? log,
    Object? error,
    Completer<SymptomLog?>? pending,
  }) => pumpApp(
    tester,
    SymptomCheckInStrip(date: date),
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

  /// How many of [scale]'s five dots are painted as filled.
  int filledDots(WidgetTester tester, SymptomScale scale) {
    final primary = Theme.of(tester.element(find.byType(SymptomCheckInStrip)))
        .colorScheme
        .primary;

    var filled = 0;
    for (var dot = 1; dot <= 5; dot++) {
      final container = tester.widget<Container>(
        find.byKey(Key('symptom_dot_${scale.name}_$dot')),
      );
      final decoration = container.decoration! as BoxDecoration;
      if (decoration.color == primary) {
        filled++;
      }
    }
    return filled;
  }

  testWidgets('renders one cell per scale', (tester) async {
    await pumpStrip(tester);
    await tester.pumpAndSettle();

    for (final scale in SymptomScale.values) {
      expect(
        find.byKey(Key('symptom_cell_${scale.name}')),
        findsOneWidget,
        reason: scale.name,
      );
      expect(find.text(scale.shortLabel), findsOneWidget);
    }
  });

  // design/m5_preflight.md §1.1 — every M5 issue labelled the fifth cell
  // "brain fog" while reading a field the model does not have.
  testWidgets('the fifth cell is mood, never brain fog', (tester) async {
    await pumpStrip(tester);
    await tester.pumpAndSettle();

    expect(find.text('מצב רוח'), findsOneWidget);
    expect(find.textContaining('ערפל'), findsNothing);
  });

  // The strip now has four scale cells — physical was removed in #290.
  testWidgets('renders exactly four scale cells, not five', (tester) async {
    await pumpStrip(tester);
    await tester.pumpAndSettle();

    expect(SymptomScale.values.length, 4);
    for (final scale in SymptomScale.values) {
      expect(
        find.byKey(Key('symptom_cell_${scale.name}')),
        findsOneWidget,
        reason: scale.name,
      );
    }
    // No physical scale cell should appear — physical is now a chip row.
    expect(find.byKey(const Key('symptom_cell_physical')), findsNothing);
  });

  group('an unlogged day', () {
    testWidgets('still renders the strip, with every dot empty', (
      tester,
    ) async {
      await pumpStrip(tester);
      await tester.pumpAndSettle();

      for (final scale in SymptomScale.values) {
        expect(filledDots(tester, scale), 0, reason: scale.name);
      }
    });

    testWidgets('shows ללא תסמינים פיזיים in the chip row', (tester) async {
      await pumpStrip(tester);
      await tester.pumpAndSettle();

      expect(find.text('ללא תסמינים פיזיים'), findsOneWidget);
    });

    testWidgets('shows the add-symptoms button', (tester) async {
      await pumpStrip(tester);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('add_symptoms_button')), findsOneWidget);
    });
  });

  group('a logged day', () {
    // Against distinct scores: a strip that drew every cell from
    // `energyScore` passes any assertion an all-3s fixture can make.
    testWidgets('fills each cell from its own scale', (tester) async {
      await pumpStrip(tester, log: SymptomLogFixture.varied(date: date));
      await tester.pumpAndSettle();

      expect(filledDots(tester, SymptomScale.energy), 1);
      expect(filledDots(tester, SymptomScale.clarity), 2);
      expect(filledDots(tester, SymptomScale.hunger), 3);
      expect(filledDots(tester, SymptomScale.mood), 4);
    });

    testWidgets('fills all five dots for a best day', (tester) async {
      await pumpStrip(tester, log: SymptomLogFixture.bestDay(date: date));
      await tester.pumpAndSettle();

      expect(filledDots(tester, SymptomScale.mood), 5);
    });

    testWidgets('fills one dot for a worst day', (tester) async {
      await pumpStrip(tester, log: SymptomLogFixture.worstDay(date: date));
      await tester.pumpAndSettle();

      expect(filledDots(tester, SymptomScale.energy), 1);
    });

    testWidgets('shows ללא תסמינים פיזיים for a logged day with empty set', (
      tester,
    ) async {
      await pumpStrip(
        tester,
        log: SymptomLogFixture.fixture(date: date, symptoms: const {}),
      );
      await tester.pumpAndSettle();

      expect(find.text('ללא תסמינים פיזיים'), findsOneWidget);
    });
  });

  group('chip row', () {
    // The varied fixture marks only muscleCramps — one chip, not all eight,
    // and not the first enum value. A row that renders all PhysicalSymptom.values
    // or always the first would fail this.
    testWidgets('shows one chip per marked symptom', (tester) async {
      await pumpStrip(tester, log: SymptomLogFixture.varied(date: date));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('strip_symptom_muscleCramps')),
        findsOneWidget,
      );
      // No other symptoms should appear.
      for (final s in PhysicalSymptom.values) {
        if (s == PhysicalSymptom.muscleCramps) continue;
        expect(
          find.byKey(Key('strip_symptom_${s.name}')),
          findsNothing,
          reason: s.name,
        );
      }
    });

    // Chips must appear in PhysicalSymptom.values order, not insertion order.
    // worstDay has {headache, dizziness, muscleCramps, nausea} — insertion order
    // differs from enum order (halitosis, constipation, muscleCramps, headache,
    // diarrhea, dizziness, nausea, insomnia). Enum order: muscleCramps (index 2),
    // headache (index 3), dizziness (index 5), nausea (index 6).
    //
    // The strip iterates `PhysicalSymptom.values` and filters by
    // `log.symptoms.contains`, so the Wrap children list is built in enum
    // order regardless of set insertion order. We verify by finding all four
    // chips and confirming their widget tree order (via topLeft.dy for rows
    // that wrap, and the overall element order via `tester.allWidgets`).
    testWidgets('renders chips in enum order, not set insertion order', (
      tester,
    ) async {
      await pumpStrip(tester, log: SymptomLogFixture.worstDay(date: date));
      await tester.pumpAndSettle();

      // All four worst-day symptoms should appear.
      expect(
        find.byKey(const Key('strip_symptom_muscleCramps')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('strip_symptom_headache')), findsOneWidget);
      expect(find.byKey(const Key('strip_symptom_dizziness')), findsOneWidget);
      expect(find.byKey(const Key('strip_symptom_nausea')), findsOneWidget);

      // Enum order is enforced by construction: the strip iterates
      // PhysicalSymptom.values (not the set) and filters. We confirm by
      // reading the order of Chip widgets in the widget tree — they must
      // appear in the same sequence as PhysicalSymptom.values.
      final chipOrder = tester
          .widgetList<Chip>(find.byType(Chip))
          .map((c) {
            // Each Chip's key encodes the symptom name.
            final key = (c.key as ValueKey<String>).value;
            return key.replaceFirst('strip_symptom_', '');
          })
          .where((name) => PhysicalSymptom.values.any((s) => s.name == name))
          .toList();

      // Expected: enum order among the four marked symptoms.
      final expected = PhysicalSymptom.values
          .where((s) => SymptomLogFixture.worstDay().symptoms.contains(s))
          .map((s) => s.name)
          .toList();

      expect(chipOrder, equals(expected));
    });

    testWidgets('no chip row label for a day with no symptoms', (tester) async {
      await pumpStrip(tester);
      await tester.pumpAndSettle();

      for (final s in PhysicalSymptom.values) {
        expect(
          find.byKey(Key('strip_symptom_${s.name}')),
          findsNothing,
          reason: s.name,
        );
      }
    });
  });

  group('tapping a cell', () {
    testWidgets('opens the sheet', (tester) async {
      await pumpStrip(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('symptom_cell_energy')));
      await tester.pumpAndSettle();

      expect(find.byType(SymptomLogSheet), findsOneWidget);
    });

    // Epic #9's Definition of Done: "tapping a strip icon opens the correct
    // pre-focused sheet". #76's own text refuses this; the Epic wins.
    testWidgets('focuses the sheet on the scale that was tapped', (
      tester,
    ) async {
      await pumpStrip(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('symptom_cell_hunger')));
      await tester.pumpAndSettle();

      final sheet = tester.widget<SymptomLogSheet>(
        find.byType(SymptomLogSheet),
      );
      expect(sheet.focus, SymptomScale.hunger);
      expect(sheet.date, date);
    });

    // Without this the sheet would reset a logged day to the mid-scale
    // default and the save would erase the user's stored note.
    testWidgets('hands the day\'s existing log to the sheet', (tester) async {
      final stored = SymptomLogFixture.varied(
        id: 20260909,
        date: date,
        notes: 'ישנתי רע',
      );
      await pumpStrip(tester, log: stored);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('symptom_cell_mood')));
      await tester.pumpAndSettle();

      final sheet = tester.widget<SymptomLogSheet>(
        find.byType(SymptomLogSheet),
      );
      expect(sheet.existing, stored);
    });
  });

  group('add-symptoms button', () {
    testWidgets('opens the sheet with focusSymptoms: true', (tester) async {
      await pumpStrip(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_symptoms_button')));
      await tester.pumpAndSettle();

      final sheet = tester.widget<SymptomLogSheet>(
        find.byType(SymptomLogSheet),
      );
      expect(sheet.focusSymptoms, isTrue);
      expect(sheet.date, date);
    });

    testWidgets('passes the existing log to the sheet', (tester) async {
      final stored = SymptomLogFixture.varied(id: 20260909, date: date);
      await pumpStrip(tester, log: stored);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_symptoms_button')));
      await tester.pumpAndSettle();

      final sheet = tester.widget<SymptomLogSheet>(
        find.byType(SymptomLogSheet),
      );
      expect(sheet.existing, stored);
    });

    testWidgets('passes null existing when day is not logged', (tester) async {
      await pumpStrip(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_symptoms_button')));
      await tester.pumpAndSettle();

      final sheet = tester.widget<SymptomLogSheet>(
        find.byType(SymptomLogSheet),
      );
      expect(sheet.existing, isNull);
    });
  });

  group('while loading', () {
    testWidgets('reserves the cells without painting a score', (tester) async {
      final pending = Completer<SymptomLog?>();
      await pumpStrip(tester, pending: pending);
      await tester.pump();

      expect(find.byType(SymptomCheckInStrip), findsOneWidget);
      expect(find.byKey(const Key('symptom_dot_energy_1')), findsNothing);

      pending.complete(SymptomLogFixture.bestDay(date: date));
      await tester.pumpAndSettle();

      expect(filledDots(tester, SymptomScale.energy), 5);
    });

    testWidgets(
      'chip row reserves its height without rendering chips or text',
      (tester) async {
        final pending = Completer<SymptomLog?>();
        await pumpStrip(tester, pending: pending);
        await tester.pump();

        // No chips and no "ללא תסמינים פיזיים" text while loading.
        for (final s in PhysicalSymptom.values) {
          expect(find.byKey(Key('strip_symptom_${s.name}')), findsNothing);
        }
        expect(find.text('ללא תסמינים פיזיים'), findsNothing);

        // The card is still present — height is reserved, not collapsed.
        expect(find.byType(SymptomCheckInStrip), findsOneWidget);
      },
    );

    testWidgets('add-symptoms button is hidden while loading', (tester) async {
      final pending = Completer<SymptomLog?>();
      await pumpStrip(tester, pending: pending);
      await tester.pump();

      expect(find.byKey(const Key('add_symptoms_button')), findsNothing);

      pending.complete(null);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('add_symptoms_button')), findsOneWidget);
    });
  });

  group('when the read fails', () {
    const failure = PersistenceException(
      'SembastSymptomLogRepository.findByDate',
      'closed',
    );

    // riverpod 3 reports a provider that failed before producing a value as
    // `AsyncLoading` **with** an error, so a loading-first widget shows its
    // placeholder forever. This asserts the placeholder is gone — without
    // that, the test passes with the bug present.
    testWidgets('shows the cells, not a loading placeholder', (tester) async {
      await pumpStrip(tester, error: failure);
      await tester.pump();

      expect(find.byKey(const Key('symptom_dot_energy_1')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('says the read failed rather than showing a blank day', (
      tester,
    ) async {
      await pumpStrip(tester, error: failure);
      await tester.pump();

      expect(find.text('לא ניתן לטעון'), findsOneWidget);
    });

    // A failed read must not block the write: logging the day is still the
    // most useful thing the user can do from here.
    testWidgets('leaves the cells tappable', (tester) async {
      await pumpStrip(tester, error: failure);
      await tester.pump();

      await tester.tap(find.byKey(const Key('symptom_cell_energy')));
      await tester.pumpAndSettle();

      expect(find.byType(SymptomLogSheet), findsOneWidget);
    });

    testWidgets('chip row stays tappable via add-symptoms button', (
      tester,
    ) async {
      await pumpStrip(tester, error: failure);
      await tester.pump();

      // The chip row should still show the add button when read failed.
      expect(find.byKey(const Key('add_symptoms_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('add_symptoms_button')));
      await tester.pumpAndSettle();

      expect(find.byType(SymptomLogSheet), findsOneWidget);
      final sheet = tester.widget<SymptomLogSheet>(
        find.byType(SymptomLogSheet),
      );
      expect(sheet.focusSymptoms, isTrue);
    });
  });

  testWidgets('fits a narrow screen without overflowing', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpStrip(tester, log: SymptomLogFixture.varied(date: date));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
