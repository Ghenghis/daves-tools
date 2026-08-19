const fs = require('fs');
const path = require('path');

let typedRegistry = null;
const typedRegistryPath = path.join(__dirname, '..', 'configs', 'typed-registry.json');
try {
  const raw = fs.readFileSync(typedRegistryPath, 'utf8').replace(/^\uFEFF/, '');
  typedRegistry = JSON.parse(raw);
} catch (err) {
  // fallback to legacy shape
  typedRegistry = null;
}

const TAG_MAP = {
  'reverse engineering': ['x64dbg', 'dnspyex', 'assetripper', 'cpp2il', 'r2unity', 'hyper-v-mcp'],
  'debug': ['x64dbg', 'dnspyex'],
  'windows': ['win-dev-skills', 'winapp-cli', 'hyper-v-mcp', 'x64dbg'],
  'mobile': ['android-mcp', 'appium-mcp', 'mobile-harness'],
  'web': ['playwright-cli-skills', 'playwright-mcp'],
  'test': ['playwright-cli-skills', 'playwright-mcp'],
  'unity': ['assetripper', 'r2unity', 'cpp2il'],
  'ci': ['gitlab-mcp', 'github-mcp'],
  'git': ['gitlab-mcp', 'github-mcp'],
  'devops': ['gitlab-mcp'],
  'voice': ['edge-tts', 'voice'],
  'memory': ['memory']
};

function recommend(registry, task) {
  const lower = (task || '').toLowerCase().trim();
  if (!lower) return [];
  const keys = new Set();

  for (const [term, ids] of Object.entries(TAG_MAP)) {
    if (lower.includes(term)) ids.forEach(id => keys.add(id));
  }

  const assets = (typedRegistry && typedRegistry.assets) || (registry && registry.assets) || [];
  const legacyServers = (registry && registry.servers) || {};

  for (const asset of assets) {
    const id = (asset.id || '').toLowerCase();
    const name = (asset.display_name || '').toLowerCase();
    if (!id) continue;

    if (lower.includes(id) || lower.includes(name)) {
      keys.add(id);
      continue;
    }

    const terms = [
      ...(asset.profiles || []),
      ...(asset.capabilities || []),
      ...(asset.asset_type ? [asset.asset_type] : [])
    ].map(t => (t || '').toString().toLowerCase().trim()).filter(Boolean);

    for (const t of terms) {
      if (lower.includes(t) || t.includes(lower)) {
        keys.add(id);
        break;
      }
    }
  }

  for (const [key, s] of Object.entries(legacyServers)) {
    if (s.tags) {
      for (const t of s.tags) {
        const tag = (t || '').toString().toLowerCase().trim();
        if (tag && lower.includes(tag)) keys.add(key);
      }
    }
    if (s.name && lower.includes(s.name.toLowerCase())) keys.add(key);
  }

  return Array.from(keys)
    .map(k => {
      const asset = assets.find(a => a.id === k);
      const legacy = legacyServers[k];
      if (asset) {
        return {
          key: asset.id,
          name: asset.display_name,
          asset_type: asset.asset_type,
          profiles: asset.profiles,
          capabilities: asset.capabilities
        };
      }
      if (legacy) {
        return { key: k, name: legacy.name, tier: legacy.tier, profile: legacy.profile };
      }
      return null;
    })
    .filter(Boolean);
}

module.exports = { recommend };
