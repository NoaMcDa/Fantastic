import 'package:fantastic/core/constants/add_meal_copy.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/domain/models/estimate_failure_reason.dart';
import 'package:fantastic/features/diary/domain/models/estimated_item.dart';
import 'package:fantastic/features/diary/domain/models/macro_source.dart';
import 'package:fantastic/features/diary/domain/models/meal_estimate.dart';
import 'package:fantastic/features/diary/domain/services/macro_estimator.dart';
import 'package:fantastic/features/diary/presentation/camera/meal_photo_source.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_bottom_sheet.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_photo_sheet.dart';
import 'package:fantastic/features/diary/presentation/widgets/estimate_review_list.dart';
import 'package:fantastic/features/keto_lens/application/scan_orchestrator.dart';
import 'package:fantastic/features/keto_lens/domain/models/ingredient_verdict.dart';
import 'package:fantastic/features/keto_lens/domain/models/macro_verdict.dart';
import 'package:fantastic/features/keto_lens/domain/models/parsed_label.dart';
import 'package:fantastic/features/keto_lens/domain/models/scan_result.dart';
import 'package:fantastic/features/keto_lens/domain/models/verdict_badge.dart';
import 'package:fantastic/features/keto_lens/presentation/widgets/scan_result_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class _MockEstimator extends Mock implements MacroEstimator {}

class _MockOrchestrator extends Mock implements ScanOrchestrator {}

class _MockPhotoSource extends Mock implements MealPhotoSource {}

