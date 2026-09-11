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

/// The ingredient classifier.
///
/// `keepAlive` for the same reason as [labelParser]: it is stateless, and
/// its rule lists are compile-time constants.

@ProviderFor(ingredientClassifier)
const ingredientClassifierProvider = IngredientClassifierProvider._();

/// The ingredient classifier.
///
/// `keepAlive` for the same reason as [labelParser]: it is stateless, and
/// its rule lists are compile-time constants.

final class IngredientClassifierProvider
    extends
        $FunctionalProvider<
          IngredientClassifier,
          IngredientClassifier,
          IngredientClassifier
        >
    with $Provider<IngredientClassifier> {
  /// The ingredient classifier.
  ///
  /// `keepAlive` for the same reason as [labelParser]: it is stateless, and
  /// its rule lists are compile-time constants.
  const IngredientClassifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ingredientClassifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ingredientClassifierHash();

  @$internal
  @override
  $ProviderElement<IngredientClassifier> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IngredientClassifier create(Ref ref) {
    return ingredientClassifier(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IngredientClassifier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IngredientClassifier>(value),
    );
  }
}

String _$ingredientClassifierHash() =>
    r'3fe5ce50504009c24ec565adeb6f45d7b488aad8';
