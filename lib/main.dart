import 'package:fantastic/core/database/isar_provider.dart';
import 'package:fantastic/core/router/app_router.dart';
import 'package:fantastic/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await openAppIsar();
  runApp(
    ProviderScope(
      overrides: [if (db != null) isarProvider.overrideWithValue(db)],
      child: const FantasticApp(),
    ),
  );
}

/// Opens the app's database, or returns `null` while no collection has been
/// registered in [appIsarSchemas].
///
/// `Isar.open` rejects an empty schema list outright — its first act is to
/// throw `IsarError: At least one collection needs to be opened` — so opening
/// unconditionally killed `main()` before `runApp` and the app never launched.
/// M0 registers no collections by design, so until M1 fills [appIsarSchemas]
/// the right move is to not open Isar at all: `isarProvider` stays
/// un-overridden, which already throws a descriptive error if anything reads
/// it, and nothing in M0 does.
@visibleForTesting
Future<Isar?> openAppIsar() async {
  if (appIsarSchemas.isEmpty) {
    return null;
  }

  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(appIsarSchemas, directory: dir.path);
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
