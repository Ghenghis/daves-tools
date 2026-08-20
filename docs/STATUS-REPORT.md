# DAVE-AI Tools Status Report

**Generated:** 2026-08-19T18:10:12.7991642-07:00

## Executive Summary

- **Overall cockpit readiness:** 29 / 43 catalog assets healthy
- **MCP live certifications passing:** 2 / 16
- **LLM provider tokens ready:** 5 / 7
- **Primary cockpit:** Dave's Tools with project-specific preflight and fallbacks

## Health by Asset Type

| Asset Type | Total | Healthy | Unhealthy |
|---|---|---|---|
| agent_runtime | 1 | 1 | 0 |
| benchmark | 1 | 1 | 0 |
| cli_dependency | 7 | 7 | 0 |
| gui_dependency | 4 | 4 | 0 |
| marketplace | 3 | 3 | 0 |
| mcp_server | 16 | 2 | 14 |
| service | 1 | 1 | 0 |
| skill_pack | 10 | 10 | 0 |

## MCP Server Certification Status

| MCP Server | Verdict | Command | Last Verified | Error / Notes |
|---|---|---|---|---|
| Serena | failed | `uvx mcp-server-serena --project <PROJECT_ROOT>` | 2026-08-20T00:57:39.335Z | MCP error -32000: Connection closed |
| Context7 | passed | `npx -y @upstash/context7-mcp@latest` | 2026-08-19T22:57:48.633Z |  |
| GitHub MCP | passed | `npx -y @modelcontextprotocol/server-github` | 2026-08-19T23:08:24.093Z |  |
| GitLab MCP | failed | `npx -y @modelcontextprotocol/server-gitlab` | 2026-08-19T23:20:13.972Z | MCP error -32000: Connection closed |
| SearXNG MCP | unknown | `node G:\Github\searxng-mcp\dist\index.js` |  |  |
| Android MCP | failed | `node G:\Github\android-mcp\dist\index.js` | 2026-08-19T23:16:35.764Z | MCP error -32000: Connection closed |
| Appium MCP | unknown | `node G:\Github\appium-mcp\dist\index.js` |  |  |
| Apktool MCP | failed | `npx -y apktool-mcp` | 2026-08-19T22:59:02.134Z | MCP error -32000: Connection closed |
| JADX AI MCP | unknown | `npx -y jadx-ai-mcp` |  |  |
| JADX MCP Server | unknown | `npx -y jadx-mcp-server` |  |  |
| Ghidra MCP Headless | unknown | ` ` |  |  |
| GhidraMCP LaurieWired | unknown | ` ` |  |  |
| pyghidra-mcp | unknown | ` ` |  |  |
| AutoGenesis | failed | `npx -y autogenesis` | 2026-08-19T23:15:35.261Z | MCP error -32000: Connection closed |
| Hyper-V MCP | unknown | `npx -y hyper-v-mcp` |  |  |
| x64dbg Automate MCP | unknown | `npx -y x64dbg-automate-mcp` |  |  |

## Unhealthy Assets and Required Remediation

- **GhidraMCP LaurieWired** ($(@{id=ghidramcp-lauriewired; display_name=GhidraMCP LaurieWired; asset_type=mcp_server; install_ok=True; env_ok=True; missing_env=System.Object[]; protocol_ok=unknown; healthy=False; repair_actions=System.Object[]}.id)) - asset_type: mcp_server
  - Repair actions: Run certifier
- **Ghidra MCP Headless** ($(@{id=ghidra-mcp-headless; display_name=Ghidra MCP Headless; asset_type=mcp_server; install_ok=True; env_ok=True; missing_env=System.Object[]; protocol_ok=unknown; healthy=False; repair_actions=System.Object[]}.id)) - asset_type: mcp_server
  - Repair actions: Run certifier
- **JADX MCP Server** ($(@{id=jadx-mcp-server; display_name=JADX MCP Server; asset_type=mcp_server; install_ok=True; env_ok=True; missing_env=System.Object[]; protocol_ok=unknown; healthy=False; repair_actions=System.Object[]}.id)) - asset_type: mcp_server
  - Repair actions: Run certifier
- **pyghidra-mcp** ($(@{id=pyghidra-mcp; display_name=pyghidra-mcp; asset_type=mcp_server; install_ok=True; env_ok=True; missing_env=System.Object[]; protocol_ok=unknown; healthy=False; repair_actions=System.Object[]}.id)) - asset_type: mcp_server
  - Repair actions: Run certifier
- **x64dbg Automate MCP** ($(@{id=x64dbg-automate-mcp; display_name=x64dbg Automate MCP; asset_type=mcp_server; install_ok=True; env_ok=True; missing_env=System.Object[]; protocol_ok=unknown; healthy=False; repair_actions=System.Object[]}.id)) - asset_type: mcp_server
  - Repair actions: Run certifier
