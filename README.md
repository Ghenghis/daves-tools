# DAVE-AI Tools

A typed, certifiable, Windows-first harness for Model Context Protocol (MCP) servers, skill packs, and the dependencies that power local-first AI workflows.

This repository is the control plane for the DAVE-AI ecosystem: a single source of truth for what tools are installed, how they are launched, what they are allowed to touch, and whether they are actually healthy.

- 62 catalogued assets (12 MCP servers, 10 skill packs, 20 CLI dependencies, 11 GUI dependencies, 3 marketplaces, 3 tool packs, 1 benchmark, 1 agent runtime, 1 service)
- One typed registry (`configs/typed-registry.json`) drives every launcher, certifier, and installer
- Every asset is tagged with profiles, permissions, health rules, and a mutation approval policy
- High-risk tools can be sandboxed in containers via `harness/container.js`
- Local LLM support through LM Studio and Ollama, with ComfyUI for diffusion workflows

## What this gives you

- Stop copy-pasting JSON snippets into Claude Desktop, Cline, or Windsurf. The registry exports validated launch snippets.
- Know before an agent calls a tool whether the tool is installed, reachable, and domain-tested.
- Keep secrets off disk in plaintext with DPAPI-backed credential resolution.
- Run untrusted or network-facing MCPs inside Docker without rewriting their launch commands.
- Recover automatically when LM Studio crashes or becomes unreachable via `toolkit/Watch-LmStudio.ps1`.

## What this is NOT

- It is not a new model hub. It does not download or host LLM weights. We point you to `docs/RECOMMENDED-MODELS.md` for the best local GGUF models.
- It is not a replacement for official MCP servers. It is a manager, certifier, and integration layer.
- It is not finished. Certification coverage is still growing; see `docs/certification-summary.json` for the current pass/fail state.

## Quick start

1. Install prerequisites: Node.js LTS, Python 3.x with `pip`, Git, and optionally Docker Desktop.
2. Clone the repository and install the harness:
   ```
   npm install
   ```
3. (Optional) set up Windows service monitoring:
   ```powershell
   .\toolkit\Install-McpService.ps1
   ```
4. Certify the currently configured assets:
   ```
   node harness/certifier.js
   ```
5. Start the orchestration harness:
   ```
   node harness/proxy.js
   ```
6. Open `docs/SETUP.md` for IDE-specific wiring (Claude Desktop, Cline, Windsurf, Roo Code).

## Repository layout

| Path | Purpose |
|------|---------|
| `configs/typed-registry.json` | Single source of truth for all 62 assets |
| `harness/` | Certifier, proxy, container resolver, health checks, watchdog, supervisor |
| `harness/daemon/` | Windows service wrapper (`davestoolsmcpwatchdog.exe`) |
| `docs/` | Certification reports, setup guides, security model, catalog |
| `toolkit/` | PowerShell and Node scripts for install, sync, and watchdogs |

## Architecture

```
IDE / Agent
    |
    v
harness/proxy.js  (MCP lifecycle, task-aware switching)
    |
    +-- harness/certifier.js   (pre-flight certification)
    +-- harness/container.js   (Docker fallback for high-risk MCPs)
    +-- harness/health.js      (heartbeat + recovery)
    +-- harness/watchdog.js    (global harness watchdog)
    |
    v
Stdio / SSE MCP servers, local skill packs, and ComfyUI/LM Studio endpoints
```

The harness routes each tool call through a typed, permission-scoped channel. Profiles such as `CORE`, `CODE`, `MEDIA`, `SECURITY`, and `REVERSE` decide which assets are active for a given task. When an asset is marked `isolation: container` in the registry, `harness/container.js` transparently wraps the launch in Docker.

## Registry design

`configs/typed-registry.json` describes every asset with the following fields:

- `id`, `display_name`, `asset_type`
- `source` URL, ref, commit, license, and sha256
- `profiles` the asset belongs to
- `capabilities` it exposes
- `runtime` command, args, cwd, env, timeout, and transport
- `permissions` filesystem roots, network hosts, credential refs, mutation level, approval policy
- `verification` install, protocol, domain smoke, last verified timestamp, and evidence id
- optional `metadata.isolation` for containerized execution

No MCP server is loaded unless it is represented in this file and has passed at least the protocol certification for its profile.

