import 'dart:async';

import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/diary/application/providers/symptom_providers.dart';
import 'package:fantastic/features/diary/application/symptom_logging_service.dart';
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
      expect(filledDots(tester, SymptomScale.physical), 4);
      expect(filledDots(tester, SymptomScale.mood), 5);
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
