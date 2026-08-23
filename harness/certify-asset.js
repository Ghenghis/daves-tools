const fs = require('fs');
const path = require('path');
const os = require('os');
const { certify } = require('./certifier.js');

const id = process.argv[2];
const regPath = process.argv[3] || 'configs/typed-registry.json';

function atomicWriteJson(filePath, obj) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  const tmp = path.join(os.tmpdir(), `${path.basename(filePath)}.${process.pid}.${Date.now()}.tmp`);
  fs.writeFileSync(tmp, JSON.stringify(obj, null, 2));
  fs.renameSync(tmp, filePath);
}

const raw = fs.readFileSync(regPath, 'utf8').replace(/^\uFEFF/, '');
const reg = JSON.parse(raw);
const asset = reg.assets.find(a => a.id === id);

if (!asset) {
  console.error('Asset not found: ' + id);
  process.exit(2);
}

certify(asset).then(result => {
  const out = `audit/cert-${id}.json`;
  atomicWriteJson(out, result);

  asset.verification.protocol = (result.init === 'passed' && result.list_tools === 'passed') ? 'passed' : 'failed';
  asset.verification.domain_smoke = result.safe_call;
  asset.verification.last_verified = new Date().toISOString();
  asset.verification.evidence_id = `cert-${id}`;
  atomicWriteJson(regPath, reg);

  console.log(JSON.stringify(result));
}).catch(err => {
  console.error(err.message);
  process.exit(1);
});
