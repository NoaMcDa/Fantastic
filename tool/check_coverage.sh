#!/usr/bin/env bash
# tool/check_coverage.sh — enforce the domain + application line-coverage gate.
#
# Usage: tool/check_coverage.sh [lcov-file] [min-percent]
#
# Why a script rather than an off-the-shelf action such as `very_good_coverage`:
#
# - **Scope.** The contract (`design/tests.md`) is 80% on `domain/` +
#   `application/`, not on `lib/`. `data/` and `presentation/` are covered by
#   contract and widget tests instead, and including them measures the wrong
#   thing in both directions. No lcov action filters by path.
# - **Independence from summary records.** This counts `DA:<line>,<hits>`
#   directly rather than reading `LF:`/`LH:`. `design/cicd_plan.md` §5.3 and
#   `design/m1_handoff.md` recorded that this project's `lcov.info` carried no
#   summary lines at all, which would have made an LF-based reader compute 0/0
#   and report a silent 100% for every file. On Flutter 3.47.3 that is no
#   longer true — every record now carries `LF:`/`LH:` — but the fact that it
#   changed once under us is the argument for not depending on it.
#
# Generated files are excluded: `.g.dart` is riverpod boilerplate nobody writes
# or reviews, and letting it into the denominator measures the generator.
#
# **Expect the number to differ by a line or two between machines.** Measured
# on the same container twice it is identical, but a CI runner reported
# 472/473 where a dev box reported 470/472 on the same commit — the two
# differing files were `streak_notification_service.dart` and
# `text_recognition_service.dart`. `flutter test` shards by CPU count and
# collects coverage across those isolates, so exactly which lines get recorded
# shifts slightly with the machine. File *presence* was identical, which is
# what `check_coverage_files.sh` keys on. The practical consequence: keep real
# headroom between the gate and the measured number, and do not chase a
# one-line disagreement between your terminal and the run.
set -euo pipefail

LCOV="${1:-coverage/lcov.info}"
MIN="${2:-80}"

[ -f "$LCOV" ] || { echo "No coverage file at $LCOV — run 'flutter test --coverage' first."; exit 1; }

awk -v min="$MIN" '
  /^SF:/ {
    file  = substr($0, 4)
    gated = (file ~ /\/domain\// || file ~ /\/application\//) && file !~ /\.g\.dart$/
    tot = 0; hit = 0
  }
  /^DA:/ { split(substr($0, 4), a, ","); tot++; if (a[2] + 0 > 0) hit++ }
  /^end_of_record/ {
    if (gated && tot > 0) {
      total += tot; hits += hit
      if (hit < tot) { short[file] = sprintf("%d/%d", hit, tot) }
      printf "  %-64s %4d/%4d\n", file, hit, tot
    }
  }
  END {
    # Load-bearing: without it, a refactor that renamed a layer would turn the
    # gate into a no-op and nobody would notice. A gate that always passes is
    # worse than no gate.
    if (total == 0) {
      print "FAIL: no gated lines found — refusing to pass a vacuous gate."
      exit 1
    }
    pct = 100 * hits / total
    printf "\nGated coverage (domain + application): %d/%d = %.2f%% (min %d%%)\n",
           hits, total, pct, min
    if (pct + 0 < min + 0) {
      print "FAIL: below the gate."
      for (f in short) { printf "  uncovered: %-58s %s\n", f, short[f] }
      exit 1
    }
    print "PASS"
    exit 0
  }
' "$LCOV"
