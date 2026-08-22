[CmdletBinding()]
param(
    [string]$RegistryPath = "C:\Users\Admin\CascadeProjects\daves-tools\configs\typed-registry.json",
    [string]$DoctorPath   = "C:\Users\Admin\CascadeProjects\daves-tools\docs\capability-report.json",
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"
& "C:\Users\Admin\CascadeProjects\daves-tools\toolkit\Load-PrivateEnv.ps1" -Quiet

$reg = Get-Content $RegistryPath | ConvertFrom-Json
$doctor = if (Test-Path $DoctorPath) { Get-Content $DoctorPath | ConvertFrom-Json } else { @{ results = @() } }
$healthy = @($doctor.results | Where-Object { $_.healthy -eq $true } | ForEach-Object { $_.id })

function Get-McpServers() {
    $mcp = @{}
    foreach ($a in $reg.assets) {
        if ($a.runtime.transport -ne 'stdio' -or -not $a.runtime.command) { continue }
        if ($a.id -notin $healthy) { continue }
        $cfg = @{
            command = $a.runtime.command
            args    = @($a.runtime.args)
        }
        if ($a.runtime.env_refs -and $a.runtime.env_refs.Count -gt 0) {
            $envMap = @{}
            foreach ($ref in $a.runtime.env_refs) {
                $v = [Environment]::GetEnvironmentVariable($ref)
                if (-not $v) { $v = "" }
                $envMap[$ref] = $v
            }
            $cfg.env = $envMap
        }
        $mcp[$a.id] = $cfg
    }
    return $mcp
}

function Merge-McpConfig($FilePath, $McpServers, $TopKey = $null) {
    $existing = if (Test-Path $FilePath) { Get-Content $FilePath | ConvertFrom-Json } else { @{} }
    if (-not $existing) { $existing = @{} }
    if ($TopKey) {
        if (-not $existing.$TopKey) { $existing | Add-Member -NotePropertyName $TopKey -NotePropertyValue @{} -Force }
        $existing.$TopKey = $McpServers
    } else {
        $existing.mcpServers = $McpServers
    }
    $dir = Split-Path $FilePath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $existing | ConvertTo-Json -Depth 5 | Set-Content -Path $FilePath -Encoding UTF8
    Write-Output "Wrote $FilePath"
}

$mcp = Get-McpServers
Write-Output "Installing $($mcp.Count) healthy MCP servers into IDE configs..."

$appData = $env:APPDATA
$userProf = $env:USERPROFILE

# Claude Desktop
Merge-McpConfig -FilePath "$appData\Claude\settings.json" -McpServers $mcp

# Codex
Merge-McpConfig -FilePath "$userProf\.codex\config.json" -McpServers $mcp

# Kilo Code
Merge-McpConfig -FilePath "$userProf\.kilocode\mcp.json" -McpServers $mcp

# Devin
Merge-McpConfig -FilePath "$userProf\.devin\mcp.json" -McpServers $mcp

Write-Output "IDE config installation complete."
