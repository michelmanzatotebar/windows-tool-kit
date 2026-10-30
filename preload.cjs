const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('batRunner', {
  execute: (relativePath) => ipcRenderer.invoke('bat:run', relativePath),
  cancel: () => ipcRenderer.invoke('bat:cancel'),
  openWallpaperFolder: () => ipcRenderer.invoke('folder:open-wallpaper'),
  sendInput: (input) => ipcRenderer.send('bat:input', input),
  onOutput: (callback) => {
    const listener = (_event, output) => callback(output);
    ipcRenderer.on('bat:output', listener);
    return () => ipcRenderer.removeListener('bat:output', listener);
  },
  onFinished: (callback) => {
    const listener = (_event, result) => callback(result);
    ipcRenderer.on('bat:finished', listener);
    return () => ipcRenderer.removeListener('bat:finished', listener);
  }
});
