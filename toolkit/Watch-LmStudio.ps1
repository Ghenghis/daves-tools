[CmdletBinding()]
Param(
    [switch]$RegisterTask,
    [switch]$UnregisterTask,
    [string]$ConfigPath
)

$ErrorActionPreference = 'Stop'

if (-not $ConfigPath) {
    $ConfigPath = Join-Path $PSScriptRoot '..' 'configs' 'lmstudio-watchdog.json'
}

$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$logPath = $config.logPath
if (-not [System.IO.Path]::IsPathRooted($logPath)) {
    $logPath = Join-Path $PSScriptRoot '..' $logPath | Resolve-Path
}

function Write-Log($message) {
    $line = '{0} {1}' -f (Get-Date -Format 'o'), $message
    $dir = Split-Path $logPath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Add-Content -Path $logPath -Value $line
    if ($Host.Name -ne 'ServerRemoteHost') { Write-Host $line }
}

function Find-LmStudioExe {
    $paths = @(
        $config.exe,
        (Join-Path $env:LOCALAPPDATA 'LM-Studio' 'LM Studio.exe'),
        (Join-Path $env:LOCALAPPDATA 'LM-Studio' 'app-0*' 'LM Studio.exe'),
        (Join-Path $env:ProgramFiles 'LM-Studio' 'LM Studio.exe')
    )
    foreach ($p in $paths) {
        if ($p -and (Test-Path $p)) { return $p }
    }
    $found = Get-ChildItem -Path $env:LOCALAPPDATA -Filter 'LM Studio.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
    if ($found) { return $found }
    throw 'Could not find LM Studio.exe. Set config.exe to the full path.'
}

function Test-LmStudioAlive {
    try {
        $r = Invoke-RestMethod -Uri $config.url -Method GET -TimeoutSec 10 -ErrorAction Stop
        return $r -ne $null
    } catch {
        return $false
    }
}

function Stop-LmStudioProcess {
    Get-Process | Where-Object { $_.Name -like '*LM Studio*' -or $_.Path -like '*LM-Studio*' } | ForEach-Object {
        Write-Log ('Stopping PID {0}' -f $_.Id)
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 2
}

function Start-LmStudioProcess {
    $exe = Find-LmStudioExe
    Write-Log ('Starting {0}' -f $exe)
    if ($config.startArgs -and $config.startArgs.Count -gt 0) {
        Start-Process -FilePath $exe -ArgumentList $config.startArgs -WindowStyle Hidden
    } else {
        Start-Process -FilePath $exe -WindowStyle Hidden
    }
}

function Wait-ForAlive {
    $max = [math]::Round(120 / 5)
    for ($i = 0; $i -lt $max; $i++) {
        Start-Sleep -Seconds 5
        if (Test-LmStudioAlive) { return $true }
    }
    return $false
}

if ($RegisterTask) {
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ('-WindowStyle Hidden -ExecutionPolicy Bypass -File "{0}"' -f (Join-Path $PSScriptRoot 'Watch-LmStudio.ps1'))
    $trigger = New-ScheduledTaskTrigger -AtLogon
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    Register-ScheduledTask -TaskName 'DAVE-AI LM Studio Watchdog' -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force
    Write-Log 'Registered scheduled task DAVE-AI LM Studio Watchdog'
    return
}

if ($UnregisterTask) {
    Unregister-ScheduledTask -TaskName 'DAVE-AI LM Studio Watchdog' -Confirm:$false
    Write-Log 'Unregistered scheduled task'
    return
}

$failures = 0
Write-Log 'LM Studio watchdog started'

while ($true) {
    if (Test-LmStudioAlive) {
        if ($failures -gt 0) {
            Write-Log 'LM Studio is reachable again'
            $failures = 0
        }
    } else {
        $failures++
        Write-Log ('LM Studio unreachable. Failure {0} of {1}' -f $failures, $config.retries)
        if ($failures -ge $config.retries) {
            Write-Log 'Restart threshold reached. Restarting LM Studio.'
            Stop-LmStudioProcess
            Start-Sleep -Seconds $config.restartDelay
            Start-LmStudioProcess
            if (Wait-ForAlive) {
                Write-Log 'LM Studio is back. LM Link should auto-reconnect.'
            } else {
                Write-Log 'LM Studio did not come back after restart.'
            }
            $failures = 0
        }
    }
    Start-Sleep -Seconds $config.interval
}