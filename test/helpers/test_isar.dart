import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:isar_community/isar.dart';

/// Single-flight guard: `flutter test` runs several test files against the
/// same isolate, and Isar Core must only be initialised once per process.
Future<void>? _initialization;

/// Opens a uniquely-named, in-memory-style Isar instance for a single test.
///
/// Every call gets its own database (named by microsecond timestamp), so
/// two contract tests running in parallel never share state. Pair with
/// [closeTestIsar] in `tearDown`.
///
/// [schemas] must not be empty — Isar rejects an instance with no collections.
Future<Isar> openTestIsar(List<CollectionSchema<dynamic>> schemas) async {
  await _ensureIsarCore();
  return Isar.open(
    schemas,
    directory: Directory.systemTemp.path,
    name: 'test_${DateTime.now().microsecondsSinceEpoch}',
  );
}

/// Closes [isar] and deletes its on-disk files, leaving no leftovers in
/// the system temp directory.
Future<void> closeTestIsar(Isar isar) async {
  await isar.close(deleteFromDisk: true);
}

/// Path of the Isar Core native binary shipped inside the already-installed
/// `isar_community_flutter_libs` package, or `null` if it cannot be resolved.
///
/// Exposed so a test can assert the offline path is genuinely available rather
/// than inferring it from the absence of a network error.
Future<String?> resolveBundledIsarCorePath() async {
  final root = await _resolvePackageRoot('isar_community_flutter_libs');
  if (root == null) {
    return null;
  }

  final binary = File(root.resolve(_bundledLibraryRelativePath()).toFilePath());
  return binary.existsSync() ? binary.path : null;
}

/// Root URI of an installed package, read from `.dart_tool/package_config.json`.
///
/// `Isolate.resolvePackageUri` is unsupported in the `flutter_tester` runtime,
/// so the package config — which `flutter pub get` always writes — is the way
/// to find a dependency's files from inside a test.
Future<Uri?> _resolvePackageRoot(String packageName) async {
  final configFile = File(
    '${Directory.current.path}/.dart_tool/package_config.json',
  );
  if (!configFile.existsSync()) {
    return null;
  }

  final config =
      jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
  final packages = (config['packages'] as List<dynamic>)
      .cast<Map<String, dynamic>>();

  for (final package in packages) {
    if (package['name'] == packageName) {
      // rootUri may be relative — it is resolved against the directory
      // holding package_config.json, per the package-config spec.
      final raw = package['rootUri'] as String;
      // Guarantee a trailing slash so `resolve` appends to the root rather
      // than replacing its last path segment.
      final rootUri = Uri.parse(raw.endsWith('/') ? raw : '$raw/');
      return configFile.parent.uri.resolveUri(rootUri);
    }
  }
  return null;
}

Future<void> _ensureIsarCore() => _initialization ??= _initializeIsarCoreOnce();

/// Initialises Isar Core from the binary bundled with
/// `isar_community_flutter_libs`, so `flutter test` never touches the network.
///
/// `Isar.initializeIsarCore(download: true)` — what this helper did originally —
/// resolves its download path from `Platform.script`, which under `flutter test`
/// is an ephemeral temp directory. The binary was therefore re-fetched from
/// `binaries.isar-community.dev` on *every* run, and the whole suite failed
/// wherever that host is blocked. But `isar_community_flutter_libs` is already a
/// declared dependency and ships the same native library for every desktop
/// platform, so after `flutter pub get` the binary is always on disk and there
/// is nothing to download.
Future<void> _initializeIsarCoreOnce() async {
  // On a real device the library is loaded by the platform, not by us.
  if (Platform.isIOS || Platform.isAndroid) {
    await Isar.initializeIsarCore();
    return;
  }

  final bundled = await resolveBundledIsarCorePath();
  if (bundled == null) {
    throw StateError(
      'Could not find the Isar Core binary for ${Abi.current()} inside the '
      'isar_community_flutter_libs package.\n'
      'Expected it at <package>/${_bundledLibraryRelativePath()}.\n'
      'Run `flutter pub get` to install the package, and check that '
      'isar_community_flutter_libs is still listed in pubspec.yaml.',
    );
  }

  try {
    await Isar.initializeIsarCore(libraries: {Abi.current(): bundled});
  } on Object catch (error) {
    throw StateError(
      'Failed to load the Isar Core binary at $bundled.\n'
      'It is present but could not be opened — most often an ABI mismatch '
      'between isar_community and isar_community_flutter_libs, which must be '
      'pinned to the same version in pubspec.yaml.\n'
      'Cause: $error',
    );
  }
}

/// Location of the native library inside `isar_community_flutter_libs`,
/// relative to that package's root.
String _bundledLibraryRelativePath() {
  if (Platform.isWindows) {
    return 'windows/libisar.dll';
  }
  if (Platform.isMacOS) {
    return 'macos/libisar.dylib';
  }
  return 'linux/libisar.so';
}
