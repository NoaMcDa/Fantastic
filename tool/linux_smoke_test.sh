#!/usr/bin/env bash
#
# Headless startup smoke test for the Linux desktop build.
#
# Run it after `flutter build linux --release`, from the repository root or
# from anywhere — it finds its own way there:
#
#   flutter build linux --release
#   tool/linux_smoke_test.sh
#
# ## Why this exists
#
# A compile is not a launch. Every Linux fault this app has had was a *startup*
# fault, and all three were invisible to `flutter analyze`, to `flutter test`
# and to `flutter build linux`:
#
#   1. `getApplicationDocumentsDirectory()` throwing, because
#      `path_provider_linux` shells out to `xdg-user-dir`.
#   2. `flutter_local_notifications` refusing to `initialize` without a
#      settings object for the platform.
#   3. `zonedSchedule` being unimplemented on Linux.
#
# They were found by building the app and looking at the screen. This script is
# the automated version of looking at the screen, and would have caught all
# three: each of them left `main`'s outer catch rendering StartupFailureApp.
#
# ## What it asserts
#
#   1. The process is still alive after ${SMOKE_RUN_SECONDS}s. Catches a hard
#      crash, an abort in the engine, and a `main` that throws its way out.
#   2. The database file was created under XDG_DATA_HOME. This is a *positive*
#      signal, not the absence of a negative: it can only exist if
#      `openAppDatabase()` resolved a directory and wrote to it, which is
#      exactly what fault (1) above broke.
#   3. The log contains none of the fatal patterns below.
#
# ## What it deliberately tolerates
#
# A headless X server is noisy, and a smoke test that fails on noise gets
# switched off. So this matches an explicit list of fatal patterns rather than
# rejecting everything it does not recognise. `libEGL` DRI3 warnings,
# `Atk-CRITICAL`, the Impeller backend line and `fl_gnome_settings` all appear
# on a perfectly healthy headless run. The log is printed in full either way,
# and anything outside the known-benign set is surfaced for a human to read
# without failing the build.
#
set -u -o pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

readonly BUNDLE_DIR='build/linux/x64/release/bundle'
readonly RUN_SECONDS="${SMOKE_RUN_SECONDS:-20}"
readonly LOG="${SMOKE_LOG:-build/linux_smoke_test.log}"

# Lines that are expected on a headless runner and mean nothing is wrong.
# Every entry here has been observed on a green run — `Atk-CRITICAL`,
# `fl_gnome_settings` and the `libEGL` DRI3 pair in a container, and the AT-SPI
# accessibility-bus warning on a GitHub runner, which has no a11y bus. A notice
# that fires on every healthy run is noise people learn to scroll past, which
# is the same way a warning stops being read.
readonly BENIGN_NOISE='libEGL|DRI3|Atk-CRITICAL|Impeller|fl_gnome_settings|Gtk-WARNING|Gdk-|MESA|dbus|dbind-WARNING|AT-SPI|org\.a11y\.Bus|Failed to connect to the bus'

fail() {
  echo "::error::linux smoke test: $*" >&2
  echo "linux smoke test FAILED: $*" >&2
  dump_log
  exit 1
}

dump_log() {
  if [[ -s "$LOG" ]]; then
    echo '--- application log ---' >&2
    cat "$LOG" >&2
    echo '--- end application log ---' >&2
  else
    echo '--- application log is empty ---' >&2
  fi
}

# ---------------------------------------------------------------------------
# The three strings this script needs are read out of the sources that own
# them, never re-declared here. A rename in the app is then a loud failure of
# this script rather than a check that silently stops checking anything.
# ---------------------------------------------------------------------------

# `const String startupFailureLogPrefix = '...';` in lib/main.dart.
MARKER="$(sed -n "s/^const String startupFailureLogPrefix = '\(.*\)';$/\1/p" lib/main.dart)"
[[ -n "$MARKER" ]] || fail \
  "could not read startupFailureLogPrefix out of lib/main.dart — if it was renamed, update this script, because without it a failed startup looks identical to a healthy one"

# `const String appDatabaseName = '...';` in the io half of the db firewall.
DB_NAME="$(sed -n "s/^const String appDatabaseName = '\(.*\)';$/\1/p" lib/core/database/database_factory_io.dart)"
[[ -n "$DB_NAME" ]] || fail 'could not read appDatabaseName out of lib/core/database/database_factory_io.dart'

