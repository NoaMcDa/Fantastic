"""Renders the Hebrew label images used to capture real OCR fixtures.

Pillow must be built with Raqm, or Hebrew is laid out left-to-right and
unshaped, and the whole exercise measures the wrong thing:

    python3 -c "from PIL import features; print(features.check('raqm'))"

The text is rendered with the app's own bundled Assistant font, right-aligned
with an RTL base direction, which is as close to what the app's users will
photograph as this repository can get without a camera. It is not a substitute
for real photographs of real packaging - see design/m6_platform_research.md
Part 7, which is still the honest prerequisite.

Usage: python3 tool/render_labels.py <output-dir>
"""

import sys

from PIL import Image, ImageDraw, ImageFont

FONT = "assets/fonts/Assistant-Regular.ttf"
BOLD = "assets/fonts/Assistant-Bold.ttf"

# Deliberately the same three label bodies as test/fixtures/hebrew_label_fixture.dart,
# so the hand-written fixtures and the captured ones can be compared directly.
LABELS = {
    "tahini": """טחינה גולמית משומשום מלא
ערכים תזונתיים ל-100 גרם
שומנים 53.8 גרם
מתוכם חומצות שומן רוויות 7.6 גרם
פחמימות 10.5 גרם
מתוכם סוכרים 0.9 גרם
סיבים תזונתיים 9.3 גרם
חלבונים 26.5 גרם
נתרן 25 מ"ג
רכיבים: 100% שומשום מלא""",
    "proteinBar": """חטיף חלבון בטעם שוקולד
רכיבים: חלבון מי גבינה, מלטיטול, שמן קוקוס, קקאו, אגוזי לוז, מלח.
ערכים תזונתיים ל-100 גרם
שומנים 22,5 גרם
מתוכם חומצות שומן רוויות 9 גרם
פחמימות 30 גרם
מתוכם רב כהליים 25 גרם
סיבים תזונתיים 8 גרם
חלבונים 33 גרם""",
    "pointedWafer": """ופל בטעם וניל
רכיבים: קמח חיטה, סוכר, שמן קנולה, מלטודקסטרין, מלח
ערכים תזונתיים ל-100 גרם
שׁוּמָן 24 גר׳
פַחמִימוֹת 62 גר׳
סיבים תזונתיים 2 גר׳
חלבונים 6 גר׳""",
}


def render(name: str, text: str, out_dir: str) -> str:
    """Writes one label as a PNG and returns its path."""
    lines = text.split("\n")
    # Wide enough that the ingredient line - the longest on any real pack -
    # is not clipped. A clipped line is a rendering artifact that would look
    # exactly like an OCR failure in the captured fixture.
    width = 1240
    height = 80 + 58 * len(lines)
    image = Image.new("RGB", (width, height), "white")
    draw = ImageDraw.Draw(image)
    regular = ImageFont.truetype(FONT, 34)
    bold = ImageFont.truetype(BOLD, 40)

    y = 40
    for index, line in enumerate(lines):
        draw.text(
            (width - 50, y),
            line,
            # The product name and the "per 100 g" header are set heavier on a
            # real pack; matching that keeps the rendering honest rather than
            # uniformly easy to read.
            font=bold if index in (0, 1) else regular,
            fill="black",
            anchor="ra",
            direction="rtl",
            language="he",
        )
        y += 58

    path = f"{out_dir}/{name}.png"
    image.save(path)
    return path


def main_into(out_dir):
    """Renders every label into out_dir. Importable, so
    tool/capture_ocr_fixtures.py can drive it without a subprocess."""
    return [render(name, text, out_dir) for name, text in LABELS.items()]


# Menu layout constants. Kept separate from the label constants above because
# a menu row is two columns on one baseline, not one column of stacked lines.
_MENU_WIDTH = 1240
_MENU_MARGIN = 50
_MENU_HEADER_HEIGHT = 76
_MENU_ROW_HEIGHT = 58
_MENU_DESC_HEIGHT = 44


