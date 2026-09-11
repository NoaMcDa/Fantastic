import 'package:fantastic/features/dashboard/application/providers/daily_log_providers.dart';
import 'package:fantastic/features/diary/application/meal_logging_service.dart';
import 'package:fantastic/features/diary/application/providers/meal_providers.dart';
import 'package:fantastic/features/diary/domain/models/macro_source.dart';
import 'package:fantastic/features/diary/domain/models/meal_entry.dart';
import 'package:fantastic/core/utils/numeric_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manual meal-entry form: a name and three macro fields.
///
/// Opened from the dashboard FAB. On a valid submit it logs the meal, refreshes
/// the day's providers and closes.
class AddMealBottomSheet extends ConsumerStatefulWidget {
  const AddMealBottomSheet({
    required this.date,
    this.initialName,
    this.initialFatG,
    this.initialNetCarbsG,
    this.initialProteinG,
    this.source = MacroSource.manual,
    this.imageRef,
    super.key,
  });

  /// The day the meal is logged against — today from the dashboard, the
  /// selected day from the diary.
  final DateTime date;

  /// The name field's own maximum.
  ///
  /// Public because a caller that prefills the name has to cut it to the same
  /// length — a description mode hands the user's whole sentence in here —
  /// and two copies of `100` is how they come to disagree.
  static const int maxNameLength = 100;

  /// A name to open the form with, or null for an empty field.
  ///
  /// Added for Keto Lens (#84), which opens this sheet with the macros it
  /// read off a label. Every prefill is optional and defaults to null, so
  /// the dashboard and diary call sites are unchanged.
  final String? initialName;

  /// Fat in grams to open the form with, or null for an empty field.
  ///
  /// **Null is not zero.** A macro the scanner did not find is unknown, and
  /// prefilling it as zero would have the user save a fat-free tahini
  /// without noticing. An empty field makes the form's own validator ask.
  final double? initialFatG;

  /// Net carbs in grams to open the form with, or null for an empty field.
  final double? initialNetCarbsG;

  /// Protein in grams to open the form with, or null for an empty field.
  final double? initialProteinG;

  /// Where the prefilled macros came from, recorded on the saved meal.
  ///
  /// Defaults to [MacroSource.manual], so every existing call site and every
  /// existing test is unaffected and typed entry behaves exactly as it did.
  /// A caller that prefills from an estimate passes its own source, and the
  /// diary can then tell a figure that was measured from one that was
  /// guessed — see `MacroSourceCopy`.
  ///
  /// **It is not inferred from whether the prefills are non-null.** A user who
  /// retypes every field of an estimate has still reached the number through
  /// an estimate, and the honest label is the one the opener knew.
  final MacroSource source;

  /// A reference to the photograph the meal was logged from, or null.
  ///
  /// **It is the path the picker returned, and nothing is copied into app
  /// storage.** On every platform that is a cache path the OS may reclaim, so
  /// this is a reference that **may dangle**, and a later reader must treat a
  /// missing file as normal rather than as corruption.
  ///
  /// **Nothing renders it yet.** A durable copy plus a thumbnail in the meal
  /// card is separate work; filling this field now is what makes that work
  /// possible later, and pretending otherwise here would ship a broken image
  /// in a card. The field itself has been persisted, mapped and
  /// contract-tested since M1 and had never been written by any production
  /// code path until the photo mode.
  final String? imageRef;

