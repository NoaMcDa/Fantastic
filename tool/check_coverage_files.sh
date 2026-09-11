#!/usr/bin/env bash
# tool/check_coverage_files.sh — every gated file must appear in the report.
#
# Usage: tool/check_coverage_files.sh [lcov-file]
#
# `flutter test --coverage` emits an `SF:` record only for a file some test
# imports. A file with **no test at all** is therefore absent from `lcov.info`
# and cannot drag the percentage down — so `check_coverage.sh` alone would read
# 100% on a layer nobody tested.
#
# The catch is that lcov is *also* silent for a file with nothing to execute —
# a bare enum, an `abstract interface class`. Both cases look identical from
# the report, so this cannot be inferred; `tool/coverage_ignore.txt` names the
# second kind explicitly. An ignore list shows up in a diff and gets reviewed.
# An inference does not.
set -euo pipefail

LCOV="${1:-coverage/lcov.info}"
IGNORE="$(dirname "$0")/coverage_ignore.txt"

[ -f "$LCOV" ] || { echo "No coverage file at $LCOV — run 'flutter test --coverage' first."; exit 1; }

# The parentheses around the -path alternation are required: without them
# `-type`/`-name` bind to only the second branch and bare directories show up.
missing="$(comm -23 \
  <(find lib \( -path '*/domain/*' -o -path '*/application/*' \) -type f -name '*.dart' \
      ! -name '*.g.dart' | sort) \
  <(cat <(grep '^SF:' "$LCOV" | cut -c4-) <(grep -vE '^\s*(#|$)' "$IGNORE") | sort))"

if [ -n "$missing" ]; then
  echo "::error::Gated files with no coverage record and not on the ignore list:"
  echo "$missing" | sed 's/^/  /'
  echo
  echo "Either write a test, or — if the file is declaration-only (a bare enum,"
  echo "an abstract interface) — add it to tool/coverage_ignore.txt with a reason."
  exit 1
fi

echo "PASS: every gated file is either covered or explicitly ignored."
