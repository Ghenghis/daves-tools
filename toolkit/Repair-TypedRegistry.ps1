[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [string]$RegistryPath = '',

    [Parameter()]
    [string]$SchemaPath = '',

    [Parameter()]
    [string]$BackupDir = ''
)

$ErrorActionPreference = 'Stop'

if (-not $PSScriptRoot) { $PSScriptRoot = (Get-Item $MyInvocation.MyCommand.Path).DirectoryName }
$toolkitDir = (Resolve-Path $PSScriptRoot).Path
$repoRoot = (Resolve-Path (Join-Path $toolkitDir '..')).Path

if ([string]::IsNullOrWhiteSpace($RegistryPath)) { $RegistryPath = Join-Path (Join-Path $repoRoot 'configs') 'typed-registry.json' }
if ([string]::IsNullOrWhiteSpace($SchemaPath)) { $SchemaPath = Join-Path (Join-Path $repoRoot 'configs') 'typed-registry.schema.json' }
if ([string]::IsNullOrWhiteSpace($BackupDir)) { $BackupDir = Join-Path $repoRoot 'logs' }

$RegistryPath = (Resolve-Path $RegistryPath).Path
$BackupDir = (Resolve-Path $BackupDir -ErrorAction SilentlyContinue).Path

function Write-RepairedFile {
    param([string]$Path, [string]$Content)
    $temp = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($temp, $Content, [System.Text.UTF8Encoding]::new($false))
    # Write to a temp file first to avoid corrupting the original on encoding/IO failure.
    [System.IO.File]::Delete($Path)
    [System.IO.File]::Move($temp, $Path)
}

if (-not $BackupDir) {
    $BackupDir = Join-Path (Split-Path -Parent $RegistryPath) 'logs'
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

$backupFile = Join-Path $BackupDir ("typed-registry-backup-{0:yyyyMMddTHHmmss}.json" -f (Get-Date).ToUniversalTime())
Copy-Item -LiteralPath $RegistryPath -Destination $backupFile -Force
Write-Host "Backup: $backupFile"

$raw = [System.IO.File]::ReadAllText($RegistryPath, [System.Text.UTF8Encoding]::new($true))

# Escape any backslash that is not part of a valid JSON escape sequence.
$validEscapes = '[\\/"bfnrtu]'
$repaired = [regex]::Replace($raw, '(?m)(?<!\\)\\(?!' + $validEscapes + ')', { param($m) '\\' + $m.Value.Substring(1) })

if ($raw -ne $repaired) {
    Write-Host "Repaired invalid JSON escapes in $RegistryPath"
    if ($PSCmdlet.ShouldProcess($RegistryPath, 'write repaired JSON')) {
        Write-RepairedFile -Path $RegistryPath -Content $repaired
    }
}
else {
    Write-Host "No invalid JSON escapes found in $RegistryPath"
}

& (Join-Path $PSScriptRoot 'Validate-TypedRegistry.ps1') -RegistryPath $RegistryPath -SchemaPath $SchemaPath
