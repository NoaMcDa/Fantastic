import 'dart:io';

import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/keto_lens/data/providers.dart';
import 'package:fantastic/features/keto_lens/domain/models/scan_result.dart';
import 'package:fantastic/features/keto_lens/domain/models/serving_basis.dart';
import 'package:fantastic/features/keto_lens/domain/models/verdict_badge.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/image_picker_photo_picker.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/photo_picker.dart';
import 'package:fantastic/features/keto_lens/presentation/widgets/scan_result_sheet.dart';
import 'package:fantastic/features/keto_lens/presentation/widgets/verdict_badge_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../test/fixtures/fixtures.dart';
import '../helpers/app_harness.dart';

/// F9 — add a photo of a label, read the verdict, log what it found.
///
/// ## What is real here, and what is not
///
/// The photo is real: `test/fixtures/images/tahini_label.png` is the image
/// #274 captured its OCR fixtures from, and the flow asserts the file it
/// hands the pipeline actually exists. The parser, the classifier, the
/// orchestrator, the sealed [ScanResult], the sheet, the prefill and the
/// meal write are all the shipped code.
///
/// Two seams are faked, both at the plugin boundary and both already
/// interfaces in `lib/`:
///
/// - [PhotoPicker] — `image_picker` has no platform channel under the
///   headless tester, so there is no gallery to open.
/// - [TextRecognitionService] — the desktop arm is `dart:ffi` against a
///   system `libtesseract`, which neither this container nor CI installs
///   (`tesseract_ffi_recognizer_test.dart` skips for the same reason). The
///   fake returns [RealOcrFixture] text, which is **verbatim Tesseract
///   output for this very image** — not a string anybody wrote to make a
///   test pass.
///
/// So this covers everything after OCR. It does not measure OCR accuracy;
/// #256 and Epic #10 stay open, and `design/m8_preflight.md` §0.4 is the
/// standing statement of that. If CI ever installs `libtesseract`, drop the
/// recogniser override and this same flow scans the PNG for real.
const String _labelImage = 'test/fixtures/images/tahini_label.png';

class _FixturePhotoPicker implements PhotoPicker {
  const _FixturePhotoPicker(this.path);

  final String? path;

  @override
  Future<String?> pickFromGallery() async => path;

  @override
  Future<List<String>> pickMultiple({required int limit}) async => const [];
}

class _CannedRecognizer implements TextRecognitionService {
  const _CannedRecognizer(this.text);

  final String text;

  @override
  bool get isAvailable => true;

  @override
  Future<String> recognise(String imagePath) async => text;
}

List<Override> _lensOverrides({
  required String ocrText,
  String? pickedPath = _labelImage,
}) => [
  photoPickerProvider.overrideWithValue(_FixturePhotoPicker(pickedPath)),
  textRecognitionServiceProvider.overrideWithValue(_CannedRecognizer(ocrText)),
];

/// Opens the lens tab and imports a photo through the gallery button.
///
/// Headless there is no camera, so the tab lands on its camera-problem state
/// — whose fallback is `gallery_fallback_button`, not the viewfinder's
/// `gallery_button`. Both call the same `_pickFromGallery`, so the flow
/// takes whichever this build offers rather than assuming one.
Future<void> importPhoto(WidgetTester tester) async {
  await goToTab(tester, 'tab_lens');
  final gallery =
      find.byKey(const Key('gallery_fallback_button')).evaluate().isNotEmpty
      ? find.byKey(const Key('gallery_fallback_button'))
      : find.byKey(const Key('gallery_button'));
  expect(
    gallery,
    findsOneWidget,
    reason: 'the lens offers no way to import a photo',
  );
  await tapAt(tester, gallery);
}

