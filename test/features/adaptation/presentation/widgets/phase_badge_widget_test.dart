import 'package:fantastic/core/constants/phase_copy.dart';
import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/adaptation/data/providers.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:fantastic/features/adaptation/domain/repositories/streak_repository.dart';
import 'package:fantastic/features/adaptation/presentation/widgets/phase_badge_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

class _MockStreakRepository extends Mock implements StreakRepository {}

void main() {
  late _MockStreakRepository repository;

  setUp(() {
    repository = _MockStreakRepository();
    when(repository.watch).thenAnswer((_) => Stream.value(null));
  });

  List<Override> overridesFor(StreakState? streak) {
    when(repository.watch).thenAnswer((_) => Stream.value(streak));
    return [streakRepositoryProvider.overrideWithValue(repository)];
  }

  Future<void> pumpBadge(WidgetTester tester, {StreakState? streak}) async {
    await pumpApp(
      tester,
      const PhaseBadgeWidget(),
      overrides: overridesFor(streak),
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

  Color badgeColour(WidgetTester tester) =>
      tester.widget<ActionChip>(find.byType(ActionChip)).backgroundColor!;

  group('label', () {
    testWidgets('shows the induction name', (tester) async {
      await pumpBadge(tester, streak: streakIn(AdaptationPhase.induction));

      expect(
        find.text(PhaseCopy.names[AdaptationPhase.induction]!),
        findsOneWidget,
      );
    });

    testWidgets('shows the deep ketosis name', (tester) async {
      await pumpBadge(tester, streak: streakIn(AdaptationPhase.deepKetosis));

      expect(
        find.text(PhaseCopy.names[AdaptationPhase.deepKetosis]!),
        findsOneWidget,
      );
    });

    // First launch is induction, not a blank chip.
    testWidgets('shows induction before anything is logged', (tester) async {
      await pumpBadge(tester);

      expect(
        find.text(PhaseCopy.names[AdaptationPhase.induction]!),
        findsOneWidget,
      );
    });
  });

  group('colour', () {
    // Theme tokens, not the raw hex the issue lists, so the badge tracks the
    // palette every other widget uses.
    test('each phase has its own colour', () {
      final colours = AdaptationPhase.values
          .map(PhaseBadgeWidget.colourFor)
          .toSet();

      expect(colours, hasLength(AdaptationPhase.values.length));
    });

    test('induction is the caution colour', () {
      expect(
        PhaseBadgeWidget.colourFor(AdaptationPhase.induction),
        AppTheme.caution,
      );
    });

    test('deep ketosis is the success colour', () {
      expect(
        PhaseBadgeWidget.colourFor(AdaptationPhase.deepKetosis),
        AppTheme.success,
      );
    });

    testWidgets('the chip is painted in the phase colour', (tester) async {
      await pumpBadge(tester, streak: streakIn(AdaptationPhase.deepKetosis));

      expect(badgeColour(tester), AppTheme.success);
    });
  });

  group('navigation', () {
    testWidgets('tapping opens the phase detail route', (tester) async {
      String? pushed;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          // Wrapped in a Scaffold: Chip needs a Material ancestor, which
          // pumpApp supplies elsewhere but a bare router route does not.
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: PhaseBadgeWidget()),
          ),
          GoRoute(
            path: PhaseBadgeWidget.route,
            builder: (_, state) {
              pushed = state.uri.toString();
              return const SizedBox.shrink();
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: overridesFor(streakIn(AdaptationPhase.induction)),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('phase_badge')));
      await tester.pumpAndSettle();

      expect(pushed, PhaseBadgeWidget.route);
    });
  });

  group('loading and failure', () {
    // A chip-shaped placeholder, not a collapse: the badge is one line in a
    // column and the dashboard would jump when the phase landed.
    testWidgets('holds a placeholder chip while loading', (tester) async {
      when(repository.watch).thenAnswer((_) => const Stream.empty());

      await pumpApp(
        tester,
        const PhaseBadgeWidget(),
        overrides: [streakRepositoryProvider.overrideWithValue(repository)],
      );
      await tester.pump();

      expect(find.byType(Chip), findsOneWidget);
      expect(find.byType(ActionChip), findsNothing);
    });

    // riverpod 3 reports a never-resolved failure as AsyncLoading *with* an
    // error, so a widget that checks isLoading first shows its placeholder
    // forever. Asserting the placeholder is absent is what catches that.
    testWidgets('shows nothing at all on failure', (tester) async {
      when(repository.watch)
          .thenAnswer((_) => Stream.error(Exception('store gone')));

      await pumpApp(
        tester,
        const PhaseBadgeWidget(),
        overrides: [streakRepositoryProvider.overrideWithValue(repository)],
      );
      await tester.pumpAndSettle();

      expect(find.byType(ActionChip), findsNothing);
      expect(find.byType(Chip), findsNothing);
      expect(find.text('...'), findsNothing);
    });
  });
}
