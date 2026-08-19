const fs = require('fs');
const { certify } = require('./certifier.js');

const id = process.argv[2];
const regPath = process.argv[3] || 'configs/typed-registry.json';

const raw = fs.readFileSync(regPath, 'utf8').replace(/^\uFEFF/, '');
const reg = JSON.parse(raw);
const asset = reg.assets.find(a => a.id === id);

if (!asset) {
  console.error('Asset not found: ' + id);
  process.exit(2);
}

certify(asset).then(result => {
  const out = `audit/cert-${id}.json`;
  fs.mkdirSync('audit', { recursive: true });
  fs.writeFileSync(out, JSON.stringify(result, null, 2));

  asset.verification.protocol = (result.init === 'passed' && result.list_tools === 'passed') ? 'passed' : 'failed';
  asset.verification.domain_smoke = result.safe_call;
  asset.verification.last_verified = new Date().toISOString();
  asset.verification.evidence_id = `cert-${id}`;
  fs.writeFileSync(regPath, JSON.stringify(reg, null, 2));

  console.log(JSON.stringify(result));
}).catch(err => {
  console.error(err.message);
  process.exit(1);
});
