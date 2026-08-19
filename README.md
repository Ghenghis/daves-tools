# DAVE-AI Tools - Typed Capability Registry

> This README is generated from `configs/typed-registry.json`. Do not hand-edit; run `toolkit\Build-ReadmeFromTypedRegistry.ps1` to regenerate.

A capability registry and early orchestration harness for the DAVE-AI agent ecosystem. Assets are classified by type so MCP servers, skill packs, CLIs, GUIs, services and benchmarks are not confused with one another.

## What this repository gives you

- **One typed registry** of 43 unique catalog assets (`configs/typed-registry.json`).
- **16 MCP server candidates** with corrected official launchers where known.
- **Preflight report** (`docs/preflight.json`) counts only unique phase rows.
- **Agentic orchestration harness** (`harness/index.js`) exposes a single MCP endpoint for discovery, enable/disable and namespaced child calls.
- **Task-aware switching** (`harness/recommender.js`) recommends assets by profile and capability, filtering empty/blank terms.

## Quick start

```powershell
# Rebuild the typed registry from the audit data
.\toolkit\Build-TypedRegistry.ps1

# Run preflight (ignores duplicate repair rows)
.\toolkit\Run-Preflight.ps1

# Regenerate this README
.\toolkit\Build-ReadmeFromTypedRegistry.ps1

# Run the harness
cd harness; npm install; npm start
```

## Asset counts

| Asset type | Count |
|---|---|
| Total unique | 43 |
| mcp_server | 16 |
| skill_pack | 10 |
| cli/gui/service dependencies | 12 |

## Catalog by type

### agent_runtime

