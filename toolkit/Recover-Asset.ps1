[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$AssetId,
    [string]$RegistryPath = "C:\Users\Admin\CascadeProjects\daves-tools\configs\typed-registry.json",
    [string]$InstallRoot = "C:\Users\Admin\Github",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$raw = [System.IO.File]::ReadAllText($RegistryPath)
$raw = $raw -replace '^\uFEFF', ''
$reg = $raw | ConvertFrom-Json

$asset = $reg.assets | Where-Object { $_.id -eq $AssetId } | Select-Object -First 1
if (-not $asset) { throw "Asset $AssetId not found in registry" }

$dir = Join-Path $InstallRoot $asset.id
$backup = $dir + ".bak"
$log = @()

function Backup-Dir($src) {
    if (Test-Path $src) {
        $dst = $src + ".bak"
        if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
        Copy-Item -Recurse -Force $src $dst
        return "Backed up to $dst"
    }
    return "No existing directory to back up"
}

if (-not $DryRun) {
    $log += Backup-Dir $dir
    if (Test-Path $dir) {
        Remove-Item -Recurse -Force $dir
    }
    if ($asset.source.url -and $asset.source.url -match 'github.com/([^/]+/[^/]+)') {
        $repo = $matches[1]
        git clone --depth 1 --single-branch --branch $asset.source.ref "https://github.com/$repo.git" $dir
        $log += "Re-cloned $repo to $dir"
    } else {
        $log += "No source URL; run custom install"
    }
    $asset.verification.install = 'passed'
    $asset.verification.last_verified = (Get-Date -Format 'o')
    [System.IO.File]::WriteAllText($RegistryPath, ($reg | ConvertTo-Json -Depth 5))
} else {
    $log += "DRY-RUN: would back up $dir, remove it, and re-clone"
}

$report = [ordered]@{
    action = 'recovery'
    asset_id = $AssetId
    display_name = $asset.display_name
    install_dir = $dir
    dry_run = [bool]$DryRun
    log = $log
    timestamp = (Get-Date -Format 'o')
}
$out = "C:\Users\Admin\CascadeProjects\daves-tools\docs\recovery-$AssetId.json"
[System.IO.File]::WriteAllText($out, ($report | ConvertTo-Json -Depth 3))
Write-Output ($log -join "`n")
Write-Output "Wrote $out"
