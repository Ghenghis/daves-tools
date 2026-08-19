[CmdletBinding()]
param(
    [string]$RegistryPath = "C:\Users\Admin\CascadeProjects\daves-tools\configs\typed-registry.json",
    [string]$ReportPath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\certification-report.json"
)

$ErrorActionPreference = "Stop"

$raw = [System.IO.File]::ReadAllText($RegistryPath)
$raw = $raw -replace '^\uFEFF', ''
$reg = $raw | ConvertFrom-Json

$mcpAssets = $reg.assets | Where-Object { $_.asset_type -eq 'mcp_server' }
$results = @()
$auditDir = "C:\Users\Admin\CascadeProjects\daves-tools\audit"
if (-not (Test-Path $auditDir)) { New-Item -ItemType Directory -Path $auditDir | Out-Null }

$scriptPath = "C:\Users\Admin\CascadeProjects\daves-tools\harness\certify-asset.js"

foreach ($a in $mcpAssets) {
    Write-Output "Certifying $($a.display_name) ..."
    $outFile = "$auditDir\cert-$($a.id).json"
    $errFile = "$auditDir\cert-$($a.id).err"
    $argList = @($scriptPath, $a.id, $RegistryPath)
    $proc = Start-Process -FilePath "node" -ArgumentList $argList -PassThru -Wait -NoNewWindow -WorkingDirectory "C:\Users\Admin\CascadeProjects\daves-tools" -RedirectStandardOutput $outFile -RedirectStandardError $errFile
    if ($proc.ExitCode -ne 0) {
        $err = ""
        if (Test-Path $errFile) { $err = [System.IO.File]::ReadAllText($errFile) }
        $results += [ordered]@{
            id = $a.id
            display_name = $a.display_name
            init = 'failed'
            error = $err
            duration_ms = 0
            verdict = 'failed'
        }
    } else {
        $r = [System.IO.File]::ReadAllText($outFile) | ConvertFrom-Json
        $a.verification.protocol = if ($r.init -eq 'passed' -and $r.list_tools -eq 'passed') { 'passed' } else { 'failed' }
        $a.verification.domain_smoke = $r.safe_call
        $a.verification.last_verified = (Get-Date -Format 'o')
        $a.verification.evidence_id = "cert-$($a.id)"
        $results += $r
    }
}

$report = [ordered]@{
    timestamp = (Get-Date -Format 'o')
    total = $mcpAssets.Count
    passed = ($results | Where-Object { $_.verdict -eq 'passed' }).Count
    failed = ($results | Where-Object { $_.verdict -eq 'failed' }).Count
    not_applicable = ($results | Where-Object { $_.verdict -eq 'not_applicable' }).Count
    results = $results
}

[System.IO.File]::WriteAllText($ReportPath, ($report | ConvertTo-Json -Depth 5))
[System.IO.File]::WriteAllText($RegistryPath, ($reg | ConvertTo-Json -Depth 5))
Write-Output "Wrote $ReportPath"
