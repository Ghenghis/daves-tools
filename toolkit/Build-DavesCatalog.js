const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');

const typed = JSON.parse(fs.readFileSync(path.join(root, 'configs/typed-registry.json'), 'utf8'));
const certDir = path.join(root, 'docs');
const certFiles = fs.readdirSync(certDir).filter(f => f.startsWith('cert-') && f.endsWith('.json'));
const certs = {};
certFiles.forEach(f => {
  const c = JSON.parse(fs.readFileSync(path.join(certDir, f), 'utf8'));
  certs[c.id] = c;
});

const statusBadge = (v) => {
  if (v === 'passed') return '✅ passed';
  if (v === 'failed') return '❌ failed';
  if (v === 'not_applicable') return '➖ n/a';
  return '⚪ unknown';
};

const clean = (s) => String(s || '').replace(/\n/g, ' ').replace(/\r/g, ' ');

const lines = [];
lines.push('# MCP Catalog');
lines.push('');
lines.push('Generated from `configs/typed-registry.json` and the certification files in `docs/cert-*.json`.');
lines.push('');
lines.push('**Asset totals:** ' + typed.total + ' — ' + typed.mcp_server_count + ' MCP servers, ' + typed.skill_pack_count + ' skill packs, ' + typed.dependency_count + ' runtime dependencies.');
lines.push('');

const byType = {};
typed.assets.forEach(a => {
  byType[a.asset_type] = byType[a.asset_type] || [];
  byType[a.asset_type].push(a);
});

Object.keys(byType).sort().forEach(type => {
  const assets = byType[type].sort((a, b) => a.id.localeCompare(b.id));
  lines.push('## ' + type.replace(/_/g, ' ').toUpperCase() + ' (' + assets.length + ')');
  lines.push('');

  assets.forEach(a => {
    const c = certs[a.id];
    const v = c ? c.verdict : (a.verification ? a.verification.protocol : 'unknown');

    lines.push('### ' + a.display_name + ' (`' + a.id + '`)');
    lines.push('');
    lines.push('- **ID:** `' + a.id + '`');
    lines.push('- **Type:** ' + a.asset_type);
    lines.push('- **Profiles:** ' + (a.profiles || []).join(', '));
    lines.push('- **Capabilities:** ' + (a.capabilities || []).join(', '));

    if (a.source && a.source.url) {
      lines.push('- **Source:** ' + a.source.url);
    }

    if (a.runtime) {
      lines.push('- **Transport:** ' + (a.runtime.transport || 'none'));
      lines.push('- **Command:** `' + (a.runtime.command || '') + '`');
      lines.push('- **Args:** `' + clean((a.runtime.args || []).join(' ')) + '`');
      if (a.runtime.cwd) lines.push('- **Working directory:** ' + a.runtime.cwd);
      if (a.runtime.timeout_ms) lines.push('- **Timeout:** ' + a.runtime.timeout_ms + ' ms');
    }

    if (a.permissions) {
      lines.push('- **Mutation level:** ' + (a.permissions.mutation_level || 'unknown'));
      lines.push('- **Approval policy:** ' + (a.permissions.approval_policy || 'unknown'));
      if ((a.permissions.filesystem_roots || []).length) {
        lines.push('- **Filesystem roots:** ' + a.permissions.filesystem_roots.join(', '));
      }
      if ((a.permissions.network_hosts || []).length) {
        lines.push('- **Network hosts:** ' + a.permissions.network_hosts.join(', '));
      }
    }

    if (a.metadata && a.metadata.isolation) {
      lines.push('- **Container isolation:** ' + a.metadata.isolation);
    }

    if (a.verification && a.verification.last_verified) {
      lines.push('- **Last verified:** ' + a.verification.last_verified);
    }

    lines.push('- **Certification verdict:** ' + statusBadge(v));

    if (c && c.error) {
      lines.push('- **Certification error:** ' + clean(c.error));
    } else if (a.verification && a.verification.error) {
      lines.push('- **Verification error:** ' + clean(a.verification.error));
    }

    if (c && c.tools && c.tools.length) {
      lines.push('- **Tools exposed:** ' + c.tools.length);
      lines.push('');
      c.tools.forEach(t => {
        const desc = clean((t.description || '')).split('. ')[0] || 'No description';
        lines.push('  - `' + t.name + '` — ' + desc);
      });
    }

    lines.push('');
  });
});

fs.writeFileSync(path.join(root, 'docs/MCP-CATALOG.md'), lines.join('\n'), 'utf8');
console.log('Wrote docs/MCP-CATALOG.md with ' + typed.assets.length + ' assets.');