import 'package:fantastic/features/onboarding/domain/models/biological_sex.dart';
import 'package:fantastic/features/onboarding/domain/models/onboarding_data.dart';
import 'package:fantastic/features/onboarding/presentation/onboarding_validators.dart';
import 'package:fantastic/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// Step 2 of 4 — the biometrics the macro calculation needs.
///
/// Sex, age, weight and height feed Mifflin-St Jeor. The "כבר בקטו?" toggle
/// and its date picker feed the streak seed — `design/ui_ux_design.md` §1b
/// and `design/tasks.md` both specify them, Epic #8's Definition of Done
/// requires the seeding they enable, and #70's text has neither
/// (`design/m4_preflight.md` §1.3).
///
/// Answers leave as a [PartialOnboardingData] in go_router's `extra`.
class OnboardingScreen2 extends StatefulWidget {
  const OnboardingScreen2({super.key});

  @override
  State<OnboardingScreen2> createState() => _OnboardingScreen2State();
}

class _OnboardingScreen2State extends State<OnboardingScreen2> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  /// Defaulted rather than nullable: a segmented control with nothing
  /// selected reads as broken, and both options are equally likely.
  BiologicalSex _sex = BiologicalSex.female;

  bool _alreadyOnKeto = false;
  DateTime? _ketoStartDate;

  /// How far back the start-date picker reaches.
  ///
  /// Two years. Someone three years in is not being onboarded for the first
  /// time, and an unbounded picker makes the common case — a few weeks ago —
  /// a long scroll.
  static const int _maxPastYears = 2;

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: 2,
      title: 'קצת עליכם',
      ctaLabel: 'הבא',
      onNext: _onNext,
      child: Form(
        key: _formKey,
        // A `SingleChildScrollView` + `Column`, never a `ListView`. A
        // `ListView` builds lazily, and a `TextFormField` it has disposed
        // deregisters itself from the enclosing `Form` — so `validate()`
        // silently skips it and returns true for a field the user never
        // filled. `_onNext` then parses an empty controller and throws. The
        // fields here fit without scrolling at the default text scale, but a
        // large accessibility scale is exactly the case that pushes one past
        // the viewport's cache extent. A `Column` builds every child eagerly,
        // so every field stays registered however far it is scrolled.
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SexSelector(
                value: _sex,
                onChanged: (sex) => setState(() => _sex = sex),
              ),
              const SizedBox(height: 24),
              TextFormField(
                key: const Key('age_field'),
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'גיל'),
                validator: OnboardingValidators.age,
                // The field holds digits, and a bare digit run is reordered
                // inside the RTL layout without this.
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('weight_field'),
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'משקל (ק״ג)'),
                validator: OnboardingValidators.weightKg,
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('height_field'),
                controller: _heightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'גובה (ס״מ)'),
                validator: OnboardingValidators.heightCm,
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                key: const Key('already_on_keto_switch'),
                value: _alreadyOnKeto,
                onChanged: _onAlreadyOnKetoChanged,
                title: const Text('כבר בקטו?'),
                subtitle: const Text('נמשיך את הרצף מהיום שהתחלתם'),
                contentPadding: EdgeInsets.zero,
              ),
              // Mounted only while the toggle is on, so a date left behind
              // by a toggle the user changed their mind about cannot be read:
              // the state is cleared in the same `setState` that hides the
              // row.
              if (_alreadyOnKeto) _startDateTile(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _startDateTile(BuildContext context) {
    final date = _ketoStartDate;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_outlined),
      title: const Text('תאריך התחלה'),
      subtitle: Text(
        date == null ? 'בחרו תאריך' : DateFormat('d MMMM y', 'he').format(date),
      ),
      trailing: const Icon(Icons.edit_outlined),
      onTap: _pickStartDate,
    );
  }

  void _onAlreadyOnKetoChanged(bool value) {
    setState(() {
      _alreadyOnKeto = value;
      if (!value) {
        _ketoStartDate = null;
      }
    });
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _ketoStartDate ?? now,
      firstDate: DateTime(now.year - _maxPastYears, now.month, now.day),
      // No future start dates: a run that has not begun cannot have banked a
      // day, and `OnboardingService` would ignore one anyway.
      lastDate: now,
    );
    // The picker is a route, and this screen can be gone by the time it
    // closes — the router restarts the flow whenever a step loses its
    // navigation `extra`. `setState` on a disposed `State` throws.
    if (picked != null && mounted) {
      setState(() => _ketoStartDate = picked);
    }
  }

  void _onNext() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final data = PartialOnboardingData(
      sex: _sex,
      age: int.parse(_ageController.text.trim()),
      // Already proved finite and positive by the validators — this cannot
      // return null after `validate()` passed.
      weightKg: OnboardingValidators.positiveFinite(_weightController.text)!,
      heightCm: OnboardingValidators.positiveFinite(_heightController.text)!,
      // Null unless the toggle is on *and* a date was chosen: a toggle
      // switched on and then ignored is not a claim about a start date.
      ketoStartDate: _alreadyOnKeto ? _ketoStartDate : null,
    );

    context.push('/onboarding/3', extra: data);
  }
}

/// Sex, as a two-option segmented control.
class _SexSelector extends StatelessWidget {
  const _SexSelector({required this.value, required this.onChanged});

  final BiologicalSex value;
  final ValueChanged<BiologicalSex> onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SegmentedButton<BiologicalSex>(
        segments: const [
          ButtonSegment(
            value: BiologicalSex.female,
            label: Text('נקבה', key: Key('sex_female')),
          ),
          ButtonSegment(
            value: BiologicalSex.male,
            label: Text('זכר', key: Key('sex_male')),
          ),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}
