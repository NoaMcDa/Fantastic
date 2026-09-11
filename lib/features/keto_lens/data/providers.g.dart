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

/// The product-level verdict rule.
///
/// `keepAlive` for the same reason as [ingredientClassifier]: it is stateless,
/// and every threshold it reads is a compile-time constant.

@ProviderFor(macroClassifier)
const macroClassifierProvider = MacroClassifierProvider._();

/// The product-level verdict rule.
///
/// `keepAlive` for the same reason as [ingredientClassifier]: it is stateless,
/// and every threshold it reads is a compile-time constant.

final class MacroClassifierProvider
    extends
        $FunctionalProvider<MacroClassifier, MacroClassifier, MacroClassifier>
    with $Provider<MacroClassifier> {
  /// The product-level verdict rule.
  ///
  /// `keepAlive` for the same reason as [ingredientClassifier]: it is stateless,
  /// and every threshold it reads is a compile-time constant.
  const MacroClassifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'macroClassifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$macroClassifierHash();

  @$internal
  @override
  $ProviderElement<MacroClassifier> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MacroClassifier create(Ref ref) {
    return macroClassifier(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MacroClassifier value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MacroClassifier>(value),
    );
  }
}

String _$macroClassifierHash() => r'2f0a6a18759b0343f4a26e30ff7f08e5d9154a21';

/// On-device OCR, or the stub that says it is unavailable.
///
/// Which one is decided at compile time by the conditional export in
/// `adapters/text_recognizer_factory.dart`, not here and not at run time.
/// This provider cannot name either concrete class — that is the point of
/// the firewall.
///
/// `keepAlive` because it is stateless: the native recogniser it wraps is
/// created and closed inside each `recognise` call, so nothing is held
/// between scans.

@ProviderFor(textRecognitionService)
const textRecognitionServiceProvider = TextRecognitionServiceProvider._();

/// On-device OCR, or the stub that says it is unavailable.
///
/// Which one is decided at compile time by the conditional export in
/// `adapters/text_recognizer_factory.dart`, not here and not at run time.
/// This provider cannot name either concrete class — that is the point of
/// the firewall.
///
/// `keepAlive` because it is stateless: the native recogniser it wraps is
/// created and closed inside each `recognise` call, so nothing is held
/// between scans.

final class TextRecognitionServiceProvider
    extends
        $FunctionalProvider<
          TextRecognitionService,
          TextRecognitionService,
          TextRecognitionService
        >
    with $Provider<TextRecognitionService> {
  /// On-device OCR, or the stub that says it is unavailable.
  ///
  /// Which one is decided at compile time by the conditional export in
  /// `adapters/text_recognizer_factory.dart`, not here and not at run time.
  /// This provider cannot name either concrete class — that is the point of
  /// the firewall.
  ///
  /// `keepAlive` because it is stateless: the native recogniser it wraps is
  /// created and closed inside each `recognise` call, so nothing is held
  /// between scans.
  const TextRecognitionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'textRecognitionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$textRecognitionServiceHash();

  @$internal
  @override
  $ProviderElement<TextRecognitionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TextRecognitionService create(Ref ref) {
    return textRecognitionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TextRecognitionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TextRecognitionService>(value),
    );
  }
}

String _$textRecognitionServiceHash() =>
    r'ade4b940c7ee8811b441d03b91df22d029e70ec5';
