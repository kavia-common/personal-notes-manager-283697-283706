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
