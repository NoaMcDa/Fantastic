import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

/// Opens the app's database on a platform that has a filesystem.
///
/// The native half of the conditional export in `database_factory.dart` — see
/// there for why the choice is made at compile time rather than with `kIsWeb`.
///
/// One file under the app-documents directory, which is the directory iOS
/// backs up and never reclaims. `path_provider` is imported here and nowhere
/// else: it has no web implementation, so a shared import would throw a
/// `MissingPluginException` in the browser before `runApp`.
Future<Database> openAppDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  return databaseFactoryIo.openDatabase('${dir.path}/$appDatabaseName');
}

/// The database's name — a filename on native, an IndexedDB store name on web.
const String appDatabaseName = 'fantastic.db';
