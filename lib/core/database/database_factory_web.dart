import 'package:sembast_web/sembast_web.dart';

/// Opens the app's database in a browser, backed by IndexedDB.
///
/// The web half of the conditional export in `database_factory.dart`. There is
/// no path to build: `databaseFactoryWeb` reads the argument as an IndexedDB
/// database name, so `path_provider` is neither imported nor needed here.
///
/// `sembast_web` reaches IndexedDB through `package:web`, not the deprecated
/// `dart:html`, which is what keeps a `--wasm` build possible.
Future<Database> openAppDatabase() =>
    databaseFactoryWeb.openDatabase(appDatabaseName);

/// The database's name — a filename on native, an IndexedDB store name on web.
const String appDatabaseName = 'fantastic.db';
