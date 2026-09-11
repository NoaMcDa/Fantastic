#!/usr/bin/env bash
# Regenerates test/fixtures/real_ocr_fixture.dart from rendered Hebrew labels.
#
# The point of that file is that nobody chose its contents: it is verbatim
# Tesseract output against the model this app bundles. Regenerate it rather
# than editing it, and re-read the assertions afterwards - a changed model or
# a changed renderer can legitimately change what comes back.
#
# Note: the Dart fixture uses """ delimiters, not '''. Hebrew labels abbreviate
# grams with a geresh, so captured text routinely ENDS in an apostrophe and a
# ''' literal will not compile. Keep the """ form.
#
# Needs: tesseract (>= 4, with no language packs - the bundled model is used),
#        python3 with Pillow built against Raqm (for RTL shaping).
set -euo pipefail
cd "$(dirname "$0")/.."
command -v tesseract >/dev/null || { echo "tesseract not installed"; exit 1; }

work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
mkdir -p "$work/tessdata"
cp assets/tessdata/heb.traineddata "$work/tessdata/"

python3 tool/render_labels.py "$work"
for png in "$work"/*.png; do
  echo "=== $(basename "$png") ==="
  tesseract "$png" - -l heb --psm 6 --tessdata-dir "$work/tessdata" 2>/dev/null
done
