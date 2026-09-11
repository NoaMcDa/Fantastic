import 'package:fantastic/core/constants/add_meal_copy.dart';
import 'package:fantastic/core/router/app_router.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/domain/models/estimate_failure_reason.dart';
import 'package:fantastic/features/diary/domain/models/estimated_item.dart';
import 'package:fantastic/features/diary/domain/models/macro_source.dart';
import 'package:fantastic/features/diary/domain/models/meal_estimate.dart';
import 'package:fantastic/features/diary/presentation/camera/meal_photo_source.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_bottom_sheet.dart';
import 'package:fantastic/features/diary/presentation/widgets/estimate_failure_view.dart';
import 'package:fantastic/features/diary/presentation/widgets/estimate_review_list.dart';
import 'package:fantastic/features/keto_lens/application/scan_orchestrator.dart';
import 'package:fantastic/features/keto_lens/domain/models/scan_result.dart';
import 'package:fantastic/features/keto_lens/presentation/widgets/scan_result_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Photograph the plate, or the label — and let the app work out which.
///
/// ## The order is the design
///
/// Two capabilities hide in #312's *"a photo of the meal with ocr"*, and
/// which runs first is the whole decision.
///
/// A packaged product's **nutrition panel is text**, and the app already
/// reads it: `ScanOrchestrator` → Tesseract → `HebrewLabelParser`, on six
/// platforms, **with no network call**, and corrected by #257 so the figures
/// are scaled to what was actually eaten. That path is free, offline,
/// instant, and reads *printed* figures rather than estimating them.
///
/// A **plate of shakshuka** has no text on it at all, and only the
/// multimodal estimator can say anything about it — at roughly 39% error on
/// portion size, the worst number this app can produce.
///
/// So the label is tried first, always. Running the estimator first would
/// spend a network request, a quota slot and the user's privacy on a photo
/// the app could have read for free, and would replace exact printed figures
/// with a guess.
///
/// **The OCR attempt is free, so it runs even when estimation is off.** A
/// user who has never pasted an API key can still photograph a label and log
/// it, and the `notConfigured` copy only appears when the photo was *not* a
/// label.
///
/// Nothing under `lib/features/keto_lens/` is modified by this sheet: it is a
/// second caller of `ScanOrchestrator`, not a second copy, and a successful
/// scan is handed to the same `ScanResultSheet` the lens tab opens, with the
/// same serving-basis control and the same badge.
class AddMealPhotoSheet extends ConsumerStatefulWidget {
  const AddMealPhotoSheet({required this.date, super.key});

  /// The day the meal is logged against.
  final DateTime date;

  /// Signature unchanged from the placeholder #322 shipped, so `AddMealFab`
  /// is not touched by this issue.
  static Future<void> show(BuildContext context, {required DateTime date}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => AddMealPhotoSheet(
          date: date,
          key: const Key('add_meal_photo_sheet'),
        ),
      );

  @override
  ConsumerState<AddMealPhotoSheet> createState() => _AddMealPhotoSheetState();
}

class _AddMealPhotoSheetState extends ConsumerState<AddMealPhotoSheet> {
  final TextEditingController _description = TextEditingController();

  /// The photograph being worked on, kept so a retry does not re-open the
  /// picker and so the path can be attached to the saved meal.
  String? _photoPath;

  List<EstimatedItem>? _items;
  List<String> _unidentified = const [];
  EstimateFailureReason? _failure;

  /// True while the picker is open, the label scan is running, or the
  /// estimate is in flight — they are one wait from the user's seat.
  bool _busy = false;

