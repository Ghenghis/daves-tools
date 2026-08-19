[CmdletBinding()]
param(
    [string]$CatalogPath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\missing-from-catalog.json",
    [string]$RegistryPath = "C:\Users\Admin\CascadeProjects\daves-tools\configs\mcp-registry.json",
    [string]$OutPath = "C:\Users\Admin\CascadeProjects\daves-tools\README.md"
)

$ErrorActionPreference = "Stop"

$catalog = Get-Content $CatalogPath -Raw | ConvertFrom-Json
$reg = if (Test-Path $RegistryPath) { (Get-Content $RegistryPath -Raw | ConvertFrom-Json).servers } else { @{} }

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('# DAVE-AI Tools - 49 MCP Server Ecosystem')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('A state-of-the-art collection of 49 installed, packaged, and orchestrated MCP (Model Context Protocol) servers for the DAVE-AI agent harness. Every server is cloned, tracked, and can be toggled on/off at runtime through the `daves-tools-harness` orchestrator.')
[void]$sb.AppendLine('')

[void]$sb.AppendLine('## What this repository gives you')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('- **One installer for 49 MCP servers** - cloned from GitHub and packaged into `configs/claude-desktop-missing.json`.')
[void]$sb.AppendLine('- **Preflight verification** - `docs/preflight.json` reports whether every server is cloned and healthy.')
[void]$sb.AppendLine('- **Agentic orchestration harness** - `harness/index.js` exposes a single MCP endpoint. The host sees only 6 management tools, while child MCP servers are activated and deactivated on demand.')
[void]$sb.AppendLine('- **Task-aware switching** - `discover_mcps_for_task` recommends the right servers for a given task, avoiding context bloat and resource waste.')
[void]$sb.AppendLine('')

[void]$sb.AppendLine('## Quick start')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('```powershell')
[void]$sb.AppendLine('# Re-run the full installation and packaging pipeline')
[void]$sb.AppendLine('.\toolkit\Run-AllPhases.ps1 -InstallDeps')
[void]$sb.AppendLine('.\toolkit\Run-Preflight.ps1')
[void]$sb.AppendLine('.\toolkit\Run-AllPhases.ps1 -PackageOnly')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('# Build the orchestration registry')
[void]$sb.AppendLine('.\toolkit\Build-McpRegistry.ps1')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('# Run the harness')
[void]$sb.AppendLine('cd harness; npm install; npm start')
[void]$sb.AppendLine('```')
[void]$sb.AppendLine('')

[void]$sb.AppendLine('## How the harness works')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('```')
[void]$sb.AppendLine('Claude / Claude Code / Windsurf / OpenHands')
[void]$sb.AppendLine('                 |')
[void]$sb.AppendLine('                 | stdio / streamable-http')
[void]$sb.AppendLine('                 v')
[void]$sb.AppendLine('    daves-tools-harness (one MCP endpoint)')
[void]$sb.AppendLine('                 |')
[void]$sb.AppendLine('    +------------+------------+')
[void]$sb.AppendLine('    v            v            v')
[void]$sb.AppendLine(' enabled      disabled    recommended')
[void]$sb.AppendLine(' child MCPs   child MCPs  by task text')
[void]$sb.AppendLine('```')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('The orchestrator exposes these 6 stable tools to the host:')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('- `list_available_mcps` - browse the full catalog and see health/installed state.')
[void]$sb.AppendLine('- `enable_mcp` - start a child server and add its tools (namespaced as `server__tool`).')
[void]$sb.AppendLine('- `disable_mcp` - stop a child server and free its resources.')
[void]$sb.AppendLine('- `list_active_mcps` - show currently active servers and tool counts.')
[void]$sb.AppendLine('- `discover_mcps_for_task` - get server recommendations from a task description.')
[void]$sb.AppendLine('- `call_mcp_tool` - execute any active, namespaced child tool.')
[void]$sb.AppendLine('')