void main() {
  testWidgets('a photo of a clean label is analysed and shown as clean keto', (
    tester,
  ) async {
    expect(
      File(_labelImage).existsSync(),
      isTrue,
      reason:
          'the flow must hand the pipeline a real image, not a made-up path',
    );

    await pumpApp(
      tester,
      await bootApp(
        onboarded: true,
        overrides: _lensOverrides(ocrText: RealOcrFixture.tahini),
      ),
    );
    await importPhoto(tester);

    // The verdict, from the real classifier over the real parser's output.
    expect(find.byType(ScanResultSheet), findsOneWidget);
    expect(find.byKey(const Key('verdict_badge')), findsOneWidget);

    // **Not a green "קטו נקי" tick, and that is the design.** This label's
    // ingredient line is `100% שומשום מלא` — sesame, which is on none of the
    // rule lists, so the classifier recognised nothing and says so instead
    // of claiming the product is clean. `IngredientVerdict.recognisedNothing`
    // exists for exactly this: "nothing here is bad" and "nothing here was
    // readable" must not paint the same badge (`CLAUDE.md` §OCR).
    expect(
      find.text(
        VerdictBadgeWidget.labelFor(
          VerdictBadge.cleanKeto,
          recognisedNothing: true,
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.text(VerdictBadgeWidget.labelFor(VerdictBadge.cleanKeto)),
      findsNothing,
    );

    // The macros the parser pulled off the label. 53.8 rather than 7.6 is
    // the saturated-fat trap: the sub-row one line below uses the same
    // Hebrew word, and a parser taking the first match reports it.
    expect(find.text('53.8 ג'), findsOneWidget);
    // 10.5 total carbs − 9.3 fibre, formatted without a pointless decimal.
    expect(find.text('1.2 ג'), findsOneWidget);
    expect(find.text('26.5 ג'), findsOneWidget);

    // The label declares per-100 g and the sheet says so, rather than
    // leaving the user to infer it (#257, fixed on this base by #281). The
    // amount field starts at the reference 100, so the strip above is still
    // the printed figures until the user says what they ate.
    expect(
      find.text(ScanResultSheet.basisCaption(ServingBasis.per100g)),
      findsOneWidget,
    );
    expect(fieldText(tester, 'scan_amount_field'), '100');
  });

  testWidgets('adding the scan to the diary prefills and logs it', (
    tester,
  ) async {
    final app = await bootApp(
      onboarded: true,
      overrides: _lensOverrides(ocrText: RealOcrFixture.tahini),
    );
    await pumpApp(tester, app);
    await importPhoto(tester);

    // **What a user actually eats.** A 15 g spoonful of tahini, not the
    // 100 g the label is printed per. Before #257 this field did not exist
    // and the whole 100 g went into the diary — corrupting the day's macros,
    // the keto ratio, the streak evaluation and the phase from one tap.
    await enterInto(tester, 'scan_amount_field', '15');

    // The strip updates to what will be LOGGED, so the number the user is
    // about to save is the one in front of them: 53.8 × 0.15.
    expect(find.text('8.1 ג'), findsOneWidget);

    await tapAt(tester, find.byKey(const Key('add_to_diary_button')));

    // The scan sheet is gone and the meal form is up, prefilled.
    expect(find.byType(ScanResultSheet), findsNothing);
    expect(find.byKey(const Key('save_meal_button')), findsOneWidget);
    expect(find.text('מוצר סרוק'), findsOneWidget);

    // Scaled to the 15 g eaten, not the 100 g printed — the fix, asserted
    // where a user would see it. 53.8 × 0.15 = 8.07, shown and saved as 8.1,
    // which is the figure the strip above displayed.
    expect(fieldText(tester, 'fat_field'), '8.1');
    // 26.5 × 0.15 = 3.975, which rounds to a whole 4.
    expect(fieldText(tester, 'protein_field'), '4');

    // **The defect this flow found, now fixed and asserted as such (#304).**
    // The sheet rendered net carbs as a tidy `0.2 ג` and the field it
    // prefilled two taps later carried the raw double — `10.5 - 9.3` is not
    // 1.2 in binary floating point — so the same number appeared two ways one
    // screen apart, and the long one was the one the user was asked to save.
    // Both sides now go through `GramsText.format`.
    final carbs = fieldText(tester, 'carbs_field');
    expect(carbs, '0.2');
    expect(
      carbs.length,
      lessThanOrEqualTo(4),
      reason:
          'the prefill is showing floating-point noise ($carbs) again where '
          'the sheet above it shows one decimal — see #304',
    );

    await tapAt(tester, find.byKey(const Key('save_meal_button')));

    // It reached storage as a meal like any other.
    await waitFor(
      tester,
      () async =>
          (await app.container
                  .read(mealRepositoryProvider)
                  .findByDate(DateTime.now()))
              .isNotEmpty,
      reason: 'the scanned meal never reached the repository',
    );
    final meals = await app.container
        .read(mealRepositoryProvider)
        .findByDate(DateTime.now());
    expect(meals.single.mealName, 'מוצר סרוק');
    // What was on screen is what reached storage, to the digit. Before #304
    // the field said 8.069999999999999 and this said the same — self-consistent
    // and not what the user was shown.
    expect(meals.single.fatG, 8.1);
    expect(meals.single.netCarbsG, 0.2);

    // And the dashboard shows it, which is the whole point of the journey:
    // the lens tab is where it started.
    await goToTab(tester, 'tab_home');
    await scrollDown(tester);
    expect(find.text('מוצר סרוק'), findsOneWidget);
  });

  testWidgets('a photo that is not a label is never given a verdict', (
    tester,
  ) async {
    await pumpApp(
      tester,
      await bootApp(
        onboarded: true,
        // Text the engine really can produce from a photo of something that
        // is not a nutrition label: words, no macro table, no ingredients.
        overrides: _lensOverrides(ocrText: 'חנות הטבע\nפתוח 08:00-21:00'),
      ),
    );
    await importPhoto(tester);

    // **The defect M6's audit caught, asserted from the outside.** #83
    // specified reporting an unreadable label as `Clean Keto`, which would
    // have told a user in a shop that a product was keto-safe *because the
    // app could not read it*. The sealed ScanResult exists so that cannot
    // be expressed; this is the UI-level proof.
    expect(find.byKey(const Key('verdict_badge')), findsNothing);
    expect(
      find.text(VerdictBadgeWidget.labelFor(VerdictBadge.cleanKeto)),
      findsNothing,
    );
    expect(
      find.text(ScanResultSheet.failureTitle(ScanFailureReason.notALabel)),
      findsOneWidget,
    );
    // A failed scan is worth retrying, so the sheet offers it.
    expect(find.byKey(const Key('retry_scan_button')), findsOneWidget);
  });

  testWidgets('backing out of the gallery leaves the screen as it was', (
    tester,
  ) async {
    await pumpApp(
      tester,
      await bootApp(
        onboarded: true,
        overrides: _lensOverrides(
          ocrText: RealOcrFixture.tahini,
          // The picker returning null is the user cancelling. Not an error,
          // and not worth a sheet.
          pickedPath: null,
        ),
      ),
    );
    await importPhoto(tester);

    expect(find.byType(ScanResultSheet), findsNothing);
    expect(find.byKey(const Key('lens_camera_problem')), findsOneWidget);
  });

  // **The reported defect, driven through the real UI** (#306). A whole-wheat
  // and rye bread at 34.2 g of net carbs per 100 g rendered `קטו נקי` — a
  // green tick — because the verdict read only the ingredient list and never
  // looked at the panel beside it. Every number in this flow comes from a real
  // photographed label via `RealOcrFixture`.
  testWidgets('a high-carb label is not given a green tick', (tester) async {
    final app = await bootApp(
      onboarded: true,
      overrides: _lensOverrides(ocrText: RealOcrFixture.wholeWheatRyeBread),
    );
    await pumpApp(tester, app);
    await importPhoto(tester);

    expect(find.byType(ScanResultSheet), findsOneWidget);
    expect(find.text('לא קטו'), findsOneWidget);
    expect(find.text('קטו נקי'), findsNothing);

    // The line that turns a verdict into an instruction: 58 g of this bread
    // exhausts a whole day's carbohydrate budget.
    expect(
      find.textContaining('ממצים את תקציב הפחמימות היומי'),
      findsOneWidget,
    );
  });
}
