[CmdletBinding()]
param(
    [string]$AuditPath = "$PSScriptRoot\..\audit-2026-08-19\daves-tools-e2e-audit-2026-08-19\daves-tools-audit-data.json",
    [string]$OutPath = "$PSScriptRoot\..\configs\typed-registry.json",
    [string]$SchemaPath = "$PSScriptRoot\..\configs\typed-registry.schema.json"
)

$ErrorActionPreference = "Stop"

$raw = [System.IO.File]::ReadAllText($AuditPath)
$raw = $raw -replace '^\uFEFF', ''
$audit = $raw | ConvertFrom-Json

$typeMap = @{
    'Skill pack/source' = 'skill_pack'
    'Plugin marketplace' = 'marketplace'
    'MCP server' = 'mcp_server'
    'Skill pack/plugin' = 'skill_pack'
    'Curated skill marketplace' = 'marketplace'
    'MCP/CLI' = 'mcp_server'
    'MCP server/connector' = 'mcp_server'
    'Remote MCP server/connector' = 'mcp_server'
    'Duplicate profile variant' = 'skill_pack'
    'Benchmark/evaluation suite' = 'benchmark'
    'CLI/E2E dependency' = 'cli_dependency'
    'Skill/harness' = 'skill_pack'
    'Agent runtime' = 'agent_runtime'
    'Skill pack' = 'skill_pack'
    'CLI dependency' = 'cli_dependency'
    'CLI' = 'cli_dependency'
    'MCP plugin' = 'mcp_server'
    'Interactive MCP/plugin' = 'mcp_server'
    'Service/API dependency' = 'service'
    'App/API' = 'service'
    'RE suite dependency' = 'cli_dependency'
    'GUI dependency' = 'gui_dependency'
    'GUI/CLI dependency' = 'gui_dependency'
    'GUI' = 'gui_dependency'
    'RE framework dependency' = 'cli_dependency'
    'MCP/automation adapter' = 'mcp_server'
    'MCP/test framework' = 'mcp_server'
    'Debugger GUI dependency' = 'gui_dependency'
    'CLI + skill pack' = 'skill_pack'
    'CLI/skills' = 'skill_pack'
    'High-risk MCP server' = 'mcp_server'
    'Unproven duplicate/adapter concept' = 'skill_pack'
    'Security skill pack/marketplace' = 'marketplace'
    'Marketplace' = 'marketplace'
    'Skills' = 'skill_pack'
    'Plugin/skills' = 'skill_pack'
    'MCP/Connector' = 'mcp_server'
    'Windows skill/plugin pack' = 'skill_pack'
    'MCP' = 'mcp_server'
}

$officialLaunchers = @{
    'Serena' = @{
        transport = 'stdio'
        command = 'uvx'
        args = @('mcp-server-serena', '--project', '<PROJECT_ROOT>')
        env_refs = @('UV_PYTHON', 'PATH')
    }
    'GitHub MCP' = @{
        transport = 'stdio'
        command = 'npx'
        args = @('-y', '@github/mcp-server')
        env_refs = @('GITHUB_PERSONAL_ACCESS_TOKEN')
    }
    'GitLab MCP' = @{
        transport = 'streamable_http'
        command = 'none'
        args = @()
        env_refs = @('GITLAB_PERSONAL_ACCESS_TOKEN')
    }
    'Context7' = @{
        transport = 'stdio'
        command = 'npx'
        args = @('-y', '@upstash/context7-mcp@latest')
        env_refs = @()
    }
    'Playwright CLI + Skills' = @{
        transport = 'stdio'
        command = 'npx'
        args = @('-y', '@playwright/mcp@latest')
        env_refs = @('PLAYWRIGHT_BROWSERS_PATH')
    }
}

function Get-AssetType($class) {
    if ($typeMap.ContainsKey($class)) { return $typeMap[$class] }
    return 'cli_dependency'
}

$assets = foreach ($item in $audit.items) {
    $name = $item.name
    $id = ($name -replace '[^\w]', '-').ToLower() -replace '-+', '-'
    $class = $item.actual_class
    $assetType = Get-AssetType $class
    $profiles = $item.profile -split '[/,]' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    $caps = $item.missing_skills -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ }

    $runtime = if ($officialLaunchers.ContainsKey($name)) {
        $officialLaunchers[$name]
    } elseif ($assetType -eq 'mcp_server' -and $item.launcher) {
        $parts = $item.launcher -split '\s+'
        @{ transport = 'stdio'; command = $parts[0]; args = $parts[1..($parts.Length-1)]; env_refs = @() }
    } else {
        @{ transport = 'none'; command = $item.launcher; args = @(); env_refs = @() }
    }

    [ordered]@{
        id = $id
        display_name = $name
        asset_type = $assetType
        source = [ordered]@{
            url = $item.upstream
            ref = if ($item.upstream -match '/tree/') { ($item.upstream -split '/tree/')[-1] } else { 'main' }
            commit = $null
            license = $null
            sha256 = $null
        }
        profiles = @($profiles)
        capabilities = @($caps)
        runtime = [ordered]@{
            transport = $runtime.transport
            command = $runtime.command
            args = @($runtime.args)
            env_refs = @($runtime.env_refs)
            cwd = $null
            healthcheck = @{}
            timeout_ms = 30000
            max_concurrency = 1
            auto_start = ($assetType -eq 'mcp_server')
        }
        permissions = [ordered]@{
            filesystem_roots = @()
            network_hosts = @()
            credentials = @($runtime.env_refs | Where-Object { $_ })
            mutation_level = 'read_only'
            approval_policy = 'on_mutation'
        }
        verification = [ordered]@{
            install = 'unknown'
            protocol = 'unknown'
            domain_smoke = 'unknown'
            last_verified = $null
            evidence_id = $null
        }
    }
}

$registry = [ordered]@{
    version = '1.0.0'
    generated = (Get-Date -Format 'o')
    schema = 'configs/typed-registry.schema.json'
    total = $assets.Count
    mcp_server_count = ($assets | Where-Object { $_.asset_type -eq 'mcp_server' }).Count
    skill_pack_count = ($assets | Where-Object { $_.asset_type -eq 'skill_pack' }).Count
    dependency_count = ($assets | Where-Object { $_.asset_type -in 'cli_dependency','gui_dependency','service' }).Count
    assets = @($assets)
}

[System.IO.File]::WriteAllText($OutPath, ($registry | ConvertTo-Json -Depth 5))

$srcSchema = "$PSScriptRoot\..\audit-2026-08-19\daves-tools-e2e-audit-2026-08-19\recommended-registry.schema.json"
if (Test-Path $srcSchema) {
    Copy-Item $srcSchema $SchemaPath -Force
}

Write-Output "Wrote $OutPath with $($assets.Count) assets"
