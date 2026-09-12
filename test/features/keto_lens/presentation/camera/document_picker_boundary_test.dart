import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces the one-adapter-one-plugin discipline `file_selector_document_
/// picker.dart` claims for itself in its own doc comment: `PhotoPicker` and
/// `ImagePickerPhotoPicker` make the same claim about `image_picker`, but
/// nothing before this checked either claim against the actual source tree.
void main() {
  test('file_selector is imported by exactly one file under lib/', () {
    final libDir = Directory('lib');

    final importers = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) => file.readAsStringSync().contains(
            "import 'package:file_selector/",
          ),
        )
        .map((file) => file.path.replaceAll(r'\', '/'))
        .toList();

    expect(importers, [
      'lib/features/keto_lens/presentation/camera/file_selector_document_picker.dart',
    ]);
  });
}
