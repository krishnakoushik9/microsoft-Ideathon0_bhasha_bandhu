const { app, BrowserWindow, ipcMain, dialog } = require('electron');
const path = require('path');
const fs = require('fs');
const { spawn } = require('child_process');
const os = require('os');

// Keep a global reference of the window object to prevent it from being garbage collected
let mainWindow;
let backendProcess = null;
let backendReady = false;

function createWindow() {
  // Create the browser window
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    minWidth: 800,
    minHeight: 600,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    },
    icon: path.join(__dirname, '../frontend/assets/logo.png')
  });

  // Load the index.html file
  mainWindow.loadFile(path.join(__dirname, '../frontend/index.html'));

  // Open DevTools in development mode
  if (process.env.NODE_ENV === 'development') {
    mainWindow.webContents.openDevTools();
  }

  // Handle window close
  mainWindow.on('closed', () => {
    mainWindow = null;
    stopBackend();
  });
}

// Start the backend server
function startBackend() {
  const isWin = process.platform === 'win32';
  const pythonExecutable = isWin ? 'python' : 'python3';
  const backendPath = path.join(__dirname, '../backend/main.py');

  console.log('Starting backend server...');
  
  // Check if backend file exists
  if (!fs.existsSync(backendPath)) {
    console.error('Backend file not found:', backendPath);
    dialog.showErrorBox(
      'Backend Error',
      'Backend file not found. Please make sure the application is installed correctly.'
    );
    return;
  }

  // Start the backend process
  backendProcess = spawn(pythonExecutable, [backendPath]);

  // Handle backend output
  backendProcess.stdout.on('data', (data) => {
    console.log(`Backend: ${data}`);
    
    // Check if server is ready
    if (data.toString().includes('APRS Legal Assistant API is running')) {
      backendReady = true;
      if (mainWindow) {
        mainWindow.webContents.send('backend-ready');
      }
    }
  });

  // Handle backend errors
  backendProcess.stderr.on('data', (data) => {
    console.error(`Backend Error: ${data}`);
  });

  // Handle backend exit
  backendProcess.on('close', (code) => {
    console.log(`Backend process exited with code ${code}`);
    backendProcess = null;
    backendReady = false;
  });
}

// Stop the backend server
function stopBackend() {
  if (backendProcess) {
    console.log('Stopping backend server...');
    
    // Kill the process
    if (process.platform === 'win32') {
      spawn('taskkill', ['/pid', backendProcess.pid, '/f', '/t']);
    } else {
      backendProcess.kill('SIGTERM');
    }
    
    backendProcess = null;
    backendReady = false;
  }
}

// Initialize app
app.whenReady().then(() => {
  createWindow();
  startBackend();

  // On macOS, recreate window when dock icon is clicked
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

// Quit when all windows are closed, except on macOS
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

// Handle app quit
app.on('quit', () => {
  stopBackend();
});

// IPC handlers
ipcMain.handle('get-backend-status', () => {
  return { ready: backendReady };
});

ipcMain.handle('restart-backend', () => {
  stopBackend();
  startBackend();
  return { success: true };
});

ipcMain.handle('open-file-dialog', async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    properties: ['openFile'],
    filters: [
      { name: 'Documents', extensions: ['pdf', 'doc', 'docx', 'txt'] }
    ]
  });
  
  if (!result.canceled) {
    return { filePath: result.filePaths[0] };
  }
  
  return { filePath: null };
});
