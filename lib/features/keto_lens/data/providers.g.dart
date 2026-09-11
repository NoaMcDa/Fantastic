// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Hebrew label parser.
///
/// `keepAlive` because it is stateless and its regexes are compiled once on
/// first use. Rebuilding it per listener would recompile them.

@ProviderFor(labelParser)
const labelParserProvider = LabelParserProvider._();

/// The Hebrew label parser.
///
/// `keepAlive` because it is stateless and its regexes are compiled once on
/// first use. Rebuilding it per listener would recompile them.

final class LabelParserProvider
    extends $FunctionalProvider<LabelParser, LabelParser, LabelParser>
    with $Provider<LabelParser> {
  /// The Hebrew label parser.
  ///
  /// `keepAlive` because it is stateless and its regexes are compiled once on
  /// first use. Rebuilding it per listener would recompile them.
  const LabelParserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labelParserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labelParserHash();

  @$internal
  @override
  $ProviderElement<LabelParser> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LabelParser create(Ref ref) {
    return labelParser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LabelParser value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LabelParser>(value),
    );
  }
}

String _$labelParserHash() => r'b3ac10a6b6eeebfeb99462faec0acf5d1a06c715';
