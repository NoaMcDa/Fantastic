import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'flows/grace_period_flow.dart' as grace_period;
import 'flows/keto_lens_flow.dart' as keto_lens;
import 'flows/meal_logging_flow.dart' as meal_logging;
import 'flows/navigation_smoke_flow.dart' as navigation_smoke;
import 'flows/onboarding_flow.dart' as onboarding;
import 'flows/storage_failure_flow.dart' as storage_failure;
import 'flows/streak_flow.dart' as streak;
import 'flows/symptom_diary_flow.dart' as symptom_diary;

/// The end-to-end suite. **One entry point, deliberately.**
///
/// Run it with:
///
/// ```bash
/// flutter test -d flutter-tester integration_test/app_test.dart
/// ```
///
/// Two things about that command are load-bearing:
///
/// - **`-d flutter-tester`.** Without a device the run fails outright with
///   "No supported devices connected". With the headless tester it runs the
///   real app — real router, real provider graph, real repositories, real
///   in-memory sembast — on any Linux box, including the CI runner. No
///   simulator, and nothing here is nightly-only
///   (`design/m8_preflight.md` Part 0).
/// - **This file, not the directory.** Only one app launch is allowed per
///   invocation: pointing the runner at `integration_test/` fails the second
///   file with "The log reader failed unexpectedly", whichever file is
///   second (§6.1). Every flow is therefore a plain library exporting
///   `main()`, grouped here — which is also why they are named `_flow.dart`
///   rather than `_flow_test.dart`.
///
/// `flutter test` (the per-PR unit and widget gate) globs `test/` only and
/// never picks any of this up.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('navigation', navigation_smoke.main);
  group('onboarding', onboarding.main);
  group('meal logging', meal_logging.main);
  group('streak', streak.main);
  group('symptom diary', symptom_diary.main);
  group('keto lens', keto_lens.main);
  group('grace period', grace_period.main);
  group('storage failure', storage_failure.main);
}
