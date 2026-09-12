// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The on-device menu-page OCR loop.
///
/// Not `keepAlive`: unlike the stateless Keto Lens wiring it wraps, this
/// holds no compiled state worth keeping between scans, and a fresh instance
/// per listener costs nothing but a field assignment.

@ProviderFor(menuPageReader)
const menuPageReaderProvider = MenuPageReaderProvider._();

/// The on-device menu-page OCR loop.
///
/// Not `keepAlive`: unlike the stateless Keto Lens wiring it wraps, this
/// holds no compiled state worth keeping between scans, and a fresh instance
/// per listener costs nothing but a field assignment.

final class MenuPageReaderProvider
    extends $FunctionalProvider<MenuPageReader, MenuPageReader, MenuPageReader>
    with $Provider<MenuPageReader> {
  /// The on-device menu-page OCR loop.
  ///
  /// Not `keepAlive`: unlike the stateless Keto Lens wiring it wraps, this
  /// holds no compiled state worth keeping between scans, and a fresh instance
  /// per listener costs nothing but a field assignment.
  const MenuPageReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'menuPageReaderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$menuPageReaderHash();

  @$internal
  @override
  $ProviderElement<MenuPageReader> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MenuPageReader create(Ref ref) {
    return menuPageReader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MenuPageReader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MenuPageReader>(value),
    );
  }
}

String _$menuPageReaderHash() => r'430ac442fe9681d19ba5689a8f4092475b30770b';

/// Reads a PDF menu's text layer. `keepAlive`, matching the Keto Lens OCR
/// wiring this sits beside: `PdfrxPageExtractor` is stateless (a `const`
/// constructor) and cheap to keep, and there is no per-scan state worth
/// discarding between listeners the way there would be for a stateful
/// engine.

@ProviderFor(pdfPageExtractor)
const pdfPageExtractorProvider = PdfPageExtractorProvider._();

/// Reads a PDF menu's text layer. `keepAlive`, matching the Keto Lens OCR
/// wiring this sits beside: `PdfrxPageExtractor` is stateless (a `const`
/// constructor) and cheap to keep, and there is no per-scan state worth
/// discarding between listeners the way there would be for a stateful
/// engine.

final class PdfPageExtractorProvider
    extends
        $FunctionalProvider<
          PdfPageExtractor,
          PdfPageExtractor,
          PdfPageExtractor
        >
    with $Provider<PdfPageExtractor> {
  /// Reads a PDF menu's text layer. `keepAlive`, matching the Keto Lens OCR
  /// wiring this sits beside: `PdfrxPageExtractor` is stateless (a `const`
  /// constructor) and cheap to keep, and there is no per-scan state worth
  /// discarding between listeners the way there would be for a stateful
  /// engine.
  const PdfPageExtractorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pdfPageExtractorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pdfPageExtractorHash();

  @$internal
  @override
  $ProviderElement<PdfPageExtractor> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PdfPageExtractor create(Ref ref) {
    return pdfPageExtractor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PdfPageExtractor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PdfPageExtractor>(value),
    );
  }
}

String _$pdfPageExtractorHash() => r'4e3163c04ab22e33f79b672c479508e9a26cc0de';

/// The composition root for the menu engine, and the **only** file that
/// names a concrete [MenuAnalyzer]. A vision-direct analyser is a second
/// class and a branch here — never an edit above this line.
///
/// `llmChatClientProvider` is M15's seam (`lib/features/diary/data/providers.dart`)
/// — reused rather than duplicated, per `design/m16_menu_scanner_research.md`
/// §4 and `CLAUDE.md`'s note that M16 does not relax the OCR no-network
/// invariant.

@ProviderFor(menuAnalyzer)
const menuAnalyzerProvider = MenuAnalyzerProvider._();

/// The composition root for the menu engine, and the **only** file that
/// names a concrete [MenuAnalyzer]. A vision-direct analyser is a second
/// class and a branch here — never an edit above this line.
///
/// `llmChatClientProvider` is M15's seam (`lib/features/diary/data/providers.dart`)
/// — reused rather than duplicated, per `design/m16_menu_scanner_research.md`
/// §4 and `CLAUDE.md`'s note that M16 does not relax the OCR no-network
/// invariant.

final class MenuAnalyzerProvider
    extends $FunctionalProvider<MenuAnalyzer, MenuAnalyzer, MenuAnalyzer>
    with $Provider<MenuAnalyzer> {
  /// The composition root for the menu engine, and the **only** file that
  /// names a concrete [MenuAnalyzer]. A vision-direct analyser is a second
  /// class and a branch here — never an edit above this line.
  ///
  /// `llmChatClientProvider` is M15's seam (`lib/features/diary/data/providers.dart`)
  /// — reused rather than duplicated, per `design/m16_menu_scanner_research.md`
  /// §4 and `CLAUDE.md`'s note that M16 does not relax the OCR no-network
  /// invariant.
  const MenuAnalyzerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'menuAnalyzerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$menuAnalyzerHash();

  @$internal
  @override
  $ProviderElement<MenuAnalyzer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MenuAnalyzer create(Ref ref) {
    return menuAnalyzer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MenuAnalyzer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MenuAnalyzer>(value),
    );
  }
}

String _$menuAnalyzerHash() => r'cb2c585890a110c2c050eb0dcf0a187a091fa7d0';
