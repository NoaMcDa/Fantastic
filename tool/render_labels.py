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


if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else "."
    for label_name, label_text in LABELS.items():
        print(render(label_name, label_text, target))
