import 'dart:async';

import 'package:fantastic/core/constants/add_meal_copy.dart';
import 'package:fantastic/core/constants/menu_copy.dart';
import 'package:fantastic/core/router/app_router.dart';
import 'package:fantastic/features/menu/data/providers.dart';
import 'package:fantastic/features/menu/domain/models/menu_analysis.dart';
import 'package:fantastic/features/menu/domain/models/menu_analysis_failure_reason.dart';
import 'package:fantastic/features/menu/domain/services/menu_analyzer.dart';
import 'package:fantastic/features/menu/presentation/screens/menu_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

/// A [MenuAnalyzer] that returns whatever the test put in it.
///
/// The interface, never the concrete `RemoteMenuAnalyzer` — the DoD item
/// this screen must hold, and the only way to reach every failure reason
/// without a network.
class _FakeMenuAnalyzer implements MenuAnalyzer {
  MenuAnalysis result = MenuAnalysisFixture.clean();
  Object? error;

  String? capturedText;
  List<String> capturedImagePaths = const [];

  /// Held open so a test can observe the analysing state before it
  /// resolves — the same technique `camera_screen_test.dart`'s
  /// `captureGate` uses for the same reason: a fake that resolves inside one
  /// microtask drain never renders the intermediate frame.
  Completer<void>? gate;

  @override
  Future<MenuAnalysis> analyse({
    String? text,
    List<String> imagePaths = const [],
    void Function(int page, int of)? onPage,
  }) async {
    capturedText = text;
    capturedImagePaths = imagePaths;
    await gate?.future;
    if (error != null) {
      throw error!;
    }
    return result;
  }
}

