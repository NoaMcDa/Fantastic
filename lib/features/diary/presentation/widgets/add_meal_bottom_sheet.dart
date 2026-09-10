import 'package:fantastic/features/dashboard/application/providers/daily_log_providers.dart';
import 'package:fantastic/features/diary/application/meal_logging_service.dart';
import 'package:fantastic/features/diary/application/providers/meal_providers.dart';
import 'package:fantastic/features/diary/domain/models/meal_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manual meal-entry form: a name and three macro fields.
///
/// Opened from the dashboard FAB. On a valid submit it logs the meal, refreshes
/// the day's providers and closes.
class AddMealBottomSheet extends ConsumerStatefulWidget {
  const AddMealBottomSheet({required this.date, super.key});

  /// The day the meal is logged against — today from the dashboard, the
  /// selected day from the diary.
  final DateTime date;

  /// Opens the sheet as a modal over [context].
  ///
  /// Lives here rather than at the call site so the sheet owns how it is
  /// presented: `isScrollControlled` is required for the keyboard-avoidance
  /// below to have anywhere to expand into.
  static Future<void> show(BuildContext context, {required DateTime date}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => AddMealBottomSheet(date: date),
      );

  @override
  ConsumerState<AddMealBottomSheet> createState() => _AddMealBottomSheetState();
}

class _AddMealBottomSheetState extends ConsumerState<AddMealBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _fatController = TextEditingController();
  final _carbsController = TextEditingController();
  final _proteinController = TextEditingController();

  bool _saving = false;
  String? _saveError;

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
                maxLength: _maxNameLength,
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

  static const int _maxNameLength = 100;

  String? _validateName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'שדה חובה';
    }
    if (trimmed.length > _maxNameLength) {
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
