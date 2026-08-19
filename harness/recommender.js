const TAG_MAP = {
  'reverse engineering': ['x64dbg', 'dnspyex', 'assetripper', 'cpp2il', 'r2unity', 'hyper-v-mcp'],
  'debug': ['x64dbg', 'dnspyex'],
  'windows': ['win-dev-skills', 'winapp-cli', 'hyper-v-mcp', 'x64dbg'],
  'mobile': ['playwright-mcp---skills'], // will need actual
  'web': ['playwright-cli---skills'],
  'test': ['playwright-cli---skills'],
  'unity': ['assetripper', 'r2unity', 'cpp2il'],
  'ci': ['gitlab-mcp', 'github'],
  'git': ['gitlab-mcp', 'github'],
  'devops': ['gitlab-mcp'],
  'voice': ['edge-tts', 'voice'],
  'memory': ['memory']
};

function recommend(registry, task) {
  const lower = (task || '').toLowerCase();
  const keys = new Set();
  for (const [term, ids] of Object.entries(TAG_MAP)) {
    if (lower.includes(term)) ids.forEach(id => keys.add(id));
  }
  const servers = registry.servers || {};
  for (const [key, s] of Object.entries(servers)) {
    if (s.tags) {
      for (const t of s.tags) {
        if (lower.includes(t.toLowerCase())) keys.add(key);
      }
    }
  }
  return Array.from(keys)
    .map(k => servers[k])
    .filter(Boolean)
    .map(s => ({ key: s.key, name: s.name, tier: s.tier, profile: s.profile }));
}

module.exports = { recommend };
