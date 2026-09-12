"""Generates test/fixtures/rendered_menu_ocr_fixture.dart from a rendered
two-column Hebrew menu.

Sibling to tool/capture_ocr_fixtures.py, not a replacement: it reuses that
script's prepare() (the app's own ScalingTextRecognizer.prepare, run through
tool/prepare_for_ocr.dart) and recognise() (the same tesseract invocation, at
the same LANG / PSM / ASSUMED_DPI the app's three adapters pin) unchanged.
This script does not get to re-choose the engine settings.

Two things differ from the label capture:

* the source image is render_labels.render_menu(), a two-column layout, not
  a single-column bordered nutrition panel;
* the output is its own file, test/fixtures/rendered_menu_ocr_fixture.dart,
  never test/fixtures/real_ocr_fixture.dart. That file's own header explains
  why a rendered-vs-photographed distinction has to stay visible, and
  test/fixtures/ci_ocr_fixture.dart is the precedent for "different
  provenance, different file".

Usage: python3 tool/capture_menu_ocr_fixture.py
Needs: tesseract >= 4, python3 with Pillow built against Raqm (for RTL shaping),
       and `dart` on PATH (for tool/prepare_for_ocr.dart).
"""

import os
import shutil
import subprocess
import sys
import tempfile

import render_labels
from capture_ocr_fixtures import (
    ASSUMED_DPI,
    LANG,
    PSM,
    dart_literal,
    prepare,
    recognise,
)

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(REPO, "test", "fixtures", "rendered_menu_ocr_fixture.dart")
IMAGE_OUT = os.path.join(REPO, "test", "fixtures", "images", "menu_grill.png")

# A two-column Israeli grill menu: two sections, each with a full-width bold
# header, a dish/price row on one baseline, and one wrapped description - the
# same shapes test/fixtures/hebrew_menu_fixture.dart's `grill` transcript
# covers by hand, rendered here instead of typed.
GRILL_MENU = [
    "ראשונות",
    (
        "חומוס עם טחינה ולימון",
        "₪28",
        "מוגש עם פטרוזיליה קצוצה, פפריקה ולחמניה חמה לצד",
    ),
    ("סלט ירוק עם רוטב שמן זית ולימון", "₪32", None),
    "עיקריות",
    ("אנטריקוט על הגריל עם ירקות צלויים", "64 ש\"ח", None),
    (
        "שניצל עוף עם פירה ורוטב פטריות",
        "58 ש\"ח",
        "שניצל עוף פריך מוגש עם פירה תפוחי אדמה חמאתי",
    ),
]

HEADER = '''/// Genuine Tesseract output for a **rendered** two-column Hebrew menu.
///
/// Its own file, not part of `real_ocr_fixture.dart`, for the reason
/// `ci_ocr_fixture.dart` is its own file: the provenance differs and saying
/// so is worth more than one import line. The engine output here is real -
/// captured at `-l %(lang)s --psm %(psm)s -c user_defined_dpi=%(dpi)s`
/// against the bundled models, on Tesseract %(version)s - but **the image is
/// rendered, not photographed**: the app's own Assistant font, flat, evenly
/// lit, no glare, no curl, no restaurant lighting. It answers the question
/// `design/m16_menu_scanner_research.md` \xa75 could not: what a
/// segmentation mode pinned for a bordered nutrition table (`psm 4`) does
/// when handed two columns instead of one.
///
/// **Generated, not written. Do not hand-edit.** Regenerate with
/// `python3 tool/capture_menu_ocr_fixture.py`.
///
/// ## What it found about columns
///
/// `psm 4` did **not** interleave the two columns. Every price stayed
/// paired with its own dish, on its own output line, in the right reading
/// order - confirmed with `tesseract ... tsv` word-box output, where each
/// price's bounding box shares its own dish's `line_num` and never a
/// neighbouring row's.
///
/// What it did instead is corrupt the price digits themselves, on every
/// row: `₪28` came back `₪588`, `₪32` came back `2`, `64 ש"ח`
/// came back `4 ש"ח`, `58 ש"ח` came back `8 ש"ח` - a leading digit lost in
/// three of the four, a wrong extra one gained in the fourth. That is not a
/// new defect: it is the already-documented "the Hebrew model cannot read
/// an isolated column of Latin digits" (`design/m6_platform_handoff.md`),
/// reappearing on a menu's much wider price-margin gap. Every dish name and
/// the one wrapped description came back at 92-93%% confidence with zero
/// errors.
///
/// **What this means for `MenuAnalysisPrompt`'s "columns may be
/// interleaved" instruction:** it is aimed at a failure mode this capture
/// did not produce. The failure mode this capture did produce - a
/// corrupted price - never reaches the parser's output at all:
/// `MenuResponseParser` has no price field, and the "name" the model must
/// copy verbatim came through unharmed on every row. **This one capture
/// does not show OCR as the bottleneck for a dish/price row, and does not
/// by itself justify filing the vision swap.** It does not clear a
/// side-by-side two-section layout (two independent lists printed next to
/// each other, not built here) - the shape "interleaved" was actually
/// written for - which stays unmeasured. See
/// `design/m16_menu_scanner_research.md` \xa75.
abstract final class RenderedMenuOcrFixture {
  /// A two-section grill menu (ראשונות / עיקריות), each dish printed with
  /// its price on the same line - the dish right-aligned, the price
  /// left-aligned - and one wrapped description line. Source: `GRILL_MENU`
  /// in this script; rendered by `render_labels.render_menu`.
  static const String grill = %(literal)s;
}
'''


def main():
    if not shutil.which("tesseract"):
        raise SystemExit("tesseract not installed")

    from PIL import features

    if not features.check("raqm"):
        raise SystemExit(
            "Pillow was not built with Raqm - Hebrew would lay out "
            "left-to-right and unshaped, and the capture would measure the "
            "wrong thing."
        )

    version_result = subprocess.run(
        ["tesseract", "--version"], capture_output=True, text=True, check=True,
    )
    version = version_result.stdout.splitlines()[0].removeprefix("tesseract ").strip()

    work = tempfile.mkdtemp()
    try:
        tessdata = os.path.join(work, "tessdata")
        os.makedirs(tessdata)
        for model in ("heb.traineddata", "eng.traineddata"):
            shutil.copy(os.path.join(REPO, "assets", "tessdata", model), tessdata)

        rendered_dir = os.path.join(work, "rendered")
        os.makedirs(rendered_dir)
        image_path = render_labels.render_menu("grill", GRILL_MENU, rendered_dir)

        os.makedirs(os.path.dirname(IMAGE_OUT), exist_ok=True)
        shutil.copy(image_path, IMAGE_OUT)

        prepared = prepare(image_path, os.path.join(work, "grill_p.png"))
        text = recognise(prepared, tessdata)

        print("--- raw capture ---")
        print(text)
        print("--- end raw capture ---")

        with open(OUT, "w", encoding="utf-8") as f:
            f.write(
                HEADER
                % {
                    "lang": LANG,
                    "psm": PSM,
                    "dpi": ASSUMED_DPI,
                    "version": version,
                    "literal": dart_literal(text),
                }
            )
        print(f"wrote {OUT}")
        print(f"  grill: {len(text.splitlines())} lines")
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    sys.path.insert(0, os.path.join(REPO, "tool"))
    main()
