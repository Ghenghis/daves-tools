# Missing DAVE-AI Ecosystem Items

This is the working list of the most useful missing pieces for the DAVE-AI Agent Harness, as of 2026-08-19.

## 1. Skills

### Already present in harness
- `daveai-project-intake`, `daveai-capability-doctor`, `daveai-proof-ledger`, etc.

### Missing but needed
- `superpowers` — spec-first, subagent-driven implementation methodology
- `github-or-gitlab-connector` — repository connector for PRs, issues, and releases
- `trailofbits-curated` — security review and dependency advisory skill
- `daveai-tool-picker` — select the right tool for a task from the catalog
- `daveai-repo-hygiene` — batch manage 700+ AI-created repositories

## 2. MCP servers

### Core DAVE-AI stdio (already wired)
- `minimax-media`
- `hermes3d-locks`
- `serena-semantic`

### Missing marketplace / connectivity
- `github` — GitHub issues/PRs/actions
- `brave-search` — web search
- `context7` — library documentation
- `puppeteer` — headless browser automation
- `filesystem` — scoped file I/O
- `package-registry` — NPM/PyPI/crates version lookup
- `frida` — dynamic instrumentation
- `windbg` — Windows crash/dump analysis

### Recommended canonical sources
See `mcp-manager\marketplace.json` for the 7 canonical MCP server repos.

## 3. Tools / helpers

- `mcp-manager` — install and validate MCP servers from the marketplace
- `repo-catalog-sync` — compare `repo_catalog.json` against current workspace
- `preflight-safe` — fast presence check without blocking calls
- `proof-ledger` — hash-chained evidence logger

## 4. Connectors

- `.harness\connectors` registry with name, command, and purpose for each MCP
- GitHub/GitLab connection profiles
- Marketplace endpoint mappings

## 5. Documentation

- `docs\MISSING-ITEMS.md` (this file)
- `mcp-manager\README.md`
- `toolkit\README.md`
