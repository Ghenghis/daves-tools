const { Client } = require('@modelcontextprotocol/sdk/client/index.js');
const { StdioClientTransport } = require('@modelcontextprotocol/sdk/client/stdio.js');
const { z } = require('zod');
const { buildContainerCommand } = require('./container.js');

const DEFAULT_TIMEOUT_MS = 30000;
const CALL_TIMEOUT_MS = 15000;

async function withTimeout(promise, ms, label) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`${label} timed out after ${ms}ms`)), ms);
    promise.then(
      v => { clearTimeout(timer); resolve(v); },
      e => { clearTimeout(timer); reject(e); }
    );
  });
}

function buildEnv(asset) {
  const env = { ...process.env };
  for (const ref of asset.runtime.env_refs || []) {
    const value = process.env[ref];
    if (value !== undefined) env[ref] = value;
  }
  return env;
}

async function certify(asset, options = {}) {
  const start = Date.now();
  const result = {
    id: asset.id,
    display_name: asset.display_name,
    command: asset.runtime.command,
    args: asset.runtime.args,
    start_time: new Date().toISOString(),
    init: 'unknown',
    list_tools: 'unknown',
    schema_valid: 'unknown',
    safe_call: 'unknown',
    stop: 'unknown',
    error: null,
    duration_ms: 0,
    tools: [],
    safe_call_result: null,
    server_version: null,
    pinned_version: (asset.metadata && asset.metadata.pinned_version) || null,
    version_match: 'unknown'
  };

  if (asset.runtime.transport === 'none' || !asset.runtime.command) {
    result.init = 'not_applicable';
    result.list_tools = 'not_applicable';
    result.schema_valid = 'not_applicable';
    result.safe_call = 'not_applicable';
    result.stop = 'not_applicable';
    result.duration_ms = Date.now() - start;
    return result;
  }

  const container = buildContainerCommand(asset);
  const usingContainer = container && !container.fallback;
  const command = usingContainer ? container.command : asset.runtime.command;
  const rawArgs = usingContainer ? container.args : asset.runtime.args;
  const args = (rawArgs || []).filter(Boolean).map(a => a.replace('<PROJECT_ROOT>', process.cwd()));
  const runtimeCwd = usingContainer ? container.cwd : asset.runtime.cwd;
  const timeout = asset.runtime.timeout_ms || DEFAULT_TIMEOUT_MS;

  let client = null;
  let transport = null;
  let stderr = '';

  try {
    client = new Client({ name: `certifier-${asset.id}`, version: '1.0.0' });
    transport = new StdioClientTransport({
      command,
      args,
      env: buildEnv(asset),
      stderr: 'pipe',
      cwd: runtimeCwd || undefined
    });

    try {
      const stream = transport.stderr;
      if (stream && stream.on) {
        stream.on('data', (data) => { stderr += data.toString(); });
      }
    } catch {}

    await withTimeout(client.connect(transport), timeout, 'connect');
    result.init = 'passed';

    try {
      const info = client.getServerVersion && client.getServerVersion();
      if (info && info.version) {
        result.server_version = info.version;
        if (result.pinned_version) {
          result.version_match = info.version === result.pinned_version ? 'passed' : 'warning';
        } else {
          result.version_match = 'not_pinned';
        }
      } else {
        result.version_match = result.pinned_version ? 'unreported' : 'not_pinned';
      }
    } catch {
      result.version_match = 'unreported';
    }

    const toolsResp = await withTimeout(
      client.request({ method: 'tools/list' }, z.any()),
      timeout,
      'listTools'
    );
    result.list_tools = 'passed';
    const tools = (toolsResp && toolsResp.tools) || [];
    result.tools = tools.map(t => ({
      name: t.name,
      description: (t.description || '').slice(0, 200),
      inputSchema: t.inputSchema || { type: 'object', properties: {} }
    }));

    let schemasValid = true;
    for (const t of tools) {
      if (!t.inputSchema || typeof t.inputSchema !== 'object') {
        schemasValid = false;
      }
    }
    result.schema_valid = schemasValid ? 'passed' : 'failed';

    const safe = tools.find(t => {
      const schema = t.inputSchema || {};
      const required = Array.isArray(schema.required) ? schema.required : [];
      return required.length === 0;
    });

    if (safe) {
      try {
        const callResult = await withTimeout(
          client.callTool({ name: safe.name, arguments: {} }),
          CALL_TIMEOUT_MS,
          'safe_call'
        );
        result.safe_call = 'passed';
        result.safe_call_result = {
          tool: safe.name,
          has_content: !!(callResult && (callResult.content || callResult.result))
        };
      } catch (callErr) {
        result.safe_call = 'failed';
        result.safe_call_result = { tool: safe.name, error: callErr.message };
      }
    } else {
      result.safe_call = 'not_applicable';
    }

    await withTimeout(client.close(), 5000, 'stop');
    result.stop = 'passed';
  } catch (err) {
    if (result.init === 'unknown') result.init = 'failed';
    result.error = err.message;
  } finally {
    if (client) {
      try { await client.close(); } catch {}
    }
    if (transport) {
      try { transport.close && transport.close(); } catch {}
    }
  }

  if (stderr) result.stderr = stderr.slice(0, 2000);
  result.duration_ms = Date.now() - start;
  if (!result.error && result.init === 'passed' && result.list_tools === 'passed') {
    result.verdict = 'passed';
  } else if (result.init === 'not_applicable') {
    result.verdict = 'not_applicable';
  } else {
    result.verdict = 'failed';
  }
  return result;
}

module.exports = { certify };
