#!/usr/bin/env bash
set -euo pipefail
# Validation script: installs runtime pkgs (if missing), runs build (no-op), starts electron, waits for readiness marker, collects evidence, graceful shutdown
WORKSPACE="/home/kavia/workspace/code-generation/personal-notes-manager-283697-283706/notes_native_app"
cd "$WORKSPACE"
export DEBIAN_FRONTEND=noninteractive
# allow override of runtime packages to keep installs minimal (e.g. only GTK3)
DEFAULT_PKGS=(libgtk-3-0 libgdk-pixbuf2.0-0 libx11-6 libxss1 libasound2 libnss3 libgbm1 fonts-noto-color-emoji)
IFS=',' read -r -a REQUIRED_PKGS <<< "${VALIDATION_PKGS:-$(printf "%s," "${DEFAULT_PKGS[@]}")}"; REQUIRED_PKGS=(${REQUIRED_PKGS[@]})
MISSING=()
for p in "${REQUIRED_PKGS[@]}"; do dpkg -s "$p" >/dev/null 2>&1 || MISSING+=("$p"); done
if [ ${#MISSING[@]} -ne 0 ]; then for i in 1 2 3; do sudo apt-get update -q && sudo apt-get install -y -q "${MISSING[@]}" && break || sleep 1; done; fi
# build (no-op) but keep safe
npm run build --silent >/dev/null || true
export DISPLAY=${DISPLAY:-:99}
TMPLOG=/tmp/notes_native_app.log
: >"$TMPLOG"
# start app using local electron
if [ ! -x ./node_modules/.bin/electron ]; then echo "error: local electron binary not found at ./node_modules/.bin/electron" >&2; exit 2; fi
./node_modules/.bin/electron . >"$TMPLOG" 2>&1 &
APP_PID=$!
TIMEOUT=${VALIDATION_TIMEOUT:-60}
READY=0
for i in $(seq 1 "$TIMEOUT"); do
  if grep -q 'NOTES_APP_READY' "$TMPLOG"; then READY=1; break; fi
  sleep 1
done
EVIDENCE=/tmp/notes_native_evidence.txt
echo "timestamp: $(date --iso-8601=seconds)" >"$EVIDENCE"
if [ "$READY" -ne 1 ]; then
  echo "status: failed" >>"$EVIDENCE"
  echo "reason: readiness marker not seen within ${TIMEOUT}s" >>"$EVIDENCE"
  echo "last log excerpt:" >>"$EVIDENCE"
  tail -n 500 "$TMPLOG" >>"$EVIDENCE" || true
  # resolve native electron binary for ldd diagnostics
  NATIVE_BIN=""
  if [ -f node_modules/electron/dist/electron ]; then NATIVE_BIN="node_modules/electron/dist/electron"; fi
  if [ -z "$NATIVE_BIN" ] && [ -L node_modules/.bin/electron ]; then NATIVE_BIN=$(readlink -f node_modules/.bin/electron || true); fi
  if [ -n "$NATIVE_BIN" ] && [ -x "$NATIVE_BIN" ]; then echo "ldd $NATIVE_BIN:" >>"$EVIDENCE"; ldd "$NATIVE_BIN" 2>&1 | tail -n 200 >>"$EVIDENCE" || true; fi
  # attempt graceful stop
  kill "$APP_PID" >/dev/null 2>&1 || true
  sleep 1
  if kill -0 "$APP_PID" >/dev/null 2>&1; then kill -9 "$APP_PID" >/dev/null 2>&1 || true; fi
  echo "evidence: $EVIDENCE"
  exit 9
fi
# success evidence
echo "status: success" >>"$EVIDENCE"
echo "app_pid: $APP_PID" >>"$EVIDENCE"
tail -n 200 "$TMPLOG" >>"$EVIDENCE" || true
# graceful shutdown
kill -INT "$APP_PID" >/dev/null 2>&1 || true
for i in 1 5; do
  if ! kill -0 "$APP_PID" >/dev/null 2>&1; then break; fi
  sleep 1
done
if kill -0 "$APP_PID" >/dev/null 2>&1; then kill -9 "$APP_PID" >/dev/null 2>&1 || true; fi
echo "evidence: $EVIDENCE"
