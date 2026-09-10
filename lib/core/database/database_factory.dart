/// Opens the app's database on whichever platform it is compiled for.
///
/// The import is resolved at compile time, not with a `kIsWeb` branch: a
/// runtime check would still drag `path_provider` and `dart:io` into the web
/// bundle, and the web bundle cannot link them. Defaulting to the web file and
/// switching on `dart.library.io` — rather than the other way round — means
/// every non-VM target (dart2js, dartdevc, wasm) gets the browser factory,
/// including ones that do not exist yet.
///
/// Exposes `openAppDatabase()` and `appDatabaseName`; `main.dart` is the only
/// caller, and hands the result to `databaseProvider`.
library;

export 'database_factory_web.dart'
    if (dart.library.io) 'database_factory_io.dart';
