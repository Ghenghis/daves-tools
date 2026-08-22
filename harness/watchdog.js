const fs = require('fs');
const path = require('path');
const { execFile } = require('child_process');
const { Client } = require('@modelcontextprotocol/sdk/client/index.js');
const { StdioClientTransport } = require('@modelcontextprotocol/sdk/client/stdio.js');
const { z } = require('zod');
const { recordEvent } = require('./events.js');
const { loadPrivateEnv } = require('./privateenv.js');

const ROOT = path.join(__dirname, '..');
const TYPED_REGISTRY = path.join(ROOT, 'configs', 'typed-registry.json');
const STATE_PATH = path.join(ROOT, 'docs', 'supervisor-state.json');
const AUTO_REPAIR = path.join(ROOT, 'toolkit', 'Auto-Repair.ps1');

const INTERVAL_MS = parseInt(process.env.WATCHDOG_INTERVAL_MS || '60000', 10);
const PING_TIMEOUT_MS = parseInt(process.env.WATCHDOG_PING_TIMEOUT_MS || '30000', 10);
const MAX_FAILURES_BEFORE_REPAIR = parseInt(process.env.WATCHDOG_REPAIR_THRESHOLD || '3', 10);
const ONESHOT = process.argv.includes('--once');

function loadTypedRegistry() {
  const raw = fs.readFileSync(TYPED_REGISTRY, 'utf8');
  return JSON.parse(raw.replace(/^﻿/, ''));
}

function loadState() {
  try {
    if (fs.existsSync(STATE_PATH)) return JSON.parse(fs.readFileSync(STATE_PATH, 'utf8'));
  } catch {}
  return { started_at: null, servers: {} };
}

function saveState(state) {
  try {
    fs.writeFileSync(STATE_PATH, JSON.stringify(state, null, 2));
  } catch (err) {
    console.error('watchdog: failed to save state:', err.message);
  }
}

function ensureEntry(state, id) {
  if (!state.servers[id]) {
    state.servers[id] = {
      status: 'unknown',
      last_heartbeat: null,
      last_latency_ms: null,
      consecutive_failures: 0,
      restart_count: 0,
      last_restart_at: null,
      last_error: null,
      last_repair_at: null
    };
  }
  return state.servers[id];
}

async function pingStdio(asset) {
  const rt = asset.runtime || {};
  const started = Date.now();
  const client = new Client({ name: `watchdog-${asset.id}`, version: '1.0.0' });
  const transport = new StdioClientTransport({
    command: rt.command,
    args: rt.args || [],
    env: { ...process.env },
    cwd: rt.cwd || undefined
  });
  try {
    await Promise.race([
      client.connect(transport),
      new Promise((_, rej) => setTimeout(() => rej(new Error('connect timeout')), PING_TIMEOUT_MS))
    ]);
    await Promise.race([
      client.request({ method: 'ping' }, z.any()),
      new Promise((_, rej) => setTimeout(() => rej(new Error('ping timeout')), PING_TIMEOUT_MS))
    ]);
    return { ok: true, latency_ms: Date.now() - started };
  } catch (err) {
    return { ok: false, error: err.message, latency_ms: Date.now() - started };
  } finally {
    try { await client.close(); } catch {}
  }
}

async function pingHttp(url) {
  const started = Date.now();
  const controller = new AbortController();
  const t = setTimeout(() => controller.abort(), PING_TIMEOUT_MS);
  try {
    const resp = await fetch(url, { signal: controller.signal });
    if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
    return { ok: true, latency_ms: Date.now() - started, http_status: resp.status };
  } catch (err) {
    return { ok: false, error: err.message, latency_ms: Date.now() - started };
  } finally {
    clearTimeout(t);
  }
}

function runRepair(assetId) {
  return new Promise((resolve) => {
    if (!fs.existsSync(AUTO_REPAIR)) return resolve({ ran: false, reason: 'Auto-Repair.ps1 missing' });
    const args = ['-ExecutionPolicy', 'Bypass', '-File', AUTO_REPAIR, '-Only', assetId];
    execFile('pwsh', args, { timeout: 180000 }, (err, stdout, stderr) => {
      resolve({ ran: true, ok: !err, output: (stdout || '').slice(-500), error: err ? err.message : null });
    });
  });
}

