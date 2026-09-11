import 'package:fantastic/features/onboarding/application/onboarding_service.dart';
import 'package:fantastic/features/onboarding/application/providers/onboarding_gate.dart';
import 'package:fantastic/features/onboarding/domain/models/macro_targets.dart';
import 'package:fantastic/features/onboarding/domain/models/onboarding_data.dart';
import 'package:fantastic/features/onboarding/presentation/onboarding_validators.dart';
import 'package:fantastic/features/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Step 4 of 4 — the calculated targets, editable, and the commit.
///
/// Showing the computed numbers rather than applying them silently is the
/// point of the screen: the user sees what the app concluded about them and
/// can disagree with it before being measured against it every day.
class OnboardingScreen4 extends ConsumerStatefulWidget {
  const OnboardingScreen4({required this.data, super.key});

  final OnboardingData data;

  @override
  ConsumerState<OnboardingScreen4> createState() => _OnboardingScreen4State();
}

class _OnboardingScreen4State extends ConsumerState<OnboardingScreen4> {
  final _formKey = GlobalKey<FormState>();

  late final MacroTargets _calculated;
  late final TextEditingController _fatController;
  late final TextEditingController _netCarbsController;
  late final TextEditingController _proteinController;

  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    // Synchronous and pure, so there is nothing to await and no loading
    // state to render — `calculateMacroTargets` touches no storage.
    _calculated = ref
        .read(onboardingServiceProvider)
        .calculateMacroTargets(widget.data);
    _fatController = _controllerFor(_calculated.fatG);
    _netCarbsController = _controllerFor(_calculated.netCarbsG);
    _proteinController = _controllerFor(_calculated.proteinG);
  }

  @override
  void dispose() {
    _fatController.dispose();
    _netCarbsController.dispose();
    _proteinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OnboardingScaffold(
      step: 4,
      title: 'היעדים שלכם',
      // `ui_ux_design.md` §1d, not the issue's 'אישור — נתחיל!'.
      ctaLabel: _saving ? 'שומר...' : 'התחל את המסע',
      onNext: _saving ? null : _onConfirm,
      child: Form(
        key: _formKey,
        // A `SingleChildScrollView` + `Column`, never a `ListView` — see
        // `OnboardingScreen2` for why a lazy list under a `Form` lets
        // `validate()` skip a field it has disposed, after which the
        // non-null assertions in `_onConfirm` throw.
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'חישבנו יעדים יומיים לפי הנתונים שמסרתם. אפשר לשנות אותם '
                'עכשיו, וגם בהמשך.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              _targetField(
                key: const Key('fat_target_field'),
                controller: _fatController,
                label: 'שומן יומי (גרם)',
              ),
              const SizedBox(height: 16),
              _targetField(
                key: const Key('carbs_target_field'),
                controller: _netCarbsController,
                // Calculated as the fixed induction allowance and editable
                // anyway: #73 calls 20 g "not user-adjustable" and #72
                // renders it in an editable field. The editable field wins —
                // a target the dashboard judges the user against has to be
                // one they agreed to (`design/m4_preflight.md` §5.4).
                label: 'פחמימות נטו (גרם)',
              ),
              const SizedBox(height: 16),
              _targetField(
                key: const Key('protein_target_field'),
                controller: _proteinController,
                label: 'חלבון (גרם)',
              ),
              if (_saveError != null) ...[
                const SizedBox(height: 16),
                Text(
                  _saveError!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _targetField({
    required Key key,
    required TextEditingController controller,
    required String label,
  }) => TextFormField(
    key: key,
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label),
    validator: OnboardingValidators.macroTargetG,
    // A bare digit run is reordered inside the RTL layout without this.
    textDirection: TextDirection.ltr,
  );

  static TextEditingController _controllerFor(double grams) =>
      TextEditingController(text: grams.toStringAsFixed(0));

  Future<void> _onConfirm() async {
    // The validator, not `double.tryParse(...) ?? fallback`. `tryParse`
    // accepts `Infinity` and `NaN`, neither of which is null, so the issue's
    // fallback never fires for either — and both then divide through every
    // bar on the dashboard (`design/m4_preflight.md` §1.4).
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
    });

    final targets = MacroTargets(
      fatG: OnboardingValidators.positiveFinite(_fatController.text)!,
      netCarbsG: OnboardingValidators.positiveFinite(_netCarbsController.text)!,
      proteinG: OnboardingValidators.positiveFinite(_proteinController.text)!,
    );

    try {
      await ref
          .read(onboardingServiceProvider)
          .completeOnboarding(data: widget.data, targets: targets);
    } on Object catch (_) {
      // Stays on the screen with the numbers intact. Navigating to a
      // dashboard that would immediately send the user back here — because
      // the profile never reached storage — is the worst of both.
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

    // Opens the gate before navigating. Without this the router's redirect
    // still believes onboarding is pending and sends the user straight back
    // to step 1 — forever, on every launch. #74 expects
    // `OnboardingService.completeOnboarding` to invalidate a provider, which
    // it holds no `Ref` to do (`design/m4_preflight.md` §1.1).
    ref.read(onboardingGateProvider.notifier).markCompleted();

    if (!mounted) {
      return;
    }
    // `go`, not `push`: the flow is finished and there is nothing to come
    // back to. '/' rather than '/dashboard' — the alias only redirects here
    // (`design/m4_preflight.md` §5.2).
    context.go('/');
  }
}
