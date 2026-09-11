import 'package:fantastic/features/onboarding/data/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_gate.g.dart';

/// Whether onboarding has been completed, as the router needs to know it:
/// **synchronously**.
///
/// #74 specifies an async `hasCompletedOnboarding` provider awaited inside
/// go_router's `redirect`. That cannot ship, for two reasons
/// (`design/m4_preflight.md` §1.2):
///
/// - riverpod 3 reports a provider that fails *before ever producing a
///   value* as `AsyncLoading` **with an error attached**, and its `.future`
///   never completes. The gate reads storage, so a storage failure is
///   precisely its first-value failure mode — and an awaited redirect that
///   never returns leaves the app on a blank screen with no error and no way
///   forward.
/// - Routing would then be asynchronous on every navigation, to answer a
///   question that changes exactly once in the life of an install.
///
/// So the one asynchronous read happens once, at startup, in
/// [seedOnboardingGate], and both transitions afterwards are explicit:
/// `main` seeds it, and onboarding screen 4 calls [markCompleted]. #74's
/// own plan has `OnboardingService` calling `ref.invalidate` — it holds no
/// `Ref` and cannot, which is why the flow as written bounces the user
/// straight back into onboarding forever (§1.1).
///
/// **False is the safe default**: an install that has not been seeded yet,
/// or one whose profile could not be read, shows onboarding. Showing it
/// again is a nuisance; skipping it leaves the user measured against targets
/// they never set.
@Riverpod(keepAlive: true)
class OnboardingGate extends _$OnboardingGate {
  @override
  bool build() => false;

  /// Opens the gate. Called once by [seedOnboardingGate] on a launch with a
  /// stored profile, and once by screen 4 when the flow is committed.
  void markCompleted() => state = true;
}

/// Reads the stored profile and opens the gate if onboarding is done.
///
/// Called from `main` before `runApp`, alongside the database open, so the
/// router's first redirect already has the answer. The profile *record's
/// existence* is the flag — there is no separate boolean, and no
/// `shared_preferences` (`design/m4_preflight.md` §4).
///
/// A top-level function rather than logic inside `main` so it is testable:
/// `main` itself cannot be pumped.
Future<void> seedOnboardingGate(ProviderContainer container) async {
  final profile = await container.read(userProfileRepositoryProvider).load();
  if (profile != null) {
    container.read(onboardingGateProvider.notifier).markCompleted();
  }
}