# `set(APPLICATION_ID "...")` in linux/CMakeLists.txt — path_provider_linux
# names the data directory after it.
APP_ID="$(sed -n 's/^set(APPLICATION_ID "\(.*\)")$/\1/p' linux/CMakeLists.txt)"
[[ -n "$APP_ID" ]] || fail 'could not read APPLICATION_ID out of linux/CMakeLists.txt'

readonly MARKER DB_NAME APP_ID

# Fatal patterns, in the order they are reported.
#   $MARKER              — main caught a startup failure and fell back to the
#                          error screen. The app is alive and looks fine; it is
#                          showing the user a database error.
#   Unhandled Exception  — the engine's own line for an error nothing caught.
#   EXCEPTION CAUGHT BY  — any FlutterError report, which on Linux means a real
#                          framework or widget failure: the one non-fatal
#                          reporter in this app (the notification guard in
#                          `main`) cannot fire here, because
#                          `NotificationService.initialise` returns early on
#                          any platform that cannot schedule, and Linux is one.
readonly FATAL_PATTERNS=(
  "$MARKER"
  'Unhandled Exception'
  'EXCEPTION CAUGHT BY'
)

readonly APP="$BUNDLE_DIR/fantastic"
[[ -x "$APP" ]] || fail "no built bundle at $APP — run 'flutter build linux --release' first"

command -v xvfb-run >/dev/null 2>&1 || fail "xvfb-run is not installed (apt-get install xvfb)"

# A fresh XDG root per run. The database lands under XDG_DATA_HOME, and one
# left over from an earlier run would hide a first-launch-only fault — which is
# the only kind this script is looking for.
XDG_ROOT="$(mktemp -d)"
export XDG_DATA_HOME="$XDG_ROOT/data"
export XDG_CONFIG_HOME="$XDG_ROOT/config"
export XDG_CACHE_HOME="$XDG_ROOT/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"

mkdir -p "$(dirname "$LOG")"
: >"$LOG"

APP_PID=''
cleanup() {
  if [[ -n "$APP_PID" ]]; then
    kill -TERM "$APP_PID" 2>/dev/null || true
    # The app is a grandchild of this shell (xvfb-run → Xvfb + app), so the
    # TERM above may not reach it. Named by its full built path so this can
    # never match anything but the binary this run started.
    pkill -TERM -f "$PWD/$APP" 2>/dev/null || true
    sleep 1
    kill -KILL "$APP_PID" 2>/dev/null || true
    pkill -KILL -f "$PWD/$APP" 2>/dev/null || true
  fi
  rm -rf "$XDG_ROOT"
}
trap cleanup EXIT

echo "Launching $APP headlessly for ${RUN_SECONDS}s…"
xvfb-run -a --server-args='-screen 0 1280x900x24' "$PWD/$APP" >"$LOG" 2>&1 &
APP_PID=$!

# Poll rather than sleep: a process that dies at second two should be reported
# as having died at second two, not waited out.
for ((elapsed = 0; elapsed < RUN_SECONDS; elapsed++)); do
  sleep 1
  if ! kill -0 "$APP_PID" 2>/dev/null; then
    fail "the app exited after ${elapsed}s instead of staying up for ${RUN_SECONDS}s"
  fi
done

echo "Still running after ${RUN_SECONDS}s."

# --- 2. The database was opened ---------------------------------------------

DB_FILE="$XDG_DATA_HOME/$APP_ID/$DB_NAME"
[[ -f "$DB_FILE" ]] || fail \
  "the app never created its database at \$XDG_DATA_HOME/$APP_ID/$DB_NAME — openAppDatabase() did not complete, which is what a path_provider failure on this platform looks like"

echo "Database created at \$XDG_DATA_HOME/$APP_ID/$DB_NAME."

# --- 3. No fatal line in the log --------------------------------------------

for pattern in "${FATAL_PATTERNS[@]}"; do
  if grep -qF -- "$pattern" "$LOG"; then
    fail "the log contains '$pattern'"
  fi
done

echo 'No fatal lines in the application log.'

# Everything else is reported, not enforced. A new line nobody has classified
# yet is worth a human glance and is not worth a red build.
UNRECOGNISED="$(grep -Ev "$BENIGN_NOISE" "$LOG" | grep -v '^[[:space:]]*$' || true)"
if [[ -n "$UNRECOGNISED" ]]; then
  echo '::notice::linux smoke test: log lines outside the known-benign set (not a failure)'
  echo '--- unrecognised log lines ---'
  echo "$UNRECOGNISED"
  echo '--- end unrecognised log lines ---'
fi

dump_log
echo 'linux smoke test PASSED'
