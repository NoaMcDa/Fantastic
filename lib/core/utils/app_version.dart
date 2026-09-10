import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_version.g.dart';

/// The app's current version string.
///
/// Also serves as the build_runner pipeline's canary: a minimal valid
/// `@riverpod` function, just enough to prove code generation resolves
/// end-to-end (issue #15).
@riverpod
String appVersion(Ref ref) => '1.0.0';
