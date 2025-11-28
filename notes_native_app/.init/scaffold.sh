#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/personal-notes-manager-283697-283706/notes_native_app"
mkdir -p "$WORKSPACE" && cd "$WORKSPACE"
# deterministic package.json; use local binary invocation to avoid npx/global fetch
cat > package.json <<'JSON'
{
  "name": "notes_native_app",
  "version": "0.1.0",
  "private": true,
  "main": "src/main.js",
  "scripts": {
    "start": "NODE_ENV=development ./node_modules/.bin/electron .",
    "build": "echo \"no-op build\"",
    "test": "NODE_ENV=test ./node_modules/.bin/jest --runInBand --colors=false"
  },
  "devDependencies": {
    "electron": "25.3.2",
    "jest": "29.7.0"
  }
}
JSON
mkdir -p src && cat > src/main.js <<'JS'
const { app, BrowserWindow } = require('electron');
function createWindow(){
  console.log('NOTES_APP_STARTING');
  const w = new BrowserWindow({ width: 800, height: 600, webPreferences: { contextIsolation: false, nodeIntegration: false } });
  w.loadFile('index.html');
  console.log('NOTES_APP_READY');
}
app.whenReady().then(createWindow);
// keep app running even if all windows close (scaffold requirement)
app.on('window-all-closed', ()=>{});
JS
cat > src/renderer.js <<'JS'
console.log('renderer ready');
JS
cat > index.html <<'HTML'
<!doctype html>
<html><head><meta charset="utf-8"><title>Notes</title></head><body>
<h1>Notes App (scaffold)</h1>
<script src="src/renderer.js"></script>
</body></html>
HTML
cat > .gitignore <<'GIT'
node_modules/
/dist
/*.log
GIT
mkdir -p data
if command -v sqlite3 >/dev/null 2>&1; then sqlite3 data/notes.db "CREATE TABLE IF NOT EXISTS notes(id INTEGER PRIMARY KEY, title TEXT, body TEXT);"; else echo "note: sqlite3 not present, data/notes.db will be created when sqlite available"; fi
