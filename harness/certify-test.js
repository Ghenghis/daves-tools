const { certify } = require('./certifier.js');

const testAsset = {
  id: 'local-test',
  display_name: 'Local Test MCP',
  asset_type: 'mcp_server',
  runtime: {
    transport: 'stdio',
    command: 'node',
    args: ['harness/test-server.js'],
    env_refs: [],
    timeout_ms: 10000
  },
  permissions: {
    mutation_level: 'read_only',
    filesystem_roots: []
  },
  verification: {}
};

certify(testAsset).then(result => {
  const { recordEvent } = require('./events.js');
  const out = 'docs/local-test-certification.json';
  require('fs').writeFileSync(out, JSON.stringify(result, null, 2));
  recordEvent('certification.test', { asset: 'local-test', verdict: result.verdict, evidence: out });
  console.log(JSON.stringify(result, null, 2));
}).catch(err => {
  console.error(err.message);
  process.exit(1);
});
