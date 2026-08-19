[CmdletBinding()]
param(
    [string]$StatusDir = "C:\Users\Admin\CascadeProjects\daves-tools\docs"
)

$ErrorActionPreference = "Stop"

$fixFile = Join-Path $StatusDir 'phase-fix-status.json'
if (-not (Test-Path $fixFile)) { throw "No $fixFile found" }
$fixes = Get-Content $fixFile | ConvertFrom-Json
if (-not $fixes) { $fixes = @() }

$files = Get-ChildItem -Path $StatusDir -Filter 'phase-*-status.json' | Where-Object { $_.Name -ne 'phase-fix-status.json' }
foreach ($f in $files) {
    $items = Get-Content $f.FullName | ConvertFrom-Json
    if (-not $items) { $items = @() }
    foreach ($fix in $fixes) {
        $idx = 0
        $found = -1
        foreach ($item in $items) {
            if ($item.name -eq $fix.name) { $found = $idx; break }
            $idx++
        }
        if ($found -ge 0) {
            $items[$found] = $fix
        }
    }
    $items | ConvertTo-Json -Depth 3 | Set-Content -Path $f.FullName -Encoding UTF8
}

Write-Output "Merged $(($fixes).Count) fix entries into phase status files."
