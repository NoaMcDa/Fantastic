import 'dart:async';

import 'package:fantastic/core/constants/electrolyte_constants.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/dashboard/application/providers/daily_log_providers.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:fantastic/features/dashboard/presentation/widgets/electrolytes_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  final date = DailyLogFixture.defaultDate;

  /// A day meeting every phase-1 minimum, so nothing is short.
  DailyLog metDay() => DailyLogFixture.fixture(
    sodiumMg: ElectrolyteConstants.phase1SodiumMinMg,
    potassiumMg: ElectrolyteConstants.phase1PotassiumMinMg,
    magnesiumMg: ElectrolyteConstants.phase1MagnesiumMinMg,
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    DailyLog? log,
    AdaptationPhase phase = AdaptationPhase.induction,
  }) => pumpApp(
    tester,
    ElectrolytesCard(date: date, phase: phase),
    overrides: [todaysDailyLogProvider(date).overrideWith((ref) async => log)],
  );

  List<LinearProgressIndicator> gauges(WidgetTester tester) => tester
      .widgetList<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
      .toList();

  group('rendering', () {
    testWidgets('shows three gauges, expanded by default', (tester) async {
      await pumpCard(tester, log: metDay());
      await tester.pumpAndSettle();

      expect(gauges(tester), hasLength(3));
    });

    testWidgets('labels the three electrolytes in Hebrew', (tester) async {
      await pumpCard(tester, log: metDay());
      await tester.pumpAndSettle();

      expect(find.text('נתרן'), findsOneWidget);
      expect(find.text('אשלגן'), findsOneWidget);
      expect(find.text('מגנזיום'), findsOneWidget);
    });

    testWidgets('shows logged and target milligrams', (tester) async {
      await pumpCard(tester, log: DailyLogFixture.fixture(sodiumMg: 3200));
      await tester.pumpAndSettle();

      final target = ElectrolyteConstants.phase1SodiumMinMg.toStringAsFixed(0);
      expect(find.text('3200/$target מ״ג'), findsOneWidget);
    });

    testWidgets('fills each gauge to logged over target', (tester) async {
      await pumpCard(
        tester,
        log: DailyLogFixture.fixture(
          sodiumMg: ElectrolyteConstants.phase1SodiumMinMg / 2,
        ),
      );
      await tester.pumpAndSettle();

      expect(gauges(tester).first.value, closeTo(0.5, 0.001));
    });

    testWidgets('clamps an over-target gauge to full', (tester) async {
      await pumpCard(
        tester,
        log: DailyLogFixture.fixture(
          sodiumMg: ElectrolyteConstants.phase1SodiumMinMg * 5,
        ),
      );
      await tester.pumpAndSettle();

      expect(gauges(tester).first.value, 1.0);
    });
  });

  group('deficit state', () {
    testWidgets('a short electrolyte colours its gauge with the error colour', (
      tester,
    ) async {
      await pumpCard(tester, log: DailyLogFixture.fixture(sodiumMg: 0));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(ElectrolytesCard));
      expect(gauges(tester).first.color, Theme.of(context).colorScheme.error);
    });

    testWidgets('a met electrolyte does not use the error colour', (
      tester,
    ) async {
      await pumpCard(tester, log: metDay());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(ElectrolytesCard));
      expect(
        gauges(tester).first.color,
        isNot(Theme.of(context).colorScheme.error),
      );
    });

    // Colour alone would be invisible to a red/green colour-blind user, so the
    // deficit is also stated in words.
    testWidgets('a deficit is announced in text, not only in colour', (
      tester,
    ) async {
      await pumpCard(tester, log: DailyLogFixture.empty());
      await tester.pumpAndSettle();

      expect(find.text('חסרים אלקטרוליטים'), findsOneWidget);
    });

    testWidgets('no deficit means no warning text', (tester) async {
      await pumpCard(tester, log: metDay());
      await tester.pumpAndSettle();

      expect(find.text('חסרים אלקטרוליטים'), findsNothing);
    });
  });

  group('phase sensitivity', () {
    // The same intake is short under induction's higher targets and met later.
    testWidgets('the same day reads differently by phase', (tester) async {
      final log = DailyLogFixture.fixture(
        sodiumMg: ElectrolyteConstants.phase23SodiumMinMg,
        potassiumMg: ElectrolyteConstants.phase23PotassiumMinMg,
        magnesiumMg: ElectrolyteConstants.phase23MagnesiumMinMg,
      );

      await pumpCard(tester, log: log);
      await tester.pumpAndSettle();
      expect(find.text('חסרים אלקטרוליטים'), findsOneWidget);

      await pumpCard(tester, log: log, phase: AdaptationPhase.deepKetosis);
      await tester.pumpAndSettle();
      expect(find.text('חסרים אלקטרוליטים'), findsNothing);
    });

    testWidgets('defaults to induction, the safest assumption', (tester) async {
      // Induction carries the highest targets, so defaulting to it over-warns
      // rather than under-warns while M3's phase provider does not exist.
      await pumpApp(
        tester,
        ElectrolytesCard(date: date),
        overrides: [
          todaysDailyLogProvider(date).overrideWith(
            (ref) async => DailyLogFixture.fixture(
              sodiumMg: ElectrolyteConstants.phase23SodiumMinMg,
            ),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('חסרים אלקטרוליטים'), findsOneWidget);
    });
  });

  group('expand and collapse', () {
    testWidgets('tapping the chevron hides the gauges', (tester) async {
      await pumpCard(tester, log: metDay());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('כווץ'));
      await tester.pumpAndSettle();

      // `hitTestable`, not a bare finder: AnimatedCrossFade keeps both
      // children mounted and collapses the hidden one, so `find.text` still
      // matches it. What matters is that it is no longer visible or reachable.
      expect(find.text('נתרן').hitTestable(), findsNothing);
    });

    testWidgets('tapping again brings them back', (tester) async {
      await pumpCard(tester, log: metDay());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('כווץ'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('הרחב'));
      await tester.pumpAndSettle();

      expect(find.text('נתרן').hitTestable(), findsOneWidget);
    });

    // The header stays, so the card does not vanish when collapsed.
    testWidgets('the title survives collapsing', (tester) async {
      await pumpCard(tester, log: metDay());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('כווץ'));
      await tester.pumpAndSettle();

      expect(find.text('אלקטרוליטים'), findsOneWidget);
    });
  });

  group('non-data states', () {
    testWidgets('renders nothing when the day has no log', (tester) async {
      await pumpCard(tester);
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('renders nothing while loading', (tester) async {
      await pumpApp(
        tester,
        ElectrolytesCard(date: date),
        overrides: [
          todaysDailyLogProvider(date)
              .overrideWith((ref) => Completer<DailyLog?>().future),
        ],
      );
      await tester.pump();

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('renders nothing when the read fails', (tester) async {
      await pumpApp(
        tester,
        ElectrolytesCard(date: date),
        overrides: [
          todaysDailyLogProvider(date)
              .overrideWith((ref) async => throw Exception('disk gone')),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsNothing);
    });
  });

  testWidgets('lays out without overflowing a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpCard(tester, log: DailyLogFixture.empty());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