| Name | Profiles | Upstream | Command / notes |
|---|---|---|---|
| Mobilerun | MOBILE-AGENT | [https://github.com/droidrun/mobilerun](https://github.com/droidrun/mobilerun) | npx -y mobilerun  |

### benchmark

| Name | Profiles | Upstream | Command / notes |
|---|---|---|---|
| AndroidWorld | EVAL | [https://github.com/google-research/android_world](https://github.com/google-research/android_world) | npx -y androidworld  |

### cli_dependency

| Name | Profiles | Upstream | Command / notes |
|---|---|---|---|
| Apktool | ANDROID-RE | [https://github.com/iBotPeaches/Apktool](https://github.com/iBotPeaches/Apktool) | npx -y apktool  |
| Cpp2IL | UNITY-RE | [https://github.com/SamboyCoding/Cpp2IL](https://github.com/SamboyCoding/Cpp2IL) | npx -y cpp2il  |
| Ghidra | NATIVE-RE | [https://github.com/NationalSecurityAgency/ghidra](https://github.com/NationalSecurityAgency/ghidra) | dependency / not launchable as MCP |
| Maestro | ANDROID-DEV | [https://github.com/mobile-dev-inc/Maestro](https://github.com/mobile-dev-inc/Maestro) | npx -y maestro  |
| r2unity | UNITY-RE | [https://github.com/radareorg/r2unity](https://github.com/radareorg/r2unity) | npx -y r2unity  |
| radare2 | NATIVE-RE | [https://github.com/radareorg/radare2](https://github.com/radareorg/radare2) | dependency / not launchable as MCP |
| WinApp CLI | WINDOWS-DEV | [https://github.com/microsoft/winappCli](https://github.com/microsoft/winappCli) | npx -y winapp-cli  |

### gui_dependency

| Name | Profiles | Upstream | Command / notes |
|---|---|---|---|
| AssetRipper | UNITY-RE | [https://github.com/AssetRipper/AssetRipper](https://github.com/AssetRipper/AssetRipper) | npx -y assetripper  |
| dnSpyEx | UNITY-RE | [https://github.com/dnSpyEx/dnSpy](https://github.com/dnSpyEx/dnSpy) | npx -y dnspyex  |
| iaito | NATIVE-RE | [https://github.com/radareorg/iaito](https://github.com/radareorg/iaito) | dependency / not launchable as MCP |
| x64dbg | WINDOWS-RE | [https://github.com/x64dbg/x64dbg](https://github.com/x64dbg/x64dbg) | npx -y x64dbg  |

### marketplace

| Name | Profiles | Upstream | Command / notes |
|---|---|---|---|
| Claude Plugins Official | CORE | [https://github.com/anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) | npx -y claude-plugins-official  |
| Trail of Bits Skills | REVIEW | [https://github.com/trailofbits/skills](https://github.com/trailofbits/skills) | npx -y trail-of-bits-skills  |
| Trail of Bits Skills Curated | CORE, ON-DEMAND | [https://github.com/trailofbits/skills-curated](https://github.com/trailofbits/skills-curated) | dependency / not launchable as MCP |

### mcp_server

| Name | Profiles | Upstream | Command / notes |
|---|---|---|---|
| Android MCP | ANDROID-DEV | [https://github.com/qalvinahmad/android-mcp](https://github.com/qalvinahmad/android-mcp) | node G:\Github\android-mcp\dist\index.js |
| Apktool MCP | ANDROID-RE | [https://github.com/zinja-coder/apktool-mcp-server](https://github.com/zinja-coder/apktool-mcp-server) | npx -y apktool-mcp |
| Appium MCP | ANDROID-DEV | [https://github.com/appium/appium-mcp](https://github.com/appium/appium-mcp) | node G:\Github\appium-mcp\dist\index.js |
| AutoGenesis | WINDOWS-DEV | [https://github.com/microsoft/AutoGenesis](https://github.com/microsoft/AutoGenesis) | npx -y autogenesis |
| Context7 | RESEARCH | [https://github.com/upstash/context7](https://github.com/upstash/context7) | npx -y @upstash/context7-mcp@latest |
| Ghidra MCP Headless | NATIVE-RE | [https://github.com/SumTuusDeus/ghidra-mcp](https://github.com/SumTuusDeus/ghidra-mcp) | dependency / not launchable as MCP |
| GhidraMCP LaurieWired | NATIVE-RE | [https://github.com/LaurieWired/GhidraMCP](https://github.com/LaurieWired/GhidraMCP) | dependency / not launchable as MCP |
| GitHub MCP | REPO | [https://github.com/github/github-mcp-server](https://github.com/github/github-mcp-server) | npx -y @github/mcp-server |
| GitLab MCP | REPO | [https://docs.gitlab.com/user/model_context_protocol/mcp_server/](https://docs.gitlab.com/user/model_context_protocol/mcp_server/) | dependency / not launchable as MCP |
| Hyper-V MCP | ISOLATED-LAB | [https://github.com/originsec/hyperv-mcp](https://github.com/originsec/hyperv-mcp) | npx -y hyper-v-mcp |
| JADX AI MCP | ANDROID-RE | [https://github.com/zinja-coder/jadx-ai-mcp](https://github.com/zinja-coder/jadx-ai-mcp) | npx -y jadx-ai-mcp |
| JADX MCP Server | ANDROID-RE | [https://github.com/Qtty/jadx-mcp-server](https://github.com/Qtty/jadx-mcp-server) | npx -y jadx-mcp-server |
| pyghidra-mcp | NATIVE-RE | [https://github.com/clearbluejar/pyghidra-mcp](https://github.com/clearbluejar/pyghidra-mcp) | dependency / not launchable as MCP |
| SearXNG MCP | RESEARCH | [https://github.com/ihor-sokoliuk/mcp-searxng](https://github.com/ihor-sokoliuk/mcp-searxng) | node G:\Github\searxng-mcp\dist\index.js |
| Serena | CORE | [https://github.com/oraios/serena](https://github.com/oraios/serena) | uvx mcp-server-serena --project <PROJECT_ROOT> |
| x64dbg Automate MCP | WINDOWS-RE | [https://github.com/dariushoule/x64dbg-automate-pyclient](https://github.com/dariushoule/x64dbg-automate-pyclient) | npx -y x64dbg-automate-mcp |

### service

| Name | Profiles | Upstream | Command / notes |
|---|---|---|---|
| MobSF | ANDROID-RE | [https://github.com/MobSF/Mobile-Security-Framework-MobSF](https://github.com/MobSF/Mobile-Security-Framework-MobSF) | npx -y mobsf  |

### skill_pack

| Name | Profiles | Upstream | Command / notes |
|---|---|---|---|
| Android MCP Lean | ANDROID-DEV | [https://github.com/qalvinahmad/android-mcp](https://github.com/qalvinahmad/android-mcp) | node G:\Github\android-mcp-lean\dist\index.js  |
| Android Reverse Engineering Skill | ANDROID-RE | [https://github.com/SimoneAvogadro/android-reverse-engineering-skill](https://github.com/SimoneAvogadro/android-reverse-engineering-skill) | npx -y android-reverse-engineering-skill  |
| Anthropic Skills | CORE | [https://github.com/anthropics/skills](https://github.com/anthropics/skills) | npx -y anthropic-skills  |
| Frida MCP Skills | ANDROID-RE-DYNAMIC | [https://github.com/yfe404/frida-mcp-skills](https://github.com/yfe404/frida-mcp-skills) | npx -y frida-mcp-skills  |
| Maestro MCP | ANDROID-DEV | [https://github.com/mobile-dev-inc/Maestro](https://github.com/mobile-dev-inc/Maestro) | npx -y maestro-mcp  |
| Mobile Harness | MOBILE-AGENT | [https://github.com/droidrun/mobile-harness](https://github.com/droidrun/mobile-harness) | npx -y mobile-harness  |
| Playwright CLI + Skills | WEB-E2E | [https://github.com/microsoft/playwright-cli](https://github.com/microsoft/playwright-cli) | npx -y @playwright/mcp@latest |
| Superpowers | CORE | [https://github.com/obra/superpowers](https://github.com/obra/superpowers) | node G:\Github\superpowers\.opencode\plugins\superpowers.js  |
| win-dev-skills | WINDOWS-DEV | [https://github.com/microsoft/win-dev-skills](https://github.com/microsoft/win-dev-skills) | npx -y win-dev-skills  |
| x64dbg-skills | WINDOWS-RE | [https://github.com/dariushoule/x64dbg-skills](https://github.com/dariushoule/x64dbg-skills) | npx -y x64dbg-skills  |

## Official launchers corrected for P0 assets

| Asset | Transport | Command |
|---|---|---|
| Serena | stdio | uvx mcp-server-serena --project <PROJECT_ROOT> |
| GitHub MCP | stdio | npx -y @github/mcp-server |
| GitLab MCP | streamable_http | none |
| Context7 | stdio | npx -y @upstash/context7-mcp@latest |
| Playwright CLI + Skills | stdio | npx -y @playwright/mcp@latest |

## Remediation

This README reflects the Phase 0 truth reset from the 2026-08-19 E2E audit. The prior README claimed 49 installed MCP servers; the catalog actually contains **43 unique assets**, of which **16** are MCP server candidates. The remaining entries are skills, CLIs, GUIs, services, benchmarks and marketplaces.

