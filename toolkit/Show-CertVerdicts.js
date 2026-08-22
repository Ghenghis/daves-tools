const fs = require('fs');
const ids = process.argv.slice(2);
for (const id of ids) {
    try {
        const raw = fs.readFileSync(`docs/cert-${id}.json`, 'utf8');
        const start = raw.indexOf('{');
        const r = JSON.parse(raw.slice(start));
        console.log(`${id}: verdict=${r.verdict} init=${r.init} list_tools=${r.list_tools} tools=${(r.tools || []).length} error=${r.error || ''}`);
    } catch (e) {
        console.log(`${id}: parse-fail ${e.message}`);
    }
}
