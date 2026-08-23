[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Idea,
    [string]$RegistryPath = "C:\Users\Admin\CascadeProjects\daves-tools\configs\typed-registry.json",
    [string]$DoctorPath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\capability-report.json",
    [string]$SummaryPath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\certification-summary.json",
    [string]$ProfilePath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\project-preflight.json"
)

$ErrorActionPreference = "SilentlyContinue"

& "C:\Users\Admin\CascadeProjects\daves-tools\toolkit\Load-PrivateEnv.ps1" -Quiet

$reg = [System.IO.File]::ReadAllText($RegistryPath) | ConvertFrom-Json
$doctor = if (Test-Path $DoctorPath) { [System.IO.File]::ReadAllText($DoctorPath) | ConvertFrom-Json } else { @{ results = @() } }
$cert = if (Test-Path $SummaryPath) { [System.IO.File]::ReadAllText($SummaryPath) | ConvertFrom-Json } else { @{ results = @() } }

$healthy = @()
foreach ($r in $doctor.results | Where-Object { $_.healthy -eq $true }) { $healthy += $r.id }

$certLookup = @{}
foreach ($c in $cert.results) { $certLookup[$c.id] = $c.verdict }

$keywords = $Idea.ToLower().Split(' ,.;:')
$profiles = @{
    'mobile-reverse' = @('android-mcp','android-mcp-lean','mobile-harness','maestro','maestro-mcp','appium-mcp','apktool-mcp','jadx-mcp-server','jadx-ai-mcp','ghidra-mcp-headless','ghidramcp-lauriewired','pyghidra-mcp','dnspyex','assetripper','cpp2il')
    'web-automation' = @('playwright-cli-skills','hermes3d-hermeskool-mcp','serena','browserbase','searxng-mcp','context7')
    'ai-core' = @('anthropic-skills','claude-plugins-official','superpowers','context7','hermes3d-hermeskool-mcp','playwright-cli-skills')
    'dev-sec' = @('trail-of-bits-skills','trail-of-bits-skills-curated','radare2','x64dbg','x64dbg-skills','x64dbg-automate-mcp','iaito','r2unity')
}

$best = 'ai-core'
$bestScore = 0
foreach ($p in $profiles.Keys) {
    $score = 0
    foreach ($k in $keywords) {
        if ($p -like "*$k*") { $score += 2 }
        foreach ($id in $profiles[$p]) {
            if ($id -like "*$k*") { $score += 1 }
        }
    }
    if ($score -gt $bestScore) { $bestScore = $score; $best = $p }
}

$desired = $profiles[$best]
$primary = $desired | Where-Object { $healthy -contains $_ -and $certLookup[$_] -ne 'failed' }
$fallback = $desired | Where-Object { ($healthy -notcontains $_) -or $certLookup[$_] -eq 'failed' }

$allHealthy = $reg.assets | Where-Object { $_.asset_type -in @('mcp_server','skill_pack') -and $healthy -contains $_.id -and $certLookup[$_.id] -ne 'failed' } | Select-Object -First 5
$fallback += $allHealthy.id | Where-Object { $primary -notcontains $_ }

$preflight = [ordered]@{
    timestamp = (Get-Date -Format 'o')
    idea = $Idea
    selected_profile = $best
    healthy_count = $healthy.Count
    primary = $primary
    fallback = ($fallback | Select-Object -Unique)
    profile_notes = @(
        "Primary cockpit uses healthy + non-failed assets from `$best` profile.",
        "Fallback list triggers automatically if a primary tool is unavailable.",
        "Load private env with toolkit\Load-PrivateEnv.ps1 before invoking MCPs."
    )
}

[System.IO.File]::WriteAllText($ProfilePath, ($preflight | ConvertTo-Json -Depth 3))
Write-Output "Wrote $ProfilePath"
Write-Output "Healthy assets: $($healthy.Count); Primary: $($primary.Count); Fallback: $(($preflight.fallback).Count)"
