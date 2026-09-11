import 'package:fantastic/core/constants/profile_copy.dart';
import 'package:fantastic/core/widgets/skeleton_box.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/domain/models/estimation_settings.dart';
import 'package:fantastic/features/profile/application/providers/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the user opts in to estimation, and pastes their key.
///
/// **This is the only place in the app that turns on sending anything
/// anywhere.** sembast is local, Tesseract is bundled, and Keto Lens's
/// no-network invariant is untouched by M15 — a scan still makes no network
/// call. Estimation is different, so it is opt-in, and the disclosure is
/// always visible rather than behind an expander.
///
/// The key is the user's own because the free tier is 50 requests a day *per
/// key*: one key shipped inside the app would be exhausted by a handful of
/// users before lunch, and a key in a Flutter bundle is extractable anyway.
class EstimationSettingsSection extends ConsumerStatefulWidget {
  const EstimationSettingsSection({super.key});

  /// Apple HIG's minimum touch target.
  ///
  /// A fourth copy of this constant, after the two symptom widgets and
  /// `NotificationSettingTile`. Still left duplicated: hoisting it spans four
  /// features and would make this issue non-atomic.
  static const double minTouchTarget = 44;

  /// How many trailing characters of a stored key are shown.
  ///
  /// Enough to tell two keys apart, not enough to be worth shoulder-surfing.
  static const int visibleKeyTail = 4;

  @override
  ConsumerState<EstimationSettingsSection> createState() =>
      _EstimationSettingsSectionState();
}

