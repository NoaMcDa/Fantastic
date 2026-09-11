import 'package:fantastic/core/database/database_factory.dart';
import 'package:fantastic/core/database/database_provider.dart';
import 'package:fantastic/core/providers/notification_providers.dart';
import 'package:fantastic/core/router/app_router.dart';
import 'package:fantastic/features/adaptation/application/providers/notification_providers.dart';
import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/onboarding/application/providers/onboarding_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Hebrew month and day names for the dashboard's date header. `DateFormat`
  // with an explicit locale throws without its symbol data loaded.
  await initializeDateFormatting('he');

  // A failure here used to escape `main` unhandled, which on iOS is a crash
  // with a log and in a browser is a blank white page with nothing to read.
  // Rendering the error instead means a broken storage layer is diagnosable
  // on the device it broke on.
  try {
    final db = await openAppDatabase();
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    // Before runApp, so the router's very first redirect already knows
    // whether this is a first launch. The one asynchronous read the gate
    // needs, done here rather than inside go_router's redirect — see
    // `OnboardingGate`. It swallows its own failures and leaves the gate
    // shut: a profile that will not decode is not a database that will not
    // open, and reporting it as one left the app permanently on the failure
    // screen with no way back.
    await seedOnboardingGate(container);

    // Before runApp, so a notification tapped from a cold start has a plugin
    // to be delivered to. A no-op on web — see NotificationService.
    final notifications = await container
        .read(notificationServiceProvider)
        .initialise();
    if (notifications) {
      // Rescheduled on every launch rather than once ever: the id is stable
      // so this replaces rather than accumulates, and it is the only thing
      // that re-arms the reminder after an OS upgrade or a restore has
      // dropped pending notifications. Scheduling before permission is
      // granted is harmless — the OS simply delivers nothing until it is.
      await container
          .read(streakNotificationServiceProvider)
          .scheduleDailyReminder();
    }
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const FantasticApp(),
      ),
    );
  } on Object catch (error) {
    runApp(StartupFailureApp(error: error));
  }
}

class FantasticApp extends ConsumerWidget {
  const FantasticApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp.router(
        routerConfig: ref.watch(appRouterProvider),
        theme: AppTheme.dark,
        locale: const Locale('he'),
        supportedLocales: const [Locale('he'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    );
  }
}

/// Shown when the database cannot be opened, in place of the app.
///
/// Deliberately dependency-free — no router, no providers, no localisation
/// delegates: whatever failed in [main] must not be able to fail again here.
class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.danger),
                  const SizedBox(height: 16),
                  const Text(
                    'לא ניתן לפתוח את מסד הנתונים',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
