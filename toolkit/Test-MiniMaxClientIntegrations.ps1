[CmdletBinding()]
param(
    [switch]$Fix,
    [string]$LogFile = 'C:\Users\Admin\CascadeProjects\daves-tools\logs\client-integrations.log'
)

$ErrorActionPreference = 'Continue'
New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null
$results = [System.Collections.Generic.List[object]]::new()

function Check {
    param([string]$Name, [bool]$Pass, [string]$Detail)
    $results.Add([pscustomobject]@{ Check = $Name; Status = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail })
}

function ServiceRunning {
    param([string]$Name, [switch]$Fix)
    $service = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if ($Fix -and $null -ne $service -and $service.Status -ne 'Running') {
        Start-Service -Name $Name -ErrorAction SilentlyContinue | Out-Null
        Start-Sleep -Seconds 3
        $service = Get-Service -Name $Name -ErrorAction SilentlyContinue
    }
    [pscustomobject]@{
        Running = [bool]($null -ne $service -and $service.Status -eq 'Running')
        State = $(if ($null -ne $service) { [string]$service.Status } else { 'missing' })
    }
}

function ValidJson {
    param([string]$Path)
    try { Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json | Out-Null; return $true } catch { return $false }
}

$claudeService = ServiceRunning -Name 'claude-minimax-proxy' -Fix:$Fix
Check -Name 'Claude gateway service' -Pass $claudeService.Running -Detail "claude-minimax-proxy: $($claudeService.State)"
$codexService = ServiceRunning -Name 'api2codex-minimax' -Fix:$Fix
Check -Name 'Codex gateway service' -Pass $codexService.Running -Detail "api2codex-minimax: $($codexService.State)"

$claudeRegistry = Get-ItemProperty 'HKCU:\SOFTWARE\Policies\Claude' -ErrorAction SilentlyContinue
Check -Name 'Claude registry endpoint' -Pass ($claudeRegistry.inferenceGatewayBaseUrl -eq 'http://127.0.0.1:48217/anthropic') -Detail "$($claudeRegistry.inferenceGatewayBaseUrl)"
Check -Name 'Claude managed MCP' -Pass ([bool]$claudeRegistry.managedMcpServers) -Detail 'managedMcpServers present'

$kiloConfig = 'C:\Users\Admin\.config\kilo\kilo.json'
$kiloMcp = 'C:\Users\Admin\.kilocode\mcp.json'
Check -Name 'Kilo provider JSON' -Pass (ValidJson -Path $kiloConfig) -Detail $kiloConfig
Check -Name 'Kilo MCP JSON' -Pass (ValidJson -Path $kiloMcp) -Detail $kiloMcp
if (ValidJson -Path $kiloConfig) {
    $kilo = Get-Content -Path $kiloConfig -Raw | ConvertFrom-Json
    $provider = $kilo.provider.'minimax-local'
    Check -Name 'Kilo MiniMax provider' -Pass ([bool]$provider -and $provider.options.baseURL -eq 'http://127.0.0.1:48217/v1') -Detail "baseURL=$($provider.options.baseURL)"
    $modelCount = ($provider.models.PSObject.Properties | Measure-Object).Count
    Check -Name 'Kilo MiniMax models' -Pass ($modelCount -ge 3) -Detail "models=$modelCount"
}
if (ValidJson -Path $kiloMcp) {
    $kiloMcpData = Get-Content -Path $kiloMcp -Raw | ConvertFrom-Json
    Check -Name 'Kilo shared mini MCP' -Pass ($kiloMcpData.mini.enabled -eq $true) -Detail 'mini enabled'
}

$devinConfig = 'C:\Users\Admin\AppData\Roaming\devin\mcp_config.json'
$devinProjectConfig = 'C:\Users\Admin\.devin\mcp.json'
Check -Name 'Devin user MCP JSON' -Pass (ValidJson -Path $devinConfig) -Detail $devinConfig
Check -Name 'Devin project MCP JSON' -Pass (ValidJson -Path $devinProjectConfig) -Detail $devinProjectConfig
$devinText = Get-Content -Path $devinConfig -Raw -ErrorAction SilentlyContinue
Check -Name 'Devin no plaintext MiniMax key' -Pass ($devinText -notmatch 'sk-[A-Za-z0-9_-]{20,}') -Detail 'credential scan'
if (ValidJson -Path $devinConfig) {
    $devin = Get-Content -Path $devinConfig -Raw | ConvertFrom-Json
    Check -Name 'Devin shared mini MCP' -Pass ($devin.mcpServers.'daves-tools'.command -eq 'C:\Users\Admin\go\bin\mini.exe') -Detail 'daves-tools -> mini'
}

$codexConfig = 'C:\Users\Admin\.codex\config.toml'
Check -Name 'Codex config exists' -Pass (Test-Path $codexConfig) -Detail $codexConfig
$catalog = 'C:\Users\Admin\.codex\model-catalogs\minimax-catalog.json'
Check -Name 'Codex MiniMax catalog' -Pass (Test-Path $catalog) -Detail $catalog

function PostJson {
    param([string]$Uri, [hashtable]$Headers, [string]$Body)
    try { return Invoke-WebRequest -Uri $Uri -Method POST -Headers $Headers -Body $Body -TimeoutSec 90 -UseBasicParsing } catch { return $null }
}

$proxyToken = (Get-Content -Path 'C:\private\.proxy-token' -Raw -ErrorAction SilentlyContinue).Trim()
$claudeHeaders = @{ 'X-Api-Key' = $proxyToken; 'anthropic-version' = '2023-06-01'; 'Content-Type' = 'application/json' }
$claudeBody = '{"model":"claude-sonnet-4-5","max_tokens":24,"messages":[{"role":"user","content":"say ok"}]}'
$claudeResponse = PostJson -Uri 'http://127.0.0.1:48217/anthropic/v1/messages' -Headers $claudeHeaders -Body $claudeBody
Check -Name 'Claude request contract' -Pass ([bool]$claudeResponse -and $claudeResponse.StatusCode -eq 200) -Detail 'POST /anthropic/v1/messages'

$codexBody = '{"model":"MiniMax-M3","input":[{"role":"user","content":[{"type":"input_text","text":"say ok"}]}],"max_output_tokens":24,"stream":false}'
$codexResponse = PostJson -Uri 'http://127.0.0.1:48218/v1/responses' -Headers @{ 'Authorization' = 'Bearer local'; 'Content-Type' = 'application/json' } -Body $codexBody
Check -Name 'Codex request contract' -Pass ([bool]$codexResponse -and $codexResponse.StatusCode -eq 200) -Detail 'POST /v1/responses'

foreach ($server in @('minimax', 'minimax-media', 'minimax-coding-plan', 'touchpoint', 'winremote', 'daves-tools-harness')) {
    $listing = & 'C:\Users\Admin\go\bin\mini.exe' ls $server 2>&1 | Out-String
    Check -Name "MCP $server" -Pass (($LASTEXITCODE -eq 0) -and ($listing -match '(?m)^TOOL\s')) -Detail 'targeted handshake/list-tools'
}

$stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$failed = @($results | Where-Object Status -eq 'FAIL').Count
$results | Format-Table -AutoSize
"[$stamp] $(if ($failed -eq 0) { 'HEALTHY' } else { "$failed FAILURES" }) :: " + (($results | ForEach-Object { "$($_.Check)=$($_.Status)" }) -join '; ') | Add-Content -LiteralPath $LogFile
if ($failed -eq 0) { Write-Output 'Client integrations: HEALTHY'; exit 0 }
Write-Output "Client integrations: $failed check(s) failed"
exit 1
