"""Generates test/fixtures/photographed_menu_ocr_fixture.dart from real menus.

The third and last tier of M16's corpus, and the only one no agent can
manufacture: a photograph of a real Israeli restaurant menu, taken by a person
holding a phone in a restaurant. The other two tiers — hand-typed menu text and
a menu rendered in the app's own font — are written or drawn here, and neither
carries glare, curl, a laminated sheet catching a ceiling light, or a typeface
chosen by a designer rather than by us.

A sibling of `capture_ocr_fixtures.py` rather than a branch inside it, for the
reason `ci_ocr_fixture.dart` is its own file: the provenance differs, and a
separate file says so without a reader having to take a doc comment's word for
it. `real_ocr_fixture.dart` is not touched by this script.

**Everything about the engine is imported, not restated.** `prepare`,
`recognise` and the `heb+eng` / `psm 4` / `user_defined_dpi=300` settings come
from `capture_ocr_fixtures` unchanged. A menu capture at settings chosen for a
menu would measure an app that does not exist — the shipped scanner has one
configuration and this is it.

Usage: python3 tool/capture_menu_ocr_fixtures.py
Needs: tesseract >= 4, and the Flutter SDK on PATH for `dart run`.

Pillow is imported transitively (`capture_ocr_fixtures` imports the label
renderer at module scope) but nothing here renders anything: the images this
script reads are photographs, already committed.
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile

from capture_ocr_fixtures import (
    ASSUMED_DPI,
    LANG,
    PSM,
    dart_literal,
    prepare,
    recognise,
)

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(REPO, "test", "fixtures", "photographed_menu_ocr_fixture.dart")
IMAGES = os.path.join(REPO, "test", "fixtures", "images")

# (fixture name, image file, doc comment).
MENUS = [
    (
        "vivie",
        "vivie_restaurant_menu.jpg",
        "A real Israeli restaurant menu, photographed off the table by the "
        "user who asked for M16. Three price-bearing sections, dish names "
        "right, prices left, a designer's light serif on cream stock. The "
        "dish names largely survive the engine; the prices largely do not, "
        "and what they come back as is the finding — see the class comment.",
    ),
]

# What the menu prints, read off the photograph by eye, in printed order.
#
# Here rather than in the generated file because it is the one thing in this
# exercise a human *must* supply: it is the ground truth the capture is scored
# against, and a fixture that generated its own answer key would be scoring
# the engine against itself. `real_menu_pipeline_test.dart` holds the same
# list for the same reason and that duplication is deliberate — this copy
# exists so a maintainer regenerating the fixture is told, on the spot,
# whether the finding still holds.
PRINTED_PRICES = {
    "vivie": [
        28, 18, 52, 24, 74, 73, 78, 72,
        63, 64, 58, 62, 79, 83,
        109, 132, 89, 148, 89, 79, 83, 159, 72,
    ],
}


def tesseract_version():
    """The engine's own version string, for the generated header.

    5.3.4 and 5.5.3 read the same *label* differently — `חלבונים` against
    `חזלבונים` — which is why `ci_ocr_fixture.dart` exists at all. A capture
    that does not say which engine produced it cannot be compared with
    anything later.
    """
    out = subprocess.run(
        ["tesseract", "--version"], capture_output=True, text=True,
    ).stdout
    return out.splitlines()[0].strip()


def score(text, printed):
    """How many of the printed prices came back, and how many came back wrong.

    Scored on **distinct** values, not on the printed sequence. The menu prints
    72 and 79 twice each, and a bare membership test cannot say which of the
    two occurrences was read — counting the sequence would have claimed four
    successes for two. Overstating a result in the tool that measures it is the
    one failure this whole exercise exists to avoid.

    Not used by the fixture — the numbers live in the test, which is where a
    regression should fail. This is printed to the terminal so that whoever
    regenerates the file learns immediately whether §10 of
    `design/m16_menu_scanner_research.md` is still true of the engine in front
    of them.
    """
    found = [int(n) for n in re.findall(r"\d+", text)]
    correct = set(found) & set(printed)
    wrong = [n for n in found if n not in set(printed)]
    return len(correct), len(found), len(wrong), len(set(printed))


HEADER_TEMPLATE = '''/// Genuine Tesseract output, captured from a **photographed** restaurant menu.
///
/// The third tier of M16's corpus and the only one that could not be
/// manufactured here. Tier one is menu text somebody typed; tier two is a menu
/// rendered in the app's own font, flat and evenly lit. This is neither: it is
/// a real Israeli restaurant menu, photographed off the table, at the angle
/// and the distance and the lighting a user actually gets.
///
/// Verbatim stdout of Tesseract against the models this app bundles
/// (`assets/tessdata/heb.traineddata` + `eng.traineddata`, tessdata_fast) at
/// the settings the app actually runs — `-l %(lang)s --psm %(psm)s
/// -c user_defined_dpi=%(dpi)s` — over an image put through the app's own
/// `ScalingTextRecognizer.prepare`. Captured on **%(version)s**. Whatever the
/// engine got wrong is preserved, and a great deal of it is wrong.
///
/// **Generated, not written. Do not hand-edit.** Regenerate with
/// `tool/capture_menu_ocr_fixtures.sh`.
///
/// ## The source image was already compressed, and that is part of the finding
///
/// [vivie] was supplied at **480x640, 40 KB** — a phone photograph after a
/// messaging app had had it. Nothing here downscaled it further; it arrived
/// that way, which is how a photograph normally reaches an app that accepts
/// one from the gallery. `OcrImagePrep` grows it to 1600 px wide before the
/// engine sees it, its `maxUpscale` of 4 not even reached.
///
/// ## What it found: the dish names read, the prices do not
///
/// This is the uncomfortable half of M16 and it belongs in the fixture rather
/// than only in a design document.
///
/// The menu prints **23 prices**, 19 of them distinct. The pipeline returned
/// **12 numbers**. Two of them were right. The other ten match nothing printed
/// anywhere on the menu, and they are wrong in one consistent way: the
/// left-hand digit is gone and the right-hand one survives. `28` came back as
/// `8`, `18` as `8`, `74` as `4`, `63` as `3`, `58` as `8`. Both prices that
/// survived whole — `72` and `79` — did so complete; nothing came back
/// half-right in the other direction.
///
/// A scanner that reads a 28 shekel dish as 8 shekels has not failed visibly.
/// It has lied quietly, in the exact shape #257 was, and a user has no way to
/// tell the two apart from the result alone. The nine dishes of the third
/// section returned no number at all, which is the honest failure and the one
/// worth preferring.
///
/// The Hebrew is a different story, and a much better one. Scored by edit
/// distance against the printed menu, of the **23 dish names**:
///
/// * **9 came back character-perfect** — `צלחת חריפים`, `ריזוטו, פטריות בלו
///   אויסטר`, `פילה דג ים, אורז אסור, ביסק סרטנים`.
/// * **17 scored 0.75 or better**, the band where a word is plainly
///   recognisable through one or two corrupted letters (`ברוסקטה סרדינים
///   כבושיט` for `...כבושים`).
/// * **The 4 that failed are the last four on the page**, nearest the foot of
///   the photograph where the frame falls off — 0.33 to 0.55. Not a property
///   of the dishes; a property of where they sat in the shot.
///
/// That asymmetry is the single most useful thing this capture says about
/// M16. A keto classifier reads ingredients, not prices, so the payload M16
/// needs is the payload that survives — which is the exact inverse of Keto
/// Lens, where the numbers are the whole point and the Hebrew is scaffolding.
///
/// ## Resolution is the limit here, not the settings
///
/// Measured rather than assumed: re-running the same photograph at 1600, 2400,
/// 3200, 4000 and 4500 px wide on the app's own kernel recovers at most 3 of
/// 19 distinct prices at any width. Upscaling cannot invent strokes a 480 px
/// source never recorded, so the app's own `targetWidth` is as good as any
/// larger number and the cap is not what is costing the digits.
///
/// ## `psm 4` is pinned for a label, and a menu is not a label
///
/// Also measured, on this image: `psm 6` returned 21%% more text than `psm 4`
/// and kept **20** of the 23 dish rows whole against `psm 4`'s **12**,
/// recovering most of a third section `psm 4` dropped entirely. Neither reads
/// the prices. `psm 4` was chosen because `psm 6` flattened a bordered
/// nutrition table (`design/m6_platform_handoff.md`); nothing about that
/// finding was ever about menus. M16 should not assume the inherited setting
/// is right for it — see `design/m16_menu_scanner_research.md` §10.
///
/// ## What this still does not establish
///
/// **One menu is not a corpus.** Issue #373 asks for three, deliberately
/// differing — a multi-column layout, a laminated sheet with glare, and a
/// bilingual Hebrew/English card. This is one, and it is none of those three
/// on purpose: it is simply the menu somebody had. No accuracy figure is
/// claimed for menus in general, no menu has been read *through the app's own
/// camera*, and #373 stays open until the other two are photographed.
abstract final class PhotographedMenuOcrFixture {'''


def main():
    if not shutil.which("tesseract"):
        raise SystemExit("tesseract not installed")

    version = tesseract_version()
    work = tempfile.mkdtemp()
    try:
        tessdata = os.path.join(work, "tessdata")
        os.makedirs(tessdata)
        for model in ("heb.traineddata", "eng.traineddata"):
            shutil.copy(os.path.join(REPO, "assets", "tessdata", model), tessdata)

        entries = []
        for name, image, doc in MENUS:
            src = os.path.join(IMAGES, image)
            if not os.path.exists(src):
                raise SystemExit(f"missing photograph: {src}")
            prepared = prepare(src, os.path.join(work, f"{name}_p.png"))
            entries.append((name, doc, recognise(prepared, tessdata)))

        header = HEADER_TEMPLATE % {
            "lang": LANG, "psm": PSM, "dpi": ASSUMED_DPI, "version": version,
        }
        with open(OUT, "w", encoding="utf-8") as f:
            f.write(header + "\n")
            for i, (name, doc, text) in enumerate(entries):
                if i:
                    f.write("\n")
                f.write(f"  /// {doc}\n")
                f.write(f"  static const String {name} = {dart_literal(text)};\n")
            f.write("}\n")

        print(f"wrote {OUT}")
        print(f"  engine: {version}")
        for name, _, text in entries:
            correct, found, wrong, distinct = score(text, PRINTED_PRICES[name])
            print(
                f"  {name}: {len(text.splitlines())} lines, "
                f"{found} numbers returned for "
                f"{len(PRINTED_PRICES[name])} printed prices "
                f"({distinct} distinct) — {correct} correct, "
                f"{wrong} matching nothing on the menu"
            )
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    sys.path.insert(0, os.path.join(REPO, "tool"))
    main()
