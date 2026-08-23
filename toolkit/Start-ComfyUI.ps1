# Starts ComfyUI with automatic port shifting. If the preferred port is busy
# or reserved for another known service, it walks forward to the next free
# port and records the chosen port in configs/service-ports.json so other
# tools (LM Studio watchdog, MCP harness, docs) can discover it live.
[CmdletBinding()]
Param(
    [string]$ComfyUIPath = 'S:\ComfyUI',
    [int]$PreferredPort = 8188,
    [string]$BindAddress = '0.0.0.0',
    [switch]$Cpu,
    [switch]$Foreground
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$logDir = Join-Path $repoRoot 'logs'
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

. (Join-Path $PSScriptRoot 'Find-OpenPort.ps1')

$port = Find-OpenPort -PreferredPort $PreferredPort -BindAddress $BindAddress -ServiceName 'comfyui'
Write-Output ("[Start-ComfyUI] Using port {0}" -f $port)

$servicePortsPath = Join-Path (Join-Path $repoRoot 'configs') 'service-ports.json'
$state = if (Test-Path $servicePortsPath) {
    Get-Content $servicePortsPath -Raw | ConvertFrom-Json
} else {
    New-Object PSObject
}
$entry = [PSCustomObject]@{
    port      = $port
    address   = $BindAddress
    url       = "http://127.0.0.1:$port"
    startedAt = (Get-Date -Format 'o')
    path      = $ComfyUIPath
}
if ($state.PSObject.Properties.Match('comfyui').Count -gt 0) {
    $state.comfyui = $entry
} else {
    $state | Add-Member -MemberType NoteProperty -Name 'comfyui' -Value $entry
}
($state | ConvertTo-Json -Depth 5) | Out-File $servicePortsPath -Encoding utf8

$logPath = Join-Path $logDir 'comfyui-server.log'
$argsList = @('main.py', '--listen', $BindAddress, '--port', $port)
if ($Cpu) { $argsList += '--cpu' }

Write-Output ("[Start-ComfyUI] Logging to {0}" -f $logPath)

if ($Foreground) {
    Set-Location $ComfyUIPath
    python @argsList
} else {
    Start-Process -FilePath 'python' -ArgumentList $argsList -WorkingDirectory $ComfyUIPath `
        -RedirectStandardOutput $logPath -RedirectStandardError "$logPath.err" -WindowStyle Hidden
    Write-Output ("[Start-ComfyUI] Started in background. GUI: http://127.0.0.1:{0}" -f $port)
}
