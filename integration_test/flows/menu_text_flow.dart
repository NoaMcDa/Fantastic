import 'package:fantastic/core/constants/menu_copy.dart';
import 'package:fantastic/core/router/app_router.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/domain/models/estimation_settings.dart';
import 'package:fantastic/features/menu/data/providers.dart';
import 'package:fantastic/features/menu/domain/models/menu_analysis.dart';
import 'package:fantastic/features/menu/domain/models/menu_analysis_failure_reason.dart';
import 'package:fantastic/features/menu/domain/services/menu_analyzer.dart';
import 'package:fantastic/features/menu/presentation/screens/menu_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/fixtures/fixtures.dart';
import '../helpers/app_harness.dart';

/// #366 — the pasted-text half of the two flows this milestone closes on.
///
/// `MenuAnalyzer` is faked here, one layer above the boundary #366's photo
/// flow exercises for real — this flow's job is the screens: the route, the
/// entry chip, the verdict grouping, the failure copy. `menu_photo_flow.dart`
/// is where the real analyser, the real OCR loop, the real prompt and the
/// real parser are proven end to end.
class _FlowMenuAnalyzer implements MenuAnalyzer {
  MenuAnalysis result = MenuAnalysisFixture.analysed(unreadPages: const []);

  @override
  Future<MenuAnalysis> analyse({
    String? text,
    List<String> imagePaths = const [],
    void Function(int page, int of)? onPage,
  }) async => result;
}

void main() {
  testWidgets(
    'pasting a menu analyses it into groups, and every failure is handled',
    (tester) async {
      final analyzer = _FlowMenuAnalyzer();
      final app = await bootApp(
        onboarded: true,
        overrides: [menuAnalyzerProvider.overrideWithValue(analyzer)],
      );
      // Realistic boot state, per the issue's plan — inert for this flow's
      // own assertions, since the fake above replaces the whole chain that
      // would otherwise read it, but written through the real repository so
      // the app is not left in a state no real user reaches.
      await app.container
          .read(estimationSettingsRepositoryProvider)
          .save(
            const EstimationSettings(
              apiKey: 'sk-e2e-flow-key',
              consentAccepted: true,
            ),
          );
      await pumpApp(tester, app);

      // 2. The lens tab's `תפריט` chip is the only door in.
      await goToTab(tester, 'tab_lens');
      await tapAt(tester, find.byKey(const Key('lens_mode_menu')));

      expect(find.byType(MenuScannerScreen), findsOneWidget);
      // The lens tab stays lit — `/lens/menu` is a child route of `/lens`,
      // not a sibling, and `AppShell`'s prefix match depends on that.
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        kTabPaths.indexOf('/lens'),
      );

      // 3. Paste and analyse.
      await enterInto(tester, 'menu_text_field', HebrewMenuFixture.grill);
      await tapAt(tester, find.byKey(const Key('menu_analyse_button')));

      // 4. Green before yellow before red.
      expect(find.byKey(const Key('menu_legend')), findsOneWidget);
      final greenTop = tester
          .getTopLeft(find.byKey(const Key('menu_orderAsIs_heading')))
          .dy;
      final yellowTop = tester
          .getTopLeft(find.byKey(const Key('menu_modifiable_heading')))
          .dy;
      expect(
        greenTop,
        lessThan(yellowTop),
        reason: 'order-as-is dishes must render above modifiable ones',
      );

      // Every widget below here is a `SliverList` child, which — even from
      // a `SliverChildListDelegate` — has no element at all until the
      // viewport reaches it (`design/m5_handoff.md`), so each is scrolled
      // to before it is referenced rather than assumed to already be built.
      final scrollable = find.byType(Scrollable).last;

      // 5. Expanding a yellow card reveals its why and its instruction.
      final yellowDishName = AnalysedDishFixture.modifiable().name;
      await tester.scrollUntilVisible(
        find.byKey(Key('dish_card_$yellowDishName')),
        200,
        scrollable: scrollable,
      );
      await settle(tester);
      await tapAt(tester, find.byKey(Key('dish_card_$yellowDishName')));
      expect(find.byKey(Key('dish_why_$yellowDishName')), findsOneWidget);
      expect(
        find.byKey(Key('dish_modification_$yellowDishName')),
        findsOneWidget,
      );

      final redDishName = AnalysedDishFixture.nonKeto().name;
      await tester.scrollUntilVisible(
        find.byKey(const Key('menu_red_header')),
        200,
        scrollable: scrollable,
      );
      await settle(tester);
      expect(
        find.descendant(
          of: find.byKey(const Key('menu_red_header')),
          matching: find.text('(1)'),
        ),
        findsOneWidget,
        reason: 'the red header shows its count even while collapsed',
      );
      expect(
        find.byKey(Key('dish_card_$redDishName')),
        findsNothing,
        reason: 'a collapsed red group must not build its dish cards',
      );
      await tapAt(tester, find.byKey(const Key('menu_red_header')));
      expect(find.byKey(Key('dish_card_$redDishName')), findsOneWidget);

      // Expanding the red group pushed the unclassified section further
      // down still — scroll again rather than assume it is already in view.
      await tester.scrollUntilVisible(
        find.byKey(const Key('menu_unclassified')),
        200,
        scrollable: scrollable,
      );
      await settle(tester);
      expect(find.byKey(const Key('menu_unclassified')), findsOneWidget);
      expect(find.text('מנת היום'), findsOneWidget);

      // 6. offline — a headline, no progress indicator, the pasted text
      // still in the field.
      await tapAt(tester, find.byKey(const Key('menu_analyse_another_button')));
      expect(fieldText(tester, 'menu_text_field'), HebrewMenuFixture.grill);

      analyzer.result = const MenuAnalysisFailed(
        reason: MenuAnalysisFailureReason.offline,
      );
      await tapAt(tester, find.byKey(const Key('menu_analyse_button')));

      expect(find.text(MenuCopy.failedOfflineHeadline), findsOneWidget);
      expect(find.byKey(const Key('menu_analysing')), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(fieldText(tester, 'menu_text_field'), HebrewMenuFixture.grill);

      // 7. notConfigured — reached through offline's own retry, since
      // #360's disclosure sentence is a different widget this issue does
      // not depend on (see #366's amendment comment). The headline names no
      // key being configured, and the way out is Profile, not a retry.
      analyzer.result = const MenuAnalysisFailed(
        reason: MenuAnalysisFailureReason.notConfigured,
      );
      await tapAt(tester, find.byKey(const Key('menu_retry_button')));

      expect(find.text(MenuCopy.failedNotConfiguredHeadline), findsOneWidget);
      expect(find.byKey(const Key('menu_profile_button')), findsOneWidget);
      expect(find.byKey(const Key('menu_retry_button')), findsNothing);
    },
  );
}
