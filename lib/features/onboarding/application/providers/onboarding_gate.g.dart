// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_gate.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(OnboardingGate)
const onboardingGateProvider = OnboardingGateProvider._();

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
final class OnboardingGateProvider
    extends $NotifierProvider<OnboardingGate, bool> {
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
  const OnboardingGateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingGateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingGateHash();

  @$internal
  @override
  OnboardingGate create() => OnboardingGate();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$onboardingGateHash() => r'befe0015e3a67e0d71209563393dfa6cac0788c7';

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

abstract class _$OnboardingGate extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