def _wrap_rtl(draw, text, font, max_width):
    """Greedy word-wraps `text` to lines no wider than `max_width`.

    Pillow does not wrap text on its own; this measures each candidate line
    with the same `draw.textlength(..., direction="rtl", language="he")`
    call `render_menu` uses to draw it, so the wrap decision and the drawn
    width always agree.
    """
    words = text.split(" ")
    lines = []
    current = ""
    for word in words:
        candidate = f"{current} {word}".strip()
        width = draw.textlength(
            candidate, font=font, direction="rtl", language="he"
        )
        if current and width > max_width:
            lines.append(current)
            current = word
        else:
            current = candidate
    if current:
        lines.append(current)
    return lines


def render_menu(name: str, rows: list, out_dir: str) -> str:
    """Writes one two-column Hebrew menu as a PNG and returns its path.

    `rows` holds, in print order, three kinds of entry:

    * a bare `str` — a section header (e.g. "ראשונות"), spanning the full
      width in bold, exactly as `render()` above sets a label's product-name
      line heavier.
    * a `(dish_text, price_text)` tuple — one menu row. The dish is drawn
      anchored `ra` at the right margin and the price anchored `la` at the
      left margin, on the same baseline: two columns on one line, which is
      how an Israeli menu prints and exactly the shape that raises the
      column-interleaving question `psm 4` has never been tested against.
    * a `(dish_text, price_text, description_text)` triple — the same row,
      plus a wrapped description line underneath in the regular face at a
      smaller size, matching a real menu's dish blurb. Pass `None` as the
      third element for a row with no description.

    Same white background, same Assistant font, same `direction="rtl"`,
    `language="he"` arguments the label renderer above uses.
    """
    regular = ImageFont.truetype(FONT, 34)
    bold = ImageFont.truetype(BOLD, 38)
    desc_font = ImageFont.truetype(FONT, 26)

    # A throwaway canvas to measure description wraps against before the
    # real image's height is known.
    probe = ImageDraw.Draw(Image.new("RGB", (_MENU_WIDTH, 10), "white"))
    desc_max_width = _MENU_WIDTH - 2 * _MENU_MARGIN

    lines = []
    for row in rows:
        if isinstance(row, str):
            lines.append(("header", row))
            continue
        dish, price = row[0], row[1]
        lines.append(("row", dish, price))
        description = row[2] if len(row) > 2 else None
        if description:
            for wrapped in _wrap_rtl(probe, description, desc_font, desc_max_width):
                lines.append(("desc", wrapped))

    height = 80
    for entry in lines:
        kind = entry[0]
        if kind == "header":
            height += _MENU_HEADER_HEIGHT
        elif kind == "row":
            height += _MENU_ROW_HEIGHT
        else:
            height += _MENU_DESC_HEIGHT

    image = Image.new("RGB", (_MENU_WIDTH, height), "white")
    draw = ImageDraw.Draw(image)

    y = 40
    for entry in lines:
        kind = entry[0]
        if kind == "header":
            draw.text(
                (_MENU_WIDTH - _MENU_MARGIN, y),
                entry[1],
                font=bold,
                fill="black",
                anchor="ra",
                direction="rtl",
                language="he",
            )
            y += _MENU_HEADER_HEIGHT
        elif kind == "row":
            _, dish, price = entry
            draw.text(
                (_MENU_WIDTH - _MENU_MARGIN, y),
                dish,
                font=regular,
                fill="black",
                anchor="ra",
                direction="rtl",
                language="he",
            )
            draw.text(
                (_MENU_MARGIN, y),
                price,
                font=regular,
                fill="black",
                anchor="la",
                direction="rtl",
                language="he",
            )
            y += _MENU_ROW_HEIGHT
        else:
            draw.text(
                (_MENU_WIDTH - _MENU_MARGIN, y),
                entry[1],
                font=desc_font,
                fill="black",
                anchor="ra",
                direction="rtl",
                language="he",
            )
            y += _MENU_DESC_HEIGHT

    path = f"{out_dir}/{name}.png"
    image.save(path)
    return path


if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else "."
    for path in main_into(target):
        print(path)
