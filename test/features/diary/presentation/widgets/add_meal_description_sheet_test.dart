import 'dart:async';

import 'package:fantastic/core/constants/add_meal_copy.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/domain/models/estimate_failure_reason.dart';
import 'package:fantastic/features/diary/domain/models/estimated_item.dart';
import 'package:fantastic/features/diary/domain/models/macro_source.dart';
import 'package:fantastic/features/diary/domain/models/meal_estimate.dart';
import 'package:fantastic/features/diary/domain/services/macro_estimator.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_bottom_sheet.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_description_sheet.dart';
import 'package:fantastic/features/diary/presentation/widgets/estimate_review_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class _MockEstimator extends Mock implements MacroEstimator {}

void main() {
  late _MockEstimator estimator;

  final date = DateTime(2026, 9, 11);
  const description = '200 גרם חזה עוף, 2 ביצים, כף שמן זית';

  const egg = EstimatedItem(
    name: 'ביצה',
    grams: 100,
    fatG: 10,
    netCarbsG: 1,
    proteinG: 13,
  );
  const chicken = EstimatedItem(
    name: 'חזה עוף',
    grams: 200,
    fatG: 6,
    netCarbsG: 0,
    proteinG: 46,
  );

  setUp(() => estimator = _MockEstimator());

  void answers(MealEstimate result) => when(
    () => estimator.estimate(
      description: any(named: 'description'),
      imagePath: any(named: 'imagePath'),
    ),
  ).thenAnswer((_) async => result);

  /// Pumps a button that opens the sheet, mirroring how `AddMealFab` does.
  Future<void> pumpSheet(WidgetTester tester) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Center(
          child: TextButton(
            key: const Key('open'),
            onPressed: () => AddMealDescriptionSheet.show(context, date: date),
            child: const Text('open'),
          ),
        ),
      ),
      overrides: [macroEstimatorProvider.overrideWithValue(estimator)],
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(
      find.byKey(const Key('meal_description_field')),
      text,
    );
    await tester.pumpAndSettle();
  }

  Future<void> estimate(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('estimate_button')));
    await tester.pumpAndSettle();
  }

  bool enabled(WidgetTester tester, String key) =>
      tester.widget<ButtonStyleButton>(find.byKey(Key(key))).onPressed != null;

  group('the estimate button', () {
    testWidgets('is disabled on an empty field', (tester) async {
      await pumpSheet(tester);

      expect(enabled(tester, 'estimate_button'), isFalse);
    });

    testWidgets('is disabled on whitespace alone', (tester) async {
      await pumpSheet(tester);
      await type(tester, '    ');

      expect(enabled(tester, 'estimate_button'), isFalse);
    });

    testWidgets('enables once something is typed', (tester) async {
      await pumpSheet(tester);
      await type(tester, description);

      expect(enabled(tester, 'estimate_button'), isTrue);
    });

    testWidgets('is disabled while an estimate is in flight', (tester) async {
      final completer = Completer<MealEstimate>();
      when(
        () => estimator.estimate(
          description: any(named: 'description'),
          imagePath: any(named: 'imagePath'),
        ),
      ).thenAnswer((_) => completer.future);
      await pumpSheet(tester);
      await type(tester, description);

      await tester.tap(find.byKey(const Key('estimate_button')));
      await tester.pump();

      expect(enabled(tester, 'estimate_button'), isFalse);
      expect(find.byKey(const Key('estimate_progress')), findsOneWidget);
      // The typed text stays on screen throughout.
      expect(find.text(description), findsOneWidget);

      completer.complete(const EstimateSucceeded(items: [egg]));
      await tester.pumpAndSettle();
    });

    testWidgets('sends what was typed to the estimator', (tester) async {
      answers(const EstimateSucceeded(items: [egg]));
      await pumpSheet(tester);
      await type(tester, description);
      await estimate(tester);

      verify(() => estimator.estimate(description: description)).called(1);
    });
  });

  group('a successful estimate', () {
    testWidgets('renders the review list', (tester) async {
      answers(const EstimateSucceeded(items: [egg, chicken]));
      await pumpSheet(tester);
      await type(tester, description);
      await estimate(tester);

      expect(find.byType(EstimateReviewList), findsOneWidget);
      expect(find.text('ביצה'), findsOneWidget);
      expect(find.text('חזה עוף'), findsOneWidget);
      expect(find.byKey(const Key('estimate_progress')), findsNothing);
    });

    testWidgets('shows unidentified tokens beside the items', (tester) async {
      answers(const EstimateSucceeded(items: [egg], unidentified: ['לחם']));
      await pumpSheet(tester);
      await type(tester, description);
      await estimate(tester);

      expect(find.text('לחם'), findsOneWidget);
      expect(find.text(AddMealCopy.unidentifiedMarker), findsOneWidget);
    });

    // #257's rule made visible: the total shown is the total that will be
    // logged.
    testWidgets('removing an item recomputes the total', (tester) async {
      answers(const EstimateSucceeded(items: [egg, chicken]));
      await pumpSheet(tester);
      await type(tester, description);
      await estimate(tester);
      expect(find.text('שומן 16 · פחמימות 1 · חלבון 59'), findsOneWidget);

      await tester.tap(find.byKey(const Key('estimate_item_remove_1')));
      await tester.pumpAndSettle();

      expect(find.text('שומן 10 · פחמימות 1 · חלבון 13'), findsOneWidget);
      expect(find.text('חזה עוף'), findsNothing);
    });

    testWidgets('removing every item disables confirm', (tester) async {
      answers(const EstimateSucceeded(items: [egg]));
      await pumpSheet(tester);
      await type(tester, description);
      await estimate(tester);

      await tester.tap(find.byKey(const Key('estimate_item_remove_0')));
      await tester.pumpAndSettle();

      // Rather than handing over a zero-macro meal, which saves without
      // complaint and is invisible in the day's totals.
      expect(enabled(tester, 'estimate_confirm_button'), isFalse);
    });
  });

  group('the hand-off', () {
    Future<AddMealBottomSheet> confirmAndRead(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('estimate_confirm_button')));
      await tester.pumpAndSettle();
      return tester.widget<AddMealBottomSheet>(find.byType(AddMealBottomSheet));
    }

    testWidgets('opens the manual form with the reviewed totals', (
      tester,
    ) async {
      answers(const EstimateSucceeded(items: [egg, chicken]));
      await pumpSheet(tester);
      await type(tester, description);
      await estimate(tester);

      final sheet = await confirmAndRead(tester);
      expect(sheet.initialFatG, 16);
      expect(sheet.initialNetCarbsG, 1);
      expect(sheet.initialProteinG, 59);
      expect(sheet.date, date);
    });

    testWidgets('marks the meal as estimated from text', (tester) async {
      answers(const EstimateSucceeded(items: [egg]));
      await pumpSheet(tester);
      await type(tester, description);
      await estimate(tester);

      expect(
        (await confirmAndRead(tester)).source,
        MacroSource.estimatedFromText,
      );
    });

    testWidgets('hands over the total after a removal, not before', (
      tester,
    ) async {
      answers(const EstimateSucceeded(items: [egg, chicken]));
      await pumpSheet(tester);
      await type(tester, description);
      await estimate(tester);
      await tester.tap(find.byKey(const Key('estimate_item_remove_1')));
      await tester.pumpAndSettle();

      expect((await confirmAndRead(tester)).initialFatG, 10);
    });

    testWidgets('carries the description into the name field', (tester) async {
      answers(const EstimateSucceeded(items: [egg]));
      await pumpSheet(tester);
      await type(tester, description);
      await estimate(tester);

      expect((await confirmAndRead(tester)).initialName, description);
    });

    // Trimmed for the *name* only; the estimate runs on the whole text.
    testWidgets('trims a long description to the name field maximum', (
      tester,
    ) async {
      final long = 'א' * 250;
      answers(const EstimateSucceeded(items: [egg]));
      await pumpSheet(tester);
      await type(tester, long);
      await estimate(tester);

      verify(() => estimator.estimate(description: long)).called(1);
      expect(
        (await confirmAndRead(tester)).initialName!.length,
        AddMealBottomSheet.maxNameLength,
      );
    });

    // `design/m8_preflight.md` recorded `0.17999999999999988` in a field from
    // the scan prefill. `GramsText.format` is what stops it reaching one.
    testWidgets('a noisy total reaches the field as 0.2', (tester) async {
      answers(
        const EstimateSucceeded(
          items: [
            EstimatedItem(
              name: 'שמן',
              grams: 2,
              fatG: 0.1,
              netCarbsG: 0.09,
              proteinG: 0.08999999999999999,
            ),
          ],
        ),
      );
      await pumpSheet(tester);
      await type(tester, description);
      await estimate(tester);
      await tester.tap(find.byKey(const Key('estimate_confirm_button')));
      await tester.pumpAndSettle();

      final field = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const Key('protein_field')),
          matching: find.byType(EditableText),
        ),
      );
      expect(field.controller.text, '0.1');
      expect(field.controller.text, isNot(contains('999')));
    });
  });

  group('failures', () {
    // Per reason, not as a group: "turn it on in settings" and "you are
    // offline" are not the same problem.
    for (final (reason, headline) in <(EstimateFailureReason, String)>[
      (EstimateFailureReason.notConfigured, AddMealCopy.failedNotConfigured),
      (EstimateFailureReason.offline, AddMealCopy.failedOffline),
      (EstimateFailureReason.rateLimited, AddMealCopy.failedRateLimited),
      (EstimateFailureReason.unauthorised, AddMealCopy.failedUnauthorised),
      (EstimateFailureReason.badResponse, AddMealCopy.failedBadResponse),
      (
        EstimateFailureReason.nothingIdentified,
        AddMealCopy.failedNothingIdentified,
      ),
    ]) {
      testWidgets('${reason.name} has its own headline', (tester) async {
        answers(EstimateFailed(reason: reason));
        await pumpSheet(tester);
        await type(tester, description);
        await estimate(tester);

        expect(find.text(headline), findsOneWidget);
        // An error, never a spinner (`design/m3_handoff.md`).
        expect(find.byKey(const Key('estimate_progress')), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('${reason.name} offers manual entry', (tester) async {
        answers(EstimateFailed(reason: reason));
        await pumpSheet(tester);
        await type(tester, description);
        await estimate(tester);

        expect(find.byKey(const Key('estimate_manual_button')), findsOneWidget);
      });
    }

    testWidgets('the typed text survives a failure', (tester) async {
      answers(const EstimateFailed(reason: EstimateFailureReason.offline));
      await pumpSheet(tester);
      await type(tester, description);
      await estimate(tester);

      expect(find.text(description), findsOneWidget);
    });

    testWidgets('taking manual entry carries the typed text over', (
      tester,
    ) async {
      answers(const EstimateFailed(reason: EstimateFailureReason.offline));
      await pumpSheet(tester);
      await type(tester, description);
      await estimate(tester);

      await tester.tap(find.byKey(const Key('estimate_manual_button')));
      await tester.pumpAndSettle();

      final sheet = tester.widget<AddMealBottomSheet>(
        find.byType(AddMealBottomSheet),
      );
      expect(sheet.initialName, description);
      // No macros were estimated, so none are prefilled — null is not zero.
      expect(sheet.initialFatG, isNull);
      // And the meal is not labelled an estimate, because none survived.
      expect(sheet.source, MacroSource.manual);
    });

    // Retrying a rejected key would fail the same way; a button that cannot
    // help is worse than no button.
    testWidgets('a key problem offers Profile rather than retry', (
      tester,
    ) async {
      answers(
        const EstimateFailed(reason: EstimateFailureReason.notConfigured),
      );
      await pumpSheet(tester);
      await type(tester, description);
      await estimate(tester);

      expect(find.byKey(const Key('estimate_profile_button')), findsOneWidget);
      expect(find.byKey(const Key('estimate_retry_button')), findsNothing);
    });

    testWidgets('a network problem offers retry rather than Profile', (
      tester,
    ) async {
      answers(const EstimateFailed(reason: EstimateFailureReason.offline));
      await pumpSheet(tester);
      await type(tester, description);
      await estimate(tester);

      expect(find.byKey(const Key('estimate_retry_button')), findsOneWidget);
      expect(find.byKey(const Key('estimate_profile_button')), findsNothing);
    });

    testWidgets('retrying calls the estimator again', (tester) async {
      answers(const EstimateFailed(reason: EstimateFailureReason.offline));
      await pumpSheet(tester);
      await type(tester, description);
      await estimate(tester);

      answers(const EstimateSucceeded(items: [egg]));
      await tester.tap(find.byKey(const Key('estimate_retry_button')));
      await tester.pumpAndSettle();

      expect(find.byType(EstimateReviewList), findsOneWidget);
      expect(find.byKey(const Key('estimate_failure')), findsNothing);
    });

    // `MacroEstimator` promises never to throw; a promise is not an
    // enforcement.
    testWidgets('an estimator that throws does not take the sheet down', (
      tester,
    ) async {
      when(
        () => estimator.estimate(
          description: any(named: 'description'),
          imagePath: any(named: 'imagePath'),
        ),
      ).thenThrow(StateError('contract violated'));
      await pumpSheet(tester);
      await type(tester, description);
      await estimate(tester);

      expect(find.text(AddMealCopy.failedBadResponse), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a second estimate clears the previous failure', (
      tester,
    ) async {
      answers(const EstimateFailed(reason: EstimateFailureReason.offline));
      await pumpSheet(tester);
      await type(tester, description);
      await estimate(tester);

      answers(const EstimateSucceeded(items: [egg]));
      await estimate(tester);

      expect(find.byKey(const Key('estimate_failure')), findsNothing);
    });
  });
}
