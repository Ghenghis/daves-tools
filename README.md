# DAVE-AI Tools - 49 MCP Server Ecosystem

A state-of-the-art collection of 49 installed, packaged, and orchestrated MCP (Model Context Protocol) servers for the DAVE-AI agent harness. Every server is cloned, tracked, and can be toggled on/off at runtime through the `daves-tools-harness` orchestrator.

## What this repository gives you

- **One installer for 49 MCP servers** - cloned from GitHub and packaged into `configs/claude-desktop-missing.json`.
- **Preflight verification** - `docs/preflight.json` reports whether every server is cloned and healthy.
- **Agentic orchestration harness** - `harness/index.js` exposes a single MCP endpoint. The host sees only 6 management tools, while child MCP servers are activated and deactivated on demand.
- **Task-aware switching** - `discover_mcps_for_task` recommends the right servers for a given task, avoiding context bloat and resource waste.

## Quick start

```powershell
# Re-run the full installation and packaging pipeline
.\toolkit\Run-AllPhases.ps1 -InstallDeps
.\toolkit\Run-Preflight.ps1
.\toolkit\Run-AllPhases.ps1 -PackageOnly

# Build the orchestration registry
.\toolkit\Build-McpRegistry.ps1

# Run the harness
cd harness; npm install; npm start
```

## How the harness works

```
Claude / Claude Code / Windsurf / OpenHands
                 |
                 | stdio / streamable-http
                 v
    daves-tools-harness (one MCP endpoint)
                 |
    +------------+------------+
    v            v            v
 enabled      disabled    recommended
 child MCPs   child MCPs  by task text
```

The orchestrator exposes these 6 stable tools to the host:

- `list_available_mcps` - browse the full catalog and see health/installed state.
- `enable_mcp` - start a child server and add its tools (namespaced as `server__tool`).
- `disable_mcp` - stop a child server and free its resources.
- `list_active_mcps` - show currently active servers and tool counts.
- `discover_mcps_for_task` - get server recommendations from a task description.
- `call_mcp_tool` - execute any active, namespaced child tool.

## MCP catalog by tier

### Tier A

| Name | Kind | Profile | Role / Use case | Status |
|------|------|---------|-----------------|--------|
| Anthropic Skills | Skills | CORE | Official skill examples and skill-creator | missing |
| Claude Plugins Official | Marketplace | CORE | Curated Claude plugins | missing |
| Serena | MCP | CORE | Semantic code navigation/editing | missing |
| Superpowers | Plugin/skills | CORE | Development workflow discipline | missing |

### Tier A/B

| Name | Kind | Profile | Role / Use case | Status |
|------|------|---------|-----------------|--------|
| Trail of Bits Skills Curated | Plugin marketplace | CORE/ON-DEMAND | Reviewed skills including ghidra-headless, security-awareness, Playwright | not installed |

### Tier B

| Name | Kind | Profile | Role / Use case | Status |
|------|------|---------|-----------------|--------|
| Context7 | MCP/CLI | RESEARCH | Current library docs | missing |
| GitHub MCP | MCP/Connector | REPO | Repo/issues/PR actions | missing |
| GitLab MCP | MCP/Connector | REPO | GitLab project/MR/pipeline actions | missing |
| SearXNG MCP | MCP | RESEARCH | Operator-controlled web search | missing |
| Trail of Bits Skills | Plugin marketplace | REVIEW | Security review/static analysis/supply-chain workflows | missing |

### Tier C

| Name | Kind | Profile | Role / Use case | Status |
|------|------|---------|-----------------|--------|
| Android MCP | MCP | ANDROID-DEV | Lean ADB-only Android control alternative | missing |
| Android MCP Lean | MCP | ANDROID-DEV | Lean ADB-only Android control | missing |
| AndroidWorld | Benchmark | EVAL | Android agent benchmarking | missing |
| Appium MCP | MCP | ANDROID-DEV | Cross-platform Appium automation | missing |
| Maestro | CLI/E2E | ANDROID-DEV | Deterministic mobile E2E | missing |
| Maestro MCP | MCP/CLI/E2E | ANDROID-DEV | Deterministic mobile E2E flows and agent control | missing |
| Mobile Harness | Skill/harness | MOBILE-AGENT | Portable mobile-agent operating instructions | missing |
| Mobilerun | Agent runtime | MOBILE-AGENT | Natural-language mobile control | missing |

### Tier D

| Name | Kind | Profile | Role / Use case | Status |
|------|------|---------|-----------------|--------|
| Android Reverse Engineering Skill | Plugin/skill | ANDROID-RE | Fingerprint-first APK/API extraction; Windows scripts experimental upstream | missing |
| Apktool | CLI | ANDROID-RE | Resources/smali decode/rebuild | missing |
| Apktool MCP | MCP | ANDROID-RE | Agent access to Apktool | missing |
| Frida MCP Skills | Skills | ANDROID-RE-DYNAMIC | Lifecycle-safe Frida workflow | missing |
| JADX AI MCP | MCP/plugin | ANDROID-RE | Live GUI APK decompilation/navigation | missing |
| JADX MCP Server | MCP | ANDROID-RE | Headless APK analysis | missing |
| MobSF | App/API | ANDROID-RE | Automated mobile triage | missing |

