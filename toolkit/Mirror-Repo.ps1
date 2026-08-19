[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$AssetId,
    [string]$RegistryPath = "C:\Users\Admin\CascadeProjects\daves-tools\configs\typed-registry.json",
    [string]$MirrorRoot = "C:\Users\Admin\CascadeProjects\daves-tools-mirror"
)

$ErrorActionPreference = "Stop"

$raw = [System.IO.File]::ReadAllText($RegistryPath)
$raw = $raw -replace '^\uFEFF', ''
$reg = $raw | ConvertFrom-Json

$asset = $reg.assets | Where-Object { $_.id -eq $AssetId } | Select-Object -First 1
if (-not $asset) { throw "Asset $AssetId not found" }

if (-not ($asset.source.url -and $asset.source.url -match 'github.com/([^/]+/[^/]+)')) {
    throw "Source is not a GitHub repo"
}

$repo = $matches[1]
$dir = Join-Path $MirrorRoot $asset.id
$log = @()

if (-not (Test-Path $MirrorRoot)) { New-Item -ItemType Directory -Path $MirrorRoot | Out-Null }
if (Test-Path $dir) {
    git -C $dir remote update
    git -C $dir fetch --all
    $log += "Updated mirror at $dir"
} else {
    git clone --mirror "https://github.com/$repo.git" $dir
    $log += "Created mirror at $dir"
}

$asset.artifacts.repo_mirror = $dir
$asset.artifacts.last_mirror = (Get-Date -Format 'o')
[System.IO.File]::WriteAllText($RegistryPath, ($reg | ConvertTo-Json -Depth 5))

$report = [ordered]@{
    action = 'mirror'
    asset_id = $AssetId
    repo = $repo
    mirror_path = $dir
    log = $log
    timestamp = (Get-Date -Format 'o')
}
$out = "C:\Users\Admin\CascadeProjects\daves-tools\docs\mirror-$AssetId.json"
[System.IO.File]::WriteAllText($out, ($report | ConvertTo-Json -Depth 3))
Write-Output ($log -join "`n")
Write-Output "Wrote $out"
