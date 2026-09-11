"""Generates test/fixtures/real_ocr_fixture.dart from real Hebrew labels.

The point of that file is that nobody chose its contents: every string in it is
verbatim Tesseract stdout, against the models this app bundles, at the settings
the app actually runs. This script is what makes that true — it writes the Dart
file itself rather than printing text for a human to paste, because a paste step
is a place for a hand to touch the output.

Two kinds of source, and the difference is recorded in the generated doc
comments because it matters:

* **Rendered** labels (`tool/render_labels.py`) — the app's own font, RTL, no
  camera involved. Synthetic, but the engine output is real.
* **Photographed** labels (`test/fixtures/images/`) — an actual product label
  as a user supplied it. Closer to the real thing, still not a shop photo.

Usage: python3 tool/capture_ocr_fixtures.py
Needs: tesseract >= 4, python3 with Pillow built against Raqm (for RTL shaping).
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile

import render_labels

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(REPO, "test", "fixtures", "real_ocr_fixture.dart")

# ---------------------------------------------------------------------------
# The engine settings. These MUST match the three adapters:
#   lib/features/keto_lens/data/adapters/tesseract_ffi_recognizer.dart
#   lib/features/keto_lens/data/adapters/tesseract_plugin_recognizer.dart
#   web/tesseract/fantastic_ocr.js
# A fixture captured at other settings is a fixture of an app that does not
# exist.
LANG = "heb+eng"
PSM = "4"

ASSUMED_DPI = "300"


def prepare(src, dst):
    """Applies the app's own pre-OCR preparation, by running the app's code.

    NOT reimplemented here. An earlier version of this script did the resize
    with Pillow, and the fixture it produced was a fiction: Pillow's LANCZOS
    and package:image's linear kernel disagree enough that Tesseract read
    `חלבונים` from one and `חזלבונים` from the other, and the second does not
    match HebrewLabelParser's protein keyword at all. The fixture recorded an
    easier image than the app submits, and the regression test it fed passed
    for a pipeline that does not exist.

    `tool/prepare_for_ocr.dart` is the app's own ScalingTextRecognizer.prepare,
    so there is nothing left to drift. Exit 3 means "no preparation needed" -
    the source is already a workable size and the app would pass it straight
    through.
    """
    result = subprocess.run(
        ["dart", "run", "tool/prepare_for_ocr.dart", src, dst],
        cwd=REPO, capture_output=True, text=True,
    )
    if result.returncode == 3:
        return src
    if result.returncode != 0:
        raise SystemExit(f"prepare_for_ocr failed on {src}:\n{result.stderr}")
    return dst


def recognise(path, tessdata):
    result = subprocess.run(
        ["tesseract", path, "-", "-l", LANG, "--psm", PSM,
         "-c", f"user_defined_dpi={ASSUMED_DPI}", "--tessdata-dir", tessdata],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise SystemExit(f"tesseract failed on {path}:\n{result.stderr}")
    # Trailing blank lines carry no information and churn the diff.
    return result.stdout.replace("\r\n", "\n").rstrip("\n")


def dart_literal(text):
    r"""Renders text as a Dart \"\"\" string literal.

    `'''` cannot hold this: Hebrew abbreviates grams with a geresh, so captured
    text routinely ends in an apostrophe. `\"\"\"` can, with three escapes:
    a backslash is a Dart escape, a `$` starts interpolation, and a quote
    directly before the closing delimiter would make four in a row.
    """
    text = text.replace("\\", "\\\\").replace("$", r"\$")
    text = text.replace('"""', r'\"\"\"')
    if text.endswith('"'):
        text = text[:-1] + r"\""
    return f'"""\n{text}"""'


