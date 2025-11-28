#!/usr/bin/env bash
set -euo pipefail

# Deterministic npm dependency installation and verification
WORKSPACE="/home/kavia/workspace/code-generation/personal-notes-manager-283697-283706/notes_native_app"
cd "$WORKSPACE"
export DEBIAN_FRONTEND=noninteractive
# Ensure NODE_ENV not production so devDependencies are installed
export NODE_ENV=${NODE_ENV:-development}

# Prefer npm ci when lock exists; otherwise generate lock deterministically then npm ci
if [ -f package-lock.json ]; then
  npm ci --no-audit --no-fund || { npm install --no-audit --no-fund > /tmp/npm_install.log 2>&1; echo "npm ci failed; see /tmp/npm_install.log" >&2; exit 6; }
else
  npm i --package-lock-only --no-audit --no-fund || { npm i --package-lock-only --no-audit --no-fund > /tmp/npm_install.log 2>&1; echo "package-lock generation failed; see /tmp/npm_install.log" >&2; exit 6; }
  npm ci --no-audit --no-fund || { npm install --no-audit --no-fund > /tmp/npm_install.log 2>&1; echo "npm ci failed after lock generation; see /tmp/npm_install.log" >&2; exit 6; }
fi

# verification by running local binaries to check they execute and report versions
./node_modules/.bin/electron --version > /tmp/notes_electron_version.txt 2>&1 || { echo "electron failed to run; see /tmp/notes_electron_version.txt" >&2; tail -n 200 /tmp/notes_electron_version.txt || true; exit 7; }
./node_modules/.bin/jest --version > /tmp/notes_jest_version.txt 2>&1 || { echo "jest failed to run; see /tmp/notes_jest_version.txt" >&2; tail -n 200 /tmp/notes_jest_version.txt || true; exit 8; }

# Success indicator (minimal output as required)
echo "deps: ok"