  /// Set when the picker itself failed, which is not an estimate failure and
  /// must not be worded as one.
  bool _sourceFailed = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final source = ref.watch(mealPhotoSourceProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AddMealCopy.photoTitle,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AddMealCopy.photoIntro,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('photo_description_field'),
              controller: _description,
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: AddMealCopy.photoDescriptionLabel,
                hintText: AddMealCopy.photoDescriptionHint,
              ),
            ),
            const SizedBox(height: 12),
            // Absent, not present-and-failing: `image_picker` has no camera
            // implementation on the three desktops and throws when asked.
            if (source.canTakePhoto)
              FilledButton.icon(
                key: const Key('photo_camera_button'),
                onPressed: _busy ? null : () => _start(source.takePhoto),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text(AddMealCopy.takePhoto),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('photo_gallery_button'),
              onPressed: _busy ? null : () => _start(source.pickFromGallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text(AddMealCopy.pickPhoto),
            ),
            if (_busy) ...[
              const SizedBox(height: 16),
              Text(
                AddMealCopy.reading,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Center(
                child: CircularProgressIndicator(key: Key('photo_progress')),
              ),
            ],
            if (_sourceFailed) ...[
              const SizedBox(height: 16),
              Text(
                AddMealCopy.photoSourceFailed,
                key: const Key('photo_source_failed'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            if (_failure != null) ...[
              const SizedBox(height: 16),
              EstimateFailureView(
                reason: _failure!,
                // "Try another photo", not "retry": re-running the same
                // unreadable file would fail in exactly the same way.
                retryLabel: AddMealCopy.anotherPhoto,
                onRetry: () =>
                    _start(ref.read(mealPhotoSourceProvider).pickFromGallery),
                onManual: _openManual,
                onProfile: _openProfile,
              ),
            ],
            if (_items != null) ...[
              const SizedBox(height: 16),
              EstimateReviewList(
                key: const Key('estimate_review_list'),
                items: _items!,
                unidentified: _unidentified,
                onRemove: _removeItem,
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('estimate_confirm_button'),
                onPressed: _items!.isEmpty ? null : _confirm,
                child: const Text(AddMealCopy.reviewAndSave),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Picks a photo, then runs the label-first flow over it.
  Future<void> _start(Future<String?> Function() pick) async {
    setState(() {
      _busy = true;
      _failure = null;
      _sourceFailed = false;
      _items = null;
      _unidentified = const [];
    });

    final String? path;
    try {
      path = await pick();
    } on Object catch (_) {
      // The picker failing is not an estimate failing, and must not be
      // worded as one — "check your key" in front of a refused camera
      // permission sends the user to the wrong screen.
      if (mounted) {
        setState(() {
          _busy = false;
          _sourceFailed = true;
        });
      }
      return;
    }

    if (!mounted) {
      return;
    }
    if (path == null) {
      // Backing out of the picker is not an error, and must leave no
      // spinner behind.
      setState(() => _busy = false);
      return;
    }

    _photoPath = path;
    await _readPhoto(path);
  }

  /// The label first, the estimator second.
  Future<void> _readPhoto(String path) async {
    final scan = await ref.read(scanOrchestratorProvider).scan(path);

    if (!mounted) {
      return;
    }

    // A scan that produced no macros is not a label from this sheet's point
    // of view, whatever the badge says: there is nothing to prefill, and the
    // result sheet would open empty.
    if (scan is ScanSucceeded && scan.label.hasMacros) {
      setState(() => _busy = false);
      // Straight down M6's existing path, unchanged. No network call was
      // made, and `ScanResultSheet` owns the serving basis and the badge.
      //
      // **No `onRetry`**: the lens tab passes one because its viewfinder is
      // still live behind the sheet. Here there is nothing behind it to
      // retry into.
      await ScanResultSheet.show(context, result: scan, date: widget.date);
      return;
    }

    // Deliberately *not* M6's failure copy. "This does not look like a
    // nutrition label" is the wrong sentence in front of someone who just
    // photographed a plate of food on purpose.
    await _estimate(path);
  }

  Future<void> _estimate(String path) async {
    MealEstimate result;
    try {
      result = await ref
          .read(macroEstimatorProvider)
          .estimate(description: _description.text, imagePath: path);
    } on Object catch (_) {
      // `MacroEstimator` promises never to throw; a promise is not an
      // enforcement.
      result = const EstimateFailed(reason: EstimateFailureReason.badResponse);
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      switch (result) {
        case EstimateSucceeded(:final items, :final unidentified):
          _items = List.of(items);
          _unidentified = unidentified;
        case EstimateFailed(:final reason):
          _failure = reason;
      }
    });
  }

  void _removeItem(int index) =>
      setState(() => _items = [..._items!]..removeAt(index));

  Future<void> _openManual({
    double? fatG,
    double? netCarbsG,
    double? proteinG,
    MacroSource source = MacroSource.manual,
  }) async {
    final navigator = Navigator.of(context);
    final name = _trimmedName;
    // The photo is attached even on the manual escape route: the user still
    // took it, and it is still what the meal was.
    final imageRef = _photoPath;
    navigator.pop();
    if (!navigator.mounted) {
      return;
    }
    final host = navigator.context;
    if (!host.mounted) {
      return;
    }
    await AddMealBottomSheet.show(
      host,
      date: widget.date,
      initialName: name.isEmpty ? null : name,
      initialFatG: fatG,
      initialNetCarbsG: netCarbsG,
      initialProteinG: proteinG,
      source: source,
      imageRef: imageRef,
    );
  }

  Future<void> _confirm() {
    final list = EstimateReviewList(
      items: _items!,
      unidentified: _unidentified,
      onRemove: _removeItem,
    );
    return _openManual(
      fatG: list.fatG,
      netCarbsG: list.netCarbsG,
      proteinG: list.proteinG,
      source: MacroSource.estimatedFromPhoto,
    );
  }

  void _openProfile() {
    // `maybeOf`: this sheet is pumped in widget tests with no router.
    final router = GoRouter.maybeOf(context);
    Navigator.of(context).pop();
    router?.go(kProfilePath);
  }

  /// The description, cut to the name field's own maximum. Empty is fine —
  /// the description is optional here, unlike in the text mode.
  String get _trimmedName {
    final text = _description.text.trim();
    return text.length > AddMealBottomSheet.maxNameLength
        ? text.substring(0, AddMealBottomSheet.maxNameLength)
        : text;
  }
}
