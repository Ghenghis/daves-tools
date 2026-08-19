[CmdletBinding()]
param(
    [string]$CatalogPath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\missing-from-catalog.json",
    [string]$SnippetPath = "C:\Users\Admin\CascadeProjects\daves-tools\configs\claude-desktop-missing.json",
    [string]$StatusDir = "C:\Users\Admin\CascadeProjects\daves-tools\docs",
    [string]$OutPath = "C:\Users\Admin\CascadeProjects\daves-tools\configs\mcp-registry.json"
)

$ErrorActionPreference = "Stop"

$catalog = Get-Content $CatalogPath -Raw | ConvertFrom-Json
$snippet = Get-Content $SnippetPath -Raw | ConvertFrom-Json
$statusFiles = Get-ChildItem $StatusDir -Filter 'phase-*-status.json'
$status = foreach ($f in $statusFiles) { Get-Content $f.FullName | ConvertFrom-Json }

$map = @{}
foreach ($s in $status) { $map[$s.name] = $s }

$servers = [ordered]@{}
foreach ($item in $catalog) {
    $name = $item.Name
    $key = ($name -replace '[^\w]', '-').ToLower()
    $mcpKey = $key -replace '-+', '-'
    if (-not $snippet.mcpServers.$mcpKey -and -not $snippet.mcpServers.$key) { continue }
    $cfg = if ($snippet.mcpServers.$mcpKey) { $snippet.mcpServers.$mcpKey } else { $snippet.mcpServers.$key }
    $s = if ($map.ContainsKey($name)) { $map[$name] } else { @{ cloned = $false } }
    $servers[$mcpKey] = [ordered]@{
        name = $name
        key = $mcpKey
        kind = $item.Kind
        tier = $item.Tier
        profile = $item.Profile
        role = $item.Role
        tags = @($item.Profile, $item.Role, $item.Kind, $item.Tier) + @($item.Tags -split '[,;]')
        cloned = $s.cloned
        snippet = $cfg
        enabled = $false
    }
}

$registry = [ordered]@{
    version = '1.0.0'
    generated = (Get-Date -Format o)
    total = $servers.Count
    servers = $servers
}

[System.IO.File]::WriteAllText($OutPath, ($registry | ConvertTo-Json -Depth 5))
Write-Output "Built MCP registry: $OutPath with $($servers.Count) servers"
