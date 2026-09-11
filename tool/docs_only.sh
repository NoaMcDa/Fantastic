#!/usr/bin/env bash
# tool/docs_only.sh — decide whether a diff touches nothing but documentation.
#
# Usage:  tool/docs_only.sh <base-ref> <head-ref>
# Prints: `true`  — every path changed between the two refs is documentation
#         `false` — something else changed, or the question could not be
#                   answered with certainty
#
# CI calls this once per run and skips the test, coverage, web-build and e2e
# jobs when it prints `true`. Nothing in this repository's test suite, coverage
# gate or build can be affected by editing a design document, so running them
# on a docs-only change buys nothing and costs every reviewer the wait.
#
# **Every uncertain case prints `false`.** A wrongly-skipped run lets a real
# regression reach `main` with a green tick next to it; a wrongly-run one costs
# four minutes. The asymmetry is the whole design of this script — there is no
# path through it that errors out, only paths that decide "code".
#
# What counts as documentation (see `is_doc` below):
#
#   design/**   the design folder, whatever the format — Markdown, images,
#               anything. `design/` holds no executable and is not read by any
#               test, gate or build step.
#   docs/**     same, reserved for a future docs site.
#   **/*.md     README.md, CLAUDE.md, a skill file, an ios/ placeholder README.
#   LICENSE*, NOTICE
#
# What is deliberately **not** on that list, though it reads like it belongs:
#
#   *.txt   `linux/CMakeLists.txt` and `windows/CMakeLists.txt` are the desktop
#           build definitions, and `tool/coverage_ignore.txt` is an input to the
#           coverage gate. Every `.txt` in this repository is load-bearing; not
#           one of them is prose. A blanket text rule would skip CI on a change
#           to the Linux build.
#   *.yaml/*.yml  `pubspec.yaml`, `analysis_options.yaml` and the workflows
#           themselves decide what CI even does.
#
# Run it locally the same way CI does:
#
#   tool/docs_only.sh origin/main HEAD

set -uo pipefail

# Anything we cannot decide is decided as "code". Never exits non-zero: a
# crashed classifier must not be able to fail a run, only to widen it.
code() {
  echo "false"
  exit 0
}

[ "$#" -eq 2 ] || code
base=$1
head=$2

# A missing commit is the normal shape of several real cases: the all-zero
# `before` GitHub sends for a branch's first push, or a force-pushed commit the
# runner never fetched.
git rev-parse --verify --quiet "${base}^{commit}" >/dev/null 2>&1 || code
git rev-parse --verify --quiet "${head}^{commit}" >/dev/null 2>&1 || code

# Three dots, not two: the question is "what does this branch change", not
# "how does it differ from the tip of main", and those stop being the same
# answer the moment main moves. --no-renames so a file moved out of design/
# lists both its old and its new path — with rename detection on, moving
# `lib/foo.dart` to `design/foo.md` would report only the documentation half.
changed=$(git diff --name-only --no-renames "${base}...${head}" 2>/dev/null) || code

# An empty diff means the two refs are the same commit, which is not a
# docs-only change — it is a sign the refs were computed wrongly.
[ -n "$changed" ] || code

is_doc() {
  case "$1" in
    design/*|docs/*|*.md|LICENSE|LICENSE.*|NOTICE) return 0 ;;
    *) return 1 ;;
  esac
}

while IFS= read -r path; do
  [ -n "$path" ] || continue
  is_doc "$path" || code
done <<EOF
$changed
EOF

echo "true"
