// Applies the app's own pre-OCR preparation to an image, for the fixture
// capture script.
//
// This exists so `tool/capture_ocr_fixtures.py` cannot drift from the app. An
// earlier version of that script did the resize itself with Pillow, and the
// fixture it produced was a fiction: Pillow's LANCZOS and `package:image`'s
// linear kernel disagree enough that the engine read `חלבונים` from one and
// `חזלבונים` from the other - and the second does not match the parser's
// protein keyword at all. A fixture that records an easier image than the app
// actually submits is worse than no fixture.
//
// Pure `dart run` - imports `package:image` and `dart:io` and nothing from
// Flutter, so it needs no device and no test harness.
//
// Usage: dart run tool/prepare_for_ocr.dart <source> <target>
// Exits 0 having written <target>; exits 3 when the image needed no
// preparation, which tells the caller to use the source unchanged.
import 'dart:io';

import 'package:image/image.dart' as img;

import 'package:fantastic/features/keto_lens/data/adapters/scaling_text_recognizer.dart';

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('usage: prepare_for_ocr.dart <source> <target>');
    exit(2);
  }
  final decoded = img.decodeImage(File(args[0]).readAsBytesSync());
  if (decoded == null) {
    stderr.writeln('could not decode ${args[0]}');
    exit(2);
  }
  final prepared = ScalingTextRecognizer.prepare(decoded);
  if (prepared == null) {
    exit(3);
  }
  File(args[1]).writeAsBytesSync(img.encodePng(prepared));
}
