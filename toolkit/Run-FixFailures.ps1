[CmdletBinding()]
param(
    [string]$CatalogPath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\missing-from-catalog.json",
    [string]$PreflightPath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\preflight.json",
    [string]$InstallRoot = "G:\Github"
)

$ErrorActionPreference = "Stop"

$preflight = Get-Content $PreflightPath | ConvertFrom-Json
$failed = $preflight.failures
$catalog = Get-Content $CatalogPath | ConvertFrom-Json

$failedNames = $failed | ForEach-Object { $_.name }
$fixCatalog = $catalog | Where-Object { $_.Name -in $failedNames }

$fixPath = Join-Path (Split-Path $CatalogPath) 'failed-catalog.json'
if ([string]::IsNullOrWhiteSpace($fixPath)) { $fixPath = 'C:\Users\Admin\CascadeProjects\daves-tools\docs\failed-catalog.json' }
$fixCatalog | ConvertTo-Json -Depth 3 | Set-Content -Path $fixPath -Encoding UTF8

$toolkit = Split-Path $fixPath
$toolkit = Join-Path (Split-Path $toolkit) 'toolkit'
& "$toolkit\Complete-Phase.ps1" -Phase 'fix' -CatalogPath $fixPath -InstallRoot $InstallRoot
