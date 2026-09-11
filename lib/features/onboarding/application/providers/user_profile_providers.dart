import 'package:fantastic/features/onboarding/data/providers.dart';
import 'package:fantastic/features/onboarding/domain/models/macro_targets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_profile_providers.g.dart';

/// The macro targets the dashboard measures a day against.
///
/// A stream rather than a one-shot read, for the same reason
/// `streakStateProvider` is one: the dashboard must repaint the moment
/// onboarding writes, and no caller should have to remember to invalidate
/// after a save. `UserProfileRepository.watch()` fires immediately, so this
/// has a value without a separate `load`.
///
/// [MacroTargets.defaults] — the `KetoConstants` values `MacroSummaryCard`
/// read directly through M2 and M3 — until a profile exists.
///
/// Deliberately still an `AsyncValue`: a profile that cannot be *read* is not
/// a profile that is *absent*, and a card that quietly showed 150 g of fat to
/// someone whose real target is 250 g would be telling them something false
/// that they then act on (`design/m2_handoff.md` convention 5). The error
/// propagates and `MacroSummaryCard` says the load failed.
@riverpod
Stream<MacroTargets> macroTargets(Ref ref) => ref
    .watch(userProfileRepositoryProvider)
    .watch()
    .map((profile) => profile?.targets ?? MacroTargets.defaults);
