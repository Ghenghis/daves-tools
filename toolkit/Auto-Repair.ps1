[CmdletBinding()]
param(
    [string]$RegistryPath = "C:\Users\Admin\CascadeProjects\daves-tools\configs\typed-registry.json",
    [string]$DoctorPath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\capability-report.json",
    [string]$LogPath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\repair-log.json"
)

$ErrorActionPreference = "SilentlyContinue"
& "C:\Users\Admin\CascadeProjects\daves-tools\toolkit\Load-PrivateEnv.ps1" -Quiet

$reg = [System.IO.File]::ReadAllText($RegistryPath) | ConvertFrom-Json
$doctor = if (Test-Path $DoctorPath) { [System.IO.File]::ReadAllText($DoctorPath) | ConvertFrom-Json } else { @{ results = @() } }

$defaults = @{
    'UV_PYTHON' = 'python'
    'PLAYWRIGHT_BROWSERS_PATH' = '0'
}

$log = @()
foreach ($a in $doctor.results | Where-Object { $_.healthy -eq $false }) {
    $asset = $reg.assets | Where-Object { $_.id -eq $a.id } | Select-Object -First 1
    $result = [ordered]@{ id = $a.id; actions = @(); before = $a.healthy }

    foreach ($missing in $a.missing_env) {
        $val = [Environment]::GetEnvironmentVariable($missing)
        if (-not $val) { $val = $defaults[$missing] }
        if (-not $val) {
            foreach ($f in Get-ChildItem 'G:\private' -File | Where-Object { $_.Name -like '*env*' }) {
                $found = Get-Content $f.FullName | Where-Object { $_ -match "^$([regex]::Escape($missing))\s*=" }
                if ($found) { $val = ($found -split '=', 2)[1].Trim(); break }
            }
        }
        if ($val) {
            [Environment]::SetEnvironmentVariable($missing, $val, 'Process')
            $result.actions += "Set $missing"
        } else {
            $result.actions += "Missing $missing not found"
        }
    }

    if ($asset -and $asset.asset_type -eq 'mcp_server' -and $a.protocol_ok -ne 'passed') {
        $cert = & node "C:\Users\Admin\CascadeProjects\daves-tools\harness\certify-asset.js" $a.id "$RegistryPath" 2>&1
        $last = $cert[-1]
        if ($last -and $last -match '"verdict"\s*:\s*"([^"]+)"') {
            $v = $matches[1]
            $result.actions += "Certified: $v"
        } else {
            $result.actions += "Certify output unreadable"
        }
    }

    $log += $result
}

[System.IO.File]::WriteAllText($LogPath, ($log | ConvertTo-Json -Depth 3))
Write-Output "Wrote $LogPath"
