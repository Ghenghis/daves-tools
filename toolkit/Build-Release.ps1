# Packages a Windows-ready daves-tools release: a versioned ZIP containing
# only the source, configs, scripts, docs, and Node manifest. Excludes
# node_modules, logs, daemon binaries (re-installed by Install-McpService),
# audit snapshots, and agent-specific directories.
#
# Output:
#   dist/daves-tools-vX.Y.Z/                 staged source tree
#   dist/daves-tools-vX.Y.Z.zip              distributable ZIP
#   dist/daves-tools-vX.Y.Z.zip.sha256      SHA256 of the ZIP
#
# Usage:
#   powershell -File toolkit/Build-Release.ps1
#   powershell -File toolkit/Build-Release.ps1 -Version 1.2.0
#   powershell -File toolkit/Build-Release.ps1 -OutDir D:\artifacts -SkipVerify
[CmdletBinding()]
Param(
    [string]$Version = '',
    [string]$OutDir = '',
    [string]$RepoRoot = '',
    [switch]$SkipVerify
)

$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Item $MyInvocation.MyCommand.Path).DirectoryName }
    $RepoRoot = (Resolve-Path (Join-Path -Path $scriptRoot -ChildPath '..')).Path
}

# Resolve version: explicit -Version > latest git tag matching vX.Y.Z > harness/package.json
if (-not $Version) {
    $tag = git -C $RepoRoot tag --list 'v[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | Select-Object -First 1
    if ($tag) { $Version = $tag.Substring(1) }
    else {
        $pkg = Get-Content (Join-Path -Path $RepoRoot -ChildPath 'harness/package.json') -Raw | ConvertFrom-Json
        $Version = $pkg.version
    }
}

if (-not $OutDir) { $OutDir = Join-Path -Path $RepoRoot -ChildPath 'dist' }
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

$stage = Join-Path -Path $OutDir -ChildPath ("daves-tools-v{0}" -f $Version)
$zipPath = Join-Path -Path $OutDir -ChildPath ("daves-tools-v{0}.zip" -f $Version)
$shaPath = "$zipPath.sha256"

if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
New-Item -ItemType Directory -Path $stage -Force | Out-Null

# Items that are part of the release payload.
# Use robocopy for efficient mirror+exclude semantics on Windows.
$includes = @(
    @{ src = (Join-Path $RepoRoot 'toolkit');                dst = 'toolkit' },
    @{ src = (Join-Path $RepoRoot 'harness');                dst = 'harness' },
    @{ src = (Join-Path $RepoRoot 'configs');                dst = 'configs' },
    @{ src = (Join-Path $RepoRoot 'docs');                   dst = 'docs' },
    @{ src = (Join-Path $RepoRoot 'mcp-manager');            dst = 'mcp-manager' },
    @{ src = (Join-Path $RepoRoot 'skills');                 dst = 'skills' },
    @{ src = (Join-Path $RepoRoot 'README.md');              dst = 'README.md' },
    @{ src = (Join-Path $RepoRoot 'AGENTS.md');              dst = 'AGENTS.md' },
    @{ src = (Join-Path $RepoRoot 'CHANGELOG.md');           dst = 'CHANGELOG.md' },
    @{ src = (Join-Path $RepoRoot '.gitlab-ci.yml');         dst = '.gitlab-ci.yml' },
    @{ src = (Join-Path $RepoRoot '.gitignore');             dst = '.gitignore' }
)

# robocopy patterns to exclude everywhere. * is single-segment; ** is recursive wildcards.
# Each /XD is a directory exclude; /XF is a file exclude. We apply the same excludes to every copy.
$excludeDirs = @(
    'node_modules', 'daemon', 'logs', 'audit', '.git', '.devin', '.serena',
    '.venv', '.claude', '.github', '.idea', '.vscode', '__pycache__',
    'apktool_mcp_server_workspace', 'audit-2026-08-19', 'dist'
)
$excludeFiles = @(
    '*.log', '*.err', '*.bak', '*.bak-*', '*.tmp', '*.zip', '*.pyc',
    'audit-files.txt', 'harness-events.ndjson'
)

function Get-GitField {
    param([scriptblock]$Cmd)
    try {
        & $Cmd 2>$null | Out-String
    } catch {
        $null
    }
}

