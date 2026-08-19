const fs = require('fs');
const path = require('path');

const REGISTRY_PATH = process.env.MCP_REGISTRY || path.join(__dirname, '..', 'configs', 'mcp-registry.json');

function load() {
  if (!fs.existsSync(REGISTRY_PATH)) return { version: '1.0.0', total: 0, servers: {} };
  const raw = fs.readFileSync(REGISTRY_PATH, 'utf8');
  return JSON.parse(raw.replace(/^\uFEFF/, ''));
}

function save(registry) {
  fs.writeFileSync(REGISTRY_PATH, JSON.stringify(registry, null, 2));
}

function toggle(registry, key, enabled) {
  if (registry.servers && registry.servers[key]) {
    registry.servers[key].enabled = enabled;
  }
  save(registry);
}

function setHealth(registry, key, health) {
  if (registry.servers && registry.servers[key]) {
    registry.servers[key].health = health;
  }
  save(registry);
}

module.exports = { load, save, toggle, setHealth, REGISTRY_PATH };
