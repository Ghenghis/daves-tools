# Audits scheduled tasks and PowerShell event logs for the source of an unexpected
# PowerShell popup. Each potentially slow operation runs in a background job with
# a hard timeout so the script never hangs indefinitely.
[CmdletBinding()]
Param(
    [string]$LogPath = 'logs/audit-powershell.txt',
    [int]$TimeoutSeconds = 20
)

$ErrorActionPreference = 'Continue'

if (-not [System.IO.Path]::IsPathRooted($LogPath)) {
    $LogPath = Join-Path (Split-Path $PSScriptRoot -Parent) $LogPath
}
$logDir = Split-Path $LogPath -Parent
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

$lines = New-Object System.Collections.Generic.List[string]

function Add-Section([string]$title) {
    $lines.Add('')
    $lines.Add('=== ' + $title + ' ===')
}

function Invoke-WithTimeout {
    param(
        [scriptblock]$Script,
        [int]$Seconds = $TimeoutSeconds,
        [string]$Label = 'operation'
    )
    $job = Start-Job -ScriptBlock $Script
    $done = Wait-Job -Job $job -Timeout $Seconds
    if (-not $done) {
        Stop-Job -Job $job -ErrorAction SilentlyContinue
        Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
        return @('[TIMEOUT] ' + $Label + ' did not finish within ' + $Seconds + 's')
    }
    $result = Receive-Job -Job $job -ErrorAction SilentlyContinue
    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
    if (-not $result) { return @('[EMPTY] ' + $Label + ' returned no results') }
    return $result
}

Write-Host ('Starting audit, timeout {0}s per step. Writing to {1}' -f $TimeoutSeconds, $LogPath)

Add-Section 'Scheduled tasks with non-Microsoft authors or dave/ai/mcp/comfy/lm paths'
$r = Invoke-WithTimeout -Label 'Get-ScheduledTask' -Script {
    Get-ScheduledTask -ErrorAction SilentlyContinue |
        Where-Object { ($_.Author -notmatch 'Microsoft|Windows') -or ($_.TaskPath -match 'dave|ai|mcp|comfy|lm') } |
        Select-Object TaskName, TaskPath, Author, State |
        Format-Table -AutoSize | Out-String -Width 200
}
$lines.Add(($r -join "`n"))
Write-Host 'Scheduled tasks: done'

Add-Section 'Running PowerShell/pwsh/cmd processes'
$r = Invoke-WithTimeout -Label 'Get-Process' -Script {
    Get-Process -Name 'powershell', 'pwsh', 'cmd' -ErrorAction SilentlyContinue |
        Select-Object Name, Id, StartTime, Path |
        Format-Table -AutoSize | Out-String -Width 200
}
$lines.Add(($r -join "`n"))
Write-Host 'Processes: done'

Add-Section 'PowerShell process command lines (WMI)'
$r = Invoke-WithTimeout -Label 'Win32_Process' -Script {
    Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match 'powershell|pwsh' } |
        Select-Object Name, ProcessId, CommandLine |
        Format-Table -AutoSize -Wrap | Out-String -Width 200
}
$lines.Add(($r -join "`n"))
Write-Host 'Command lines: done'

Add-Section 'PowerShell script block log (Operational, last 20, ID 4104)'
$r = Invoke-WithTimeout -Seconds ([Math]::Max($TimeoutSeconds, 30)) -Label 'Get-WinEvent Operational' -Script {
    try {
        Get-WinEvent -FilterHashtable @{LogName = 'Microsoft-Windows-PowerShell/Operational'; Id = 4104 } -MaxEvents 20 -ErrorAction Stop |
            Select-Object TimeCreated, Id, @{N = 'Text'; E = { $_.Message.Substring(0, [Math]::Min(200, $_.Message.Length)) } } |
            Format-Table -AutoSize -Wrap | Out-String -Width 200
    } catch {
        'No events found or access denied: ' + $_.Exception.Message
    }
}
$lines.Add(($r -join "`n"))
Write-Host 'Script block log: done'

Add-Section 'Windows PowerShell classic log (last 20)'
$r = Invoke-WithTimeout -Seconds ([Math]::Max($TimeoutSeconds, 30)) -Label 'Get-WinEvent classic' -Script {
    try {
        Get-WinEvent -LogName 'Windows PowerShell' -MaxEvents 20 -ErrorAction Stop |
            Select-Object TimeCreated, Id, @{N = 'Text'; E = { $_.Message.Substring(0, [Math]::Min(200, $_.Message.Length)) } } |
            Format-Table -AutoSize -Wrap | Out-String -Width 200
    } catch {
        'No events found or access denied: ' + $_.Exception.Message
    }
}
$lines.Add(($r -join "`n"))
Write-Host 'Classic log: done'

Add-Section 'Task Scheduler operational log (last 20 task runs)'
$r = Invoke-WithTimeout -Seconds ([Math]::Max($TimeoutSeconds, 30)) -Label 'Get-WinEvent TaskScheduler' -Script {
    try {
        Get-WinEvent -LogName 'Microsoft-Windows-TaskScheduler/Operational' -MaxEvents 20 -ErrorAction Stop |
            Select-Object TimeCreated, Id, @{N = 'Text'; E = { $_.Message.Substring(0, [Math]::Min(200, $_.Message.Length)) } } |
            Format-Table -AutoSize -Wrap | Out-String -Width 200
    } catch {
        'No events found or access denied: ' + $_.Exception.Message
    }
}
$lines.Add(($r -join "`n"))
Write-Host 'Task Scheduler log: done'

$lines | Out-File $LogPath -Encoding utf8
Write-Host ('Wrote ' + $LogPath)
