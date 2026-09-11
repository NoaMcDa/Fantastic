import 'package:fantastic/core/constants/phase_copy.dart';
import 'package:fantastic/features/adaptation/data/providers.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:fantastic/features/adaptation/domain/repositories/streak_repository.dart';
import 'package:fantastic/features/adaptation/presentation/screens/phase_detail_screen.dart';
import 'package:fantastic/features/adaptation/presentation/widgets/grace_period_banner.dart';
import 'package:fantastic/features/adaptation/presentation/widgets/phase_description_card.dart';
import 'package:fantastic/features/adaptation/presentation/widgets/streak_calendar_widget.dart';
import 'package:fantastic/features/dashboard/data/providers.dart';
import 'package:fantastic/features/dashboard/domain/repositories/daily_log_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../fixtures/fixtures.dart';

class _MockStreakRepository extends Mock implements StreakRepository {}

class _MockDailyLogRepository extends Mock implements DailyLogRepository {}

void main() {
  late _MockStreakRepository streakRepository;
  late _MockDailyLogRepository dailyLogRepository;

  setUp(() {
    streakRepository = _MockStreakRepository();
    dailyLogRepository = _MockDailyLogRepository();
    when(streakRepository.watch).thenAnswer((_) => Stream.value(null));
    when(dailyLogRepository.findAll).thenAnswer((_) async => []);
  });

  /// The screen is a `Scaffold` in its own right, so it is pumped directly
  /// rather than through `pumpApp`, which would nest two.
  Future<void> pumpScreen(WidgetTester tester, {StreakState? streak}) async {
    when(streakRepository.watch).thenAnswer((_) => Stream.value(streak));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          streakRepositoryProvider.overrideWithValue(streakRepository),
          dailyLogRepositoryProvider.overrideWithValue(dailyLogRepository),
        ],
        child: const MaterialApp(
          locale: Locale('he'),
          supportedLocales: [Locale('he'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: PhaseDetailScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// A streak long enough to sit in [phase].
  StreakState streakIn(AdaptationPhase phase) =>
      StreakStateFixture.withStreak(switch (phase) {
        AdaptationPhase.induction => 3,
        AdaptationPhase.fatAdapted => 12,
        AdaptationPhase.deepKetosis => 40,
      });

  group('the timeline', () {
    testWidgets('lists all three phases', (tester) async {
      await pumpScreen(tester, streak: streakIn(AdaptationPhase.induction));

      for (final phase in AdaptationPhase.values) {
        expect(find.text(PhaseCopy.names[phase]!), findsOneWidget);
      }
    });

    // A locked phase is shown, not hidden: seeing what is ahead is the point
    // of a roadmap.
    testWidgets('in induction, nothing is complete and two are locked', (
      tester,
    ) async {
      await pumpScreen(tester, streak: streakIn(AdaptationPhase.induction));

      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsNWidgets(2));
    });

    testWidgets('in fat adaptation, one is complete and one is locked', (
      tester,
    ) async {
      await pumpScreen(tester, streak: streakIn(AdaptationPhase.fatAdapted));

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('in deep ketosis, two are complete and none are locked', (
      tester,
    ) async {
      await pumpScreen(tester, streak: streakIn(AdaptationPhase.deepKetosis));

      expect(find.byIcon(Icons.check), findsNWidgets(2));
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsNothing);
    });

    // Three descriptions at once would bury the one that applies.
    testWidgets('only the active phase expands its description', (
      tester,
    ) async {
      await pumpScreen(tester, streak: streakIn(AdaptationPhase.fatAdapted));

      expect(find.byType(PhaseDescriptionCard), findsOneWidget);
      expect(
        tester
            .widget<PhaseDescriptionCard>(find.byType(PhaseDescriptionCard))
            .phase,
        AdaptationPhase.fatAdapted,
      );
    });

    // First launch: induction is the phase a new user is genuinely in.
    testWidgets('a null streak shows induction as active', (tester) async {
      await pumpScreen(tester);

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(
        tester
            .widget<PhaseDescriptionCard>(find.byType(PhaseDescriptionCard))
            .phase,
        AdaptationPhase.induction,
      );
    });

    // Day ranges are display copy; the highlighted step is driven by the
    // phase the service computed, never by these strings.
    testWidgets('each step shows its day range', (tester) async {
      await pumpScreen(tester, streak: streakIn(AdaptationPhase.induction));

      for (final phase in AdaptationPhase.values) {
        expect(find.text(PhaseCopy.dayRanges[phase]!), findsOneWidget);
      }
    });
  });

  group('grace period', () {
    testWidgets('the banner shows when the streak is at risk', (tester) async {
      await pumpScreen(
        tester,
        streak: StreakStateFixture.inGracePeriod(
          gracePeriodEnd: DateTime.now().add(const Duration(hours: 6)),
        ),
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    // Placed unconditionally and zero-height when idle, so the layout does
    // not shift when a grace period opens.
    testWidgets('the banner is present but empty when it is not', (
      tester,
    ) async {
      await pumpScreen(tester, streak: streakIn(AdaptationPhase.induction));

      expect(
        find.byType(GracePeriodBanner, skipOffstage: false),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });
  });

  testWidgets('shows the month calendar', (tester) async {
    await pumpScreen(tester, streak: streakIn(AdaptationPhase.induction));

    expect(find.byType(StreakCalendarWidget), findsOneWidget);
  });

  group('loading and failure', () {
    testWidgets('shows a spinner while the phase resolves', (tester) async {
      when(streakRepository.watch).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            streakRepositoryProvider.overrideWithValue(streakRepository),
            dailyLogRepositoryProvider.overrideWithValue(dailyLogRepository),
          ],
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: PhaseDetailScreen(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // Unlike the streak ring, this screen has nothing else on it — failing
    // silently would leave the user staring at a blank page.
    testWidgets('states the failure rather than rendering nothing', (
      tester,
    ) async {
      when(streakRepository.watch)
          .thenAnswer((_) => Stream.error(Exception('store gone')));

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            streakRepositoryProvider.overrideWithValue(streakRepository),
            dailyLogRepositoryProvider.overrideWithValue(dailyLogRepository),
          ],
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: PhaseDetailScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('לא ניתן לטעון את הנתונים'), findsOneWidget);
    });
  });

  testWidgets('lays out without overflowing a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpScreen(tester, streak: streakIn(AdaptationPhase.induction));

    expect(tester.takeException(), isNull);
  });
}