void main() {
  late _MockEstimator estimator;
  late _MockOrchestrator orchestrator;
  late _MockPhotoSource photos;

  final date = DateTime(2026, 9, 11);
  const path = '/tmp/plate.jpg';

  const egg = EstimatedItem(
    name: 'ביצה',
    grams: 100,
    fatG: 10,
    netCarbsG: 1,
    proteinG: 13,
  );

  /// A scan that produced real printed macros — the free, offline path.
  ScanResult labelScan() => const ScanSucceeded(
    label: ParsedLabel(
      rawText: 'ערכים תזונתיים',
      fatG: 33,
      netCarbsG: 2,
      proteinG: 25,
    ),
    verdict: IngredientVerdict(badge: VerdictBadge.cleanKeto),
    macroVerdict: MacroVerdict.indeterminate(MacroIndeterminacy.noBasis),
  );

  /// A scan that parsed *something* but no macros. There is nothing to
  /// prefill, so the result sheet would open empty.
  ScanResult macrolessScan() => const ScanSucceeded(
    label: ParsedLabel(rawText: 'שקשוקה'),
    verdict: IngredientVerdict(badge: VerdictBadge.cleanKeto),
    macroVerdict: MacroVerdict.indeterminate(MacroIndeterminacy.noCarbRow),
  );

  setUp(() {
    estimator = _MockEstimator();
    orchestrator = _MockOrchestrator();
    photos = _MockPhotoSource();
    when(() => photos.canTakePhoto).thenReturn(true);
    when(photos.takePhoto).thenAnswer((_) async => path);
    when(photos.pickFromGallery).thenAnswer((_) async => path);
  });

  void scans(ScanResult result) =>
      when(() => orchestrator.scan(any())).thenAnswer((_) async => result);

  void estimates(MealEstimate result) => when(
    () => estimator.estimate(
      description: any(named: 'description'),
      imagePath: any(named: 'imagePath'),
    ),
  ).thenAnswer((_) async => result);

  Future<void> pumpSheet(WidgetTester tester) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Center(
          child: TextButton(
            key: const Key('open'),
            onPressed: () => AddMealPhotoSheet.show(context, date: date),
            child: const Text('open'),
          ),
        ),
      ),
      overrides: [
        macroEstimatorProvider.overrideWithValue(estimator),
        scanOrchestratorProvider.overrideWithValue(orchestrator),
        mealPhotoSourceProvider.overrideWithValue(photos),
      ],
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
  }

  Future<void> pick(
    WidgetTester tester, {
    String key = 'photo_gallery_button',
  }) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  group('the label is tried first', () {
    // Running the estimator first would spend a network request, a quota slot
    // and the user's privacy on a photo the app could read for free — and
    // would replace exact printed figures with a guess.
    testWidgets('a readable label opens ScanResultSheet', (tester) async {
      scans(labelScan());
      await pumpSheet(tester);
      await pick(tester);

      expect(find.byType(ScanResultSheet), findsOneWidget);
    });

    testWidgets('a readable label never reaches the estimator', (tester) async {
      scans(labelScan());
      await pumpSheet(tester);
      await pick(tester);

      verifyNever(
        () => estimator.estimate(
          description: any(named: 'description'),
          imagePath: any(named: 'imagePath'),
        ),
      );
    });

    // The scan runs before anything else, so a user who has never pasted a
    // key can still photograph a label and log it.
    testWidgets(
      'works with estimation unconfigured, and says nothing about it',
      (tester) async {
        scans(labelScan());
        estimates(
          const EstimateFailed(reason: EstimateFailureReason.notConfigured),
        );
        await pumpSheet(tester);
        await pick(tester);

        expect(find.byType(ScanResultSheet), findsOneWidget);
        expect(find.text(AddMealCopy.failedNotConfigured), findsNothing);
      },
    );

    testWidgets('a scan that parsed no macros falls through to the estimator', (
      tester,
    ) async {
      scans(macrolessScan());
      estimates(const EstimateSucceeded(items: [egg]));
      await pumpSheet(tester);
      await pick(tester);

      // Opening a result sheet with nothing in it would be worse than useless.
      expect(find.byType(ScanResultSheet), findsNothing);
      expect(find.byType(EstimateReviewList), findsOneWidget);
    });

    testWidgets('a failed scan falls through without M6 failure copy', (
      tester,
    ) async {
      scans(const ScanFailed(reason: ScanFailureReason.notALabel));
      estimates(const EstimateSucceeded(items: [egg]));
      await pumpSheet(tester);
      await pick(tester);

      // "This does not look like a nutrition label" is the wrong sentence in
      // front of someone who just photographed a plate of food on purpose.
      expect(find.byType(ScanResultSheet), findsNothing);
      expect(find.byType(EstimateReviewList), findsOneWidget);
    });
  });

  group('the estimate path', () {
    testWidgets('sends the photo and the typed description', (tester) async {
      scans(const ScanFailed(reason: ScanFailureReason.notALabel));
      estimates(const EstimateSucceeded(items: [egg]));
      await pumpSheet(tester);
      await tester.enterText(
        find.byKey(const Key('photo_description_field')),
        'שקשוקה',
      );
      await pick(tester);

      verify(() => estimator.estimate(description: 'שקשוקה', imagePath: path))
          .called(1);
    });

    testWidgets('estimates with no description at all', (tester) async {
      scans(const ScanFailed(reason: ScanFailureReason.notALabel));
      estimates(const EstimateSucceeded(items: [egg]));
      await pumpSheet(tester);
      await pick(tester);

      expect(find.byType(EstimateReviewList), findsOneWidget);
    });

    testWidgets('reuses the description mode review list, not a copy', (
      tester,
    ) async {
      scans(const ScanFailed(reason: ScanFailureReason.notALabel));
      estimates(const EstimateSucceeded(items: [egg], unidentified: ['לחם']));
      await pumpSheet(tester);
      await pick(tester);

      expect(find.text('ביצה'), findsOneWidget);
      expect(find.text('לחם'), findsOneWidget);
      expect(find.text(AddMealCopy.unidentifiedMarker), findsOneWidget);
    });

    testWidgets('removing an item recomputes the total', (tester) async {
      scans(const ScanFailed(reason: ScanFailureReason.notALabel));
      estimates(const EstimateSucceeded(items: [egg]));
      await pumpSheet(tester);
      await pick(tester);

      await tester.tap(find.byKey(const Key('estimate_item_remove_0')));
      await tester.pumpAndSettle();

      expect(find.text('שומן 0 · פחמימות 0 · חלבון 0'), findsOneWidget);
      expect(
        tester
            .widget<ButtonStyleButton>(
              find.byKey(const Key('estimate_confirm_button')),
            )
            .onPressed,
        isNull,
      );
    });
  });

  group('the hand-off', () {
    Future<AddMealBottomSheet> confirm(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('estimate_confirm_button')));
      await tester.pumpAndSettle();
      return tester.widget<AddMealBottomSheet>(find.byType(AddMealBottomSheet));
    }

    testWidgets('carries the totals, the photo source and the image', (
      tester,
    ) async {
      scans(const ScanFailed(reason: ScanFailureReason.notALabel));
      estimates(const EstimateSucceeded(items: [egg]));
      await pumpSheet(tester);
      await pick(tester);

      final sheet = await confirm(tester);
      expect(sheet.initialFatG, 10);
      expect(sheet.initialNetCarbsG, 1);
      expect(sheet.initialProteinG, 13);
      expect(sheet.source, MacroSource.estimatedFromPhoto);
      // The field persisted, mapped and contract-tested since M1 that no
      // production code path had ever filled.
      expect(sheet.imageRef, path);
      expect(sheet.date, date);
    });

    testWidgets('uses the description as the name when one was typed', (
      tester,
    ) async {
      scans(const ScanFailed(reason: ScanFailureReason.notALabel));
      estimates(const EstimateSucceeded(items: [egg]));
      await pumpSheet(tester);
      await tester.enterText(
        find.byKey(const Key('photo_description_field')),
        'שקשוקה',
      );
      await pick(tester);

      expect((await confirm(tester)).initialName, 'שקשוקה');
    });

    testWidgets('leaves the name empty when none was typed', (tester) async {
      scans(const ScanFailed(reason: ScanFailureReason.notALabel));
      estimates(const EstimateSucceeded(items: [egg]));
      await pumpSheet(tester);
      await pick(tester);

      // Null, not an empty string: the form's own validator then asks.
      expect((await confirm(tester)).initialName, isNull);
    });

    testWidgets('attaches the photo even on the manual escape route', (
      tester,
    ) async {
      scans(const ScanFailed(reason: ScanFailureReason.notALabel));
      estimates(const EstimateFailed(reason: EstimateFailureReason.offline));
      await pumpSheet(tester);
      await pick(tester);

      await tester.tap(find.byKey(const Key('estimate_manual_button')));
      await tester.pumpAndSettle();

      final sheet = tester.widget<AddMealBottomSheet>(
        find.byType(AddMealBottomSheet),
      );
      // They still took it, and it is still what the meal was.
      expect(sheet.imageRef, path);
      // But no estimate survived, so it is not labelled one.
      expect(sheet.source, MacroSource.manual);
      expect(sheet.initialFatG, isNull);
    });
  });

  group('acquiring the photo', () {
    testWidgets('offers the camera where the platform has one', (tester) async {
      await pumpSheet(tester);

      expect(find.byKey(const Key('photo_camera_button')), findsOneWidget);
      expect(find.byKey(const Key('photo_gallery_button')), findsOneWidget);
    });

    // Absent, not present-and-failing: `image_picker` has no camera
    // implementation on the three desktops and throws when asked.
    testWidgets('hides the camera where the platform has none', (tester) async {
      when(() => photos.canTakePhoto).thenReturn(false);
      await pumpSheet(tester);

      expect(find.byKey(const Key('photo_camera_button')), findsNothing);
      expect(find.byKey(const Key('photo_gallery_button')), findsOneWidget);
    });

    testWidgets('the camera button scans what it captured', (tester) async {
      scans(labelScan());
      await pumpSheet(tester);
      await pick(tester, key: 'photo_camera_button');

      verify(photos.takePhoto).called(1);
      verify(() => orchestrator.scan(path)).called(1);
    });

    testWidgets('backing out of the picker leaves no spinner', (tester) async {
      when(photos.pickFromGallery).thenAnswer((_) async => null);
      await pumpSheet(tester);
      await pick(tester);

      expect(find.byKey(const Key('photo_progress')), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // And nothing was scanned or estimated.
      verifyNever(() => orchestrator.scan(any()));
      expect(find.byKey(const Key('estimate_failure')), findsNothing);
    });

    // A refused camera permission is not an estimate failure, and "check your
    // key" in front of one sends the user to the wrong screen entirely.
    testWidgets('a picker failure is worded as a picker failure', (
      tester,
    ) async {
      when(
        photos.pickFromGallery,
      ).thenThrow(const MealPhotoSourceException('camera permission denied'));
      await pumpSheet(tester);
      await pick(tester);

      expect(find.byKey(const Key('photo_source_failed')), findsOneWidget);
      expect(find.byKey(const Key('estimate_failure')), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // The platform's English detail never reaches the user.
      expect(find.textContaining('permission denied'), findsNothing);
    });
  });

  group('failures', () {
    testWidgets('unconfigured estimation on a non-label says so', (
      tester,
    ) async {
      scans(const ScanFailed(reason: ScanFailureReason.notALabel));
      estimates(
        const EstimateFailed(reason: EstimateFailureReason.notConfigured),
      );
      await pumpSheet(tester);
      await pick(tester);

      expect(find.text(AddMealCopy.failedNotConfigured), findsOneWidget);
      expect(find.byKey(const Key('estimate_profile_button')), findsOneWidget);
      expect(find.byKey(const Key('estimate_manual_button')), findsOneWidget);
    });

    testWidgets('an unreadable image offers another photo, not a retry', (
      tester,
    ) async {
      scans(const ScanFailed(reason: ScanFailureReason.notALabel));
      estimates(
        const EstimateFailed(reason: EstimateFailureReason.badResponse),
      );
      await pumpSheet(tester);
      await pick(tester);

      expect(find.text(AddMealCopy.failedBadResponse), findsOneWidget);
      // Re-sending the same unreadable file would fail identically.
      expect(find.text(AddMealCopy.anotherPhoto), findsOneWidget);
      expect(find.text(AddMealCopy.retry), findsNothing);
    });

    testWidgets('every failure renders an error and not a spinner', (
      tester,
    ) async {
      scans(const ScanFailed(reason: ScanFailureReason.notALabel));
      for (final reason in EstimateFailureReason.values) {
        estimates(EstimateFailed(reason: reason));
        await pumpSheet(tester);
        await pick(tester);

        expect(
          find.byKey(const Key('estimate_failure')),
          findsOneWidget,
          reason: reason.name,
        );
        expect(
          find.byType(CircularProgressIndicator),
          findsNothing,
          reason: reason.name,
        );
      }
    });

    testWidgets('a failed estimate keeps the typed description', (
      tester,
    ) async {
      scans(const ScanFailed(reason: ScanFailureReason.notALabel));
      estimates(const EstimateFailed(reason: EstimateFailureReason.offline));
      await pumpSheet(tester);
      await tester.enterText(
        find.byKey(const Key('photo_description_field')),
        'שקשוקה',
      );
      await pick(tester);

      expect(find.text('שקשוקה'), findsOneWidget);
    });

    testWidgets('an estimator that throws does not take the sheet down', (
      tester,
    ) async {
      scans(const ScanFailed(reason: ScanFailureReason.notALabel));
      when(
        () => estimator.estimate(
          description: any(named: 'description'),
          imagePath: any(named: 'imagePath'),
        ),
      ).thenThrow(StateError('contract violated'));
      await pumpSheet(tester);
      await pick(tester);

      expect(find.text(AddMealCopy.failedBadResponse), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
