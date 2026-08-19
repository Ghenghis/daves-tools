[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('install','update','start','stop','uninstall','rollback')]
    [string]$Action,
    [Parameter(Mandatory)]
    [string]$AssetId,
    [string]$RegistryPath = "C:\Users\Admin\CascadeProjects\daves-tools\configs\typed-registry.json",
    [string]$InstallRoot = "C:\Users\Admin\Github"
)

$ErrorActionPreference = "Stop"

$raw = [System.IO.File]::ReadAllText($RegistryPath)
$raw = $raw -replace '^\uFEFF', ''
$reg = $raw | ConvertFrom-Json

$asset = $reg.assets | Where-Object { $_.id -eq $AssetId } | Select-Object -First 1
if (-not $asset) { throw "Asset $AssetId not found in registry" }

$dir = Join-Path $InstallRoot $asset.id
$backup = $dir + ".bak"
$log = [System.Collections.ArrayList]@()

function Write-Log($msg) {
    $log.Add($msg) | Out-Null
    Write-Output $msg
}

if ($Action -eq 'install') {
    if (Test-Path $dir) { throw "Install directory already exists: $dir" }
    New-Item -ItemType Directory -Path $dir | Out-Null
    if ($asset.source.url) {
        $url = $asset.source.url
        if ($url -match 'github.com/([^/]+/[^/]+)') {
            $repo = $matches[1]
            git clone --depth 1 --single-branch --branch $asset.source.ref "https://github.com/$repo.git" $dir
        } else {
            Write-Log "Non-GitHub source; manual install required: $url"
        }
    } else {
        Write-Log "No source URL"
    }
    $asset.verification.install = 'passed'
    $asset.verification.last_verified = (Get-Date -Format 'o')
    Write-Log "Installed $AssetId to $dir"
}

if ($Action -eq 'update') {
    if (Test-Path $dir) {
        if (Test-Path .git) {
            git -C $dir pull
        } else {
            Write-Log "No git history; cannot update. Reinstall."
        }
    } else {
        Write-Log "Not installed; run install first"
    }
    $asset.verification.last_verified = (Get-Date -Format 'o')
}

if ($Action -eq 'uninstall') {
    if (Test-Path $dir) {
        Remove-Item -Recurse -Force $dir
        Write-Log "Removed $dir"
    } else {
        Write-Log "Not installed"
    }
    $asset.verification.install = 'unknown'
}

if ($Action -eq 'rollback') {
    if (Test-Path $backup) {
        if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }
        Rename-Item $backup $dir
        Write-Log "Restored $AssetId from backup"
    } else {
        Write-Log "No backup available"
    }
}

if ($Action -eq 'start') {
    if ($asset.runtime.transport -eq 'none') {
        Write-Log "$AssetId is not an MCP server"
    } else {
        Write-Log "Use harness\index.js or node harness\certify-asset.js $AssetId to start"
    }
}

if ($Action -eq 'stop') {
    Write-Log "Use harness\index.js disable_mcp to stop"
}

# Write back updated registry
[System.IO.File]::WriteAllText($RegistryPath, ($reg | ConvertTo-Json -Depth 5))

$report = [ordered]@{
    action = $Action
    asset_id = $AssetId
    display_name = $asset.display_name
    install_dir = $dir
    log = $log
    timestamp = (Get-Date -Format 'o')
}
$out = "C:\Users\Admin\CascadeProjects\daves-tools\docs\tool-lifecycle-$AssetId-$Action.json"
[System.IO.File]::WriteAllText($out, ($report | ConvertTo-Json -Depth 3))
Write-Output "Wrote $out"
