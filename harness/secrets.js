function resolveEnvRefs(asset) {
  const refs = (asset && asset.runtime && asset.runtime.env_refs) || [];
  const env = {};
  for (const ref of refs) {
    const value = process.env[ref];
    if (value !== undefined) {
      env[ref] = value;
    }
  }
  return env;
}

function redactSecrets(text) {
  if (typeof text !== 'string') return text;
  let t = text;
  for (const [k, v] of Object.entries(process.env)) {
    if (/TOKEN|KEY|SECRET|PW|PASS|CRED/.test(k) && v && v.length > 4) {
      const re = new RegExp(v.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g');
      t = t.replace(re, '***');
    }
  }
  return t;
}

module.exports = { resolveEnvRefs, redactSecrets };
