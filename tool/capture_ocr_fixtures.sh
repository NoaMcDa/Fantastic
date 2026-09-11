#!/usr/bin/env bash
# Regenerates test/fixtures/real_ocr_fixture.dart from real Hebrew labels.
#
# The point of that file is that nobody chose its contents: it is verbatim
# Tesseract output against the models this app bundles, at the settings the app
# actually runs. Regenerate it rather than editing it, and re-read the
# assertions afterwards - a changed model or a changed setting can legitimately
# change what comes back.
#
# The work is in tool/capture_ocr_fixtures.py, which writes the Dart file
# itself. It used to print the text for a human to paste in; a paste step is a
# place for a hand to touch output whose whole value is that no hand did.
#
# Needs: tesseract (>= 4, with no language packs - the bundled models are used),
#        python3 with Pillow built against Raqm (for RTL shaping).
set -euo pipefail
cd "$(dirname "$0")/.."
command -v tesseract >/dev/null || { echo "tesseract not installed"; exit 1; }
exec python3 tool/capture_ocr_fixtures.py "$@"
