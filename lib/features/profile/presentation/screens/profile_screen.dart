import 'package:fantastic/core/constants/goal_copy.dart';
import 'package:fantastic/core/constants/keto_constants.dart';
import 'package:fantastic/core/constants/profile_copy.dart';
import 'package:fantastic/core/utils/app_version.dart';
import 'package:fantastic/core/utils/numeric_input.dart';
import 'package:fantastic/core/widgets/empty_state_widget.dart';
import 'package:fantastic/core/widgets/skeleton_box.dart';
import 'package:fantastic/features/onboarding/domain/models/user_profile.dart';
import 'package:fantastic/features/profile/application/providers/profile_providers.dart';
import 'package:fantastic/features/profile/presentation/widgets/notification_setting_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `intl` exports a `TextDirection` of its own, which shadows the Flutter one
// and has no `ltr`. Only `DateFormat` is wanted here.
import 'package:intl/intl.dart' show DateFormat;

/// The Profile tab: who the user told the app they are, what it computed for
/// them, and the one setting they can change from inside the app.
///
/// **Read-only, deliberately, and this is not an oversight.** Editing the
/// macro targets needs a validated form, a re-save path through
/// `UserProfileRepository`, and a product decision about whether editing one
/// target re-runs the Mifflin-St Jeor calculation or overrides it — which is
/// more than a polish milestone may absorb (`milestone_conventions.md` §1).
/// Account controls are #221's, in the unscheduled Login epic. So this screen
/// never calls `save`, and the absence of an edit button is the design.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(ProfileCopy.title)),
      body: _body(context, ref, profileAsync),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<UserProfile?> profileAsync,
  ) {
    // `hasError` before `hasValue`, and no `AsyncValue.when`. riverpod 3
    // reports a provider that failed before ever producing a value as
    // `AsyncLoading` *with* an error attached, so a loading-first check spins
    // forever — the failure that cost four milestones in four disguises.
    //
    // Blank fields would be worse than a spinner here: a profile that cannot
    // be *read* is not a profile that says zero.
    if (profileAsync.hasError) {
      return const Center(
        key: Key('profile_load_failed'),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(ProfileCopy.loadFailed, textAlign: TextAlign.center),
        ),
      );
    }

    if (!profileAsync.hasValue) {
      return const _ProfileSkeleton();
    }

    final profile = profileAsync.requireValue;
    // Should be unreachable — the router's onboarding gate is what keeps a
    // profileless user out of the tab shell. Rendered anyway: a screen cannot
    // see the route guard in front of it, and "distinguishable from a failed
    // read" is a requirement either way.
    if (profile == null) {
      return const Center(
        key: Key('profile_not_onboarded'),
        child: EmptyStateWidget(
          icon: Icons.person_outline,
          headline: ProfileCopy.notOnboardedTitle,
          subtitle: ProfileCopy.notOnboardedBody,
        ),
      );
    }

    return _Profile(profile: profile, version: ref.watch(appVersionProvider));
  }
}

class _Profile extends StatelessWidget {
  const _Profile({required this.profile, required this.version});

  final UserProfile profile;
  final String version;

  @override
  Widget build(BuildContext context) {
    final targets = profile.targets;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const _SectionHeader(ProfileCopy.biometricsSection),
        _ValueRow(
          key: const Key('profile_sex'),
          label: ProfileCopy.sex,
          // Not a digit run, so no `TextDirection.ltr`: it is Hebrew.
          value: ProfileCopy.sexes[profile.sex]!,
          numeric: false,
        ),
        _ValueRow(
          key: const Key('profile_age'),
          label: ProfileCopy.age,
          value: '${profile.age}',
          unit: ProfileCopy.years,
        ),
        _ValueRow(
          key: const Key('profile_weight'),
          label: ProfileCopy.weight,
          value: GramsText.format(profile.weightKg),
          unit: ProfileCopy.kg,
        ),
        _ValueRow(
          key: const Key('profile_height'),
          label: ProfileCopy.height,
          value: GramsText.format(profile.heightCm),
          unit: ProfileCopy.cm,
        ),

        const _SectionHeader(ProfileCopy.goalSection),
        _ValueRow(
          key: const Key('profile_goal'),
          label: GoalCopy.titles[profile.goal]!,
          value: GoalCopy.subtitles[profile.goal]!,
          numeric: false,
        ),

        const _SectionHeader(ProfileCopy.targetsSection),
        _ValueRow(
          key: const Key('profile_target_fat'),
          label: ProfileCopy.fat,
          value: GramsText.format(targets.fatG),
          unit: ProfileCopy.grams,
        ),
        _ValueRow(
          key: const Key('profile_target_net_carbs'),
          label: ProfileCopy.netCarbs,
          value: GramsText.format(targets.netCarbsG),
          unit: ProfileCopy.grams,
        ),
        _ValueRow(
          key: const Key('profile_target_protein'),
          label: ProfileCopy.protein,
          value: GramsText.format(targets.proteinG),
          unit: ProfileCopy.grams,
        ),
        _ValueRow(
          key: const Key('profile_keto_ratio'),
          label: ProfileCopy.ketoRatio,
          value: GramsText.format(KetoConstants.targetKetoRatioIdeal),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text(ProfileCopy.readOnlyNote),
        ),

        // Omitted rather than rendered empty when there is no start date —
        // `ketoStartDate` is nullable and an onboarding flow can skip it.
        if (profile.ketoStartDate != null)
          _ValueRow(
            key: const Key('profile_keto_start_date'),
            label: ProfileCopy.ketoStartDate,
            value: _formatDate(profile.ketoStartDate!),
            numeric: false,
          ),

        const _SectionHeader(ProfileCopy.notificationsSection),
        const NotificationSettingTile(),

        const _SectionHeader(ProfileCopy.aboutSection),
        _ValueRow(
          key: const Key('profile_app_version'),
          label: ProfileCopy.appVersion,
          value: version,
        ),
      ],
    );
  }

  /// `9 בספטמבר 2026`, falling back to the locale-independent format.
  ///
  /// `DateFormat` with an explicit locale throws when its symbol data was
  /// never initialised, and a date row is not worth taking the tab down over
  /// — the same guard `DashboardScreen._formatHebrewDate` carries.
  static String _formatDate(DateTime date) {
    try {
      return DateFormat('d MMMM yyyy', 'he').format(date);
    } on Object catch (_) {
      return DateFormat('d MMMM yyyy').format(date);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text(
      title,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(fontWeight: FontWeight.bold),
    ),
  );
}

/// One label-and-value row.
///
/// [numeric] wraps the value in `TextDirection.ltr`. Every digit run inside
/// this RTL layout needs it — a bare `42.5` reorders, which is the M3 trap
/// `_MacroProgressRow` already guards against. Hebrew values pass
/// `numeric: false` so they stay in the page's own direction.
class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    this.unit,
    this.numeric = true,
    super.key,
  });

  final String label;
  final String value;
  final String? unit;
  final bool numeric;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    title: Text(label),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, textDirection: numeric ? TextDirection.ltr : null),
        if (unit != null) ...[const SizedBox(width: 4), Text(unit!)],
      ],
    ),
  );
}

/// The screen's shape before the profile resolves.
///
/// Static, per #88: an indeterminate animation on a tab screen makes
/// `pumpAndSettle` never return, and `test/widget_test.dart` visits every tab
/// knowing nothing about what is on it.
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      for (var i = 0; i < 8; i++)
        const Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 110, height: 16),
              SkeletonBox(width: 60, height: 16),
            ],
          ),
        ),
    ],
  );
}
