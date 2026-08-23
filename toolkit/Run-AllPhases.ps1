[CmdletBinding()]
param(
    [string]$InstallRoot = "G:\Github",
    [switch]$InstallDeps,
    [switch]$PackageOnly,
    [switch]$FixFailures
)

$ErrorActionPreference = "Stop"

$tiers = @(
    @{ Name="1"; Tiers=@("A","B") },
    @{ Name="2"; Tiers=@("C") },
    @{ Name="3"; Tiers=@("D","E","F","G","H") }
)

if (-not $PackageOnly) {
    $failedCatalogPath = Join-Path (Join-Path (Split-Path $PSScriptRoot) 'docs') 'failed-catalog.json'
    $phases = if ($FixFailures) {
        if (Test-Path $failedCatalogPath) {
            $failedCatalog = Get-Content -Path $failedCatalogPath -Raw | ConvertFrom-Json
            $tiersRaw = $failedCatalog.Tier | Select-Object -Unique
            $failedTiers = if ($tiersRaw -is [array]) { $tiersRaw } else { @($tiersRaw) }
            $matchingPhases = [System.Collections.ArrayList]@()
            foreach ($phase in $tiers) {
                $hasFailure = $false
                foreach ($tier in $failedTiers) {
                    if ($phase.Tiers -contains $tier) { $hasFailure = $true; break }
                }
                if ($hasFailure) { [void]$matchingPhases.Add($phase) }
            }
            if ($matchingPhases.Count -eq 0) {
                Write-Output "No failed tiers in failed-catalog.json; nothing to fix."
            }
            $matchingPhases
        } else {
            Write-Output "No failed-catalog.json found; running all phases."
            $tiers
        }
    } else {
        $tiers
    }

    $catalogArg = @{}
    if ($FixFailures -and (Test-Path $failedCatalogPath)) {
        $catalogArg['CatalogPath'] = $failedCatalogPath
    }

    foreach ($phase in $phases) {
        Write-Output "=== Starting Phase $($phase.Name) (Tiers $($phase.Tiers -join ', ')) ==="
        & "$PSScriptRoot\Complete-Phase.ps1" -Phase $phase.Name -Tiers $phase.Tiers -InstallRoot $InstallRoot -InstallDeps:$InstallDeps @catalogArg
    }
}

Write-Output "=== Combining snippets ==="
$combined = @{ mcpServers = [ordered]@{} }
$snippets = Get-ChildItem -Path $InstallRoot -Filter 'claude-desktop-snippet.json' -Depth 1 -ErrorAction SilentlyContinue
foreach ($s in $snippets) {
    try {
        $json = Get-Content $s.FullName | ConvertFrom-Json
        $key = ($json.PSObject.Properties.Name | Select-Object -First 1)
        if ($key -and $json.$key) { $combined.mcpServers[$key] = $json.$key }
    } catch {
        Write-Warning "Skipping invalid snippet: $($s.FullName) - $_"
    }
}

$combinedPath = Join-Path (Split-Path $PSScriptRoot) "configs\claude-desktop-missing.json"
if ([string]::IsNullOrWhiteSpace($combinedPath)) {
    $combinedPath = "C:\Users\Admin\CascadeProjects\daves-tools\configs\claude-desktop-missing.json"
}
New-Item -ItemType Directory -Path (Split-Path $combinedPath) -Force | Out-Null
$combined | ConvertTo-Json -Depth 5 | Set-Content -Path $combinedPath -Encoding UTF8
Write-Output "Wrote combined config: $combinedPath"