HEADER = '''/// Genuine Tesseract output, captured from real Hebrew labels.
///
/// Every other fixture in this directory was written by hand, and
/// `design/m6_handoff.md` is blunt about what that is worth:
///
/// > they were written by the same person who wrote the parser, which is
/// > exactly the kind of test that passes and then fails on a real label.
///
/// These are the opposite. Nobody chose these strings: each is the verbatim
/// stdout of Tesseract against the models this app bundles
/// (`assets/tessdata/heb.traineddata` + `eng.traineddata`, tessdata_fast) at
/// the settings the app actually runs — `-l %(lang)s --psm %(psm)s
/// -c user_defined_dpi=%(dpi)s`, over an image put through the same
/// `OcrImagePrep` scaling step the app applies before a scan. Whatever the
/// engine got wrong is preserved, mistakes included.
///
/// **Generated, not written. Do not hand-edit.** Regenerate with
/// `tool/capture_ocr_fixtures.sh`; the value of this file is exactly that no
/// hand touched it. Re-read the assertions afterwards — a changed model, a
/// changed setting or a changed renderer can legitimately change what comes
/// back.
///
/// ## Two kinds of source, and the difference matters
///
/// [tahini], [proteinBar] and [pointedWafer] are **rendered**: the app's own
/// Assistant font at the app's own RTL layout, via `tool/render_labels.py`.
/// No camera, no glare, no curve, no shop lighting.
///
/// [wholeWheatRyeBread] is **photographed** — an actual Israeli product label,
/// supplied by the user whose failed scan prompted the fix that this fixture
/// guards. It is a bordered two-column table, which is the layout that broke:
/// numbers in the left column, Hebrew labels in the right. It closes the gap
/// between "a human imagined this OCR output" and "an engine produced it on a
/// real label".
///
/// **It does not close the gap to a shop.** It is screenshot quality — a clean,
/// flat, well-lit crop, not a photograph taken at arm's length off a curved
/// bread bag under supermarket lighting. There is still no camera in this
/// repository, no accuracy figure is claimed, and issue #256 and Epic #10 stay
/// open.
abstract final class RealOcrFixture {''' % {"lang": LANG, "psm": PSM, "dpi": ASSUMED_DPI}


def main():
    if not shutil.which("tesseract"):
        raise SystemExit("tesseract not installed")

    work = tempfile.mkdtemp()
    try:
        tessdata = os.path.join(work, "tessdata")
        os.makedirs(tessdata)
        for model in ("heb.traineddata", "eng.traineddata"):
            shutil.copy(os.path.join(REPO, "assets", "tessdata", model), tessdata)

        rendered_dir = os.path.join(work, "rendered")
        os.makedirs(rendered_dir)
        render_labels.main_into(rendered_dir)

        entries = []
        for name in ("tahini", "proteinBar", "pointedWafer"):
            src = os.path.join(rendered_dir, f"{name}.png")
            entries.append((name, recognise(prepare(src, os.path.join(work, f"{name}_p.png")), tessdata)))

        photo = os.path.join(REPO, "test", "fixtures", "images",
                             "whole_wheat_rye_bread_label.png")
        entries.append(("wholeWheatRyeBread",
                        recognise(prepare(photo, os.path.join(work, "bread_p.png")), tessdata)))

        docs = {
            "tahini": "Raw tahini, cleanly printed. Every row and every number survived the engine.",
            "proteinBar": "A protein bar: Israeli decimal comma (22,5), ingredients printed above the table, maltitol in them.",
            "pointedWafer": "A pointed (niqqud) label. The English model wins a word it should not here and the carbohydrate row is lost - the measured, accepted cost of loading `eng` for digits. See `TessdataBundle`.",
            "wholeWheatRyeBread": "A real photographed Israeli label: whole wheat + rye bread, a bordered two-column table with the numbers in the left column. This is the label that could not be scanned at all before `psm 4` + `heb+eng` + `user_defined_dpi`; under the old settings six of its nine rows came back as punctuation.",
        }

        with open(OUT, "w", encoding="utf-8") as f:
            f.write(HEADER + "\n")
            for i, (name, text) in enumerate(entries):
                if i:
                    f.write("\n")
                f.write(f"  /// {docs[name]}\n")
                f.write(f"  static const String {name} = {dart_literal(text)};\n")
            f.write("}\n")
        print(f"wrote {OUT}")
        for name, text in entries:
            print(f"  {name}: {len(text.splitlines())} lines")
    finally:
        shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    sys.path.insert(0, os.path.join(REPO, "tool"))
    main()
