const { Client } = require('@modelcontextprotocol/sdk/client/index.js');
const { StdioClientTransport } = require('@modelcontextprotocol/sdk/client/stdio.js');
const { setHealth } = require('./registry.js');
const supervisor = require('./supervisor.js');
const { buildContainerCommand } = require('./container.js');

const active = new Map();
let registryRef = { servers: {} };

function setRegistry(registry) {
  registryRef = registry;
}

async function enable(registry, key, sendNotification) {
  const server = registry.servers[key];
  if (!server) throw new Error(`Unknown MCP: ${key}`);
  if (active.has(key)) return { status: 'already active', tools: Object.keys(active.get(key).tools) };

  const container = buildContainerCommand({ runtime: server.snippet, metadata: (server.snippet && server.snippet.metadata) || {} });
  const usingContainer = container && !container.fallback;
  const command = usingContainer ? container.command : server.snippet.command;
  const args = usingContainer ? container.args : (server.snippet.args || []);
  const cwd = usingContainer ? container.cwd : (server.snippet.cwd || undefined);

  const child = new Client({ name: `harness-child-${key}`, version: '1.0.0' });
  const transport = new StdioClientTransport({
    command,
    args,
    env: { ...process.env, ...(server.snippet.env || {}) },
    cwd
  });

  try {
    await child.connect(transport);
    const tools = await child.listTools();
    const toolMap = {};
    for (const t of tools.tools || []) {
      toolMap[`${key}__${t.name}`] = {
        tool: t.name,
        client: child,
        description: t.description || `Proxied tool ${t.name}`,
        inputSchema: t.inputSchema || { type: 'object', properties: {} }
      };
    }
    active.set(key, { client: child, transport, tools: toolMap, server });
    registry.servers[key].enabled = true;
    registry.servers[key].health = 'healthy';
    setHealth(registry, key, 'healthy');
    supervisor.watch(key, child, () => restart(registry, key, sendNotification), {
      httpUrl: (server.snippet.healthcheck && server.snippet.healthcheck.url) || null,
      intervalMs: (server.snippet.healthcheck && server.snippet.healthcheck.interval_ms) || undefined
    });
    if (sendNotification) sendNotification({ method: 'notifications/tools/list_changed' });
    return { status: 'active', tools: Object.keys(toolMap), count: Object.keys(toolMap).length };
  } catch (err) {
    registry.servers[key].health = 'unhealthy';
    setHealth(registry, key, 'unhealthy');
    throw new Error(`Failed to start ${key}: ${err.message}`);
  }
}

async function disable(registry, key, sendNotification) {
  const entry = active.get(key);
  if (!entry) return { status: 'not active' };
  supervisor.unwatch(key);
  try { await entry.client.close(); } catch {}
  active.delete(key);
  registry.servers[key].enabled = false;
  registry.servers[key].health = 'idle';
  setHealth(registry, key, 'idle');
  if (sendNotification) sendNotification({ method: 'notifications/tools/list_changed' });
  return { status: 'disabled', key };
}

async function restart(registry, key, sendNotification) {
  const entry = active.get(key);
  if (entry) {
    supervisor.unwatch(key);
    try { await entry.client.close(); } catch {}
    active.delete(key);
  }
  return await enable(registry, key, sendNotification);
}

function getSupervisorStatus() {
  return supervisor.getStatus();
}

function listActive() {
  const result = [];
  for (const [key, entry] of active.entries()) {
    result.push({ key, tools: Object.keys(entry.tools), health: entry.server.health || 'healthy' });
  }
  return result;
}

function getActiveToolNames() {
  const names = [];
  for (const [key, entry] of active.entries()) {
    for (const full of Object.keys(entry.tools)) names.push(full);
  }
  return names;
}

function getActiveToolsMeta() {
  const meta = [];
  for (const [key, entry] of active.entries()) {
    for (const [full, t] of Object.entries(entry.tools)) {
      meta.push({
        name: full,
        description: t.description,
        inputSchema: t.inputSchema
      });
    }
  }
  return meta;
}

async function callTool(fullName, args) {
  for (const [key, entry] of active.entries()) {
    const tool = entry.tools[fullName];
    if (tool) {
      return await tool.client.callTool({ name: tool.tool, arguments: args });
    }
  }
  throw new Error(`Tool ${fullName} is not active. Enable its parent MCP first.`);
}

module.exports = { setRegistry, enable, disable, restart, listActive, getActiveToolNames, getActiveToolsMeta, getSupervisorStatus, callTool };
