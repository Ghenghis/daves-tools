[CmdletBinding()]
param(
    [string]$RegistryPath = "$PSScriptRoot\..\configs\typed-registry.json",
    [string]$OutPath = "$PSScriptRoot\..\README.md"
)

$ErrorActionPreference = "Stop"

$raw = [System.IO.File]::ReadAllText($RegistryPath)
$raw = $raw -replace '^\uFEFF', ''
$reg = $raw | ConvertFrom-Json

$sb = New-Object System.Text.StringBuilder

[void]$sb.AppendLine("# DAVE-AI Tools - Typed Capability Registry")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("> This README is generated from ``configs/typed-registry.json``. Do not hand-edit; run ``toolkit\Build-ReadmeFromTypedRegistry.ps1`` to regenerate.")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("A capability registry and early orchestration harness for the DAVE-AI agent ecosystem. Assets are classified by type so MCP servers, skill packs, CLIs, GUIs, services and benchmarks are not confused with one another.")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## What this repository gives you")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("- **One typed registry** of $($reg.total) unique catalog assets (``configs/typed-registry.json``).")
[void]$sb.AppendLine("- **$($reg.mcp_server_count) MCP server candidates** with corrected official launchers where known.")
[void]$sb.AppendLine("- **Preflight report** (``docs/preflight.json``) counts only unique phase rows.")
[void]$sb.AppendLine("- **Agentic orchestration harness** (``harness/index.js``) exposes a single MCP endpoint for discovery, enable/disable and namespaced child calls.")
[void]$sb.AppendLine("- **Task-aware switching** (``harness/recommender.js``) recommends assets by profile and capability, filtering empty/blank terms.")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Quick start")
[void]$sb.AppendLine("")
[void]$sb.AppendLine('```powershell')
[void]$sb.AppendLine('# Rebuild the typed registry from the audit data')
[void]$sb.AppendLine('.\toolkit\Build-TypedRegistry.ps1')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('# Run preflight (ignores duplicate repair rows)')
[void]$sb.AppendLine('.\toolkit\Run-Preflight.ps1')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('# Regenerate this README')
[void]$sb.AppendLine('.\toolkit\Build-ReadmeFromTypedRegistry.ps1')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('# Run the harness')
[void]$sb.AppendLine('cd harness; npm install; npm start')
[void]$sb.AppendLine('```')
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Asset counts")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Asset type | Count |")
[void]$sb.AppendLine("|---|---|")
[void]$sb.AppendLine("| Total unique | $($reg.total) |")
[void]$sb.AppendLine("| mcp_server | $($reg.mcp_server_count) |")
[void]$sb.AppendLine("| skill_pack | $($reg.skill_pack_count) |")
[void]$sb.AppendLine("| cli/gui/service dependencies | $($reg.dependency_count) |")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Catalog by type")
[void]$sb.AppendLine("")

$byType = @{}
foreach ($a in $reg.assets) {
    if (-not $byType[$a.asset_type]) { $byType[$a.asset_type] = @() }
    $byType[$a.asset_type] += $a
}

foreach ($t in ($byType.Keys | Sort-Object)) {
    [void]$sb.AppendLine("### $t")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("| Name | Profiles | Upstream | Command / notes |")
    [void]$sb.AppendLine("|---|---|---|---|")
    foreach ($a in ($byType[$t] | Sort-Object display_name)) {
        $prof = ($a.profiles -join ', ')
        $cmd = if ($a.runtime.command -and $a.runtime.command -ne 'none') {
            $a.runtime.command + ' ' + ($a.runtime.args -join ' ')
        } else {
            'dependency / not launchable as MCP'
        }
        [void]$sb.AppendLine("| $($a.display_name) | $prof | [$($a.source.url)]($($a.source.url)) | $cmd |")
    }
    [void]$sb.AppendLine("")
}

[void]$sb.AppendLine("## Official launchers corrected for P0 assets")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Asset | Transport | Command |")
[void]$sb.AppendLine("|---|---|---|")
$P0Names = @('Serena','GitHub MCP','GitLab MCP','Context7','Playwright CLI + Skills')
foreach ($n in $P0Names) {
    $a = $reg.assets | Where-Object { $_.display_name -eq $n } | Select-Object -First 1
    if ($a) {
        $cmd = $a.runtime.command
        if ($a.runtime.args.Count -gt 0) { $cmd += ' ' + ($a.runtime.args -join ' ') }
        [void]$sb.AppendLine("| $($a.display_name) | $($a.runtime.transport) | $cmd |")
    }
}

[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Remediation")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("This README reflects the Phase 0 truth reset from the 2026-08-19 E2E audit. The prior README claimed 49 installed MCP servers; the catalog actually contains **$($reg.total) unique assets**, of which **$($reg.mcp_server_count)** are MCP server candidates. The remaining entries are skills, CLIs, GUIs, services, benchmarks and marketplaces.")
[void]$sb.AppendLine("")

[System.IO.File]::WriteAllText($OutPath, $sb.ToString())
Write-Output "Wrote $OutPath"
