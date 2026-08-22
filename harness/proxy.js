const { Client } = require('@modelcontextprotocol/sdk/client/index.js');
const { StdioClientTransport } = require('@modelcontextprotocol/sdk/client/stdio.js');
const { setHealth } = require('./registry.js');

const active = new Map();
let registryRef = { servers: {} };

function setRegistry(registry) {
  registryRef = registry;
}

async function enable(registry, key, sendNotification) {
  const server = registry.servers[key];
  if (!server) throw new Error(`Unknown MCP: ${key}`);
  if (active.has(key)) return { status: 'already active', tools: Object.keys(active.get(key).tools) };

  const child = new Client({ name: `harness-child-${key}`, version: '1.0.0' });
  const transport = new StdioClientTransport({
    command: server.snippet.command,
    args: server.snippet.args || [],
    env: { ...process.env, ...(server.snippet.env || {}) }
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
  try { await entry.client.close(); } catch {}
  active.delete(key);
  registry.servers[key].enabled = false;
  registry.servers[key].health = 'idle';
  setHealth(registry, key, 'idle');
  if (sendNotification) sendNotification({ method: 'notifications/tools/list_changed' });
  return { status: 'disabled', key };
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

module.exports = { setRegistry, enable, disable, listActive, getActiveToolNames, getActiveToolsMeta, callTool };