function Copy-ReleaseItem {
    param([hashtable]$Item)
    $src = $Item.src
    $dstRel = $Item.dst
    $dst = Join-Path -Path $stage -ChildPath $dstRel

    if (-not (Test-Path $src)) { Write-Output "skip (missing): $src"; return }

    if ((Get-Item $src).PSIsContainer) {
        if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
        # /MIR mirrors the source, /NJH /NJS /NC /NDL /NFL /NP quiet; /R:0 /W:0 no retry
        $robocopyArgs = @($src, $dst, '/MIR', '/NJH', '/NJS', '/NC', '/NDL', '/NFL', '/NP', '/R:0', '/W:0')
        if ($excludeDirs.Count -gt 0) {
            $robocopyArgs += @('/XD') + $excludeDirs
        }
        if ($excludeFiles.Count -gt 0) {
            $robocopyArgs += @('/XF') + $excludeFiles
        }
        robocopy @robocopyArgs | Out-Null
        if ($LASTEXITCODE -ge 8) { throw "robocopy failed for $src (exit $LASTEXITCODE)" }
    } else {
        $parent = Split-Path -Path $dst -Parent
        if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Copy-Item -LiteralPath $src -Destination $dst -Force
    }
}

foreach ($item in $includes) { Copy-ReleaseItem -Item $item }

# Append release manifest at the root of the bundle.
$manifest = [ordered]@{
    product = 'daves-tools'
    version = $Version
    built_at = (Get-Date).ToUniversalTime().ToString('o')
    built_by = $env:USERNAME
    host = $env:COMPUTERNAME
    commit = (Get-GitField { & git -C $RepoRoot rev-parse HEAD } )
    short_commit = (Get-GitField { & git -C $RepoRoot rev-parse --short HEAD } )
    tag = (Get-GitField { & git -C $RepoRoot describe --exact-match --tags HEAD } )
    repo_root = $RepoRoot
    bundle_root = 'daves-tools-v' + $Version
    install_instructions = @(
        '1. Extract the ZIP to a writable directory (e.g., C:\daves-tools).',
        '2. From an elevated PowerShell prompt: .\toolkit\Install-DavesTools.ps1',
        '   - Installs Node deps, certifies CORE profile, registers the Windows service.',
        '3. Optionally: .\toolkit\Install-McpService.ps1 and .\toolkit\Watch-LmStudio.ps1 -RegisterTask',
        '4. IDE wiring: .\toolkit\Install-IdeConfigs.ps1 (Claude Desktop / Codex / Kilo / Devin).',
        '5. Verify: .\toolkit\Validate-TypedRegistry.ps1; tests via Pester.'
    )
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path -Path $stage -ChildPath 'RELEASE.json') -Encoding UTF8

# Inject version into harness/package.json so end users can read it from the binary.
$pkgPath = Join-Path -Path $stage -ChildPath 'harness/package.json'
if (Test-Path $pkgPath) {
    $pkg = Get-Content -LiteralPath $pkgPath -Raw | ConvertFrom-Json
    $pkg.version = $Version
    $pkg | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $pkgPath -Encoding UTF8
}

# Build the ZIP. Use System.IO.Compression so we don't depend on Compress-Archive's quirks.
# Entries are stored under a single top-level directory (the bundle name) so the
# extracted tree always lives under one folder, matching GitHub release convention.
if (Test-Path $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$bundleName = Split-Path -Leaf $stage
$zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $files = Get-ChildItem -Path $stage -Recurse -File
    foreach ($f in $files) {
        $rel = $f.FullName.Substring($stage.Length).TrimStart('\', '/').Replace('\', '/')
        $entryName = "$bundleName/$rel"
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $f.FullName, $entryName, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally {
    $zip.Dispose()
}

# SHA256
$hash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash
"$hash  $(Split-Path -Leaf $zipPath)" | Set-Content -LiteralPath $shaPath -Encoding ASCII

$sizeMb = [Math]::Round((Get-Item $zipPath).Length / 1MB, 2)

Write-Output ("Built {0} ({1} MB)" -f $zipPath, $sizeMb)
Write-Output ("SHA256: {0}" -f $hash)
Write-Output ("SHA256 file: {0}" -f $shaPath)
Write-Output ("Manifest: {0}" -f (Join-Path -Path $stage -ChildPath 'RELEASE.json'))

if (-not $SkipVerify) {
    Write-Output ""
    Write-Output "=== Verifying bundle ==="
    $verifyRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ("daves-tools-verify-" + [Guid]::NewGuid().ToString('N'))
    try {
        & (Join-Path -Path $RepoRoot -ChildPath 'toolkit/Verify-Release.ps1') -ZipPath $zipPath -ExtractRoot $verifyRoot
        if ($LASTEXITCODE -ne 0) { throw "Verify-Release failed (exit $LASTEXITCODE)" }
    } finally {
        if (Test-Path $verifyRoot) { Remove-Item -Recurse -Force $verifyRoot -ErrorAction SilentlyContinue }
    }
}
