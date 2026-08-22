const { execSync } = require('child_process');

function dockerAvailable() {
  try {
    execSync('docker info', { stdio: 'ignore', timeout: 5000 });
    return true;
  } catch {
    return false;
  }
}

function buildContainerCommand(asset) {
  if ((asset.metadata && asset.metadata.isolation) !== 'container') {
    return null;
  }
  if (!dockerAvailable()) {
    return { fallback: true, command: asset.runtime.command, args: asset.runtime.args, cwd: asset.runtime.cwd };
  }

  const pinned = (asset.metadata && asset.metadata.pinned_version) || 'latest';
  const pkgName = (asset.runtime.args || []).find(a => a && !a.startsWith('-') && a.includes('@')) ||
                  (asset.runtime.args || []).find(a => a && !a.startsWith('-'));
  const image = 'node:22-slim';

  if (asset.runtime.command === 'npx' && pkgName) {
    const args = [
      'run', '--rm', '-i', '--network', 'none',
      '-v', 'mcp-cache:/root/.npm:delegated',
      '-e', 'CI=1',
      image,
      'npx', '-y', pkgName
    ];
    return { command: 'docker', args, cwd: undefined, image };
  }

  if (asset.runtime.command === 'uv' || asset.runtime.command === 'python') {
    return { fallback: true, command: asset.runtime.command, args: asset.runtime.args, cwd: asset.runtime.cwd };
  }

  return null;
}

module.exports = { buildContainerCommand, dockerAvailable };
