const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const { CallToolRequestSchema, ListToolsRequestSchema } = require('@modelcontextprotocol/sdk/types.js');
const { load, save, toggle } = require('./registry.js');
const { setRegistry, enable, disable, listActive, getActiveToolNames, getActiveToolsMeta, callTool } = require('./proxy.js');
const { recommend } = require('./recommender.js');

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
  { name: 'call_mcp_tool', description: 'Call a namespaced child MCP tool (e.g. x64dbg__step).', inputSchema: { type: 'object', properties: { tool: { type: 'string' }, arguments: { type: 'object' } }, required: ['tool'] } }
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
      return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    }
    if (name === 'disable_mcp') {
      const result = await disable(registry, args.key, sendNotification);
      toggle(registry, args.key, false);
      save(registry);
      return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    }
    if (name === 'list_active_mcps') {
      return { content: [{ type: 'text', text: JSON.stringify({ servers: listActive(), tools: getActiveToolsMeta() }, null, 2) }] };
    }
    if (name === 'discover_mcps_for_task') {
      return { content: [{ type: 'text', text: JSON.stringify(recommend(registry, args.task), null, 2) }] };
    }
    if (name === 'call_mcp_tool') {
      const result = await callTool(args.tool, args.arguments || {});
      return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
    }
    // proxied tool
    const result = await callTool(name, args);
    return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
  } catch (err) {
    return { isError: true, content: [{ type: 'text', text: `Error: ${err.message}` }] };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('daves-tools-harness started');
}

main().catch(err => {
  console.error('Harness error:', err);
  process.exit(1);
});