async function sweep(state) {
  const reg = loadTypedRegistry();
  const targets = reg.assets.filter(a =>
    a.asset_type === 'mcp_server' &&
    a.runtime &&
    a.runtime.auto_start &&
    a.runtime.transport === 'stdio'
  );

  const results = [];
  for (const asset of targets) {
    const entry = ensureEntry(state, asset.id);
    const r = await pingStdio(asset);
    entry.last_latency_ms = r.latency_ms;

    if (r.ok) {
      entry.status = 'up';
      entry.last_heartbeat = new Date().toISOString();
      entry.consecutive_failures = 0;
      entry.last_error = null;
      recordEvent('mcp.heartbeat_ok', { key: asset.id, latency_ms: r.latency_ms, source: 'watchdog' });
    } else {
      entry.consecutive_failures += 1;
      entry.last_error = r.error;
      entry.status = entry.consecutive_failures >= MAX_FAILURES_BEFORE_REPAIR ? 'dead' : 'degraded';
      recordEvent('mcp.heartbeat_fail', { key: asset.id, failures: entry.consecutive_failures, error: r.error, source: 'watchdog' });

      if (entry.consecutive_failures >= MAX_FAILURES_BEFORE_REPAIR) {
        recordEvent('mcp.repair_triggered', { key: asset.id });
        const repair = await runRepair(asset.id);
        entry.last_repair_at = new Date().toISOString();
        entry.restart_count += 1;
        entry.last_restart_at = entry.last_repair_at;
        recordEvent('mcp.repair_result', { key: asset.id, ok: repair.ok, error: repair.error || null });
        if (repair.ok) {
          const recheck = await pingStdio(asset);
          if (recheck.ok) {
            entry.status = 'up';
            entry.consecutive_failures = 0;
            entry.last_heartbeat = new Date().toISOString();
            entry.last_latency_ms = recheck.latency_ms;
            recordEvent('mcp.recovered', { key: asset.id, latency_ms: recheck.latency_ms });
          }
        }
      }
    }
    results.push({ id: asset.id, status: entry.status, latency_ms: entry.last_latency_ms, advisory: false });
    saveState(state);
  }

  const httpTargets = reg.assets.filter(a =>
    a.runtime && a.runtime.healthcheck && a.runtime.healthcheck.url
  );
  for (const asset of httpTargets) {
    const entry = ensureEntry(state, asset.id);
    const r = await pingHttp(asset.runtime.healthcheck.url);
    entry.last_latency_ms = r.latency_ms;
    if (r.ok) {
      entry.status = 'up';
      entry.last_heartbeat = new Date().toISOString();
      entry.consecutive_failures = 0;
      recordEvent('mcp.http_ok', { key: asset.id, latency_ms: r.latency_ms, http_status: r.http_status });
    } else {
      entry.consecutive_failures += 1;
      entry.last_error = r.error;
      entry.status = 'degraded';
      recordEvent('mcp.http_fail', { key: asset.id, failures: entry.consecutive_failures, error: r.error });
    }
    results.push({ id: asset.id, status: entry.status, latency_ms: entry.last_latency_ms, advisory: true });
    saveState(state);
  }

  return results;
}

async function main() {
  const envCount = loadPrivateEnv();
  recordEvent('watchdog.env_loaded', { vars: envCount });
  const state = loadState();
  if (!state.started_at) state.started_at = new Date().toISOString();

  if (ONESHOT) {
    const results = await sweep(state);
    saveState(state);
    const blocking = results.filter(r => !r.advisory);
    const up = blocking.filter(r => r.status === 'up').length;
    const bad = blocking.filter(r => r.status !== 'up');
    const advisoryBad = results.filter(r => r.advisory && r.status !== 'up');
    console.log(`watchdog sweep: ${up}/${blocking.length} up (${advisoryBad.length} advisory backends down)`);
    bad.forEach(b => console.log(`  FAIL ${b.id}: ${b.status}`));
    advisoryBad.forEach(b => console.log(`  WARN ${b.id}: ${b.status} (advisory)`));
    process.exit(bad.length ? 2 : 0);
  }

  console.log(`watchdog daemon started, interval=${INTERVAL_MS}ms`);
  recordEvent('watchdog.started', { interval_ms: INTERVAL_MS });
  const loop = async () => {
    try {
      await sweep(state);
    } catch (err) {
      recordEvent('watchdog.sweep_error', { error: err.message });
    }
    saveState(state);
  };
  await loop();
  setInterval(loop, INTERVAL_MS);
}

main().catch(err => {
  recordEvent('watchdog.fatal', { error: err.message });
  console.error('watchdog fatal:', err);
  process.exit(1);
});
