[CmdletBinding()]
param(
    [string]$RegistryPath = "C:\Users\Admin\CascadeProjects\daves-tools\configs\typed-registry.json",
    [string]$AuditDir = "C:\Users\Admin\CascadeProjects\daves-tools\audit",
    [string]$JsonPath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\certification-summary.json",
    [string]$MdPath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\CERTIFICATION-SUMMARY.md"
)

$ErrorActionPreference = "Stop"

$raw = [System.IO.File]::ReadAllText($RegistryPath)
$raw = $raw -replace '^\uFEFF', ''
$reg = $raw | ConvertFrom-Json

$results = @()
foreach ($a in $reg.assets | Where-Object { $_.asset_type -eq 'mcp_server' }) {
    $file = "$AuditDir\cert-$($a.id).json"
    $verdict = $a.verification.protocol
    $err = ''
    if (Test-Path $file) {
        $c = [System.IO.File]::ReadAllText($file) | ConvertFrom-Json
        $verdict = $c.verdict
        $err = $c.error
    }
    $results += [ordered]@{
        id = $a.id
        display_name = $a.display_name
        command = $a.runtime.command
        args = $a.runtime.args -join ' '
        verdict = $verdict
        protocol = $a.verification.protocol
        domain_smoke = $a.verification.domain_smoke
        last_verified = $a.verification.last_verified
        error = $err
    }
}

$json = [ordered]@{
    timestamp = (Get-Date -Format 'o')
    total = $results.Count
    passed = ($results | Where-Object { $_.verdict -eq 'passed' }).Count
    failed = ($results | Where-Object { $_.verdict -eq 'failed' }).Count
    not_applicable = ($results | Where-Object { $_.verdict -eq 'not_applicable' }).Count
    results = $results
}

[System.IO.File]::WriteAllText($JsonPath, ($json | ConvertTo-Json -Depth 5))

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# Certification Summary")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("**Generated:** $($json.timestamp)**")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("- **Total:** $($json.total)")
[void]$sb.AppendLine("- **Passed:** $($json.passed)")
[void]$sb.AppendLine("- **Failed:** $($json.failed)")
[void]$sb.AppendLine("- **N/A:** $($json.not_applicable)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Asset | Verdict | Protocol | Smoke | Last Verified | Error |")
[void]$sb.AppendLine("|---|---|---|---|---|---|")
foreach ($r in $results | Sort-Object { $_.verdict }) {
    $err = if ($r.error) { ($r.error -replace "`n", ' ').Substring(0, [Math]::Min(80, $r.error.Length)) } else { '' }
    [void]$sb.AppendLine("| $($r.display_name) | $($r.verdict) | $($r.protocol) | $($r.domain_smoke) | $($r.last_verified) | $err |")
}

[System.IO.File]::WriteAllText($MdPath, $sb.ToString())
Write-Output "Wrote $JsonPath and $MdPath"
