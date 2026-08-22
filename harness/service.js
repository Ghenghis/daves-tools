const path = require('path');

let Service;
try {
  Service = require('node-windows').Service;
} catch {
  console.error('node-windows is not installed. Run: npm install --prefix harness node-windows');
  process.exit(1);
}

const svc = new Service({
  name: 'DavesTools MCP Watchdog',
  description: 'Heartbeat, health, and auto-repair supervisor for daves-tools MCP servers.',
  script: path.join(__dirname, 'watchdog.js'),
  nodeOptions: [],
  env: [{ name: 'WATCHDOG_INTERVAL_MS', value: process.env.WATCHDOG_INTERVAL_MS || '60000' }],
  wait: 2,
  grow: 0.5,
  maxRestarts: 10
});

const mode = process.argv[2] || 'install';

svc.on('install', () => {
  console.log('Service installed. Starting...');
  svc.start();
});
svc.on('start', () => console.log('Service started.'));
svc.on('uninstall', () => console.log('Service uninstalled.'));
svc.on('alreadyinstalled', () => console.log('Service already installed.'));
svc.on('invalidinstallation', () => console.log('Invalid installation detected.'));
svc.on('error', (err) => console.error('Service error:', err));

if (mode === 'install') svc.install();
else if (mode === 'uninstall') svc.uninstall();
else if (mode === 'start') svc.start();
else if (mode === 'stop') svc.stop();
else if (mode === 'restart') svc.restart();
else {
  console.error('usage: node service.js [install|uninstall|start|stop|restart]');
  process.exit(1);
}
