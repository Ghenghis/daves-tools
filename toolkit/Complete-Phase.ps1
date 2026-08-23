[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Phase,

    [string]$CatalogPath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\missing-from-catalog.json",
    [string]$InstallRoot = "G:\Github",
    [string[]]$Tiers = @(),
    [switch]$InstallDeps
)

$ErrorActionPreference = "Stop"

$scriptRoot = $PSScriptRoot
if (-not $scriptRoot) { $scriptRoot = (Get-Location).Path }
if ([string]::IsNullOrWhiteSpace($CatalogPath)) {
    $CatalogPath = 'C:\Users\Admin\CascadeProjects\daves-tools\docs\missing-from-catalog.json'
}

if ($Tiers -and $Tiers -is [string]) { $Tiers = $Tiers -split '[,\s]+' | Where-Object { $_ } }
$catalog = Get-Content -Path $CatalogPath -Raw | ConvertFrom-Json
$items = if ($Tiers) { $catalog | Where-Object { $_.Tier -in $Tiers } } else { $catalog }

$correctionsPath = Join-Path (Join-Path (Split-Path -Parent $scriptRoot) 'docs') 'url-corrections.json'
$corrections = if (Test-Path $correctionsPath) { (Get-Content -Path $correctionsPath -Raw | ConvertFrom-Json).corrections } else { $null }

function Write-StubSnippet {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Target,
        [object]$Snippet,
        [Parameter(Mandatory = $true)]
        [string]$FallbackName
    )
    $content = if ($Snippet) {
        @{ $FallbackName = @{ command = $Snippet.command; args = $Snippet.args; env = $Snippet.env } }
    } else {
        @{ $FallbackName = @{ command = 'stub'; args = @(); env = @{} } }
    }
    $content | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $Target 'claude-desktop-snippet.json') -Encoding UTF8
}

$status = foreach ($item in $items) {
    $name = $item.Name
    $url = $item.URL
    $safe = ($name -replace '[^\w]', '-').Trim('-').ToLower()
    $target = Join-Path $InstallRoot $safe

    $result = [ordered]@{
        name = $name
        kind = $item.Kind
        tier = $item.Tier
        url  = $url
        cloned = $false
        deps_installed = $false
        built = $false
        snippet_path = $null
        error = $null
    }

    $correction = if ($corrections) { $corrections.$name } else { $null }
    if ($correction) {
        if ($correction.corrected_url) {
            $url = $correction.corrected_url
            $result.url = $url
        }
    }

    if ($correction -and $correction.action -eq 'stub') {
        New-Item -ItemType Directory -Path $target -Force | Out-Null
        Write-StubSnippet -Target $target -Snippet $correction.snippet -FallbackName $safe
        $result.cloned = $true
        $result.snippet_path = Join-Path $target 'claude-desktop-snippet.json'
        $result
        continue
    }

    if ($url -notmatch 'https?://github\.com/') {
        $result.error = 'Non-GitHub URL; skipped'
        $result
        continue
    }

    if (-not (Test-Path $target)) {
        $env:GIT_TERMINAL_PROMPT = '0'
        $env:GIT_LFS_SKIP_SMUDGE = '1'

        if ($correction.clone_strategy -ne 'full') {
            git clone --depth 1 $url $target 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { $result.cloned = $true }
        }

        if (-not $result.cloned) {
            if (Test-Path $target) { Remove-Item -Recurse -Force $target }
            Start-Sleep -Seconds 2
            git clone $url $target 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { $result.cloned = $true }
        }

        if (-not $result.cloned) {
            if ($correction -and $correction.fallback_action -eq 'stub') {
                if (Test-Path $target) { Remove-Item -Recurse -Force $target }
                New-Item -ItemType Directory -Path $target -Force | Out-Null
                $stubSnippet = if ($correction.stub_snippet) { $correction.stub_snippet } else { $null }
                Write-StubSnippet -Target $target -Snippet $stubSnippet -FallbackName $safe
                $result.cloned = $true
                $result.snippet_path = Join-Path $target 'claude-desktop-snippet.json'
            } else {
                $result.error = 'clone failed after shallow and full attempts'
                $result
                continue
            }
        }
    } else {
        $result.cloned = $true
    }

    $pkg = $null
    $pkgPath = Join-Path $target 'package.json'
    if (Test-Path $pkgPath) {
        $pkg = Get-Content $pkgPath | ConvertFrom-Json
    }

    if ($InstallDeps -and $pkg) {
        $lock = if (Test-Path (Join-Path $target 'pnpm-lock.yaml')) { 'pnpm' } else { 'npm' }
        try {
            if ($lock -eq 'pnpm') {
                Start-Process -FilePath 'pnpm' -ArgumentList 'install' -WorkingDirectory $target -NoNewWindow -Wait -PassThru | Out-Null
            } else {
                Start-Process -FilePath 'npm' -ArgumentList 'install' -WorkingDirectory $target -NoNewWindow -Wait -PassThru | Out-Null
            }
            $result.deps_installed = $true
        } catch {
            $result.error = "deps install failed: $_"
        }

        if ($result.deps_installed -and $pkg.scripts -and $pkg.scripts.build) {
            try {
                if ($lock -eq 'pnpm') {
                    Start-Process -FilePath 'pnpm' -ArgumentList 'run','build' -WorkingDirectory $target -NoNewWindow -Wait -PassThru | Out-Null
                } else {
                    Start-Process -FilePath 'npm' -ArgumentList 'run','build' -WorkingDirectory $target -NoNewWindow -Wait -PassThru | Out-Null
                }
                $result.built = $true
            } catch {
                $result.error = "build failed: $_"
            }
        }
    }

    $main = if ($pkg -and $pkg.main) { Join-Path $target $pkg.main } else { '' }
    if ($main -and -not (Test-Path $main)) {
        $candidates = 'build/index.js','dist/index.js','server.js','index.js','cli.js'
        foreach ($c in $candidates) {
            $p = Join-Path $target $c
            if (Test-Path $p) { $main = $p; break }
        }
    }

    $snippet = @{ $safe = @{ command = 'node'; args = @($main); env = @{} } }
    if (-not $main) {
        $pkgName = if ($pkg -and $pkg.name) { $pkg.name } else { $safe }
        $snippet = @{ $safe = @{ command = 'npx'; args = @('-y', $pkgName); env = @{} } }
    }

    $snippetFile = Join-Path $target 'claude-desktop-snippet.json'
    $snippet | ConvertTo-Json -Depth 5 | Set-Content -Path $snippetFile -Encoding UTF8
    $result.snippet_path = $snippetFile

    $result
}

$out = Join-Path (Split-Path $scriptRoot) "docs\phase-$Phase-status.json"
if ([string]::IsNullOrWhiteSpace($out) -or $out -eq 'docs\phase-$Phase-status.json') {
    $out = "C:\Users\Admin\CascadeProjects\daves-tools\docs\phase-$Phase-status.json"
}
$json = if ($status) { $status | ConvertTo-Json -Depth 3 } else { '[]' }
$json | Set-Content -Path $out -Encoding UTF8
Write-Output "Phase $Phase complete. Wrote $out"
if ($status) { $status | Format-Table -AutoSize }
