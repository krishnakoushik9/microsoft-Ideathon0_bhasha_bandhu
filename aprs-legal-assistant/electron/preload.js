const { contextBridge, ipcRenderer } = require('electron');

// Expose protected methods that allow the renderer process to use
// the ipcRenderer without exposing the entire object
contextBridge.exposeInMainWorld(
  'api', {
    // Backend status
    getBackendStatus: () => ipcRenderer.invoke('get-backend-status'),
    restartBackend: () => ipcRenderer.invoke('restart-backend'),
    
    // File operations
    openFileDialog: () => ipcRenderer.invoke('open-file-dialog'),
    
    // Event listeners
    onBackendReady: (callback) => {
      ipcRenderer.on('backend-ready', () => callback());
    }
  }
);
