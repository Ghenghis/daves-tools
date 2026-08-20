[CmdletBinding()]
param(
    [string]$RegistryPath = "C:\Users\Admin\CascadeProjects\daves-tools\configs\typed-registry.json",
    [string]$JsonPath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\capability-report.json",
    [string]$MdPath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\CAPABILITY-REPORT.md",
    [string]$EnvLoader = "C:\Users\Admin\CascadeProjects\daves-tools\toolkit\Load-PrivateEnv.ps1"
)

$ErrorActionPreference = "Stop"

& $EnvLoader -Quiet

$raw = [System.IO.File]::ReadAllText($RegistryPath)
$raw = $raw -replace '^\uFEFF', ''
$reg = $raw | ConvertFrom-Json

function Test-CommandExists($cmd) {
    if ($cmd -eq 'none' -or !$cmd) { return $false }
    if ($cmd -match '^[a-zA-Z0-9_\-]+$') {
        return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
    }
    return (Test-Path $cmd)
}

function Get-RepairAction($a, $installOk, $envOk, $protoOk) {
    $actions = @()
    if (-not $installOk) {
        if ($a.asset_type -eq 'mcp_server') {
            $actions += "Install and pin the MCP server; verify command: $($a.runtime.command)"
        } else {
            $actions += "Install dependency: $($a.display_name)"
        }
    }
    if (-not $envOk) {
        $actions += "Set missing environment variables: $($missing -join ', ')"
    }
    if ($protoOk -ne 'passed' -and $a.asset_type -eq 'mcp_server') {
        $actions += "Run ``toolkit\Certify-Mcps.ps1`` for this server"
    }
    return $actions
}

$results = foreach ($a in $reg.assets) {
    $installOk = if ($a.runtime.transport -eq 'none') { $true } else { Test-CommandExists $a.runtime.command }
    $missingEnv = @()
    foreach ($e in $a.runtime.env_refs) {
        if ([Environment]::GetEnvironmentVariable($e) -eq $null) { $missingEnv += $e }
    }
    $envOk = $missingEnv.Count -eq 0
    $protoOk = $a.verification.protocol
    $actions = @()
    if (-not $installOk) { $actions += "Install: $($a.display_name)" }
    if (-not $envOk) { $actions += "Set env vars: $($missingEnv -join ', ')" }
    if ($protoOk -ne 'passed' -and $a.asset_type -eq 'mcp_server') { $actions += "Run certifier" }

    [ordered]@{
        id = $a.id
        display_name = $a.display_name
        asset_type = $a.asset_type
        install_ok = $installOk
        env_ok = $envOk
        missing_env = @($missingEnv)
        protocol_ok = $protoOk
        healthy = ($installOk -and $envOk -and ($protoOk -eq 'passed' -or $a.asset_type -ne 'mcp_server'))
        repair_actions = @($actions)
    }
}

$json = [ordered]@{
    timestamp = (Get-Date -Format 'o')
    total = $reg.assets.Count
    healthy = ($results | Where-Object { $_.healthy }).Count
    unhealthy = ($results | Where-Object { -not $_.healthy }).Count
    results = $results
}

[System.IO.File]::WriteAllText($JsonPath, ($json | ConvertTo-Json -Depth 5))

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# Capability Doctor Report")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("**Generated:** $($json.timestamp)**")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("- **Total:** $($json.total)")
[void]$sb.AppendLine("- **Healthy:** $($json.healthy)")
[void]$sb.AppendLine("- **Unhealthy:** $($json.unhealthy)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Unhealthy assets")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Asset | Type | Install | Env | Protocol | Repair |")
[void]$sb.AppendLine("|---|---|---|---|---|---|")
foreach ($r in ($results | Where-Object { -not $_.healthy } | Sort-Object display_name)) {
    $env = if ($r.env_ok) { 'OK' } else { 'missing ' + ($r.missing_env -join ', ') }
    $proto = $r.protocol_ok
    $repair = ($r.repair_actions -join '; ')
    [void]$sb.AppendLine("| $($r.display_name) | $($r.asset_type) | $($r.install_ok) | $env | $proto | $repair |")
}
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Healthy assets")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Asset | Type |")
[void]$sb.AppendLine("|---|---|")
foreach ($r in ($results | Where-Object { $_.healthy } | Sort-Object display_name)) {
    [void]$sb.AppendLine("| $($r.display_name) | $($r.asset_type) |")
}

[System.IO.File]::WriteAllText($MdPath, $sb.ToString())
Write-Output "Wrote $JsonPath and $MdPath"
