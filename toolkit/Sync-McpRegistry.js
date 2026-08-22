const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const TYPED = path.join(ROOT, 'configs', 'typed-registry.json');
const OUT = path.join(ROOT, 'configs', 'mcp-registry.json');

function load(p) {
  return JSON.parse(fs.readFileSync(p, 'utf8').replace(/^﻿/, ''));
}

const typed = load(TYPED);
const servers = {};

for (const a of typed.assets) {
  if (a.asset_type !== 'mcp_server') continue;
  if (!a.runtime || a.runtime.transport !== 'stdio') continue;
  const healthy = a.verification && a.verification.protocol === 'passed';
  if (!healthy) continue;

  servers[a.id] = {
    name: a.display_name,
    key: a.id,
    kind: 'MCP',
    tier: (a.metadata && a.metadata.tier) || 'A',
    profile: 'CORE',
    role: (a.metadata && a.metadata.notes) || a.category || '',
    tags: [a.category || 'mcp_server'],
    cloned: fs.existsSync(path.join('G:\\MCP-Servers', a.id)),
    snippet: {
      command: a.runtime.command,
      args: a.runtime.args || [],
      env: {},
      cwd: a.runtime.cwd || undefined,
      metadata: a.metadata || {}
    },
    env_refs: a.runtime.env_refs || [],
    enabled: true,
    health: 'healthy',
    pinned_version: (a.metadata && a.metadata.pinned_version) || null
  };
}

const out = {
  version: '2.0.0',
  generated: new Date().toISOString(),
  source_of_truth: 'configs/typed-registry.json (via toolkit/Sync-McpRegistry.js)',
  total: Object.keys(servers).length,
  servers
};

fs.writeFileSync(OUT, JSON.stringify(out, null, 2));
console.log(`Synced ${out.total} healthy MCP servers -> ${path.relative(ROOT, OUT)}`);