$grouped = $catalog | Group-Object -Property Tier | Sort-Object Name
[void]$sb.AppendLine('## MCP catalog by tier')
[void]$sb.AppendLine('')
foreach ($g in $grouped) {
    [void]$sb.AppendLine("### Tier $($g.Name)")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Name | Kind | Profile | Role / Use case | Status |')
    [void]$sb.AppendLine('|------|------|---------|-----------------|--------|')
    foreach ($item in ($g.Group | Sort-Object Name)) {
        $key = ($item.Name -replace '[^\w]', '-').ToLower() -replace '-+', '-'
        $status = 'not installed'
        if ($reg -and $reg.$key) {
            $status = if ($reg.$key.cloned) { 'installed' } else { 'missing' }
            if ($reg.$key.enabled) { $status += ' + active' }
        }
        $role = $item.Role -replace '\|', '\|'
        [void]$sb.AppendLine("| $($item.Name) | $($item.Kind) | $($item.Profile) | $role | $status |")
    }
    [void]$sb.AppendLine('')
}

[void]$sb.AppendLine('## Use case matrix')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| Task | Recommended MCP servers |')
[void]$sb.AppendLine('|------|-------------------------|')
[void]$sb.AppendLine('| Reverse engineer a Windows PE / .NET binary | `x64dbg`, `dnSpyEx`, `AssetRipper`, `Cpp2IL`, `r2unity` |')
[void]$sb.AppendLine('| Android reverse engineering | `apktool`, `jadx-mcp-server`, `frida-mcp-skills`, `mobsf`, `android-reverse-engineering-skill` |')
[void]$sb.AppendLine('| Web e2e testing / automation | `playwright-cli-skills` |')
[void]$sb.AppendLine('| Code review / security audit | `trail-of-bits-skills`, `anthropic-skills`, `claude-plugins-official` |')
[void]$sb.AppendLine('| CI / repo management | `github-mcp`, `gitlab-mcp` |')
[void]$sb.AppendLine('| Research / knowledge retrieval | `context7`, `searxng-mcp` |')
[void]$sb.AppendLine('| Mobile QA / Android dev | `android-mcp`, `appium-mcp`, `maestro`, `mobilerun` |')
[void]$sb.AppendLine('')

[void]$sb.AppendLine('## Adding more MCP servers')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('1. Append the server to `docs/missing-from-catalog.json`.')
[void]$sb.AppendLine('2. Run `.\toolkit\Run-AllPhases.ps1` to clone, build, and package the new entry.')
[void]$sb.AppendLine('3. Run `.\toolkit\Build-McpRegistry.ps1` to update `configs/mcp-registry.json`.')
[void]$sb.AppendLine('4. The harness picks up the new server automatically on restart.')
[void]$sb.AppendLine('')

[void]$sb.AppendLine('## Claude Desktop snippet')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('Add this single entry to `claude_desktop_config.json` to control all 49 servers:')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('```json')
[void]$sb.AppendLine('{')
[void]$sb.AppendLine('  "mcpServers": {')
[void]$sb.AppendLine('    "daves-tools-harness": {')
[void]$sb.AppendLine('      "command": "node",')
[void]$sb.AppendLine('      "args": [')
[void]$sb.AppendLine('        "C:\\Users\\Admin\\CascadeProjects\\daves-tools\\harness\\index.js"')
[void]$sb.AppendLine('      ],')
[void]$sb.AppendLine('      "env": {')
[void]$sb.AppendLine('        "MCP_REGISTRY": "C:\\Users\\Admin\\CascadeProjects\\daves-tools\\configs\\mcp-registry.json"')
[void]$sb.AppendLine('      }')
[void]$sb.AppendLine('    }')
[void]$sb.AppendLine('  }')
[void]$sb.AppendLine('}')
[void]$sb.AppendLine('```')
[void]$sb.AppendLine('')

[void]$sb.AppendLine('## Automation scripts')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| Script | Purpose |')
[void]$sb.AppendLine('|--------|---------|')
[void]$sb.AppendLine('| `toolkit/Run-AllPhases.ps1` | Clone, install, build, and package all tiers. |')
[void]$sb.AppendLine('| `toolkit/Run-Preflight.ps1` | Generate `docs/preflight.json` status report. |')
[void]$sb.AppendLine('| `toolkit/Build-McpRegistry.ps1` | Build `configs/mcp-registry.json` for the harness. |')
[void]$sb.AppendLine('| `toolkit/Run-FixFailures.ps1` | Re-run only items that failed preflight. |')
[void]$sb.AppendLine('| `harness/index.js` | The orchestrator MCP server. |')
[void]$sb.AppendLine('')

[void]$sb.AppendLine('## License')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('MIT - maintained for the DAVE-AI agent harness.')

[System.IO.File]::WriteAllText($OutPath, $sb.ToString())
Write-Output "Wrote README to $OutPath"
