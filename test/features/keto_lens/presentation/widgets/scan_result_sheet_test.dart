import 'package:fantastic/features/diary/presentation/widgets/add_meal_bottom_sheet.dart';
import 'package:fantastic/features/keto_lens/domain/models/ingredient_verdict.dart';
import 'package:fantastic/features/keto_lens/domain/models/parsed_label.dart';
import 'package:fantastic/features/keto_lens/domain/models/scan_result.dart';
import 'package:fantastic/features/keto_lens/domain/models/verdict_badge.dart';
import 'package:fantastic/features/keto_lens/presentation/widgets/scan_result_sheet.dart';
import 'package:fantastic/features/keto_lens/presentation/widgets/verdict_badge_widget.dart';
import 'package:fantastic/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fantastic/features/keto_lens/domain/models/macro_verdict.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

import '../../../../fixtures/fixtures.dart';

void main() {
  final date = DateTime(2026, 9, 11);

  Future<void> pumpSheet(
    WidgetTester tester,
    ScanResult result, {
    VoidCallback? onRetry,
  }) => pumpApp(
    tester,
    ScanResultSheet(result: result, date: date, onRetry: onRetry),
  );

  group('ScanResultSheet on a successful scan', () {
    testWidgets('renders the badge and the flagged ingredients', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        const ScanSucceeded(
          macroVerdict: MacroVerdict.indeterminate(
            MacroIndeterminacy.noCarbRow,
          ),
          label: ParsedLabel(
            fatG: 24,
            netCarbsG: 60,
            proteinG: 6,
            ingredients: ['שמן קנולה', 'סוכר'],
          ),
          verdict: IngredientVerdict(
            badge: VerdictBadge.nonKeto,
            flaggedIngredients: ['שמן קנולה'],
          ),
        ),
      );

      expect(find.byType(VerdictBadgeWidget), findsOneWidget);
      expect(find.text('לא קטו'), findsOneWidget);
      expect(find.text('רכיבים בעייתיים'), findsOneWidget);
      expect(find.text('• שמן קנולה'), findsOneWidget);
    });

    testWidgets('renders the macro strip when there are macros', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        const ScanSucceeded(
          macroVerdict: MacroVerdict.indeterminate(
            MacroIndeterminacy.noCarbRow,
          ),
          label: ParsedLabel(fatG: 53.8, netCarbsG: 1.2, proteinG: 26),
          verdict: IngredientVerdict(badge: VerdictBadge.cleanKeto),
        ),
      );

      expect(find.text('53.8 ג'), findsOneWidget);
      expect(find.text('1.2 ג'), findsOneWidget);
      // A whole number loses its pointless .0 - the label said 26.
      expect(find.text('26 ג'), findsOneWidget);
      expect(find.text('שומן'), findsOneWidget);
      expect(find.text('פחמימות נטו'), findsOneWidget);
      expect(find.text('חלבון'), findsOneWidget);
    });

    testWidgets('every digit run is laid out left to right', (tester) async {
      // M3 handoff convention 6: without this "12.5" renders "5.21" inside
      // the RTL layout.
      await pumpSheet(
        tester,
        const ScanSucceeded(
          macroVerdict: MacroVerdict.indeterminate(
            MacroIndeterminacy.noCarbRow,
          ),
          label: ParsedLabel(fatG: 12.5),
          verdict: IngredientVerdict(badge: VerdictBadge.cleanKeto),
        ),
      );

      expect(
        tester.widget<Text>(find.text('12.5 ג')).textDirection,
        TextDirection.ltr,
      );
    });

    testWidgets('a macro the parser did not find shows as a dash', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        const ScanSucceeded(
          macroVerdict: MacroVerdict.indeterminate(
            MacroIndeterminacy.noCarbRow,
          ),
          label: ParsedLabel(fatG: 10),
          verdict: IngredientVerdict(badge: VerdictBadge.cleanKeto),
        ),
      );

      // Not "0 ג" - the label did not say zero, it said nothing.
      expect(find.text('—'), findsNWidgets(2));
    });

    testWidgets('hides the macro strip when nothing was extracted', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        const ScanSucceeded(
          macroVerdict: MacroVerdict.indeterminate(
            MacroIndeterminacy.noCarbRow,
          ),
          label: ParsedLabel(ingredients: ['מלח']),
          verdict: IngredientVerdict(badge: VerdictBadge.cleanKeto),
        ),
      );

      expect(find.text('שומן'), findsNothing);
      expect(find.textContaining('גודל המנה'), findsNothing);
    });

    testWidgets('hides the flagged section when nothing was flagged', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        const ScanSucceeded(
          macroVerdict: MacroVerdict.indeterminate(
            MacroIndeterminacy.noCarbRow,
          ),
          label: ParsedLabel(fatG: 100),
          verdict: IngredientVerdict(
            badge: VerdictBadge.cleanKeto,
            matchedCleanIngredients: ['שמן זית'],
          ),
        ),
      );

      expect(find.text('רכיבים בעייתיים'), findsNothing);
    });

    testWidgets('warns that the figures are the label, not the serving', (
      tester,
    ) async {
      // Nothing in the pipeline reads a serving size, and the prefill
      // would otherwise imply the whole pack was eaten.
      await pumpSheet(
        tester,
        const ScanSucceeded(
          macroVerdict: MacroVerdict.indeterminate(
            MacroIndeterminacy.noCarbRow,
          ),
          label: ParsedLabel(fatG: 24),
          verdict: IngredientVerdict(badge: VerdictBadge.cleanKeto),
        ),
      );

      expect(find.textContaining('גודל המנה'), findsOneWidget);
    });

    // Neither side carried evidence: the ingredients matched no rule and the
    // panel could not be read. Saying "no problematic ingredients found" here
    // is a statement made from nothing, which is the class of claim #306
    // exists to stop. The neutral chip is the honest answer.
    testWidgets('no evidence on either side gives the neutral chip', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        const ScanSucceeded(
          macroVerdict: MacroVerdict.indeterminate(
            MacroIndeterminacy.noCarbRow,
          ),
          label: ParsedLabel(ingredients: ['קמח חיטה']),
          verdict: IngredientVerdict(badge: VerdictBadge.cleanKeto),
        ),
      );

      expect(find.text('לא ניתן לקבוע — בדקו את התווית'), findsOneWidget);
      expect(find.text('קטו נקי'), findsNothing);
      expect(find.text('לא נמצאו רכיבים בעייתיים'), findsNothing);
    });

    // But when the panel *does* say something clean, the softened ingredient
    // copy stands: it is true, and it is now the weaker of two statements on
    // screen rather than the only one.
    testWidgets('a clean panel keeps the softened recognised-nothing copy', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        ScanSucceeded(
          macroVerdict: MacroVerdictFixture.keto(),
          label: const ParsedLabel(netCarbsG: 2, ingredients: ['קמח חיטה']),
          verdict: const IngredientVerdict(badge: VerdictBadge.cleanKeto),
        ),
      );

      expect(find.text('לא נמצאו רכיבים בעייתיים'), findsOneWidget);
    });

    // The reported defect, asserted where the user would see it: a bread at
    // 34.2 g of net carbs per 100 g rendered a green tick, because the verdict
    // never read a number.
    testWidgets('a clean ingredient list does not survive a red panel', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        ScanSucceeded(
          macroVerdict: MacroVerdictFixture.notKeto(),
          label: const ParsedLabel(netCarbsG: 34.2, ingredients: ['קמח מלא']),
          verdict: const IngredientVerdict(badge: VerdictBadge.cleanKeto),
        ),
      );

      expect(find.text('לא קטו'), findsOneWidget);
      expect(find.text('קטו נקי'), findsNothing);
      expect(
        find.textContaining('ממצים את תקציב הפחמימות היומי'),
        findsOneWidget,
      );
    });

    testWidgets('offers the add-to-diary button', (tester) async {
      await pumpSheet(
        tester,
        const ScanSucceeded(
          macroVerdict: MacroVerdict.indeterminate(
            MacroIndeterminacy.noCarbRow,
          ),
          label: ParsedLabel(fatG: 24),
          verdict: IngredientVerdict(badge: VerdictBadge.cleanKeto),
        ),
      );

      expect(find.byKey(const Key('add_to_diary_button')), findsOneWidget);
      expect(find.text('הוסף ליומן'), findsOneWidget);
    });
  });

  group('ScanResultSheet on a failed scan', () {
    testWidgets('shows no badge at all', (tester) async {
      // The whole point of the sealed result: #83 would have rendered a
      // green "clean keto" chip here.
      await pumpSheet(
        tester,
        const ScanFailed(reason: ScanFailureReason.notALabel),
      );

      expect(find.byType(VerdictBadgeWidget), findsNothing);
      expect(find.byKey(const Key('add_to_diary_button')), findsNothing);
    });

    testWidgets('names the reason and what to do about it', (tester) async {
      await pumpSheet(
        tester,
        const ScanFailed(reason: ScanFailureReason.noTextFound),
      );

      expect(
        find.text(ScanResultSheet.failureTitle(ScanFailureReason.noTextFound)),
        findsOneWidget,
      );
      expect(
        find.text(ScanResultSheet.failureAdvice(ScanFailureReason.noTextFound)),
        findsOneWidget,
      );
    });

    testWidgets('every reason has its own title and advice', (tester) async {
      final titles = ScanFailureReason.values
          .map(ScanResultSheet.failureTitle)
          .toSet();
      final advice = ScanFailureReason.values
          .map(ScanResultSheet.failureAdvice)
          .toSet();

      expect(titles, hasLength(ScanFailureReason.values.length));
      expect(advice, hasLength(ScanFailureReason.values.length));
    });

    testWidgets('offers a retry for a retryable failure', (tester) async {
      await pumpSheet(
        tester,
        const ScanFailed(reason: ScanFailureReason.recognitionFailed),
        onRetry: () {},
      );

      expect(find.byKey(const Key('retry_scan_button')), findsOneWidget);
    });

    testWidgets('offers no retry when scanning is impossible here', (
      tester,
    ) async {
      // A browser. Retrying cannot help, and a button that cannot work is
      // worse than no button.
      await pumpSheet(
        tester,
        const ScanFailed(reason: ScanFailureReason.unavailable),
        onRetry: () {},
      );

      expect(find.byKey(const Key('retry_scan_button')), findsNothing);
      expect(find.byKey(const Key('dismiss_scan_button')), findsOneWidget);
    });

    testWidgets('offers no retry when the caller supplied no callback', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        const ScanFailed(reason: ScanFailureReason.recognitionFailed),
      );

      expect(find.byKey(const Key('retry_scan_button')), findsNothing);
    });

    testWidgets('shows no spinner - a failure is not a loading state', (
      tester,
    ) async {
      // M3's lesson, applied to a plain widget: a failure state that looks
      // like a loading state is indistinguishable from a hang.
      await pumpSheet(
        tester,
        const ScanFailed(reason: ScanFailureReason.recognitionFailed),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('ScanResultSheet add to diary', () {
    testWidgets('opens the add-meal sheet prefilled with the macros', (
      tester,
    ) async {
      await tester.pumpWidget(
        _Host(
          result: const ScanSucceeded(
            macroVerdict: MacroVerdict.indeterminate(
              MacroIndeterminacy.noCarbRow,
            ),
            label: ParsedLabel(fatG: 24, netCarbsG: 60, proteinG: 6),
            verdict: IngredientVerdict(badge: VerdictBadge.cleanKeto),
          ),
          date: date,
        ),
      );
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add_to_diary_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AddMealBottomSheet), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('fat_field')))
            .controller
            ?.text,
        '24',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('carbs_field')))
            .controller
            ?.text,
        '60',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('protein_field')))
            .controller
            ?.text,
        '6',
      );
    });

    testWidgets('a macro the parser missed is left blank, not zero', (
      tester,
    ) async {
      await tester.pumpWidget(
        _Host(
          result: const ScanSucceeded(
            macroVerdict: MacroVerdict.indeterminate(
              MacroIndeterminacy.noCarbRow,
            ),
            label: ParsedLabel(fatG: 24),
            verdict: IngredientVerdict(badge: VerdictBadge.cleanKeto),
          ),
          date: date,
        ),
      );
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_to_diary_button')));
      await tester.pumpAndSettle();

      // Prefilling zero would have the user save a fat-free tahini
      // without noticing. Blank makes the form's validator ask.
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('protein_field')))
            .controller
            ?.text,
        isEmpty,
      );
    });

    testWidgets('closes the result sheet before opening the form', (
      tester,
    ) async {
      await tester.pumpWidget(
        _Host(
          result: const ScanSucceeded(
            macroVerdict: MacroVerdict.indeterminate(
              MacroIndeterminacy.noCarbRow,
            ),
            label: ParsedLabel(fatG: 24),
            verdict: IngredientVerdict(badge: VerdictBadge.cleanKeto),
          ),
          date: date,
        ),
      );
      await tester.tap(find.byKey(const Key('open_sheet')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_to_diary_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ScanResultSheet), findsNothing);
    });
  });
}

/// A screen that opens the sheet as a real modal route.
///
/// Needed because the add-to-diary path pops this sheet and opens another
/// over the navigator that hosted it; pumping the widget bare gives it no
/// route to pop.
class _Host extends StatelessWidget {
  const _Host({required this.result, required this.date});

  final ScanResult result;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('he'),
        supportedLocales: const [Locale('he'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const Key('open_sheet'),
                  onPressed: () =>
                      ScanResultSheet.show(context, result: result, date: date),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
