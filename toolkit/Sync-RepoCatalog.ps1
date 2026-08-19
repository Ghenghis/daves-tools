[CmdletBinding()]
param(
    [string]$CatalogPath = "G:\Github\DAVEAI_Agent_Harness_RE_Android_Windows_2026-08-18\repo_catalog.json",
    [string]$Workspace = "C:\Users\Admin\claude-codex-devin"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $CatalogPath)) {
    throw "Catalog not found: $CatalogPath"
}

$catalog = Get-Content -Path $CatalogPath -Raw | ConvertFrom-Json
$missing = foreach ($item in $catalog) {
    $kind = $item.kind
    $name = $item.name
    $present = $false

    if ($kind -in @("MCP", "Plugin", "CLI")) {
        $present = Test-Path (Join-Path $Workspace "configs\mcp-examples\$($name.ToLower().Replace(' ', '-')).json") -ErrorAction SilentlyContinue
    } elseif ($kind -eq "Skills") {
        $present = Test-Path (Join-Path $Workspace ".claude\skills\$($name.ToLower().Replace(' ', '-'))") -ErrorAction SilentlyContinue
    }

    if (-not $present) {
        [pscustomobject]@{
            Name  = $name
            Kind  = $kind
            Tier  = $item.tier
            Profile = $item.profile
            Role  = $item.role
            URL   = $item.url
        }
    }
}

$missing | Format-Table -AutoSize
$missing | ConvertTo-Json -Depth 3 | Set-Content -Path "$PSScriptRoot\..\docs\missing-from-catalog.json" -Encoding UTF8
Write-Host "Wrote $(($missing).Count) missing items to docs\missing-from-catalog.json" -ForegroundColor Green