## Certification status

The latest run in `docs/certification-summary.json` shows results for every `mcp_server` asset in the registry. Numbers vary as the registry and supervisor evolve; for the current pass/fail split see `docs/CERTIFICATION-SUMMARY.md`. The supervisor's heartbeat log (`docs/harness-events.ndjson`) is the live source of truth for "is this MCP actually running right now."

`docs/MCP-CATALOG.md` lists every asset, its certification verdict, and the tool surface exposed when it passes. `docs/CERTIFICATION-LESSONS.md` explains the most common failure modes and how to fix them.

## Security model

- Secrets are referenced by name in the registry, resolved at runtime, and stored with DPAPI on Windows.
- No credentials are committed to Git. The `.gitignore` already excludes `configs/secrets.json`, `.env`, and `*.key`.
- Filesystem access is scoped to `permissions.filesystem_roots`.
- Network access is scoped to `permissions.network_hosts`.
- Any tool that can write, delete, or execute code requires explicit approval unless `mutation_level` is `read_only`.
- High-risk or binary-manipulation tools (`apktool-mcp`, reverse-engineering MCPs) default to container isolation.

See `docs/SECURITY.md` for the full policy and secret setup.

## Local LLMs and ComfyUI

- `docs/RECOMMENDED-MODELS.md` has the current list of best 7B–14B GGUF models for LM Studio on a 16 GB VRAM GPU.
- LM Studio is exposed at `http://localhost:1234`. The registry can route LLM calls to this endpoint instead of cloud providers.
- `toolkit/Watch-LmStudio.ps1` keeps LM Studio alive: heartbeat on the `/v1/models` endpoint, auto-restart on unreachable, and LM Link reconnect.
- ComfyUI runs locally on `http://localhost:8188`. The `comfyui-mcp` asset exposes lifecycle, workflow, and model tools.

## Tooling scripts

| Script | Purpose |
|--------|---------|
| `toolkit/Build-DavesCatalog.js` | Regenerate `docs/MCP-CATALOG.md` from the registry and cert files |
| `toolkit/Sync-McpRegistry.js` | Sync runtime cwd and container metadata into the registry |
| `toolkit/Install-McpService.ps1` | Install the harness as a Windows service or emit a systemd unit |
| `toolkit/Watch-LmStudio.ps1` | Heartbeat and auto-restart for LM Studio |
| `harness/certifier.js` | Certify every asset in the registry |

## Development

```
npm install
npm run certify
npm test
```

Use `node harness/certifier.js --profile CORE` to certify only the core profile, or `--id <asset>` to certify one asset at a time.

## Roadmap and known gaps

- Expand certification from 16 to all 43 assets.
- Finish unit and integration test coverage under `tests/`.
- Add health dashboards and metrics export.
- Stabilize the LM Studio and ComfyUI watchdogs across restarts.

## License and contribution

This project is private. See the repository owner for contribution guidelines. The registry may reference third-party MCP servers and skill packs under their own licenses; those licenses are recorded in `configs/typed-registry.json`.

## MiniMax four-client release harness

`toolkit/Test-MiniMaxClientIntegrations.ps1` verifies the local Claude, Codex,
Kilo, and Devin MiniMax configuration. It checks gateway services and listeners,
model catalogs, file-backed credentials, bounded MCP surfaces, targeted MCP
handshakes, and recognized plaintext credential patterns.

Cost-free structural run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File toolkit\Test-MiniMaxClientIntegrations.ps1
```

Authenticated text contracts:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File toolkit\Test-MiniMaxClientIntegrations.ps1 -Live
```

Safe repair preview:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File toolkit\Test-MiniMaxClientIntegrations.ps1 -Fix -WhatIf
```

The harness never kills an unexpected port owner. Reports are appended as JSON
Lines under `logs/client-integrations.jsonl`, which is excluded from Git. Pester
coverage lives beside the script and is enforced by `.github/workflows/quality.yml`:

```powershell
Import-Module Pester -RequiredVersion 6.1.0
Invoke-Pester toolkit\Test-MiniMaxClientIntegrations.Tests.ps1 -Output Detailed
```

The unrestricted `mini connect` aggregate is intentionally not a release
profile: it exposed 387 tools during verification. Desktop clients use direct,
targeted MiniMax MCP launchers instead.
