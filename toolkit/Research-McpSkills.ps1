[CmdletBinding()]
param(
    [string]$CatalogPath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\missing-from-catalog.json",
    [string]$InstallRoot = "G:\Github",
    [string]$OutJson = "C:\Users\Admin\CascadeProjects\daves-tools\docs\mcp-missing-skills.json",
    [string]$OutMd = "C:\Users\Admin\CascadeProjects\daves-tools\docs\MCP-MISSING-SKILLS.md"
)

$ErrorActionPreference = "Stop"

$raw = [System.IO.File]::ReadAllText($CatalogPath)
$raw = $raw -replace '^\uFEFF', ''
$catalog = $raw | ConvertFrom-Json

$skillTaxonomy = @{
    'CORE' = @(
        'semantic-code-search', 'code-navigation', 'code-editing', 'multi-file-refactor',
        'skill-creator', 'prompt-template-library', 'plugin-marketplace-browse',
        'workflow-orchestration', 'tdd-enforcement', 'test-generation'
    )
    'RESEARCH' = @(
        'web-search', 'code-search', 'library-docs-lookup', 'arxiv-paper-search',
        'current-events-search', 'multi-source-synthesis', 'citation-extraction'
    )
    'REPO' = @(
        'repo-list', 'issue-create', 'issue-read', 'pr-create', 'pr-review',
        'pr-merge', 'commit-list', 'branch-list', 'pipeline-status', 'release-notes'
    )
    'REVIEW' = @(
        'static-analysis', 'dependency-audit', 'security-scan', 'supply-chain-check',
        'second-opinion-review', 'vulnerability-triage', 'code-quality-report'
    )
    'ANDROID-DEV' = @(
        'adb-shell', 'device-list', 'install-apk', 'uninstall-apk', 'start-activity',
        'logcat-capture', 'screenshot-capture', 'ui-dump', 'gesture-automation',
        'appium-session', 'maestro-flow', 'benchmark-run'
    )
    'ANDROID-RE' = @(
        'decompile-apk', 'disassemble-dex', 'manifest-analysis', 'resource-extract',
        'certificate-inspect', 'api-call-trace', 'string-search', 'smali-edit',
        'jadx-decompile', 'apktool-rebuild', 'mobSF-scan'
    )
    'ANDROID-RE-DYNAMIC' = @(
        'frida-hook', 'runtime-trace', 'ssl-pinning-bypass', 'frida-script-library',
        'memory-dump', 'dynamic-instrumentation'
    )
    'ANDROID-EVAL' = @(
        'agent-benchmark', 'task-proposal', 'success-metric-calc', 'trajectory-log'
    )
    'MOBILE-AGENT' = @(
        'device-orchestration', 'task-delegation', 'agent-coordination',
        'result-aggregation', 'cross-platform-automation'
    )
    'WINDOWS-DEV' = @(
        'registry-read', 'service-control', 'event-log-read', 'process-list',
        'win32-api-call', 'com-automation', 'uwp-package-query', 'winget-search'
    )
    'WINDOWS-RE' = @(
        'pe-analysis', 'disassemble-x86', 'breakpoint-set', 'memory-read',
        'stack-trace', 'module-enumerate', 'symbol-resolve', 'patch-binary',
        'dbg-attach', 'winapi-hook', 'x64dbg-automation'
    )
    'UNITY-RE' = @(
        'il2cpp-dump', 'asset-extract', 'mono-assembly-decompile', 'shader-decompile',
        'scene-inspect', 'bundle-extract', 'script-metadata-recover', 'type-tree-dump'
    )
    'ISOLATED-LAB' = @(
        'vm-start', 'vm-stop', 'vm-snapshot', 'vm-restore', 'network-attach',
        'iso-mount', 'guest-command', 'hyper-v-control'
    )
    'WEB-E2E' = @(
        'browser-launch', 'page-navigate', 'element-click', 'form-fill', 'screenshot',
        'har-capture', 'console-log-capture', 'trace-export', 'mobile-emulation',
        'accessibility-audit', 'cross-browser-run'
    )
    'ON-DEMAND' = @(
        'marketplace-browse', 'skill-install', 'skill-uninstall', 'skill-search'
    )
}

