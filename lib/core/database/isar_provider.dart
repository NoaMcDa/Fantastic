import 'package:isar_community/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'isar_provider.g.dart';

// Schemas will be added here as M1 issues land.
@Riverpod(keepAlive: true)
Isar isar(Ref ref) => throw UnimplementedError(
  'isarProvider must be overridden at app root with an opened Isar instance',
);
