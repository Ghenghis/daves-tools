const path = require('path');

function isUnderRoot(filePath, roots) {
  if (!roots || roots.length === 0) return false;
  const abs = path.resolve(filePath);
  return roots.some(r => abs.toLowerCase().startsWith(path.resolve(r).toLowerCase()));
}

function isReadOnlyTool(toolName, args) {
  if (!args || typeof args !== 'object') return true;
  const keys = Object.keys(args);
  return !keys.some(k => /write|create|delete|remove|update|modify|patch|exec|run|install|uninstall/i.test(String(args[k])));
}

function hasWriteArgs(args) {
  if (!args || typeof args !== 'object') return false;
  for (const [k, v] of Object.entries(args)) {
    if (/write|create|delete|remove|update|modify|patch|exec|run|install|uninstall/i.test(k)) return true;
    if (typeof v === 'string' && /^(save|write|create|delete|remove|update|modify|patch|exec|run)/i.test(v)) return true;
  }
  return false;
}

function canCall(asset, toolName, args, workspaceRoot) {
  const perms = asset.permissions || {};
  const mutation = perms.mutation_level || 'read_only';

  if (mutation === 'disabled') {
    return { allowed: false, reason: 'Tool is disabled by policy.' };
  }

  if (mutation === 'read_only') {
    if (hasWriteArgs(args)) {
      return { allowed: false, reason: 'Read-only asset does not allow mutating calls.' };
    }
  }

  if (workspaceRoot && !perms.filesystem_roots) {
    const roots = [workspaceRoot];
    if (args && args.path) {
      if (!isUnderRoot(args.path, roots)) {
        return { allowed: false, reason: `Path ${args.path} is outside workspace root.` };
      }
    }
    if (args && args.file) {
      if (!isUnderRoot(args.file, roots)) {
        return { allowed: false, reason: `File ${args.file} is outside workspace root.` };
      }
    }
  }

  const roots = perms.filesystem_roots && perms.filesystem_roots.length > 0
    ? perms.filesystem_roots
    : workspaceRoot ? [workspaceRoot] : [];

  for (const [k, v] of Object.entries(args || {})) {
    if (typeof v === 'string' && (k === 'path' || k === 'file' || k === 'directory' || k === 'cwd' || k === 'root')) {
      if (roots.length > 0 && !isUnderRoot(v, roots)) {
        return { allowed: false, reason: `Path ${v} is outside allowed roots: ${roots.join(', ')}` };
      }
    }
  }

  if (perms.approval_policy === 'always') {
    return { allowed: false, reason: 'Approval required for all calls.' };
  }

  if (perms.approval_policy === 'on_mutation' && hasWriteArgs(args)) {
    return { allowed: false, reason: 'Approval required for mutating call.' };
  }

  return { allowed: true };
}

module.exports = { canCall, hasWriteArgs, isUnderRoot };
