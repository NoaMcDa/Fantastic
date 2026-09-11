import 'dart:convert';
import 'dart:typed_data';

import 'package:fantastic/features/diary/data/estimation/meal_photo_prep.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// A solid-colour bitmap, encoded as PNG so nothing here depends on a JPEG
/// round trip it is also the subject of.
Uint8List bitmap(
  int width,
  int height, {
  int r = 200,
  int g = 120,
  int b = 40,
}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(r, g, b));
  return Uint8List.fromList(img.encodePng(image));
}

/// Decodes what [MealPhotoPrep.prepare] produced, so a test can assert on the
/// pixels that would actually be sent rather than on a length.
img.Image sent(String base64) => img.decodeImage(base64Decode(base64))!;

void main() {
  group('the budget', () {
    test('an image over maxEdge is downscaled so its longest edge is maxEdge', () {
      final prepared = MealPhotoPrep.prepare(bitmap(4032, 3024))!;

      final image = sent(prepared);
      expect(image.width, MealPhotoPrep.maxEdge);
      // The aspect ratio survives: 4032x3024 is 4:3, so 1024 wide is 768 tall.
      expect(image.height, 768);
    });

    test('a portrait image is fitted by its height, not its width', () {
      final prepared = MealPhotoPrep.prepare(bitmap(3024, 4032))!;

      final image = sent(prepared);
      expect(image.height, MealPhotoPrep.maxEdge);
      expect(image.width, 768);
    });

    // The opposite of `OcrImagePrep`, deliberately: enlarging a thumbnail adds
    // no information a model can use and multiplies the billed bytes.
    test('an image under maxEdge is not upscaled', () {
      final prepared = MealPhotoPrep.prepare(bitmap(320, 240))!;

      final image = sent(prepared);
      expect(image.width, 320);
      expect(image.height, 240);
    });

    test('an image exactly at maxEdge is left alone', () {
      final prepared = MealPhotoPrep.prepare(
        bitmap(MealPhotoPrep.maxEdge, 500),
      )!;

      expect(sent(prepared).width, MealPhotoPrep.maxEdge);
    });

    test('a 1x1 image is handled without an exception', () {
      final prepared = MealPhotoPrep.prepare(bitmap(1, 1));

      expect(prepared, isNotNull);
      expect(sent(prepared!).width, 1);
    });
  });

  group('refusals', () {
    test('bytes that are not a decodable image return null', () {
      expect(
        MealPhotoPrep.prepare(Uint8List.fromList(utf8.encode('not an image'))),
        isNull,
      );
    });

    test('empty bytes return null rather than throwing', () {
      expect(MealPhotoPrep.prepare(Uint8List(0)), isNull);
    });

    // Nothing a camera produces reaches this, which is the point: the ceiling
    // is a refusal to send something pathological, not a tuning knob.
    test('a payload over maxEncodedBytes returns null rather than sending', () {
      // Pure random noise at maxEdge: JPEG cannot compress it, so it is the
      // densest thing that survives the downscale.
      final noise = img.Image(
        width: MealPhotoPrep.maxEdge,
        height: MealPhotoPrep.maxEdge,
      );
      var seed = 1;
      for (final pixel in noise) {
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        pixel
          ..r = seed & 0xff
          ..g = (seed >> 8) & 0xff
          ..b = (seed >> 16) & 0xff;
      }
      final bytes = Uint8List.fromList(img.encodePng(noise));

      // Asserted against the constant rather than against a hard-coded size:
      // the test must keep meaning what it says if the budget moves.
      final prepared = MealPhotoPrep.prepare(bytes);
      if (prepared != null) {
        expect(
          prepared.length,
          lessThanOrEqualTo(MealPhotoPrep.maxEncodedBytes),
        );
      }
      // Prove the ceiling is what would stop it, by measuring the same image
      // encoded at the same settings with no ceiling applied.
      final unbounded = base64Encode(
        img.encodeJpg(noise, quality: MealPhotoPrep.jpegQuality),
      );
      expect(
        prepared,
        unbounded.length > MealPhotoPrep.maxEncodedBytes ? isNull : isNotNull,
      );
    });
  });

  group('the encoding', () {
    test('is JPEG, matching the declared media type', () {
      final prepared = MealPhotoPrep.prepare(bitmap(800, 600))!;

      // The two-byte JPEG SOI marker. The constant and the bytes are one
      // decision and must not be able to drift apart.
      final bytes = base64Decode(prepared);
      expect(bytes[0], 0xFF);
      expect(bytes[1], 0xD8);
      expect(MealPhotoPrep.mediaType, 'image/jpeg');
    });

    test('is valid base64 that round-trips to a decodable image', () {
      final prepared = MealPhotoPrep.prepare(bitmap(640, 480))!;

      expect(() => base64Decode(prepared), returnsNormally);
      expect(img.decodeImage(base64Decode(prepared)), isNotNull);
    });

    test('a PNG input comes back as JPEG, not passed through', () {
      final png = bitmap(200, 200);
      final prepared = MealPhotoPrep.prepare(png)!;

      expect(base64Decode(prepared), isNot(orderedEquals(png)));
    });
  });
}
