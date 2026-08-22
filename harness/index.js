const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const { CallToolRequestSchema, ListToolsRequestSchema } = require('@modelcontextprotocol/sdk/types.js');
const { load, save, toggle } = require('./registry.js');
const { setRegistry, enable, disable, restart, listActive, getActiveToolNames, getActiveToolsMeta, getSupervisorStatus, callTool } = require('./proxy.js');
const supervisor = require('./supervisor.js');
const { recommend } = require('./recommender.js');
const { canCall } = require('./policy.js');
const { redactSecrets } = require('./secrets.js');
const { recordEvent } = require('./events.js');

const registry = load();
setRegistry(registry);

const server = new Server(
  { name: 'daves-tools-harness', version: '1.0.0' },
  { capabilities: { tools: {}, prompts: {}, resources: {} } }
);

function sendNotification(n) {
  try { server.notification(n); } catch {}
}

const orchestratorTools = [
  { name: 'list_available_mcps', description: 'List all installed MCP servers and their current enabled/health state.', inputSchema: { type: 'object', properties: { tier: { type: 'string' } }, required: [] } },
  { name: 'enable_mcp', description: 'Start an MCP server by key and make its tools available.', inputSchema: { type: 'object', properties: { key: { type: 'string' } }, required: ['key'] } },
  { name: 'disable_mcp', description: 'Stop an MCP server by key and remove its tools.', inputSchema: { type: 'object', properties: { key: { type: 'string' } }, required: ['key'] } },
  { name: 'list_active_mcps', description: 'Show currently active MCP servers and their proxied tools.', inputSchema: { type: 'object', properties: {}, required: [] } },
  { name: 'discover_mcps_for_task', description: 'Recommend MCP servers to enable for a given task.', inputSchema: { type: 'object', properties: { task: { type: 'string' } }, required: ['task'] } },
  { name: 'call_mcp_tool', description: 'Call a namespaced child MCP tool (e.g. x64dbg__step).', inputSchema: { type: 'object', properties: { tool: { type: 'string' }, arguments: { type: 'object' } }, required: ['tool'] } },
  { name: 'mcp_supervisor_status', description: 'Show heartbeat/health/restart state for all supervised MCP servers.', inputSchema: { type: 'object', properties: {}, required: [] } },
  { name: 'restart_mcp', description: 'Force-restart an MCP server child process now.', inputSchema: { type: 'object', properties: { key: { type: 'string' } }, required: ['key'] } }
];

server.setRequestHandler(ListToolsRequestSchema, async () => {
  const active = getActiveToolsMeta();
  return { tools: [...orchestratorTools, ...active] };
});

server.setRequestHandler(CallToolRequestSchema, async (req) => {
  const name = req.params.name;
  const args = req.params.arguments || {};
  try {
    if (name === 'list_available_mcps') {
      const tier = args.tier;
      const list = Object.values(registry.servers)
        .filter(s => !tier || s.tier === tier)
        .map(s => ({ key: s.key, name: s.name, tier: s.tier, profile: s.profile, enabled: s.enabled, health: s.health || 'idle' }));
      return { content: [{ type: 'text', text: JSON.stringify(list, null, 2) }] };
    }
    if (name === 'enable_mcp') {
      const result = await enable(registry, args.key, sendNotification);
      toggle(registry, args.key, true);
      save(registry);
      recordEvent('mcp.enabled', { key: args.key, status: result.status });
      return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    }
    if (name === 'disable_mcp') {
      const result = await disable(registry, args.key, sendNotification);
      toggle(registry, args.key, false);
      save(registry);
      recordEvent('mcp.disabled', { key: args.key });
      return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    }
    if (name === 'list_active_mcps') {
      return { content: [{ type: 'text', text: JSON.stringify({ servers: listActive(), tools: getActiveToolsMeta() }, null, 2) }] };
    }
    if (name === 'mcp_supervisor_status') {
      return { content: [{ type: 'text', text: JSON.stringify(getSupervisorStatus(), null, 2) }] };
    }
    if (name === 'restart_mcp') {
      const result = await restart(registry, args.key, sendNotification);
      recordEvent('mcp.manual_restart', { key: args.key, status: result.status });
      return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    }
    if (name === 'discover_mcps_for_task') {
      return { content: [{ type: 'text', text: JSON.stringify(recommend(registry, args.task), null, 2) }] };
    }
    if (name === 'call_mcp_tool' || (name.includes('__') && !orchestratorTools.find(t => t.name === name))) {
      const toolName = name === 'call_mcp_tool' ? args.tool : name;
      const toolArgs = name === 'call_mcp_tool' ? (args.arguments || {}) : args;
      const parts = toolName.split('__');
      const key = parts[0];
      const childTool = parts.slice(1).join('__');
      const asset = (registry.servers && registry.servers[key]) || {};
      const decision = canCall(asset, childTool, toolArgs, process.cwd());
      if (!decision.allowed) {
        recordEvent('mcp.call_denied', { tool: toolName, reason: decision.reason });
        return { isError: true, content: [{ type: 'text', text: redactSecrets(decision.reason) }] };
      }
      const result = await callTool(toolName, toolArgs);
      recordEvent('mcp.call', { tool: toolName, status: 'ok' });
      return { content: [{ type: 'text', text: redactSecrets(JSON.stringify(result, null, 2)) }] };
    }
  } catch (err) {
    recordEvent('mcp.error', { tool: req.params.name, error: err.message });
    return { isError: true, content: [{ type: 'text', text: redactSecrets(`Error: ${err.message}`) }] };
  }
});

async function main() {
  supervisor.start();
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('daves-tools-harness started (supervisor active)');

  const toEnable = Object.values(registry.servers || {}).filter(s => s.enabled);
  if (toEnable.length) {
    console.error(`auto-enabling ${toEnable.length} MCP servers in background...`);
    Promise.allSettled(toEnable.map(s => enable(registry, s.key, sendNotification))).then(results => {
      const ok = results.filter(r => r.status === 'fulfilled').length;
      const failed = results.map((r, i) => ({ r, key: toEnable[i].key })).filter(x => x.r.status === 'rejected').map(x => x.key);
      console.error(`auto-enable complete: ${ok}/${toEnable.length} up`);
      if (failed.length) console.error(`auto-enable failed: ${failed.join(', ')}`);
      recordEvent('harness.auto_enable', { total: toEnable.length, ok, failed });
      try { server.notification({ method: 'notifications/tools/list_changed' }); } catch {}
    });
  }
}

main().catch(err => {
  console.error('Harness error:', err);
  process.exit(1);
});