- **Hyper-V MCP** ($(@{id=hyper-v-mcp; display_name=Hyper-V MCP; asset_type=mcp_server; install_ok=True; env_ok=True; missing_env=System.Object[]; protocol_ok=unknown; healthy=False; repair_actions=System.Object[]}.id)) - asset_type: mcp_server
  - Repair actions: Run certifier
- **AutoGenesis** ($(@{id=autogenesis; display_name=AutoGenesis; asset_type=mcp_server; install_ok=True; env_ok=True; missing_env=System.Object[]; protocol_ok=failed; healthy=False; repair_actions=System.Object[]}.id)) - asset_type: mcp_server
  - Repair actions: Run certifier
- **SearXNG MCP** ($(@{id=searxng-mcp; display_name=SearXNG MCP; asset_type=mcp_server; install_ok=True; env_ok=True; missing_env=System.Object[]; protocol_ok=unknown; healthy=False; repair_actions=System.Object[]}.id)) - asset_type: mcp_server
  - Repair actions: Run certifier
- **GitLab MCP** ($(@{id=gitlab-mcp; display_name=GitLab MCP; asset_type=mcp_server; install_ok=True; env_ok=True; missing_env=System.Object[]; protocol_ok=failed; healthy=False; repair_actions=System.Object[]}.id)) - asset_type: mcp_server
  - Repair actions: Run certifier
- **Serena** ($(@{id=serena; display_name=Serena; asset_type=mcp_server; install_ok=True; env_ok=True; missing_env=System.Object[]; protocol_ok=failed; healthy=False; repair_actions=System.Object[]}.id)) - asset_type: mcp_server
  - Repair actions: Run certifier
- **Android MCP** ($(@{id=android-mcp; display_name=Android MCP; asset_type=mcp_server; install_ok=True; env_ok=True; missing_env=System.Object[]; protocol_ok=failed; healthy=False; repair_actions=System.Object[]}.id)) - asset_type: mcp_server
  - Repair actions: Run certifier
- **JADX AI MCP** ($(@{id=jadx-ai-mcp; display_name=JADX AI MCP; asset_type=mcp_server; install_ok=True; env_ok=True; missing_env=System.Object[]; protocol_ok=unknown; healthy=False; repair_actions=System.Object[]}.id)) - asset_type: mcp_server
  - Repair actions: Run certifier
- **Apktool MCP** ($(@{id=apktool-mcp; display_name=Apktool MCP; asset_type=mcp_server; install_ok=True; env_ok=True; missing_env=System.Object[]; protocol_ok=failed; healthy=False; repair_actions=System.Object[]}.id)) - asset_type: mcp_server
  - Repair actions: Run certifier
- **Appium MCP** ($(@{id=appium-mcp; display_name=Appium MCP; asset_type=mcp_server; install_ok=True; env_ok=True; missing_env=System.Object[]; protocol_ok=unknown; healthy=False; repair_actions=System.Object[]}.id)) - asset_type: mcp_server
  - Repair actions: Run certifier

## LLM Provider Token Status

| Provider | Token Var | Present | Default |
|---|---|---|---|
| MiniMax | `MINIMAX_API_KEY` | True | True |
| DeepSeek | `DEEPSEEK_API_KEY` | True | False |
| SiliconFlow | `SILICONFLOW_API_KEY` | True | False |
| LM Studio | `LMSTUDIO_API_KEY` | False | False |
| Ollama | `OLLAMA_API_KEY` | False | False |
| OpenRouter | `OPENROUTER_API_KEY` | True | False |
| DeepInfra | `DEEPINFRA_TOKEN` | True | False |

Token values are never shown. Store them in `G:\private\*.env` and run `toolkit\Load-PrivateEnv.ps1`.

## GitHub / GitLab MCP Cleanliness

- **GitHub MCP** uses `npx -y @modelcontextprotocol/server-github` and has a live `passed` certification.
- **GitLab MCP** uses `npx -y @modelcontextprotocol/server-gitlab`. Certification is **failed** because `GITLAB_PERSONAL_ACCESS_TOKEN` is not present in the loaded private env. No token values are leaked.
- Both servers rely on `toolkit\Load-PrivateEnv.ps1` for newest-wins token loading from `G:\private`.

## Preflight and Fallbacks

- `toolkit\Project-Preflight.ps1` builds a project-specific primary + fallback tool profile using only healthy assets.
- `toolkit\Capability-Doctor.ps1` loads private env and reports health (install, env, protocol) for all 43 catalog assets.
- `toolkit\Auto-Repair.ps1` sets missing env defaults and re-runs the certifier for unhealthy MCPs.

## Proof / Evidence

- `docs/certification-summary.json` - raw certification results
- `docs/capability-report.json` - raw health report
- `docs/provider-token-status.json` - raw token presence report
- `docs/project-preflight.json` - example cockpit fallback profile

