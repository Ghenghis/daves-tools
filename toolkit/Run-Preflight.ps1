[CmdletBinding()]
param(
    [string]$StatusDir = "C:\Users\Admin\CascadeProjects\daves-tools\docs"
)

$ErrorActionPreference = "Stop"

$report = [ordered]@{
    timestamp = (Get-Date -Format o)
    summary   = [ordered]@{ total = 0; cloned = 0; failed = 0; skipped = 0 }
    phases    = @()
    failures  = @()
    missing   = @()
}

$statusFiles = Get-ChildItem -Path $StatusDir -Filter 'phase-*-status.json' |
    Where-Object { $_.Name -notlike '*-fix-*' } |
    Sort-Object Name
foreach ($f in $statusFiles) {
    $items = Get-Content $f.FullName | ConvertFrom-Json
    if (-not $items) { $items = @() }
    $phase = [ordered]@{
        file  = $f.Name
        total = $items.Count
        cloned = 0
        failed = 0
    }
    foreach ($item in $items) {
        $report.summary.total++
        if ($item.cloned) { $phase.cloned++; $report.summary.cloned++ }
        if ($item.error -or -not $item.cloned) { $phase.failed++; $report.summary.failed++; $report.failures += $item }
    }
    $report.phases += $phase
}

$preflightPath = Join-Path $StatusDir 'preflight.json'
$report | ConvertTo-Json -Depth 3 | Set-Content -Path $preflightPath -Encoding UTF8
Write-Output "Preflight complete. Wrote $preflightPath"
$report.summary | Format-Table -AutoSize
