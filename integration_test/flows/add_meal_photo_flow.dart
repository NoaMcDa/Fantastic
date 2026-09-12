import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/domain/models/estimated_item.dart';
import 'package:fantastic/features/diary/domain/models/macro_source.dart';
import 'package:fantastic/features/diary/domain/models/meal_estimate.dart';
import 'package:fantastic/features/diary/domain/services/macro_estimator.dart';
import 'package:fantastic/features/diary/presentation/camera/meal_photo_source.dart';
import 'package:fantastic/features/keto_lens/application/scan_orchestrator.dart';
import 'package:fantastic/features/keto_lens/domain/models/ingredient_verdict.dart';
import 'package:fantastic/features/keto_lens/domain/models/macro_verdict.dart';
import 'package:fantastic/features/keto_lens/domain/models/parsed_label.dart';
import 'package:fantastic/features/keto_lens/domain/models/scan_result.dart';
import 'package:fantastic/features/keto_lens/domain/models/serving_basis.dart';
import 'package:fantastic/features/keto_lens/domain/models/verdict_badge.dart';
import 'package:fantastic/features/keto_lens/presentation/widgets/scan_result_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../helpers/app_harness.dart';

class _MockOrchestrator extends Mock implements ScanOrchestrator {}

/// Always returns the same path. No camera and no gallery exist here.
class _FixedPhotoSource implements MealPhotoSource {
  _FixedPhotoSource(this.path);

  final String path;

  @override
  bool get canTakePhoto => true;

  @override
  Future<String?> takePhoto() async => path;

  @override
  Future<String?> pickFromGallery() async => path;
}

/// Records whether it was called at all. **That is the assertion this flow
/// exists for**: the OCR-first rule is only checked end to end here.
class _CountingEstimator implements MacroEstimator {
  _CountingEstimator(this.result);

  final MealEstimate result;
  int calls = 0;
  String? lastDescription;
  String? lastImagePath;

  @override
  Future<MealEstimate> estimate({
    String? description,
    String? imagePath,
  }) async {
    calls++;
    lastDescription = description;
    lastImagePath = imagePath;
    return result;
  }
}

/// The photo mode's two branches: a label the app reads for free, and a plate
/// only the estimator can say anything about.
void main() {
  const path = '/tmp/photo.jpg';

  const estimate = EstimateSucceeded(
    items: [
      EstimatedItem(
        name: 'שקשוקה',
        grams: 350,
        fatG: 24,
        netCarbsG: 9,
        proteinG: 18,
      ),
    ],
  );

  ScanResult labelScan() => const ScanSucceeded(
    label: ParsedLabel(
      rawText: 'ערכים תזונתיים ל-100 גרם',
      fatG: 33,
      netCarbsG: 2,
      proteinG: 25,
      basis: ServingBasis.per100g,
    ),
    verdict: IngredientVerdict(badge: VerdictBadge.cleanKeto),
    macroVerdict: MacroVerdict.indeterminate(MacroIndeterminacy.noBasis),
  );

  Future<(AppUnderTest, _CountingEstimator)> boot(
    WidgetTester tester,
    ScanResult scan,
  ) async {
    final orchestrator = _MockOrchestrator();
    when(() => orchestrator.scan(any())).thenAnswer((_) async => scan);
    final estimator = _CountingEstimator(estimate);

    final app = await bootApp(
      onboarded: true,
      overrides: <Override>[
        scanOrchestratorProvider.overrideWithValue(orchestrator),
        macroEstimatorProvider.overrideWithValue(estimator),
        mealPhotoSourceProvider.overrideWithValue(_FixedPhotoSource(path)),
      ],
    );
    await pumpApp(tester, app);
    return (app, estimator);
  }

  Future<void> openPhotoMode(WidgetTester tester) =>
      openAddMeal(tester, mode: 'add_meal_mode_photo');

  // The whole OCR-first rule, and the only place it is checked end to end.
  // Estimating first would spend a network request, a quota slot and the
  // user's privacy on a photo the app could read for free — and would replace
  // exact printed figures with a guess.
  testWidgets('a label is read locally and never reaches the estimator', (
    tester,
  ) async {
    final (_, estimator) = await boot(tester, labelScan());

    await openPhotoMode(tester);
    await tapAt(tester, find.byKey(const Key('photo_gallery_button')));

    expect(find.byType(ScanResultSheet), findsOneWidget);
    expect(estimator.calls, 0);
  });

  testWidgets(
    'a plate falls through to the estimator and saves with the photo',
    (tester) async {
      final (app, estimator) = await boot(
        tester,
        const ScanFailed(reason: ScanFailureReason.notALabel),
      );

      await openPhotoMode(tester);
      await enterInto(tester, 'photo_description_field', 'שקשוקה עם פטה');
      await tapAt(tester, find.byKey(const Key('photo_gallery_button')));

      // Both halves reach the engine: the photo says how much, the description
      // says what.
      expect(estimator.calls, 1);
      expect(estimator.lastImagePath, path);
      expect(estimator.lastDescription, 'שקשוקה עם פטה');

      // M6's "this does not look like a nutrition label" would be the wrong
      // sentence in front of someone who photographed a plate on purpose.
      expect(find.byType(ScanResultSheet), findsNothing);
      expect(find.text('שקשוקה'), findsOneWidget);

      await tapAt(tester, find.byKey(const Key('estimate_confirm_button')));
      expect(fieldText(tester, 'fat_field'), '24');
      expect(fieldText(tester, 'carbs_field'), '9');
      await tapAt(tester, find.byKey(const Key('save_meal_button')));

      await scrollDown(tester);
      expect(find.byKey(const Key('meal_card_source_badge')), findsOneWidget);

      final stored = await app.container
          .read(mealRepositoryProvider)
          .findByDate(DateTime.now());
      expect(stored.single.source, MacroSource.estimatedFromPhoto);
      // `MealEntry.imageRef` — persisted, mapped and contract-tested since M1,
      // and written by nothing until the photo mode.
      expect(stored.single.imageRef, path);
    },
  );

  testWidgets(
    'a scan that parsed no macros falls through rather than opening empty',
    (tester) async {
      final (_, estimator) = await boot(
        tester,
        const ScanSucceeded(
          label: ParsedLabel(rawText: 'שקשוקה'),
          verdict: IngredientVerdict(badge: VerdictBadge.cleanKeto),
          macroVerdict: MacroVerdict.indeterminate(
            MacroIndeterminacy.noCarbRow,
          ),
        ),
      );

      await openPhotoMode(tester);
      await tapAt(tester, find.byKey(const Key('photo_gallery_button')));

      expect(find.byType(ScanResultSheet), findsNothing);
      expect(estimator.calls, 1);
    },
  );
}
