const { Client } = require('@modelcontextprotocol/sdk/client/index.js');
const { StdioClientTransport } = require('@modelcontextprotocol/sdk/client/stdio.js');
const path = require('path');

async function run() {
  const client = new Client({ name: 'harness-tester', version: '1.0.0' });
  const transport = new StdioClientTransport({
    command: 'node',
    args: [path.join(__dirname, 'index.js')],
    env: { ...process.env, MCP_REGISTRY: path.join(__dirname, '..', 'configs', 'mcp-registry.json') }
  });

  await client.connect(transport);

  const tools = await client.listTools();
  console.log('Orchestrator tools:', tools.tools.map(t => t.name).filter(n => !n.includes('__')));

  const list = await client.callTool({ name: 'list_available_mcps', arguments: {} });
  console.log('list_available_mcps:', list.content[0].text.slice(0, 200));

  const rec = await client.callTool({ name: 'discover_mcps_for_task', arguments: { task: 'reverse engineering a Windows binary' } });
  console.log('discover_mcps_for_task:', rec.content[0].text);

  await client.close();
}

run().catch(e => {
  console.error(e);
  process.exit(1);
});
