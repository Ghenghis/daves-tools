# daves-tools

A DAVE-AI companion repo. Curated missing tools, scripts, skills, and docs that complete the DAVE-AI Agent Harness for 2026.

## What this is

The main harness repo (`claude-codex-devin`) already wires the CORE stdio servers: `minimax-media`, `hermes3d-locks`, and `serena-semantic`. This repo fills the rest of the DAVE-AI ecosystem with the most useful missing pieces.

## Folders

- `mcp-manager/` — curated MCP server marketplace and installer
- `toolkit/` — PowerShell helpers to sync catalogs, load profiles, and run preflight checks
- `skills/` — missing DAVE-AI skills referenced by `profiles\CORE.yaml`
- `docs/` — shortlists and integration notes

## Top missing items included

1. **MCP Marketplace** — the canonical 7 MCP sources every DAVE-AI agent should know.
2. **MCP Installer** — PowerShell script to clone/install a marketplace server and validate it.
3. **Catalog Sync** — PowerShell script that reads `repo_catalog.json` from the DAVE-AI harness and lists what is missing.
4. **Missing Skills** — `superpowers`, `github-or-gitlab-connector`, `trailofbits-curated`.
5. **Integration Docs** — which items to enable, when, and why.

## Quick start

```powershell
# Sync the DAVE-AI catalog and list missing items
.\toolkit\Sync-RepoCatalog.ps1

# Install an MCP server from the marketplace
.\mcp-manager\Install-McpServer.ps1 -Name browserbase
```

## Relationship to DAVE-AI

This is not a replacement for the harness. It is the missing gap-fill: skills, connectors, and helper scripts that make the harness complete.
