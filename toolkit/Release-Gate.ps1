[CmdletBinding()]
param(
    [string]$RepoPath = "C:\Users\Admin\CascadeProjects\daves-tools",
    [string]$RegistryPath = "C:\Users\Admin\CascadeProjects\daves-tools\configs\typed-registry.json"
)

$ErrorActionPreference = "Stop"

$raw = [System.IO.File]::ReadAllText($RegistryPath)
$raw = $raw -replace '^\uFEFF', ''
$reg = $raw | ConvertFrom-Json

Push-Location $RepoPath
$branch = git rev-parse --abbrev-ref HEAD
$uncommitted = git status --short
$unpushed = git log --branches --not --remotes --oneline
Pop-Location

$gates = [System.Collections.ArrayList]@()

function Add-Gate($name, $status, $evidence) {
    [void]$gates.Add([ordered]@{ name = $name; status = $status; evidence = $evidence })
}

Add-Gate 'branch_is_main' ($branch -eq 'master' ? 'passed' : 'failed') $branch
Add-Gate 'no_uncommitted_changes' ([string]::IsNullOrWhiteSpace($uncommitted) ? 'passed' : 'failed') $uncommitted
Add-Gate 'no_unpushed_commits' ([string]::IsNullOrWhiteSpace($unpushed) ? 'passed' : 'failed') $unpushed

$allHealthy = ($reg.assets | Where-Object { $_.verification.protocol -eq 'passed' }).Count
$total = $reg.assets.Count
Add-Gate 'typed_registry_present' ($total -gt 0 ? 'passed' : 'failed') "$total assets"

$preflightPath = "C:\Users\Admin\CascadeProjects\daves-tools\toolkit\Run-Preflight.ps1"
$preflight = @()
if (Test-Path $preflightPath) {
    $preflight = & $preflightPath -OutputJson | ConvertFrom-Json
    $passCount = ($preflight | Where-Object { $_.status -eq 'passed' }).Count
    Add-Gate 'preflight_ran' 'passed' "healthy $passCount assets"
} else {
    Add-Gate 'preflight_ran' 'failed' 'Run-Preflight.ps1 not found'
}

$overall = if ($gates | Where-Object { $_.status -ne 'passed' }) { 'failed' } else { 'passed' }

$report = [ordered]@{
    timestamp = (Get-Date -Format 'o')
    branch = $branch
    overall = $overall
    gates = $gates
}

$out = "C:\Users\Admin\CascadeProjects\daves-tools\docs\release-gate.json"
[System.IO.File]::WriteAllText($out, ($report | ConvertTo-Json -Depth 5))
Write-Output "Overall: $overall"
Write-Output "Wrote $out"
