import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

/// Opens the app's database on a platform that has a filesystem.
///
/// The native half of the conditional export in `database_factory.dart` — see
/// there for why the choice is made at compile time rather than with `kIsWeb`.
///
/// `path_provider` is imported here and nowhere else: it has no web
/// implementation, so a shared import would throw a `MissingPluginException`
/// in the browser before `runApp`.
Future<Database> openAppDatabase() async {
  final dir = await _databaseDirectory();
  return databaseFactoryIo.openDatabase('${dir.path}/$appDatabaseName');
}

/// Where the database file lives, which is not the same answer on mobile and
/// on desktop.
///
/// **Mobile keeps the documents directory.** It is what iOS backs up and never
/// reclaims, and — more pressingly — it is where every existing install
/// already has its data. Moving it would silently orphan a user's diary.
///
/// **Desktop uses the application-support directory**, and this is a fix
/// rather than a preference. `path_provider_linux` implements
/// `getApplicationDocumentsDirectory()` by shelling out to `xdg-user-dir`,
/// which is not installed on a minimal system; when it is missing the call
/// throws `MissingPlatformDirectoryException` and the app dies on its error
/// screen before the first frame of real UI. Found by running the Linux build,
/// not by any test — `flutter test` never calls it.
///
/// Application support is also the semantically correct directory for a
/// database the user never opens by hand: documents is for files a person is
/// meant to see. `getApplicationSupportDirectory()` resolves from
/// `XDG_DATA_HOME` (or `$HOME/.local/share`) with no external binary involved,
/// so it cannot fail the same way.
Future<Directory> _databaseDirectory() async {
  if (Platform.isAndroid || Platform.isIOS) {
    return getApplicationDocumentsDirectory();
  }
  return getApplicationSupportDirectory();
}

/// The database's name — a filename on native, an IndexedDB store name on web.
const String appDatabaseName = 'fantastic.db';
