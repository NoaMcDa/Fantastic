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
  final dir = await getApplicationDocumentsDirectory();
  final db = await Isar.open(
    [], // Schemas registered here as M1 issues land.
    directory: dir.path,
  );
  runApp(
    ProviderScope(
      overrides: [isarProvider.overrideWithValue(db)],
      child: const FantasticApp(),
    ),
  );
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
