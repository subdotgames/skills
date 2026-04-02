#!/usr/bin/env node

/**
 * sub.games Credential Management Script
 *
 * Manages API credentials for sub.games integration with Claude Code.
 *
 * Usage:
 *   node subgames-auth.js           - Start browser auth flow (default)
 *   node subgames-auth.js auth      - Same as above
 *   node subgames-auth.js status    - Check current auth status
 *   node subgames-auth.js manual <base64> - Save manually pasted credentials
 *   node subgames-auth.js hmac <METHOD> <PATH> - Generate HMAC auth header
 *   node subgames-auth.js clear     - Remove stored credentials
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');
const crypto = require('crypto');
const { execSync } = require('child_process');

const CREDENTIALS_FILE = path.join(os.homedir(), '.subgames-credentials.json');
const DEFAULT_PORT = 9877;
const CALLBACK_TIMEOUT = 5 * 60 * 1000;
const APP_URL = process.env.SUBGAMES_APP_URL || 'https://sub.games';
const API_URL = process.env.SUBGAMES_API_URL || 'https://api.sub.games';

// --- Credential Storage ---

function readCredentials() {
  try {
    if (!fs.existsSync(CREDENTIALS_FILE)) return null;
    const data = JSON.parse(fs.readFileSync(CREDENTIALS_FILE, 'utf8'));
    if (!data.apiKey || !data.secret) return null;
    return data;
  } catch {
    return null;
  }
}

function saveCredentials(apiKey, secret) {
  const data = {
    apiKey,
    secret,
    apiUrl: API_URL,
    appUrl: APP_URL,
    createdAt: new Date().toISOString(),
  };
  fs.writeFileSync(CREDENTIALS_FILE, JSON.stringify(data, null, 2), { mode: 0o600 });
}

function clearCredentials() {
  try {
    if (fs.existsSync(CREDENTIALS_FILE)) fs.unlinkSync(CREDENTIALS_FILE);
    console.log('Credentials cleared.');
  } catch (err) {
    console.error('Failed to clear credentials:', err.message);
  }
}

// --- HMAC Signature ---

function generateHmacAuth(apiKey, secret, method, apiPath) {
  const timestamp = Date.now();
  const dataToSign = [method.toLowerCase(), apiPath.toLowerCase(), timestamp].join('\n');
  const signature = crypto.createHmac('sha256', secret).update(dataToSign).digest('hex');
  return `HMAC-SHA256 apiKey=${apiKey}, signature=${signature}, timestamp=${timestamp}`;
}

// --- Browser Auth Flow ---

function openBrowser(url) {
  const platform = os.platform();
  try {
    if (platform === 'darwin') execSync(`open "${url}"`);
    else if (platform === 'win32') execSync(`start "" "${url}"`);
    else execSync(`xdg-open "${url}"`);
  } catch {
    console.log(`Open this URL in your browser:\n  ${url}`);
  }
}

function decodeCredentials(base64) {
  try {
    const decoded = Buffer.from(base64, 'base64').toString('utf8');
    const colonIndex = decoded.indexOf(':');
    if (colonIndex === -1) return null;
    const apiKey = decoded.substring(0, colonIndex);
    const secret = decoded.substring(colonIndex + 1);
    if (!apiKey || !secret) return null;
    return { apiKey, secret };
  } catch {
    return null;
  }
}

function startCallbackAuth() {
  return new Promise((resolve, reject) => {
    let resolved = false;

    const server = http.createServer((req, res) => {
      const url = new URL(req.url, `http://localhost`);

      if (url.pathname === '/callback') {
        const credentialsParam = url.searchParams.get('credentials');

        if (!credentialsParam) {
          res.writeHead(400, { 'Content-Type': 'text/html' });
          res.end('<html><body><h2>Missing credentials parameter</h2></body></html>');
          return;
        }

        const creds = decodeCredentials(credentialsParam);
        if (!creds) {
          res.writeHead(400, { 'Content-Type': 'text/html' });
          res.end('<html><body><h2>Invalid credentials format</h2></body></html>');
          return;
        }

        saveCredentials(creds.apiKey, creds.secret);

        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(`<html><body style="font-family:system-ui;display:flex;justify-content:center;align-items:center;height:100vh;margin:0;background:#1a1a2e;color:#fff">
          <div style="text-align:center">
            <h2>Authenticated with sub.games</h2>
            <p style="color:#888">You can close this tab and return to Claude Code.</p>
          </div>
        </body></html>`);

        resolved = true;
        server.close();
        resolve(creds);
      } else {
        res.writeHead(404);
        res.end('Not found');
      }
    });

    server.on('error', (err) => {
      if (err.code === 'EADDRINUSE') {
        console.error(`Port ${DEFAULT_PORT} is in use. Try again or use manual mode.`);
        reject(err);
      } else {
        reject(err);
      }
    });

    server.listen(DEFAULT_PORT, '127.0.0.1', () => {
      const port = server.address().port;
      const authUrl = `${APP_URL}/auth/claude-callback?port=${port}`;

      console.log(`Waiting for authentication...`);
      console.log(`Opening browser to: ${authUrl}\n`);
      openBrowser(authUrl);
    });

    setTimeout(() => {
      if (!resolved) {
        server.close();
        reject(new Error('Authentication timed out after 5 minutes'));
      }
    }, CALLBACK_TIMEOUT);
  });
}

// --- Commands ---

async function main() {
  const command = process.argv[2] || 'auth';

  switch (command) {
    case 'auth': {
      const existing = readCredentials();
      if (existing) {
        console.log(`Already authenticated as: ${existing.apiKey}`);
        console.log('Run "node subgames-auth.js clear" first to re-authenticate.');
        process.exit(0);
      }
      try {
        const creds = await startCallbackAuth();
        console.log(`\nAuthenticated successfully!`);
        console.log(`  API Key: ${creds.apiKey}`);
        console.log(`  Credentials saved to: ${CREDENTIALS_FILE}`);
      } catch (err) {
        console.error(`Authentication failed: ${err.message}`);
        process.exit(1);
      }
      break;
    }

    case 'status': {
      const creds = readCredentials();
      if (creds) {
        console.log(`Authenticated`);
        console.log(`  API Key:    ${creds.apiKey}`);
        console.log(`  API URL:    ${creds.apiUrl || API_URL}`);
        console.log(`  Created:    ${creds.createdAt || 'unknown'}`);
        console.log(`  Creds file: ${CREDENTIALS_FILE}`);
      } else {
        console.log('Not authenticated. Run "node subgames-auth.js" to authenticate.');
        process.exit(1);
      }
      break;
    }

    case 'manual': {
      const base64 = process.argv[3];
      if (!base64) {
        console.error('Usage: node subgames-auth.js manual <base64-credentials>');
        process.exit(1);
      }
      const creds = decodeCredentials(base64);
      if (!creds) {
        console.error('Invalid credentials format. Expected base64(apiKey:secret).');
        process.exit(1);
      }
      saveCredentials(creds.apiKey, creds.secret);
      console.log(`Credentials saved!`);
      console.log(`  API Key: ${creds.apiKey}`);
      break;
    }

    case 'hmac': {
      const method = process.argv[3];
      const apiPath = process.argv[4];
      if (!method || !apiPath) {
        console.error('Usage: node subgames-auth.js hmac <METHOD> <PATH>');
        process.exit(1);
      }
      const creds = readCredentials();
      if (!creds) {
        console.error('Not authenticated. Run "node subgames-auth.js" first.');
        process.exit(1);
      }
      const header = generateHmacAuth(creds.apiKey, creds.secret, method, apiPath);
      console.log(header);
      break;
    }

    case 'clear': {
      clearCredentials();
      break;
    }

    default:
      console.error(`Unknown command: ${command}`);
      console.error('Commands: auth, status, manual, hmac, clear');
      process.exit(1);
  }
}

main();
