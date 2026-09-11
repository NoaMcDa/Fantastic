/// Genuine Tesseract output captured from **CI**, on an engine version this
/// machine does not have.
///
/// ## Why this is a separate file from `real_ocr_fixture.dart`
///
/// That one is generated: `tool/capture_ocr_fixtures.sh` writes it, and its
/// whole value is that no hand touched it. This one **cannot** be generated
/// here, because it came off a macOS CI runner running **Tesseract 5.5.3**
/// (installed by brew) and the container that produced the other file has
/// **5.3.4**. Transcribing it into the generated file would quietly destroy
/// the one rule that makes that file trustworthy.
///
/// So it lives here instead, and the provenance is stated rather than implied:
/// **this string was copied from a CI job's output, not produced locally.** It
/// is verbatim — no cleanup, no re-spacing — but it has a weaker guarantee
/// than a generated capture, and that difference is the reason for the
/// separate file.
///
/// ## What it is for
///
/// It exists because of a defect that only a second engine version could have
/// found. Tesseract 5.3.4 reads the protein row of this label as `חלבונים`;
/// **5.5.3 reads it as `חזלבונים`** — a spurious `ז` — and the parser's
/// original `חלבו[נן]` keyword does not match that at all. The result on a Mac
/// was a scan that looked entirely healthy, with every other macro present and
/// the basis correctly `per100g`, and **protein silently missing**.
///
/// The general lesson, which `design/m6_platform_handoff.md` now records: raw
/// OCR text is **not stable across engine versions**, so asserting on it is a
/// latent cross-platform failure. The parsed result is the only stable
/// contract, and it is what the tests assert.
abstract final class CiOcrFixture {
  /// The user's whole wheat + rye bread label, read by **Tesseract 5.5.3** on
  /// a macOS runner, through the same `psm 4` / `heb+eng` /
  /// `user_defined_dpi=300` settings and the same `ScalingTextRecognizer`
  /// preparation as every other capture.
  ///
  /// Differs from the 5.3.4 capture in four visible ways, three of them
  /// harmless and one not:
  ///
  /// * `חזלבונים` — **the defect.** A spurious `ז` inside the protein keyword.
  /// * `§` standing in for the fibre row's separator.
  /// * `(Da)` where the fat row's `(גרם)` should be.
  /// * the fat row printing its number *before* its keyword.
  static const String wholeWheatRyeBread553 = """
ערך תזונתי ל-100 גר' מוצר
אנרגיה (קלוריות ) 238
חזלבונים (גרם) 10.9
פחמימות (גרם) 41.2
כלל סיבים תזונתיים (גרם) § 7
3.3 (Da) ‏שומנים‎
מתוכם שומן רווי (גרם) 0.9
מתוכם שומן טראנס (גרם) ‎F‏ פחות מ-0.5
מתוכם כולסטרול (מ"ג) פחות מ-2.5
נתרן (מ"ג) 368""";
}
