[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Idea,
    [string]$RegistryPath = "C:\Users\Admin\CascadeProjects\daves-tools\configs\typed-registry.json",
    [string]$ReportPath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\project-profile.json",
    [string]$MdPath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\PROJECT-PROFILE.md"
)

$ErrorActionPreference = "Stop"

$raw = [System.IO.File]::ReadAllText($RegistryPath)
$raw = $raw -replace '^\uFEFF', ''
$reg = $raw | ConvertFrom-Json

$lower = $Idea.ToLower()
$words = $lower -split '\W+' | Where-Object { $_ }

function Score-Overlap($source) {
    $sourceWords = $source.ToLower() -split '\W+' | Where-Object { $_ }
    $score = 0
    foreach ($w in $words) {
        if ($sourceWords -contains $w) { $score += 1 }
    }
    return $score
}

$profileScores = @{}
foreach ($a in $reg.assets) {
    $nameScore = Score-Overlap $a.display_name
    foreach ($p in $a.profiles) {
        $score = Score-Overlap $p
        if ($score -gt 0) { $profileScores[$p] += $score }
    }
    foreach ($c in $a.capabilities) {
        $score = Score-Overlap $c
        if ($score -gt 0) {
            foreach ($p in $a.profiles) { $profileScores[$p] += $score * 0.5 }
        }
    }
    if ($nameScore -gt 0) {
        foreach ($p in $a.profiles) { $profileScores[$p] += $nameScore * 0.5 }
    }
}

$selectedProfile = if ($profileScores.Count -gt 0) {
    ($profileScores.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Key
} else {
    'CORE'
}

$risks = @()
if ($lower -match 'reverse engineering|re|patch|modify') { $risks += 'requires authorized scope gate and clean-room boundaries' }
if ($lower -match 'android|mobile|apk') { $risks += 'device state and network isolation required' }
if ($lower -match 'windows|winui|msix|signing') { $risks += 'certificate custody and signing policy required' }
if ($lower -match 'deploy|infra|cloudflare|vps|docker') { $risks += 'deployment rollback and secret management required' }
if ($lower -match 'game|unity|unreal|godot') { $risks += 'asset provenance and playtest reproducibility required' }
if ($risks.Count -eq 0) { $risks += 'standard read-only verification before mutations' }

$selectedAssets = $reg.assets | Where-Object { $_.profiles -contains $selectedProfile }
$toolAllowlist = $selectedAssets | Where-Object { $_.asset_type -eq 'mcp_server' } | Select-Object -ExpandProperty display_name
$skillAllowlist = $selectedAssets | Where-Object { $_.asset_type -eq 'skill_pack' } | Select-Object -ExpandProperty display_name
$depAllowlist = $selectedAssets | Where-Object { $_.asset_type -in 'cli_dependency','gui_dependency','service' } | Select-Object -ExpandProperty display_name

$report = [ordered]@{
    idea = $Idea
    profile = $selectedProfile
    tool_allowlist = @($toolAllowlist)
    skill_allowlist = @($skillAllowlist)
    dependency_allowlist = @($depAllowlist)
    risks = @($risks)
    acceptance_gates = @(
        'source/provenance verified',
        'install and protocol certification passed',
        'domain smoke test completed',
        'failure/recovery demonstrated',
        'HermesProof evidence recorded'
    )
    timestamp = (Get-Date -Format 'o')
}

[System.IO.File]::WriteAllText($ReportPath, ($report | ConvertTo-Json -Depth 5))

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# Project Profile")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("**Idea:** $($Idea)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("**Selected profile:** ``$selectedProfile``")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Tool allowlist")
[void]$sb.AppendLine("")
foreach ($t in $toolAllowlist) { [void]$sb.AppendLine("- $t") }
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Skill allowlist")
[void]$sb.AppendLine("")
foreach ($s in $skillAllowlist) { [void]$sb.AppendLine("- $s") }
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Dependencies")
[void]$sb.AppendLine("")
foreach ($d in $depAllowlist) { [void]$sb.AppendLine("- $d") }
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Risks")
[void]$sb.AppendLine("")
foreach ($r in $risks) { [void]$sb.AppendLine("- $r") }
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Acceptance gates")
[void]$sb.AppendLine("")
foreach ($g in $report.acceptance_gates) { [void]$sb.AppendLine("- $g") }

[System.IO.File]::WriteAllText($MdPath, $sb.ToString())
Write-Output "Wrote $ReportPath and $MdPath (profile: $selectedProfile)"
