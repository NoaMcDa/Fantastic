import 'dart:typed_data';

// `XFile` is re-exported by `image_picker`, which is a direct dependency;
// `cross_file` itself is only transitive, and importing it directly would be
// the implicit dependency `depend_on_referenced_packages` exists to catch.
import 'package:image_picker/image_picker.dart';

/// Reads the bytes behind a picked or captured photo.
///
/// An interface, and injected, for the reason the whole OCR stack is
/// interface-fronted: it keeps `RemoteMacroEstimator` testable with no file
/// system, and it keeps `dart:io` out of a file that ships in the web bundle.
///
/// That second reason is not theoretical. M6 established empirically that
/// dart2js compiles `dart:io` as a library of *throwing stubs* — a naive
/// `File(path).readAsBytes()` analyses clean, builds clean, and then throws
/// at run time in a browser only. `flutter analyze` catches neither half of
/// that. CI's `flutter build web` step catches a `path_provider` import but
/// not this one, so the discipline has to be here.
abstract interface class PhotoBytesReader {
  /// Returns the bytes at [path], or null when they cannot be read.
  ///
  /// **Never throws**, for the same reason `LlmChatClient` never throws: a
  /// file that vanished between the pick and the read, or a permission
  /// revoked in the same window, is a routine outcome of this call and not an
  /// exceptional one.
  Future<Uint8List?> read(String path);
}

/// Reads through `XFile`, which both `image_picker` and `camera` return.
///
/// `XFile` is the picker packages' own cross-platform handle and has a real
/// browser implementation backed by a blob URL, so one implementation covers
/// all six targets and no conditional-export firewall is needed.
class XFilePhotoBytesReader implements PhotoBytesReader {
  const XFilePhotoBytesReader();

  @override
  Future<Uint8List?> read(String path) async {
    try {
      return await XFile(path).readAsBytes();
    } on Object catch (_) {
      // `Object`, not `Exception`: a missing file throws a `FileSystemException`
      // on the VM but a bad blob URL surfaces as an `Error` in the browser, and
      // an `on Exception` clause would miss the second and take the sheet down
      // with it.
      return null;
    }
  }
}
