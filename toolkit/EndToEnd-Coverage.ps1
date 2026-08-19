[CmdletBinding()]
param(
    [string]$RegistryPath = "C:\Users\Admin\CascadeProjects\daves-tools\configs\typed-registry.json",
    [string]$ReportPath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\e2e-coverage.json",
    [string]$MdPath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\E2E-COVERAGE.md"
)

$ErrorActionPreference = "Stop"

$raw = [System.IO.File]::ReadAllText($RegistryPath)
$raw = $raw -replace '^\uFEFF', ''
$reg = $raw | ConvertFrom-Json

$gates = @(
    'source_provenance',
    'install',
    'launch',
    'protocol',
    'exact_tool_schema',
    'credentials',
    'permissions',
    'safe_smoke_call',
    'domain_fixture',
    'failure_recovery',
    'uninstall_rollback',
    'hermesproof_evidence'
)

$results = foreach ($a in $reg.assets) {
    $coverage = [ordered]@{}
    foreach ($g in $gates) { $coverage[$g] = 'unknown' }

    $coverage['source_provenance'] = if ($a.source.url) { 'passed' } else { 'failed' }
    $coverage['install'] = if ($a.verification.install -eq 'passed') { 'passed' } elseif ($a.runtime.transport -eq 'none') { 'not_applicable' } else { 'failed' }
    $coverage['launch'] = if ($a.runtime.command -and $a.runtime.command -ne 'none') { 'passed' } else { 'failed' }
    $coverage['protocol'] = if ($a.verification.protocol -eq 'passed') { 'passed' } else { 'failed' }
    $coverage['exact_tool_schema'] = if ($a.child_schemas -and $a.child_schemas.Count -gt 0) { 'passed' } else { 'failed' }
    $coverage['credentials'] = if ($a.permissions.env_broker -and $a.permissions.env_broker.Count -gt 0) { 'passed' } else { 'not_applicable' }
    $coverage['permissions'] = if ($a.permissions.mutation_level) { 'passed' } else { 'failed' }
    $coverage['safe_smoke_call'] = if ($a.verification.domain_smoke -eq 'passed') { 'passed' } else { 'failed' }
    $coverage['domain_fixture'] = if ($a.verification.domain_fixture) { $a.verification.domain_fixture } else { 'failed' }
    $coverage['failure_recovery'] = if ($a.artifacts.last_recovery) { 'passed' } else { 'failed' }
    $coverage['uninstall_rollback'] = if (Test-Path "C:\Users\Admin\Github\$($a.id).bak") { 'passed' } else { 'failed' }
    $coverage['hermesproof_evidence'] = if ($a.verification.evidence_id) { 'passed' } else { 'failed' }

    $passed = ($coverage.Values | Where-Object { $_ -eq 'passed' }).Count
    $failed = ($coverage.Values | Where-Object { $_ -eq 'failed' }).Count
    $notApplicable = ($coverage.Values | Where-Object { $_ -eq 'not_applicable' }).Count

    [ordered]@{
        id = $a.id
        display_name = $a.display_name
        asset_type = $a.asset_type
        coverage = $coverage
        passed = $passed
        failed = $failed
        not_applicable = $notApplicable
        percent = [math]::Round(($passed / ($gates.Count - $notApplicable) * 100), 1)
    }
}

$overallPassed = 0
$overallFailed = 0
foreach ($r in $results) { $overallPassed += $r.passed; $overallFailed += $r.failed }

$report = [ordered]@{
    timestamp = (Get-Date -Format 'o')
    total = $reg.assets.Count
    overall_passed = $overallPassed
    overall_failed = $overallFailed
    results = $results
}

[System.IO.File]::WriteAllText($ReportPath, ($report | ConvertTo-Json -Depth 5))

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# End-to-End Coverage Report")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("**Generated:** $($report.timestamp)**")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Asset | Type | Passed | Failed | N/A | % |")
[void]$sb.AppendLine("|---|---|---|---|---|---|")
foreach ($r in $results | Sort-Object percent -Descending) {
    [void]$sb.AppendLine("| $($r.display_name) | $($r.asset_type) | $($r.passed) | $($r.failed) | $($r.not_applicable) | $($r.percent) |")
}

[System.IO.File]::WriteAllText($MdPath, $sb.ToString())
Write-Output "Wrote $ReportPath and $MdPath"