  /// Opens the sheet as a modal over [context].
  ///
  /// Lives here rather than at the call site so the sheet owns how it is
  /// presented: `isScrollControlled` is required for the keyboard-avoidance
  /// below to have anywhere to expand into.
  static Future<void> show(
    BuildContext context, {
    required DateTime date,
    String? initialName,
    double? initialFatG,
    double? initialNetCarbsG,
    double? initialProteinG,
    MacroSource source = MacroSource.manual,
    String? imageRef,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => AddMealBottomSheet(
      date: date,
      initialName: initialName,
      initialFatG: initialFatG,
      initialNetCarbsG: initialNetCarbsG,
      initialProteinG: initialProteinG,
      source: source,
      imageRef: imageRef,
    ),
  );

  @override
  ConsumerState<AddMealBottomSheet> createState() => _AddMealBottomSheetState();
}

class _AddMealBottomSheetState extends ConsumerState<AddMealBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _fatController;
  late final TextEditingController _carbsController;
  late final TextEditingController _proteinController;

  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _fatController = TextEditingController(
      text: GramsText.format(widget.initialFatG),
    );
    _carbsController = TextEditingController(
      text: GramsText.format(widget.initialNetCarbsG),
    );
    _proteinController = TextEditingController(
      text: GramsText.format(widget.initialProteinG),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lifts the form clear of the software keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'הוספת ארוחה',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('meal_name_field'),
                controller: _nameController,
                textInputAction: TextInputAction.next,
                maxLength: AddMealBottomSheet.maxNameLength,
                decoration: const InputDecoration(labelText: 'שם המנה'),
                validator: _validateName,
              ),
              _macroField(
                key: const Key('fat_field'),
                controller: _fatController,
                label: 'שומן (גרם)',
              ),
              _macroField(
                key: const Key('carbs_field'),
                controller: _carbsController,
                label: 'פחמימות נטו (גרם)',
              ),
              _macroField(
                key: const Key('protein_field'),
                controller: _proteinController,
                label: 'חלבון (גרם)',
                isLast: true,
              ),
              if (_saveError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _saveError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('save_meal_button'),
                onPressed: _saving ? null : _submit,
                child: Text(_saving ? 'שומר...' : 'שמור'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _macroField({
    required Key key,
    required TextEditingController controller,
    required String label,
    bool isLast = false,
  }) => TextFormField(
    key: key,
    controller: controller,
    // `decimal: true` matters: macros are rarely whole numbers, and the
    // integer keypad gives no way to type the separator.
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
    decoration: InputDecoration(labelText: label),
    validator: _validateMacro,
    // Digits, so the field reads left-to-right inside the RTL layout.
    textDirection: TextDirection.ltr,
  );

  String? _validateName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'שדה חובה';
    }
    if (trimmed.length > AddMealBottomSheet.maxNameLength) {
      return 'שם ארוך מדי';
    }
    return null;
  }

  /// Requires a non-negative, finite number.
  ///
  /// `double.tryParse` accepts `Infinity` and `NaN`, either of which would
  /// reach the totals and make every downstream figure unusable — so both are
  /// rejected explicitly rather than left to the `< 0` check, which neither
  /// fails.
  String? _validateMacro(String? value) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null || parsed.isNaN || parsed.isInfinite || parsed < 0) {
      return 'יש להזין מספר חיובי';
    }
    return null;
  }

  /// [date]'s calendar day, at the current time of day.
  ///
  /// The day must come from [date]: a diary entry belongs to the day being
  /// viewed, not to today. The time must come from the clock, because [date]
  /// is normalised to midnight so the date-keyed providers have a stable cache
  /// key — storing it verbatim stamped every meal ever logged `00:00` (#201).
  ///
  /// For a past day the current time is a stand-in: the form does not ask when
  /// the meal was eaten, and a plausible time beats a uniform midnight.
  static DateTime _timestampFor(DateTime date) {
    final now = DateTime.now();
    return DateTime(
      date.year,
      date.month,
      date.day,
      now.hour,
      now.minute,
      now.second,
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
    });

    final entry = MealEntry(
      mealName: _nameController.text.trim(),
      fatG: double.parse(_fatController.text.trim()),
      netCarbsG: double.parse(_carbsController.text.trim()),
      proteinG: double.parse(_proteinController.text.trim()),
      timestamp: _timestampFor(widget.date),
      source: widget.source,
      imageRef: widget.imageRef,
    );

    try {
      await ref.read(mealLoggingServiceProvider).logMeal(entry);
    } on Object catch (_) {
      // Keeps the sheet open with the typed values intact. Closing on failure
      // would discard the entry and tell the user it was saved.
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError = 'השמירה נכשלה, נסו שוב';
        });
      }
      return;
    }

    if (!mounted) {
      return;
    }
    ref
      ..invalidate(todaysMealsProvider(widget.date))
      ..invalidate(todaysDailyLogProvider(widget.date));
    Navigator.of(context).pop();
  }
}
