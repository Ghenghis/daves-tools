[CmdletBinding()]
param(
    [string]$SkillsPath = "C:\Users\Admin\CascadeProjects\daves-tools\audit-2026-08-19\daves-tools-e2e-audit-2026-08-19\recommended-skills.json",
    [string]$MatrixPath = "C:\Users\Admin\CascadeProjects\daves-tools\audit-2026-08-19\daves-tools-e2e-audit-2026-08-19\daves-tools-item-matrix.csv",
    [string]$OutPath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\SKILL-ROADMAP.md"
)

$ErrorActionPreference = "Stop"

$skills = [System.IO.File]::ReadAllText($SkillsPath) | ConvertFrom-Json
$matrix = Import-Csv -Path $MatrixPath

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# DAVE-AI Skill Roadmap")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("> This document is generated from the E2E audit ``recommended-skills.json`` and ``daves-tools-item-matrix.csv``. Run ``toolkit\Build-SkillRoadmap.ps1`` to regenerate.")
[void]$sb.AppendLine("")

$byPriority = @{ P0 = @(); P1 = @(); P2 = @() }
foreach ($s in $skills) { $byPriority[$s.priority] += $s }

foreach ($p in 'P0','P1','P2') {
    [void]$sb.AppendLine("## $p skills")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("| Skill | Purpose | Required tools | Proof |")
    [void]$sb.AppendLine("|---|---|---|---|")
    foreach ($s in $byPriority[$p]) {
        $tools = ($s.tools -join ', ')
        $proof = ($s.proof -join '; ')
        [void]$sb.AppendLine("| $($s.name) | $($s.purpose) | $tools | $proof |")
    }
    [void]$sb.AppendLine("")
}

[void]$sb.AppendLine("## Asset-to-skill mapping")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Asset | Class | Priority | Missing skills |")
[void]$sb.AppendLine("|---|---|---|---|")
foreach ($row in $matrix) {
    if ($row.missing_skills -and $row.missing_skills -ne '') {
        [void]$sb.AppendLine("| $($row.name) | $($row.actual_class) | $($row.priority) | $($row.missing_skills) |")
    }
}

[System.IO.File]::WriteAllText($OutPath, $sb.ToString())
Write-Output "Wrote $OutPath"
