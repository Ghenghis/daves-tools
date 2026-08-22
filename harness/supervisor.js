const fs = require('fs');
const path = require('path');
const { z } = require('zod');
const { recordEvent } = require('./events.js');

const STATE_PATH = path.join(__dirname, '..', 'docs', 'supervisor-state.json');
const DEFAULT_HEARTBEAT_MS = 30000;
const DEFAULT_PING_TIMEOUT_MS = 10000;
const DEFAULT_MAX_FAILURES = 3;
const BACKOFF_STEPS_MS = [1000, 2000, 5000, 10000, 30000, 60000];

const watched = new Map();
let state = { started_at: null, servers: {} };

function loadState() {
  try {
    if (fs.existsSync(STATE_PATH)) {
      state = JSON.parse(fs.readFileSync(STATE_PATH, 'utf8'));
    }
  } catch {}
}

function saveState() {
  try {
    fs.writeFileSync(STATE_PATH, JSON.stringify(state, null, 2));
  } catch (err) {
    console.error('supervisor: failed to save state:', err.message);
  }
}

function ensureEntry(key) {
  if (!state.servers[key]) {
    state.servers[key] = {
      status: 'unknown',
      last_heartbeat: null,
      last_latency_ms: null,
      consecutive_failures: 0,
      restart_count: 0,
      last_restart_at: null,
      last_error: null
    };
  }
  return state.servers[key];
}

function backoffFor(failures) {
  const idx = Math.min(failures - 1, BACKOFF_STEPS_MS.length - 1);
  return BACKOFF_STEPS_MS[Math.max(idx, 0)];
}

function watch(key, child, respawn, opts = {}) {
  unwatch(key);
  const entry = ensureEntry(key);
  entry.status = 'up';
  entry.last_error = null;

  const w = {
    key,
    child,
    respawn,
    intervalMs: opts.intervalMs || DEFAULT_HEARTBEAT_MS,
    pingTimeoutMs: opts.pingTimeoutMs || DEFAULT_PING_TIMEOUT_MS,
    maxFailures: opts.maxFailures || DEFAULT_MAX_FAILURES,
    httpUrl: opts.httpUrl || null,
    timer: null,
    stopped: false
  };

  if (child && child.transport && child.transport.process) {
    child.transport.process.on('exit', (code) => {
      if (w.stopped) return;
      entry.status = 'down';
      entry.last_error = `process exited code=${code}`;
      recordEvent('mcp.process_exit', { key, code });
      scheduleRestart(w);
    });
  }

  w.timer = setInterval(() => heartbeat(w), w.intervalMs);
  watched.set(key, w);
  saveState();
}

function unwatch(key) {
  const w = watched.get(key);
  if (w) {
    w.stopped = true;
    if (w.timer) clearInterval(w.timer);
    watched.delete(key);
  }
}

async function heartbeat(w) {
  const entry = ensureEntry(w.key);
  const started = Date.now();
  try {
    if (w.httpUrl) {
      const controller = new AbortController();
      const t = setTimeout(() => controller.abort(), w.pingTimeoutMs);
      try {
        const resp = await fetch(w.httpUrl, { signal: controller.signal });
        if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
      } finally {
        clearTimeout(t);
      }
    }
    if (w.child) {
      await Promise.race([
        w.child.request({ method: 'ping' }, z.any()),
        new Promise((_, rej) => setTimeout(() => rej(new Error('ping timeout')), w.pingTimeoutMs))
      ]);
    }
    entry.status = 'up';
    entry.last_heartbeat = new Date().toISOString();
    entry.last_latency_ms = Date.now() - started;
    entry.consecutive_failures = 0;
    entry.last_error = null;
    recordEvent('mcp.heartbeat_ok', { key: w.key, latency_ms: entry.last_latency_ms });
  } catch (err) {
    entry.consecutive_failures += 1;
    entry.last_error = err.message;
    entry.status = entry.consecutive_failures >= w.maxFailures ? 'dead' : 'degraded';
    recordEvent('mcp.heartbeat_fail', { key: w.key, failures: entry.consecutive_failures, error: err.message });
    if (entry.consecutive_failures >= w.maxFailures) {
      scheduleRestart(w);
    }
  }
  saveState();
}

function scheduleRestart(w) {
  if (w.stopped || w.restarting) return;
  w.restarting = true;
  const entry = ensureEntry(w.key);
  const delay = backoffFor(entry.consecutive_failures);
  recordEvent('mcp.restart_scheduled', { key: w.key, delay_ms: delay });
  setTimeout(async () => {
    w.restarting = false;
    if (w.stopped) return;
    try { await w.child.close(); } catch {}
    try {
      const newChild = await w.respawn();
      if (newChild) {
        entry.restart_count += 1;
        entry.last_restart_at = new Date().toISOString();
        entry.consecutive_failures = 0;
        entry.status = 'up';
        recordEvent('mcp.restart_ok', { key: w.key, restart_count: entry.restart_count });
        watch(w.key, newChild, w.respawn, w);
      }
    } catch (err) {
      entry.status = 'dead';
      entry.last_error = `restart failed: ${err.message}`;
      recordEvent('mcp.restart_fail', { key: w.key, error: err.message });
    }
    saveState();
  }, delay);
}

function getStatus() {
  return {
    started_at: state.started_at,
    watched: Array.from(watched.keys()),
    servers: state.servers
  };
}

function start() {
  loadState();
  if (!state.started_at) state.started_at = new Date().toISOString();
  saveState();
}

module.exports = { start, watch, unwatch, getStatus, STATE_PATH };
