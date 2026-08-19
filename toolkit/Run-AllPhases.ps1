[CmdletBinding()]
param(
    [string]$InstallRoot = "G:\Github",
    [switch]$InstallDeps,
    [switch]$PackageOnly
)

$ErrorActionPreference = "Stop"

$tiers = @(
    @{ Name="1"; Tiers=@("A","B") },
    @{ Name="2"; Tiers=@("C") },
    @{ Name="3"; Tiers=@("D","E","F","G","H") }
)

if (-not $PackageOnly) {
    foreach ($phase in $tiers) {
        Write-Output "=== Starting Phase $($phase.Name) (Tiers $($phase.Tiers -join ', ')) ==="
        & "$PSScriptRoot\Complete-Phase.ps1" -Phase $phase.Name -Tiers $phase.Tiers -InstallRoot $InstallRoot -InstallDeps:$InstallDeps
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
