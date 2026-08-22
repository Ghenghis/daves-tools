const fs = require('fs');
const path = require('path');

const regPath = path.join(process.cwd(), 'configs', 'typed-registry.json');
let raw = fs.readFileSync(regPath, 'utf8');

// Escape any single backslash not part of a valid JSON escape sequence.
raw = raw.replace(/([^\\]|^)\\(?![\\/"bfnrtu])/g, '$1\\\\');

// Ensure the file is valid JSON now.
try {
  JSON.parse(raw);
  fs.writeFileSync(regPath, raw);
  console.log('Fixed JSON escapes in', regPath);
} catch (e) {
  console.error('Still invalid JSON:', e.message);
  process.exit(1);
}
