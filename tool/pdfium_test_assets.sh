#!/usr/bin/env bash
#
# Make PDFium loadable by `flutter test`, so M16's PDF suite runs for real.
#
#   flutter build linux --release      # runs pdfium_dart's build hook
#   tool/pdfium_test_assets.sh
#   flutter test test/features/menu/data/adapters/pdf_page_extractor_impl_test.dart
#
# ## Why this exists
#
# `pdfrx` reaches PDFium through `pdfium_dart`, which does not vendor the
# library: its build hook downloads and builds it as a **native asset**, and
# the Dart VM finds it through `.dart_tool/native_assets.yaml`. `flutter
# build` writes that manifest. **`flutter test` does not** — not after
# `flutter pub get`, not after a `flutter build` in the same checkout, and
# not with `--enable-native-assets` set. All three were tried.
#
# The consequence is the one this repository has already been bitten by
# once. `pdf_page_extractor_impl_test.dart` follows the precedent
# `tesseract_ffi_recognizer_test.dart` set and skips itself, loudly, when
# PDFium cannot be loaded — so on a runner without this manifest every test
# that opens a real PDF skips, the suite reports "All tests passed!", and
# the gate is green over a capability nothing executed. `design/
# user_bugs_handoff.md` records what shipping on that kind of green costs:
# the first real user's scan read nothing, and the suite had been green
# throughout.
#
# So this script writes the manifest by hand, pointing at the library the
# build hook already produced. It creates nothing and downloads nothing — if
# the hook has not run, that is an error worth failing on rather than
# papering over, because a manifest naming a library that is not there would
# put us straight back to a silent skip.
#
# Run it AFTER a `flutter build` for this platform. `build-linux.yml` does
# exactly that, and then asserts the suite did not skip itself — the same
# shape as the Keto Lens FFI step immediately above it.

set -euo pipefail

cd "$(dirname "$0")/.."

# Where the build hook leaves it. The `chromium_*` component is the pinned
# PDFium revision and changes when pdfium_dart is upgraded, so it is globbed
# rather than spelled out — a hard-coded revision would turn an upgrade into
# a silent skip, which is the failure this whole script exists to prevent.
readonly HOOK_GLOB='.dart_tool/hooks_runner/shared/pdfium_dart/build/*/linux-x64/libpdfium.so'

# The copy `flutter build linux` stages into the bundle. Same library, and a
# useful fallback if the hook cache is laid out differently on another
# machine or a future SDK.
readonly BUNDLE_COPY='build/linux/x64/release/bundle/lib/libpdfium.so'

library=''
# shellcheck disable=SC2086 # deliberate glob expansion
for candidate in $HOOK_GLOB "$BUNDLE_COPY"; do
  if [[ -f "$candidate" ]]; then
    library="$(realpath "$candidate")"
    break
  fi
done

if [[ -z "$library" ]]; then
  echo "pdfium_test_assets: no libpdfium.so found." >&2
  echo >&2
  echo "Looked in:" >&2
  echo "  $HOOK_GLOB" >&2
  echo "  $BUNDLE_COPY" >&2
  echo >&2
  echo "The pdfium_dart build hook has not run in this checkout. Run a" >&2
  echo "platform build first — 'flutter build linux --release' — which is" >&2
  echo "what triggers it. Writing a manifest without the library would let" >&2
  echo "the PDF suite skip itself silently, which is the failure this" >&2
  echo "script exists to prevent." >&2
  exit 1
fi

mkdir -p .dart_tool

# The manifest is JSON, despite the .yaml name — that is the format the Dart
# VM's native-assets resolver reads, and JSON is a subset of YAML, so the
# name is historical rather than wrong.
cat > .dart_tool/native_assets.yaml <<JSON
{"format-version":[1,0,0],"native-assets":{"linux_x64":{"package:pdfium_dart/libpdfium":["absolute","$library"]}}}
JSON

echo "pdfium_test_assets: wrote .dart_tool/native_assets.yaml -> $library"