void main() {
  late _FakeMenuAnalyzer analyzer;

  setUp(() {
    analyzer = _FakeMenuAnalyzer();
  });

  List<Override> overrides() => [
    menuAnalyzerProvider.overrideWithValue(analyzer),
  ];

  Future<void> pumpScreen(WidgetTester tester) async {
    await pumpApp(tester, const MenuScannerScreen(), overrides: overrides());
    await tester.pumpAndSettle();
  }

  Future<void> typeAndAnalyse(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('menu_text_field')), text);
    await tester.pump();
    await tester.tap(find.byKey(const Key('menu_analyse_button')));
    await tester.pumpAndSettle();
  }

  group('input', () {
    testWidgets('the analyse button is disabled on blank text', (tester) async {
      await pumpScreen(tester);

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('menu_analyse_button')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('typing enables the analyse button', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(
        find.byKey(const Key('menu_text_field')),
        'סלט יווני',
      );
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('menu_analyse_button')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('the photo tab is a stub, with no analyse button', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text(MenuCopy.photoPagesTab));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('menu_photo_stub')), findsOneWidget);
      expect(find.text(MenuCopy.photoTabComingSoon), findsOneWidget);
      expect(find.byKey(const Key('menu_text_field')), findsNothing);
      expect(find.byKey(const Key('menu_analyse_button')), findsNothing);
    });
  });

  group('analysing', () {
    testWidgets('calls the analyser with the pasted text and no image paths', (
      tester,
    ) async {
      await pumpScreen(tester);

      await typeAndAnalyse(tester, 'המבורגר, סלט קיסר');

      expect(analyzer.capturedText, 'המבורגר, סלט קיסר');
      expect(analyzer.capturedImagePaths, isEmpty);
    });

    testWidgets('shows a labelled indicator and keeps the pasted text', (
      tester,
    ) async {
      analyzer.gate = Completer<void>();
      await pumpScreen(tester);

      await tester.enterText(
        find.byKey(const Key('menu_text_field')),
        'פסטה ברוטב שמנת',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('menu_analyse_button')));
      await tester.pump();

      expect(find.byKey(const Key('menu_analysing')), findsOneWidget);
      expect(find.text(MenuCopy.analysingLabel), findsOneWidget);
      expect(find.text('פסטה ברוטב שמנת'), findsOneWidget);

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('menu_analyse_button')),
      );
      expect(button.onPressed, isNull);

      analyzer.gate!.complete();
      await tester.pumpAndSettle();
    });
  });

  group('result', () {
    testWidgets('a MenuAnalysed renders MenuResultView', (tester) async {
      analyzer.result = MenuAnalysisFixture.analysed();
      await pumpScreen(tester);

      await typeAndAnalyse(tester, 'תפריט מסעדה');

      expect(find.byKey(const Key('menu_legend')), findsOneWidget);
      expect(find.byKey(const Key('menu_analysing')), findsNothing);
    });

    testWidgets('נתחו תפריט אחר returns to input with the pasted text intact', (
      tester,
    ) async {
      analyzer.result = MenuAnalysisFixture.clean();
      await pumpScreen(tester);

      await typeAndAnalyse(tester, 'תפריט מסעדה');
      await tester.tap(find.byKey(const Key('menu_analyse_another_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('menu_text_field')), findsOneWidget);
      final field = tester.widget<TextField>(
        find.byKey(const Key('menu_text_field')),
      );
      expect(field.controller!.text, 'תפריט מסעדה');
      expect(find.byKey(const Key('menu_legend')), findsNothing);
    });
  });

  group('failure headlines — one per reachable reason', () {
    Future<void> failWith(
      WidgetTester tester,
      MenuAnalysisFailureReason reason,
    ) async {
      analyzer.result = MenuAnalysisFixture.failed(reason: reason);
      await pumpScreen(tester);
      await typeAndAnalyse(tester, 'תפריט לבדיקה');
    }

    testWidgets('ocrUnavailable', (tester) async {
      await failWith(tester, MenuAnalysisFailureReason.ocrUnavailable);
      expect(find.text(MenuCopy.failedOcrUnavailableHeadline), findsOneWidget);
    });

    testWidgets('noTextFound', (tester) async {
      await failWith(tester, MenuAnalysisFailureReason.noTextFound);
      expect(find.text(MenuCopy.failedNoTextFoundHeadline), findsOneWidget);
    });

    testWidgets('notConfigured', (tester) async {
      await failWith(tester, MenuAnalysisFailureReason.notConfigured);
      expect(find.text(MenuCopy.failedNotConfiguredHeadline), findsOneWidget);
    });

    testWidgets('offline', (tester) async {
      await failWith(tester, MenuAnalysisFailureReason.offline);
      expect(find.text(MenuCopy.failedOfflineHeadline), findsOneWidget);
    });

    testWidgets('rateLimited', (tester) async {
      await failWith(tester, MenuAnalysisFailureReason.rateLimited);
      expect(find.text(MenuCopy.failedRateLimitedHeadline), findsOneWidget);
      // Research §7: the quota line #321 already shows, reused rather than
      // restated.
      expect(find.text(AddMealCopy.rateLimitDetail), findsOneWidget);
    });

    testWidgets('unauthorised', (tester) async {
      await failWith(tester, MenuAnalysisFailureReason.unauthorised);
      expect(find.text(MenuCopy.failedUnauthorisedHeadline), findsOneWidget);
    });

    testWidgets('badResponse', (tester) async {
      await failWith(tester, MenuAnalysisFailureReason.badResponse);
      expect(find.text(MenuCopy.failedBadResponseHeadline), findsOneWidget);
    });

    testWidgets('noDishesFound', (tester) async {
      await failWith(tester, MenuAnalysisFailureReason.noDishesFound);
      expect(find.text(MenuCopy.failedNoDishesFoundHeadline), findsOneWidget);
    });
  });

  group('failure retry offer', () {
    testWidgets('ocrUnavailable offers no retry', (tester) async {
      analyzer.result = MenuAnalysisFixture.failed(
        reason: MenuAnalysisFailureReason.ocrUnavailable,
      );
      await pumpScreen(tester);
      await typeAndAnalyse(tester, 'תפריט');

      expect(find.byKey(const Key('menu_retry_button')), findsNothing);
    });

    testWidgets('offline offers a retry', (tester) async {
      analyzer.result = MenuAnalysisFixture.failed(
        reason: MenuAnalysisFailureReason.offline,
      );
      await pumpScreen(tester);
      await typeAndAnalyse(tester, 'תפריט');

      expect(find.byKey(const Key('menu_retry_button')), findsOneWidget);
    });

    testWidgets('badResponse offers a retry', (tester) async {
      analyzer.result = MenuAnalysisFixture.failed(
        reason: MenuAnalysisFailureReason.badResponse,
      );
      await pumpScreen(tester);
      await typeAndAnalyse(tester, 'תפריט');

      expect(find.byKey(const Key('menu_retry_button')), findsOneWidget);
    });

    testWidgets('notConfigured and unauthorised offer Profile', (tester) async {
      analyzer.result = MenuAnalysisFixture.failed(
        reason: MenuAnalysisFailureReason.notConfigured,
      );
      await pumpScreen(tester);
      await typeAndAnalyse(tester, 'תפריט');

      expect(find.byKey(const Key('menu_profile_button')), findsOneWidget);
      expect(find.byKey(const Key('menu_retry_button')), findsNothing);
    });

    testWidgets('tapping Profile navigates to the profile tab', (tester) async {
      analyzer.result = MenuAnalysisFixture.failed(
        reason: MenuAnalysisFailureReason.unauthorised,
      );
      String? pushed;
      final router = GoRouter(
        initialLocation: '/lens/menu',
        routes: [
          GoRoute(
            path: '/lens/menu',
            builder: (_, _) => const MenuScannerScreen(),
          ),
          GoRoute(
            path: kProfilePath,
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
          overrides: overrides(),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await typeAndAnalyse(tester, 'תפריט');
      await tester.tap(find.byKey(const Key('menu_profile_button')));
      await tester.pumpAndSettle();

      expect(pushed, kProfilePath);
    });
  });

  group('failure safety', () {
    testWidgets('renders no progress indicator', (tester) async {
      analyzer.result = MenuAnalysisFixture.failed(
        reason: MenuAnalysisFailureReason.badResponse,
      );
      await pumpScreen(tester);

      await typeAndAnalyse(tester, 'תפריט');

      expect(find.byKey(const Key('menu_analysing')), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('the pasted text survives every failure', (tester) async {
      analyzer.result = MenuAnalysisFixture.failed(
        reason: MenuAnalysisFailureReason.noDishesFound,
      );
      await pumpScreen(tester);

      await typeAndAnalyse(tester, 'טקסט תפריט שהודבק');

      final field = tester.widget<TextField>(
        find.byKey(const Key('menu_text_field')),
      );
      expect(field.controller!.text, 'טקסט תפריט שהודבק');
    });

    testWidgets(
      'an analyser that throws is handled without the screen crashing',
      (tester) async {
        analyzer.error = StateError('a contract violation');
        await pumpScreen(tester);

        await typeAndAnalyse(tester, 'תפריט');

        expect(tester.takeException(), isNull);
        expect(find.text(MenuCopy.failedBadResponseHeadline), findsOneWidget);
      },
    );
  });

  group('MenuScannerScreen.headlineFor / adviceFor', () {
    test('every reason has a headline and advice string', () {
      for (final reason in MenuAnalysisFailureReason.values) {
        expect(MenuScannerScreen.headlineFor(reason), isNotEmpty);
        expect(MenuScannerScreen.adviceFor(reason), isNotEmpty);
      }
    });
  });
}
