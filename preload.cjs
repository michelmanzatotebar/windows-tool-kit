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
  },
  onRepairCloseBlocked: (callback) => {
    const listener = () => callback();
    ipcRenderer.on('repair:close-blocked', listener);
    return () => ipcRenderer.removeListener('repair:close-blocked', listener);
  }
});
