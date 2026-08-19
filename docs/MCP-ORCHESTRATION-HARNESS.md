# Agentic MCP Orchestration Harness

## Problem
DAVE-AI has 49+ MCP servers installed and the catalog will keep growing. Claude Desktop, Claude Code, and other clients all load MCP servers statically from `claude_desktop_config.json` and there is no built-in way to toggle servers on/off at runtime. This causes:
- Context bloat (every tool schema is injected into every prompt).
- Resource waste (every server starts at launch).
- Tool-name collisions when many servers expose `read`, `search`, `write`.
- No automatic matching between the current task and the right tools.

## Research Findings
Several open-source projects already solve pieces of this. We can compose the best ideas:

| Project | What it does | Borrow |
|---------|--------------|--------|
| `ravitemer/mcp-hub` | Hub server that starts/stops/enables/disables servers and reconnects | Use a central hub with `enable`/`disable` state. |
| `IB-QA/MCPServerGridStudio` | Meta-MCP that exposes `discover_servers`, `activate_server`, `call_tool`, `deactivate_server` | Expose exactly those 4–5 management tools. |
| `omer-ayhan/mcpmux` | Multiplexer that exposes only `discover_tools`/`call_discovered_tool` to keep client tool count tiny | Use discovery-first, proxy-execution pattern. |
| `Microsoft/mcp-gateway` | Kubernetes-style gateway with session routing and adapter lifecycle | Use namespace routing and adapter model. |
| `CrazyKoodaa/mcp-gateway` | Native MCP proxy, tool namespacing, disabled tools, single port | Use `__` namespacing and `disabledTools`. |
| `SpideXD/mcp-swarm` | Go orchestrator with auto-scaling, health checks, registry search | Use health monitoring and registry search. |
| `keshrath/agent-discover` | SQLite-backed registry with `activate`/`deactivate` and `tools/list_changed` | Use on-demand activation and dynamic tool list updates. |

## Design: `daves-tools-harness`
A single **meta-MCP server** that manages all 49+ child MCP servers. The client only sees the orchestrator, never the raw child servers.

### Architecture
```
Claude Desktop / Code / OpenHands
            │
            │  stdio / streamable-http
            ▼
┌─────────────────────────────┐
│  daves-tools-harness        │
│  (single MCP endpoint)      │
└──────┬──────────────────────┘
       │
       │  spawn / stdio / proxy
       ▼
┌─────────────────────────────┐
│  49+ installed MCP servers  │
│  (most are idle/disabled)   │
└─────────────────────────────┘
```

### Exposed tools (constant, no context bloat)
The host sees exactly these, regardless of how many servers are added:
1. `list_available_mcps` – browse catalog by profile/tier/tags.
2. `enable_mcp` – start a server and add its tools to the active set.
3. `disable_mcp` – stop a server and remove its tools.
4. `list_active_mcps` – show active servers, tool counts, health.
5. `call_mcp_tool` – execute a tool on an active server (dynamic dispatch).
6. `discover_mcps_for_task` – input task text, return recommended servers to enable.

### Registry
- JSON file: `configs/mcp-registry.json` maps every installed server to:
  - `name`, `tier`, `profile`, `command`, `args`, `env`, `tags`
  - `enabled` (bool)
  - `installed_path` (for local Node-based snippets)
  - `health_status` (`idle`, `healthy`, `unhealthy`)
- Populated from `claude-desktop-missing.json`.
- New servers can be appended manually or by re-running `Run-AllPhases.ps1`.

### Tool namespace
To avoid collisions, every proxied tool is renamed to `serverName__toolName` (e.g. `x64dbg__step`, `gitlab-mcp__get_issue`).

### Activation lifecycle
1. `enable_mcp` spawns the server process (stdio), runs `initialize`, fetches `tools/list`.
2. Tools are merged into the orchestrator's live tool list with `__` prefix.
3. `notifications/tools/list_changed` is sent to the host so the model sees new tools immediately.
4. `disable_mcp` kills the process and sends another `tools/list_changed`.

### Task-aware switching
`discover_mcps_for_task` uses keyword matching on the `tags` and `profile` fields:
- Task contains `reverse engineering` → suggest `x64dbg`, `dnspyex`, `assetripper`, `cpp2il`.
- Task contains `test`, `e2e` → suggest `playwright-cli---skills`.
- Task contains `CI` → suggest `gitlab-mcp`, `github`.
The agent can then `enable_mcp` the ones it wants, or the harness can auto-enable based on a threshold.

### Failure isolation
A crashing child server only affects its own `__` namespaced tools. The orchestrator catches `process.on('exit')`, marks `health_status: unhealthy`, and removes its tools from the active list.

## Files to create
- `harness/package.json`
- `harness/index.js` – the MCP server entry point
- `harness/registry.js` – registry load/save/toggle
- `harness/proxy.js` – child process management and tool call dispatch
- `harness/recommender.js` – keyword/task based server recommendation
- `configs/mcp-registry.json` – generated from `claude-desktop-missing.json`
- `toolkit/Build-McpRegistry.ps1` – PowerShell script to build `mcp-registry.json` from the current catalog + status
- `toolkit/Start-Harness.ps1` – PowerShell script to run `node harness/index.js` with the right env

## Verification plan
1. Run `Build-McpRegistry.ps1` and confirm `mcp-registry.json` has 49 entries.
2. Start the harness with `node harness/index.js`.
3. In Claude Desktop, add the harness as one MCP server.
4. Use `list_available_mcps`, `enable_mcp`, `call_mcp_tool`, `disable_mcp` and confirm tool list updates.
