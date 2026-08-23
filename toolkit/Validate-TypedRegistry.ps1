[CmdletBinding()]
param(
    [Parameter()]
    [string]$RegistryPath = '',

    [Parameter()]
    [string]$SchemaPath = '',

    [Parameter()]
    [switch]$Strict
)

$ErrorActionPreference = 'Stop'

if (-not $PSScriptRoot) { $PSScriptRoot = (Get-Item $MyInvocation.MyCommand.Path).DirectoryName }
$toolkitDir = (Resolve-Path $PSScriptRoot).Path
$repoRoot = (Resolve-Path (Join-Path $toolkitDir '..')).Path

if ([string]::IsNullOrWhiteSpace($RegistryPath)) { $RegistryPath = Join-Path (Join-Path $repoRoot 'configs') 'typed-registry.json' }
if ([string]::IsNullOrWhiteSpace($SchemaPath)) { $SchemaPath = Join-Path (Join-Path $repoRoot 'configs') 'typed-registry.schema.json' }

function Test-JsonEscaped {
    param([string]$Content)
    # Look for any backslash not followed by a valid JSON escape sequence.
    $invalid = [regex]::Matches($Content, '(?m)(?<!\\)\\(?![\\/"bfnrtu\d])')
    return $invalid.Count -eq 0
}

if (-not (Test-Path -LiteralPath $RegistryPath)) {
    throw "Registry not found: $RegistryPath"
}

$raw = [System.IO.File]::ReadAllText($RegistryPath)

$jsonError = $null
$data = $raw | ConvertFrom-Json -ErrorAction SilentlyContinue -ErrorVariable jsonError
if ($jsonError) {
    throw "typed-registry.json is not valid JSON: $jsonError"
}

if (-not (Test-JsonEscaped -Content $raw)) {
    throw "typed-registry.json contains invalid escape sequences. Run Repair-TypedRegistry.ps1"
}

$warnings = @()
if (Test-Path -LiteralPath $SchemaPath) {
    $schemaJson = [System.IO.File]::ReadAllText($SchemaPath) | ConvertFrom-Json
    # Best-effort structural checks for required fields; emit warnings unless -Strict.
    if (-not $data.version) { $warnings += 'Schema warning: missing top-level version' }
    if (-not $data.assets) { $warnings += 'Schema warning: missing top-level assets array' }
    foreach ($asset in $data.assets) {
        $assetId = if ($asset.PSObject.Properties.Name.Contains('id')) { $asset.id } else { '<unknown>' }
        @('id','display_name','asset_type','source','profiles','runtime','permissions','verification') | ForEach-Object {
            if (-not $asset.PSObject.Properties.Name.Contains($_)) {
                $warnings += "Schema warning: asset '$assetId' missing required field '$_'"
            }
        }
    }
}

if ($warnings.Count -gt 0) {
    $warnings | ForEach-Object { Write-Warning $_ }
    if ($Strict) { throw "Schema violations found ($($warnings.Count)). Use -Strict to fail, or fix the registry data." }
}

Write-Host "typed-registry.json is valid JSON with no bad escape sequences"
if ($warnings.Count -gt 0) {
    Write-Host "Schema warnings: $($warnings.Count) (run with -Strict to fail the gate)"
}
exit 0