### Tier D/F

| Name | Kind | Profile | Role / Use case | Status |
|------|------|---------|-----------------|--------|
| Ghidra | RE suite | NATIVE-RE | Disassembly/decompilation/analysis | not installed |
| Ghidra MCP Headless | MCP | NATIVE-RE | Small headless PyGhidra MCP | not installed |
| GhidraMCP LaurieWired | MCP/plugin | NATIVE-RE | Interactive Ghidra MCP | not installed |
| iaito | GUI | NATIVE-RE | Official radare2 GUI | not installed |
| pyghidra-mcp | MCP | NATIVE-RE | Headless + GUI Ghidra state | not installed |
| radare2 | RE framework | NATIVE-RE | Binary analysis/debugging framework | not installed |

### Tier E

| Name | Kind | Profile | Role / Use case | Status |
|------|------|---------|-----------------|--------|
| AutoGenesis | MCP/test framework | WINDOWS-DEV | Cross-platform GUI test automation | missing |
| WinApp CLI | CLI/skills | WINDOWS-DEV | Windows app tooling/UI automation | missing |
| win-dev-skills | Plugin/skills | WINDOWS-DEV | Windows app build/test/package workflow | missing |

### Tier F

| Name | Kind | Profile | Role / Use case | Status |
|------|------|---------|-----------------|--------|
| Hyper-V MCP | MCP | ISOLATED-LAB | VM lifecycle/checkpoints/guest execution | missing |
| x64dbg | Debugger | WINDOWS-RE | Windows user-mode dynamic RE | missing |
| x64dbg Automate MCP | MCP | WINDOWS-RE | Agent debugger automation | missing |
| x64dbg-skills | Plugin/skills | WINDOWS-RE | Debugger operating workflows | missing |

### Tier G

| Name | Kind | Profile | Role / Use case | Status |
|------|------|---------|-----------------|--------|
| AssetRipper | GUI/CLI | UNITY-RE | Unity asset extraction | missing |
| Cpp2IL | CLI | UNITY-RE | Unity IL2CPP reconstruction | missing |
| dnSpyEx | GUI | UNITY-RE | .NET managed assembly analysis | missing |
| r2unity | CLI/plugin | UNITY-RE | Unity IL2CPP metadata in radare2 | missing |

### Tier H

| Name | Kind | Profile | Role / Use case | Status |
|------|------|---------|-----------------|--------|
| Playwright CLI + Skills | CLI/skills | WEB-E2E | Token-efficient browser/PWA/Electron automation for coding agents | missing |

## Use case matrix

| Task | Recommended MCP servers |
|------|-------------------------|
| Reverse engineer a Windows PE / .NET binary | `x64dbg`, `dnSpyEx`, `AssetRipper`, `Cpp2IL`, `r2unity` |
| Android reverse engineering | `apktool`, `jadx-mcp-server`, `frida-mcp-skills`, `mobsf`, `android-reverse-engineering-skill` |
| Web e2e testing / automation | `playwright-cli-skills` |
| Code review / security audit | `trail-of-bits-skills`, `anthropic-skills`, `claude-plugins-official` |
| CI / repo management | `github-mcp`, `gitlab-mcp` |
| Research / knowledge retrieval | `context7`, `searxng-mcp` |
| Mobile QA / Android dev | `android-mcp`, `appium-mcp`, `maestro`, `mobilerun` |

## Adding more MCP servers

1. Append the server to `docs/missing-from-catalog.json`.
2. Run `.\toolkit\Run-AllPhases.ps1` to clone, build, and package the new entry.
3. Run `.\toolkit\Build-McpRegistry.ps1` to update `configs/mcp-registry.json`.
4. The harness picks up the new server automatically on restart.

## Claude Desktop snippet

Add this single entry to `claude_desktop_config.json` to control all 49 servers:

```json
{
  "mcpServers": {
    "daves-tools-harness": {
      "command": "node",
      "args": [
        "C:\\Users\\Admin\\CascadeProjects\\daves-tools\\harness\\index.js"
      ],
      "env": {
        "MCP_REGISTRY": "C:\\Users\\Admin\\CascadeProjects\\daves-tools\\configs\\mcp-registry.json"
      }
    }
  }
}
```

## Automation scripts

| Script | Purpose |
|--------|---------|
| `toolkit/Run-AllPhases.ps1` | Clone, install, build, and package all tiers. |
| `toolkit/Run-Preflight.ps1` | Generate `docs/preflight.json` status report. |
| `toolkit/Build-McpRegistry.ps1` | Build `configs/mcp-registry.json` for the harness. |
| `toolkit/Run-FixFailures.ps1` | Re-run only items that failed preflight. |
| `harness/index.js` | The orchestrator MCP server. |

## License

MIT - maintained for the DAVE-AI agent harness.
