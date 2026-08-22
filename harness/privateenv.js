const fs = require('fs');
const path = require('path');

const SEARCH_PATHS = ['G:\\private', 'C:\\Users\\Admin\\private', path.join(__dirname, '..', 'private'), 'C:\\Users\\Admin'];
const DEFAULTS = {
  PLAYWRIGHT_BROWSERS_PATH: '0',
  UV_PYTHON: 'python'
};
const ALIASES = {
  GITHUB_TOKEN: 'GITHUB_PERSONAL_ACCESS_TOKEN',
  GH_TOKEN: 'GITHUB_PERSONAL_ACCESS_TOKEN',
  GITLAB_TOKEN: 'GITLAB_PERSONAL_ACCESS_TOKEN',
  GL_TOKEN: 'GITLAB_PERSONAL_ACCESS_TOKEN'
};

function parseEnvFile(filePath, into) {
  const lines = fs.readFileSync(filePath, 'utf8').split(/\r?\n/);
  for (const raw of lines) {
    const line = raw.trim();
    if (!line || line.startsWith('#') || !line.includes('=')) continue;
    const idx = line.indexOf('=');
    const k = line.slice(0, idx).trim();
    const v = line.slice(idx + 1).trim().replace(/["']/g, '');
    if (!(k in into)) into[k] = v;
  }
}

function loadPrivateEnv() {
  const loaded = {};
  for (const [k, v] of Object.entries(DEFAULTS)) loaded[k] = v;

  const files = [];
  for (const dir of SEARCH_PATHS) {
    try {
      if (!fs.existsSync(dir)) continue;
      for (const name of fs.readdirSync(dir)) {
        if (name.startsWith('.env') && name !== '.env.dpapi.json') {
          const full = path.join(dir, name);
          if (fs.statSync(full).isFile()) files.push(full);
        }
      }
    } catch {}
  }
  files.sort((a, b) => fs.statSync(b).mtimeMs - fs.statSync(a).mtimeMs);

  for (const f of files) {
    try { parseEnvFile(f, loaded); } catch {}
  }

  for (const [from, to] of Object.entries(ALIASES)) {
    if (loaded[from] && !(to in loaded)) loaded[to] = loaded[from];
  }

  for (const [k, v] of Object.entries(loaded)) {
    if (process.env[k] === undefined) process.env[k] = v;
  }
  return Object.keys(loaded).length;
}

module.exports = { loadPrivateEnv };
