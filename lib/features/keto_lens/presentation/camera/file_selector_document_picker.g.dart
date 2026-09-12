// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_selector_document_picker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How the menu scanner imports a PDF.
///
/// Overridden in widget tests with a fake.

@ProviderFor(documentPicker)
const documentPickerProvider = DocumentPickerProvider._();

/// How the menu scanner imports a PDF.
///
/// Overridden in widget tests with a fake.

final class DocumentPickerProvider
    extends $FunctionalProvider<DocumentPicker, DocumentPicker, DocumentPicker>
    with $Provider<DocumentPicker> {
  /// How the menu scanner imports a PDF.
  ///
  /// Overridden in widget tests with a fake.
  const DocumentPickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'documentPickerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$documentPickerHash();

  @$internal
  @override
  $ProviderElement<DocumentPicker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DocumentPicker create(Ref ref) {
    return documentPicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DocumentPicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DocumentPicker>(value),
    );
  }
}

String _$documentPickerHash() => r'27459c881b10bf00603f09005bc754102795f728';