$perServerResults = @()

foreach ($item in $catalog) {
    $name = $item.Name
    $safe = ($name -replace '[^\w]', '-').Trim('-').ToLower() -replace '-+', '-'
    $target = Join-Path $InstallRoot $safe
    $profiles = $item.Profile -split '[/,]' | ForEach-Object { $_.Trim() } | Where-Object { $_ }

    $currentSkills = @()
    if ($item.Kind) { $currentSkills += $item.Kind.ToLower() -replace '[^\w]', '-' }
    if ($item.Role) {
        $words = ($item.Role -split '[,;()]' | ForEach-Object { $_.Trim() }) | Where-Object { $_ }
        foreach ($w in $words) { $currentSkills += ($w.ToLower() -replace '[\s/]+', '-') }
    }
    $currentSkills = $currentSkills | Sort-Object -Unique

    $expected = @()
    foreach ($p in $profiles) {
        if ($skillTaxonomy[$p]) { $expected += $skillTaxonomy[$p] }
    }
    $expected = $expected | Sort-Object -Unique

    $missing = $expected | Where-Object { $_ -notin $currentSkills } | Sort-Object -Unique

    $hasCloned = Test-Path $target

    $perServerResults += [ordered]@{
        name = $name
        key = $safe
        tier = $item.Tier
        profiles = $profiles
        kind = $item.Kind
        current_skills = @($currentSkills)
        expected_skills = @($expected)
        missing_skills = @($missing)
        cloned = $hasCloned
        research_note = 'Based on community MCP skill taxonomy and the server profile.'
    }
}

$report = [ordered]@{
    generated = (Get-Date -Format 'o')
    total = $perServerResults.Count
    summary = [ordered]@{
        total_servers = $perServerResults.Count
        servers_with_missing = ($perServerResults | Where-Object { $_.missing_skills.Count -gt 0 }).Count
        total_missing_skills = ($perServerResults | ForEach-Object { $_.missing_skills.Count } | Measure-Object -Sum).Sum
    }
    servers = $perServerResults
}

[System.IO.File]::WriteAllText($OutJson, ($report | ConvertTo-Json -Depth 5))

$md = [System.Text.StringBuilder]::new()
[void]$md.AppendLine('# MCP Missing Skills Research')
[void]$md.AppendLine('')
[void]$md.AppendLine('This document cross-references the 49 DAVE-AI MCP servers against a community skill taxonomy to identify missing capabilities worth adding.')
[void]$md.AppendLine('')
[void]$md.AppendLine("- **Generated:** $($report.generated)")
[void]$md.AppendLine("- **Total servers:** $($report.summary.total_servers)")
[void]$md.AppendLine("- **Servers with missing skills:** $($report.summary.servers_with_missing)")
[void]$md.AppendLine("- **Total missing skill suggestions:** $($report.summary.total_missing_skills)")
[void]$md.AppendLine('')

$grouped = $perServerResults | Group-Object -Property { $_.tier }
foreach ($g in $grouped) {
    [void]$md.AppendLine("## Tier $($g.Name)")
    [void]$md.AppendLine('')
    foreach ($s in ($g.Group | Sort-Object name)) {
        [void]$md.AppendLine("### $($s.name)")
        [void]$md.AppendLine("")
        [void]$md.AppendLine("- **Kind:** $($s.kind)")
        [void]$md.AppendLine("- **Profiles:** $($s.profiles -join ', ')")
        [void]$md.AppendLine("- **Cloned:** $($s.cloned)")
        if ($s.current_skills.Count -gt 0) {
            [void]$md.AppendLine("- **Current skills:** " + ($s.current_skills -join ', '))
        }
        if ($s.missing_skills.Count -gt 0) {
            [void]$md.AppendLine("- **Missing skills to add:**")
            foreach ($m in $s.missing_skills) {
                [void]$md.AppendLine('  - ' + $m)
            }
        } else {
            [void]$md.AppendLine("- **Missing skills:** none (all expected skills appear covered)")
        }
        [void]$md.AppendLine('')
    }
}

[System.IO.File]::WriteAllText($OutMd, $md.ToString())
Write-Output "Wrote $OutJson and $OutMd"
