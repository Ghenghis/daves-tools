# Verifies a daves-tools release ZIP by extracting it into a scratch
# directory, then re-running the project's quality gates against the
# extracted bundle. Exits non-zero if any gate fails so CI can fail
# the build on a bad release.
#
# Gates:
#   - SHA256 (if a .sha256 sidecar exists next to the ZIP)
#   - Validate-TypedRegistry.ps1 against the bundled registry
#   - PSScriptAnalyzer on every bundled toolkit/*.ps1 (zero findings)
#   - Pester on both bundled test suites
#   - harness/package.json parses; scripts/*.ps1 entrypoints exist
#
# Usage:
#   powershell -File toolkit/Verify-Release.ps1 -ZipPath dist/daves-tools-v1.2.0.zip
#   powershell -File toolkit/Verify-Release.ps1 -ZipPath ... -ExtractRoot D:\verify -KeepExtract
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [string]$ZipPath,
    [string]$ExtractRoot = '',
    [switch]$KeepExtract
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ZipPath)) { throw "Zip not found: $ZipPath" }

if (-not $ExtractRoot) { $ExtractRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ("daves-tools-verify-" + [Guid]::NewGuid().ToString('N')) }
if (-not (Test-Path $ExtractRoot)) { New-Item -ItemType Directory -Path $ExtractRoot -Force | Out-Null }

Write-Output ("Verifying {0}" -f $ZipPath)
Write-Output ("Extract root: {0}" -f $ExtractRoot)

# 1. SHA256 (if sidecar present)
$shaPath = "$ZipPath.sha256"
if (Test-Path -LiteralPath $shaPath) {
    $expected = (Get-Content -LiteralPath $shaPath -Raw).Trim().Split(' ')[0].ToLower()
    $actual = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLower()
    if ($expected -ne $actual) {
        throw "SHA256 mismatch: expected $expected, got $actual"
    }
    Write-Output ("  [OK] SHA256: {0}" -f $actual)
} else {
    Write-Output ("  [skip] no .sha256 sidecar at $shaPath")
}

# 2. Extract
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $ExtractRoot)

$bundleRoot = Get-ChildItem -Path $ExtractRoot -Directory | Select-Object -First 1
if (-not $bundleRoot) { throw "Extracted bundle has no top-level directory" }
Write-Output ("  [OK] extracted: {0}" -f $bundleRoot.FullName)

# 3. Validate-TypedRegistry
$regPath = Join-Path -Path $bundleRoot.FullName -ChildPath 'configs/typed-registry.json'
if (-not (Test-Path $regPath)) { throw "Bundle missing configs/typed-registry.json" }
$out = & (Join-Path -Path $bundleRoot.FullName -ChildPath 'toolkit/Validate-TypedRegistry.ps1') -RegistryPath $regPath 2>&1
$LASTEXITCODE = 0  # explicit exit code from script
if ($out -notmatch 'valid JSON with no bad escape sequences') {
    Write-Output $out
    throw "Validate-TypedRegistry failed against the bundled registry"
}
if ($out -match 'Schema warnings: [^0]') {
    Write-Output $out
    throw "Validate-TypedRegistry reported schema warnings"
}
Write-Output "  [OK] Validate-TypedRegistry: clean"

# 4. PSScriptAnalyzer on every bundled toolkit/*.ps1
Import-Module PSScriptAnalyzer -RequiredVersion 1.25.0 -Force
$findings = @()
$bundledScripts = Get-ChildItem -Path (Join-Path -Path $bundleRoot.FullName -ChildPath 'toolkit') -Filter *.ps1
foreach ($s in $bundledScripts) {
    $r = Invoke-ScriptAnalyzer -Path $s.FullName
    if ($r) { $findings += $r }
}
$blocking = $findings | Where-Object { $_.Severity -eq 'Warning' -or $_.Severity -eq 'Error' }
if ($blocking.Count -gt 0) {
    $blocking | Format-Table -AutoSize | Out-String | Write-Output
    throw "PSScriptAnalyzer returned $($blocking.Count) blocking finding(s) in the bundle"
}
Write-Output ("  [OK] PSScriptAnalyzer: {0} scripts analyzed, 0 blocking findings" -f $bundledScripts.Count)

# 5. Pester on both bundled suites
Import-Module Pester -RequiredVersion 6.1.0 -Force
$failed = 0
foreach ($pesterFile in @('Toolkit.Tests.ps1', 'Test-MiniMaxClientIntegrations.Tests.ps1')) {
    $path = Join-Path -Path $bundleRoot.FullName -ChildPath "toolkit/$pesterFile"
    if (-not (Test-Path $path)) { Write-Output ("  [skip] $pesterFile not in bundle"); continue }
    Write-Output ("  [run] $pesterFile")
    $r = Invoke-Pester -Path $path -Output Minimal -PassThru
    if ($r.FailedCount -gt 0) {
        Write-Output ("  [FAIL] {0} test(s) failed in {1}" -f $r.FailedCount, $pesterFile)
        $failed += $r.FailedCount
    } else {
        Write-Output ("  [OK] {0}/{1} tests passed in {2}" -f $r.PassedCount, $r.TotalCount, $pesterFile)
    }
}
if ($failed -gt 0) { throw "$failed Pester test(s) failed in the bundle" }

# 6. harness/package.json parses; entrypoints exist
$pkgPath = Join-Path -Path $bundleRoot.FullName -ChildPath 'harness/package.json'
$pkg = Get-Content -LiteralPath $pkgPath -Raw | ConvertFrom-Json
if (-not $pkg.name) { throw "harness/package.json missing name" }
if (-not $pkg.version) { throw "harness/package.json missing version" }
Write-Output ("  [OK] harness/package.json: {0}@{1}" -f $pkg.name, $pkg.version)

$requiredEntrypoints = @(
    'harness/index.js', 'harness/proxy.js', 'harness/certifier.js', 'harness/registry.js',
    'harness/watchdog.js', 'harness/supervisor.js',
    'toolkit/Install-DavesTools.ps1', 'toolkit/Install-McpService.ps1',
    'toolkit/Watch-LmStudio.ps1', 'toolkit/Certify-Mcps.ps1',
    'toolkit/Find-OpenPort.ps1', 'toolkit/Validate-TypedRegistry.ps1',
    'README.md', 'AGENTS.md', 'CHANGELOG.md'
)
foreach ($rel in $requiredEntrypoints) {
    $full = Join-Path -Path $bundleRoot.FullName -ChildPath $rel
    if (-not (Test-Path $full)) { throw "Bundle missing required entrypoint: $rel" }
}
Write-Output ("  [OK] {0} required entrypoints present" -f $requiredEntrypoints.Count)

# 7. Cleanup
if (-not $KeepExtract) {
    Remove-Item -Recurse -Force $ExtractRoot
    Write-Output ("Cleaned up extract: {0}" -f $ExtractRoot)
} else {
    Write-Output ("Kept extract: {0}" -f $ExtractRoot)
}

Write-Output ""
Write-Output ("VERIFIED: {0}" -f $ZipPath)
exit 0