class _EstimationSettingsSectionState
    extends ConsumerState<EstimationSettingsSection> {
  final TextEditingController _key = TextEditingController();

  bool _consent = false;
  bool _obscured = true;
  bool _saving = false;
  bool _failed = false;

  /// Whether [_consent] has been seeded from the stored record yet.
  ///
  /// Seeded once rather than on every build: the checkbox is a live control,
  /// and rebinding it to the stored value on each rebuild would undo the
  /// user's tick the moment anything else on the screen changed.
  bool _seeded = false;

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(estimationSettingsProvider);

    // `hasError` before `hasValue`, and no `AsyncValue.when`. riverpod 3
    // reports a provider that failed before ever producing a value as
    // `AsyncLoading` *with* an error attached, so a loading-first check spins
    // forever — four milestones, four disguises.
    //
    // A settings record that cannot be read is not a record saying
    // estimation is off: rendering an unticked checkbox here would invite
    // the user to "fix" something that is not broken.
    if (settingsAsync.hasError) {
      return const _Section(
        child: Text(
          ProfileCopy.estimationLoadFailed,
          key: Key('estimation_load_failed'),
        ),
      );
    }

    if (!settingsAsync.hasValue) {
      return const _Section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeletonBox(width: 220, height: 16),
            SizedBox(height: 12),
            SkeletonBox(width: double.infinity, height: 48),
          ],
        ),
      );
    }

    final settings = settingsAsync.requireValue;
    if (!_seeded) {
      _consent = settings.consentAccepted;
      _seeded = true;
    }

    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ProfileCopy.estimationDisclosure,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          _consentRow(),
          const SizedBox(height: 8),
          _keyField(settings),
          const SizedBox(height: 12),
          _actions(settings),
          const SizedBox(height: 12),
          _stateLine(settings),
          if (_failed) ...[
            const SizedBox(height: 8),
            const Text(
              ProfileCopy.estimationSaveFailed,
              key: Key('estimation_save_failed'),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            ProfileCopy.estimationKeyHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          // Selectable rather than tappable: M15 adds no plugin, and
          // `url_launcher` for one tap of convenience is not the trade. A
          // selectable URL works on all six targets.
          const SelectableText(
            ProfileCopy.estimationKeySource,
            key: Key('estimation_key_source'),
            textDirection: TextDirection.ltr,
          ),
        ],
      ),
    );
  }

  Widget _consentRow() => ConstrainedBox(
    constraints: const BoxConstraints(
      minHeight: EstimationSettingsSection.minTouchTarget,
    ),
    child: CheckboxListTile(
      key: const Key('estimation_consent_checkbox'),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      // **Never pre-ticked.** It reflects what was stored, and a fresh
      // install stores `consentAccepted: false`.
      value: _consent,
      onChanged: _saving
          ? null
          : (value) => setState(() => _consent = value ?? false),
      title: const Text(ProfileCopy.estimationConsent),
    ),
  );

  Widget _keyField(EstimationSettings settings) => TextField(
    key: const Key('estimation_api_key_field'),
    controller: _key,
    obscureText: _obscured,
    enabled: !_saving,
    // A key is an opaque Latin run inside an RTL layout.
    textDirection: TextDirection.ltr,
    decoration: InputDecoration(
      labelText: ProfileCopy.estimationApiKey,
      // **A stored key is described, never rendered.** A settings screen is
      // shoulder-surfable, and the field is there to *replace* the key, not
      // to display it — so the placeholder says which key is stored without
      // being the key.
      hintText: _maskOf(settings.apiKey),
      hintTextDirection: TextDirection.ltr,
      suffixIcon: IconButton(
        key: const Key('estimation_key_visibility'),
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
        onPressed: () => setState(() => _obscured = !_obscured),
      ),
    ),
  );

  Widget _actions(EstimationSettings settings) => Row(
    children: [
      Expanded(
        child: FilledButton(
          key: const Key('estimation_save_button'),
          onPressed: _saving ? null : _save,
          child: const Text(ProfileCopy.estimationSave),
        ),
      ),
      if (settings.apiKey?.isNotEmpty ?? false) ...[
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            key: const Key('estimation_remove_key_button'),
            onPressed: _saving ? null : () => _removeKey(settings),
            child: const Text(ProfileCopy.estimationRemoveKey),
          ),
        ),
      ],
    ],
  );

  /// Says which half is missing, never a generic "disabled".
  ///
  /// A user who has pasted a key and not ticked the box, told only that
  /// estimation is off, has no way to know which of the two things to do.
  Widget _stateLine(EstimationSettings settings) {
    final hasKey = settings.apiKey?.isNotEmpty ?? false;
    final text = switch ((hasKey, settings.consentAccepted)) {
      (true, true) => ProfileCopy.estimationOn,
      (false, true) => ProfileCopy.estimationNoKey,
      (true, false) => ProfileCopy.estimationNoConsent,
      (false, false) => ProfileCopy.estimationNoKeyOrConsent,
    };

    return Text(
      text,
      key: const Key('estimation_state_line'),
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  /// `••••••••1234`, or null when nothing is stored.
  static String? _maskOf(String? key) {
    if (key == null || key.isEmpty) {
      return null;
    }
    final tail = key.length <= EstimationSettingsSection.visibleKeyTail
        ? key
        : key.substring(key.length - EstimationSettingsSection.visibleKeyTail);
    return '${'•' * 8}$tail';
  }

  Future<void> _save() async {
    final typed = _key.text.trim();
    final stored = ref.read(estimationSettingsProvider).requireValue;

    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await ref
          .read(estimationSettingsRepositoryProvider)
          .save(
            EstimationSettings(
              // An empty field means "leave the stored key alone", not
              // "clear it" — clearing has its own button, and a user who
              // only wanted to tick the box must not lose their key to it.
              apiKey: typed.isEmpty ? stored.apiKey : typed,
              consentAccepted: _consent,
            ),
          );
      if (!mounted) return;
      // Cleared only on success: on a failure the typed value stays on
      // screen, because emptying it would tell the user something was saved
      // that was not — the rule `AddMealBottomSheet._submit` already follows.
      _key.clear();
      ref.invalidate(estimationSettingsProvider);
    } on Object catch (_) {
      if (mounted) {
        setState(() => _failed = true);
      }
    } finally {
      // In a `finally`, not after the await: a throw would otherwise leave
      // the button disabled for good (`design/m6_handoff.md`).
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _removeKey(EstimationSettings settings) async {
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      // `withoutApiKey`, not `copyWith(apiKey: null)`: null means "unchanged"
      // in every model in this repo, and `StreakState.copyWith` records what
      // breaking that convention cost.
      await ref
          .read(estimationSettingsRepositoryProvider)
          .save(settings.withoutApiKey());
      if (!mounted) return;
      _key.clear();
      ref.invalidate(estimationSettingsProvider);
    } on Object catch (_) {
      if (mounted) {
        setState(() => _failed = true);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

/// The section's heading and padding, shared by all three states.
class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [child],
    ),
  );
}
