const fs = require('fs');
const path = require('path');
const { certify } = require('../harness/certifier.js');

const ROOT = path.join(__dirname, '..');
const TYPED = path.join(ROOT, 'configs', 'typed-registry.json');
const OUT = path.join(ROOT, 'docs', 'smoke-test-report.json');
const FAST = process.argv.includes('--fast');
const failures = [];
const warnings = [];

function fail(msg) { failures.push(msg); }
function warn(msg) { warnings.push(msg); }

function structuralChecks(reg) {
  if (!Array.isArray(reg.assets)) { fail('typed-registry.json: assets is not an array'); return; }
  const ids = new Set();
  for (const a of reg.assets) {
    if (!a.id) { fail('asset missing id'); continue; }
    if (ids.has(a.id)) fail(`duplicate asset id: ${a.id}`);
    ids.add(a.id);
    if (a.asset_type === 'mcp_server' && a.runtime && a.runtime.transport === 'stdio') {
      if (!a.runtime.command) fail(`${a.id}: stdio mcp_server missing command`);
      if (a.runtime.command === 'npx') {
        const pkgArg = (a.runtime.args || []).find(x => x && !x.startsWith('-'));
        const pinned = a.metadata && a.metadata.pinned_version;
        if (!pinned) fail(`${a.id}: npx server missing pinned_version`);
        if (pkgArg && !pkgArg.includes('@', pkgArg.startsWith('@') ? 1 : 0)) {
          fail(`${a.id}: npx arg not version-pinned: ${pkgArg}`);
        }
      }
      if (a.runtime.env_refs && a.runtime.env_refs.length && a.verification && a.verification.protocol === 'passed') {
        for (const ref of a.runtime.env_refs) {
          if (!process.env[ref]) warn(`${a.id}: env var ${ref} not set in this environment`);
        }
      }
    }
  }
}

async function liveChecks(reg) {
  const targets = reg.assets.filter(a =>
    a.asset_type === 'mcp_server' &&
    a.runtime && a.runtime.transport === 'stdio' &&
    a.verification && a.verification.protocol === 'passed'
  );
  for (const a of targets) {
    process.stderr.write(`certifying ${a.id}... `);
    const r = await certify(a);
    process.stderr.write(`${r.verdict}\n`);
    if (r.verdict !== 'passed') fail(`${a.id}: live certification ${r.verdict} (${r.error || 'no error detail'})`);
    if (r.version_match === 'warning') warn(`${a.id}: server reports v${r.server_version}, pinned package ${r.pinned_version}`);
  }
  return targets.length;
}

async function main() {
  const raw = fs.readFileSync(TYPED, 'utf8');
  let reg;
  try {
    reg = JSON.parse(raw.replace(/^﻿/, ''));
  } catch (e) {
    fail(`typed-registry.json invalid JSON: ${e.message}`);
  }

  if (reg) {
    structuralChecks(reg);
    let liveCount = 0;
    if (!FAST && failures.length === 0) {
      liveCount = await liveChecks(reg);
    }

    const report = {
      timestamp: new Date().toISOString(),
      mode: FAST ? 'fast' : 'full',
      assets: reg.assets.length,
      live_certified: liveCount,
      failures,
      warnings,
      verdict: failures.length ? 'failed' : 'passed'
    };
    fs.writeFileSync(OUT, JSON.stringify(report, null, 2));
    console.log(JSON.stringify({ verdict: report.verdict, failures: failures.length, warnings: warnings.length, live_certified: liveCount }, null, 2));
    failures.forEach(f => console.log(`FAIL ${f}`));
    warnings.forEach(w => console.log(`WARN ${w}`));
  }
  process.exit(failures.length ? 1 : 0);
}

main().catch(e => { console.error('smoke-test fatal:', e.message); process.exit(1); });
