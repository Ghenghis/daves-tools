const fs = require('fs');
const path = require('path');

const EVENTS_PATH = path.join(__dirname, '..', 'docs', 'harness-events.ndjson');

function recordEvent(type, payload = {}) {
  const line = JSON.stringify({
    timestamp: new Date().toISOString(),
    type,
    ...payload
  });
  try {
    fs.appendFileSync(EVENTS_PATH, line + '\n');
  } catch (err) {
    console.error('Failed to record event:', err.message);
  }
}

module.exports = { recordEvent };
