[CmdletBinding()]
param(
    [string[]]$SearchPaths = @(),
    [switch]$Quiet
)

# Resolve default search paths defensively: $PSScriptRoot is null when this
# script is dot-sourced from a scope that didn't set it (e.g., Pester tests).
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Item $MyInvocation.MyCommand.Path).DirectoryName }
if (-not $SearchPaths -or $SearchPaths.Count -eq 0) {
    $SearchPaths = @("G:\private", "C:\Users\Admin\private", "$scriptRoot\..\private", "C:\Users\Admin")
}

$ErrorActionPreference = "SilentlyContinue"

$all = @()
foreach ($dir in $SearchPaths) {
    if (-not $dir -or -not (Test-Path -LiteralPath $dir)) { continue }
    $all += Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '.env*' }
}

$defaults = @{
    'PLAYWRIGHT_BROWSERS_PATH' = '0'
    'UV_PYTHON' = 'python'
}

$loaded = @{}
foreach ($k in $defaults.Keys) {
    [Environment]::SetEnvironmentVariable($k, $defaults[$k], 'Process')
    $loaded[$k] = '<default>'
}

$dpapiFiles = @()
foreach ($dir in $SearchPaths) {
    if (-not $dir) { continue }
    $candidate = Join-Path $dir '.env.dpapi.json'
    if (-not $candidate) { continue }
    if (Test-Path -LiteralPath $candidate) {
        $dpapiFiles += Get-Item -LiteralPath $candidate
    }
}
foreach ($file in $dpapiFiles | Sort-Object LastWriteTime -Descending) {
    try {
        Add-Type -AssemblyName System.Security
        $store = Get-Content $file.FullName -Raw | ConvertFrom-Json
        foreach ($prop in $store.values.PSObject.Properties) {
            $k = $prop.Name
            if (-not $loaded.ContainsKey($k)) {
                $cipher = [Convert]::FromBase64String($prop.Value)
                $plain = [System.Security.Cryptography.ProtectedData]::Unprotect(
                    $cipher, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
                $v = [System.Text.Encoding]::UTF8.GetString($plain)
                [Environment]::SetEnvironmentVariable($k, $v, 'Process')
                $loaded[$k] = "$($file.FullName) (dpapi)"
            }
        }
    } catch {
        if (-not $Quiet) { Write-Warning "DPAPI store unreadable at $($file.FullName): $($_.Exception.Message)" }
    }
}

foreach ($file in $all | Sort-Object LastWriteTime -Descending) {
    Get-Content $file.FullName | ForEach-Object {
        $line = $_.Trim()
        if ($line -and !$line.StartsWith('#') -and $line.Contains('=')) {
            $k = $line.Split('=', 2)[0].Trim()
            $v = $line.Split('=', 2)[1].Trim()
            $v = $v -replace '[\x22\x27]', ''
            if (-not $loaded.ContainsKey($k)) {
                [Environment]::SetEnvironmentVariable($k, $v, 'Process')
                $loaded[$k] = $file.FullName
            }

            $aliases = @{
                'GITHUB_TOKEN' = 'GITHUB_PERSONAL_ACCESS_TOKEN'
                'GH_TOKEN' = 'GITHUB_PERSONAL_ACCESS_TOKEN'
                'GITLAB_TOKEN' = 'GITLAB_PERSONAL_ACCESS_TOKEN'
                'GL_TOKEN' = 'GITLAB_PERSONAL_ACCESS_TOKEN'
            }
            foreach ($from in $aliases.Keys) {
                if ($k -ieq $from -and -not $loaded.ContainsKey($aliases[$from])) {
                    [Environment]::SetEnvironmentVariable($aliases[$from], $v, 'Process')
                    $loaded[$aliases[$from]] = $file.FullName
                }
            }
        }
    }
}

if (-not $Quiet) {
    Write-Output "Loaded $($loaded.Count) unique env vars from G:\private (newest wins)"
}
