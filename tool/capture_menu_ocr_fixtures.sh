#!/usr/bin/env bash
# Regenerates test/fixtures/photographed_menu_ocr_fixture.dart from real menus.
#
# The sibling of tool/capture_ocr_fixtures.sh, for M16's third corpus tier:
# photographs of real Israeli restaurant menus, which no agent can produce and
# which are the only tier carrying glare, curl and a designer's typeface.
#
# Same rule as the label capture: regenerate this file rather than editing it,
# and re-read the assertions afterwards. A changed model or a changed setting
# can legitimately change what comes back - and here it would also change the
# findings written into the generated header, so re-read those too.
#
# The engine settings are not re-chosen here. capture_menu_ocr_fixtures.py
# imports prepare(), recognise() and the heb+eng/psm 4/dpi 300 constants from
# capture_ocr_fixtures.py, so the menus are read by exactly the configuration
# the app ships.
#
# Needs: tesseract (>= 4, with no language packs - the bundled models are
#        used), the Flutter SDK on PATH for `dart run`, and python3.
set -euo pipefail
cd "$(dirname "$0")/.."
command -v tesseract >/dev/null || { echo "tesseract not installed"; exit 1; }
exec python3 tool/capture_menu_ocr_fixtures.py "$@"
