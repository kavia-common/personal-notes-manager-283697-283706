#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/personal-notes-manager-283697-283706/notes_native_app"
cd "$WORKSPACE"
export DISPLAY=${DISPLAY:-:99}
TMPLOG=/tmp/notes_native_app.log
: >"$TMPLOG"
if [ ! -x ./node_modules/.bin/electron ]; then echo "error: local electron binary not found at ./node_modules/.bin/electron" >&2; exit 2; fi
./node_modules/.bin/electron . >"$TMPLOG" 2>&1 &
echo $! > /tmp/notes_native_app.pid
