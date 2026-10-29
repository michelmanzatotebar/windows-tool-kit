const { app, BrowserWindow, ipcMain, shell } = require('electron');
const { spawn } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');
const { StringDecoder } = require('node:string_decoder');

const cp850HighBytes = 'ÇüéâäàåçêëèïîìÄÅÉæÆôöòûùÿÖÜø£Ø×ƒáíóúñÑªº¿®¬½¼¡«»░▒▓│┤╡╢╖╕╣║╗╝╜╛┐└┴┬├─┼ãÃ╚╔╩╦╠═╬¤ðÐÊËÈıÍÎÏ┘┌█▄¦Ì▀ÓßÔÒõÕµþÞÚÛÙýÝ¯´≡±‗¾¶§÷¸°¨·¹³²■ ';

function decodeChunk(decoder, chunk, final = false) {
  const text = final ? decoder.end(chunk) : decoder.write(chunk);
  if (!text.includes('\uFFFD') || !chunk || chunk.length === 0) return text;
  return Array.from(chunk, (byte) => byte < 0x80 ? String.fromCharCode(byte) : cp850HighBytes[byte - 0x80]).join('');
}

const allowedScripts = new Set([
  'Aplicar scripts/1-Executar-todos-os-scripts.bat',
  'Papel de parede/0-Definir-papel-de-parede-padrao.bat',
  'Aplicar scripts/2-bloquear-Wifi.bat',
  'Aplicar scripts/3-bloqueio-tela-personalizacao-e-tela-contas.bat',
  'Aplicar scripts/4-Bloquear-microsoft-store.bat',
  'Aplicar scripts/5-Aplicar-Control-de-senha.bat',
  'Aplicar scripts/6-Desativar-Arquivos-offline-e-backup.bat',
  'lixeira limpar/ExecLimparLixeira.bat',
  'reparar sistema/RepararWindows.bat',
  'config de rede/ipReset.bat',
  'config de rede/Configurar-IP.bat',
  'Reverter scripts/Reativar-Desbloquear-todos-scripts.bat',
  'Reverter scripts/1-Desbloquear-wifi.bat',
  'Reverter scripts/2-Desbloquear-tela-personalizacao-e-tela-contas.bat',
  'Reverter scripts/3-Desbloquear-microsoft-store.bat',
  'Reverter scripts/4-Desbloquear-controle-de-senhas.bat',
  'Reverter scripts/5-Reativar-Arquivos-offline.bat'
]);

let activeProcess = null;

function getScriptsRoot() {
  return app.isPackaged ? process.resourcesPath : app.getAppPath();
}

function createWindow() {
  const window = new BrowserWindow({
    width: 1200,
    height: 820,
    minWidth: 760,
    minHeight: 600,
    backgroundColor: '#080a12',
    webPreferences: {
      preload: path.join(__dirname, 'preload.cjs'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true
    }
  });

  const allowedExternalUrls = new Set([
    'https://github.com/michelmanzatotebar',
    'https://www.linkedin.com/in/michel-manzato-tebar/'
  ]);
  window.webContents.setWindowOpenHandler(({ url }) => {
    if (allowedExternalUrls.has(url)) {
      shell.openExternal(url).catch((error) => console.error('N\u00e3o foi poss\u00edvel abrir o link externo:', error));
    }
    return { action: 'deny' };
  });

  window.loadFile(path.join(__dirname, 'src', 'index.html'));
}

function sendOutput(sender, stream, decoder, chunk, final = false) {
  let text = decodeChunk(decoder, chunk, final);
  text = text.replace(/\x1B\[[0-?]*[ -/]*[@-~]/g, '')
    .replace(/\0/g, '')
    .replace(/\r(?!\n)/g, '\n')
    .replace(/\x08/g, '');
  if (text) sender.send('bat:output', { stream, text });
}

ipcMain.handle('folder:open-wallpaper', async () => {
  const scriptsRoot = getScriptsRoot();
  const folderPath = path.resolve(scriptsRoot, 'Papel de parede', 'wallpaper');
  if (!folderPath.startsWith(`${scriptsRoot}${path.sep}`) || !fs.existsSync(folderPath)) {
    throw new Error('Pasta wallpaper não encontrada.');
  }
  const error = await shell.openPath(folderPath);
  if (error) throw new Error(error);
  return { opened: true };
});

ipcMain.handle('bat:run', async (event, relativePath) => {
  if (activeProcess) throw new Error('Aguarde o script atual terminar antes de iniciar outro.');
  if (typeof relativePath !== 'string' || !allowedScripts.has(relativePath)) {
    throw new Error('Script não autorizado.');
  }

  const scriptsRoot = getScriptsRoot();
  const batPath = path.resolve(scriptsRoot, relativePath);
  if (!batPath.startsWith(`${scriptsRoot}${path.sep}`) || !fs.existsSync(batPath)) {
    throw new Error(`Arquivo BAT não encontrado: ${relativePath}`);
  }

  // Com argumentos verbatim, o cmd recebe a chamada e o caminho entre aspas
  // exatamente como precisa, inclusive quando as pastas têm espaços.
  const command = `chcp 65001>nul & call "${batPath}"`;
  const child = spawn(process.env.ComSpec || 'cmd.exe', ['/d', '/c', command], {
    cwd: path.dirname(batPath),
    windowsHide: true,
    windowsVerbatimArguments: true,
    stdio: ['pipe', 'pipe', 'pipe']
  });
  const stdoutDecoder = new StringDecoder('utf8');
  const stderrDecoder = new StringDecoder('utf8');
  activeProcess = { child, sender: event.sender };

  child.stdout.on('data', (chunk) => sendOutput(event.sender, 'stdout', stdoutDecoder, chunk));
  child.stderr.on('data', (chunk) => sendOutput(event.sender, 'stderr', stderrDecoder, chunk));

  return new Promise((resolve, reject) => {
    child.once('error', (error) => {
      activeProcess = null;
      reject(error);
    });

    child.once('close', (code) => {
      sendOutput(event.sender, 'stdout', stdoutDecoder, undefined, true);
      sendOutput(event.sender, 'stderr', stderrDecoder, undefined, true);
      activeProcess = null;
      event.sender.send('bat:finished', { code });
      resolve({ code });
    });
  });
});

ipcMain.on('bat:input', (event, input) => {
  if (!activeProcess || activeProcess.sender !== event.sender || typeof input !== 'string') return;
  activeProcess.child.stdin.write(`${input}\r\n`);
});

app.whenReady().then(createWindow);

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) createWindow();
});

app.on('before-quit', () => {
  if (activeProcess) activeProcess.child.kill();
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
