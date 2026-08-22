[CmdletBinding()]
param(
    [switch]$Fix,
    [string]$LogFile = 'C:\Users\Admin\CascadeProjects\daves-tools\logs\client-integrations.log'
)

$ErrorActionPreference = 'Continue'
New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null
$results = [System.Collections.Generic.List[object]]::new()

function Check([string]$Name, [bool]$Pass, [string]$Detail) {
    $results.Add([pscustomobject]@{ Check = $Name; Status = $(if ($Pass) { 'PASS' } else { 'FAIL' }); Detail = $Detail })
}

function ServiceRunning([string]$Name) {
    $service = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if ($null -ne $service -and $service.Status -ne 'Running' -and $Fix) {
        Start-Service -Name $Name -ErrorAction SilentlyContinue | Out-Null
        Start-Sleep -Seconds 3
        $service = Get-Service -Name $Name -ErrorAction SilentlyContinue
    }
    [pscustomobject]@{
        Running = [bool]($null -ne $service -and $service.Status -eq 'Running')
        State = $(if ($null -ne $service) { [string]$service.Status } else { 'missing' })
    }
}

function ValidJson([string]$Path) {
    try { Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json | Out-Null; return $true } catch { return $false }
}

$claudeService = ServiceRunning 'claude-minimax-proxy'
Check 'Claude gateway service' $claudeService.Running "claude-minimax-proxy: $($claudeService.State)"
$codexService = ServiceRunning 'api2codex-minimax'
Check 'Codex gateway service' $codexService.Running "api2codex-minimax: $($codexService.State)"

$claudeRegistry = Get-ItemProperty 'HKCU:\SOFTWARE\Policies\Claude' -ErrorAction SilentlyContinue
Check 'Claude registry endpoint' ($claudeRegistry.inferenceGatewayBaseUrl -eq 'http://127.0.0.1:48217/anthropic') "$($claudeRegistry.inferenceGatewayBaseUrl)"
Check 'Claude managed MCP' ([bool]$claudeRegistry.managedMcpServers) 'managedMcpServers present'

$kiloConfig = 'C:\Users\Admin\.config\kilo\kilo.json'
$kiloMcp = 'C:\Users\Admin\.kilocode\mcp.json'
Check 'Kilo provider JSON' (ValidJson $kiloConfig) $kiloConfig
Check 'Kilo MCP JSON' (ValidJson $kiloMcp) $kiloMcp
if (ValidJson $kiloConfig) {
    $kilo = Get-Content $kiloConfig -Raw | ConvertFrom-Json
    $provider = $kilo.provider.'minimax-local'
    Check 'Kilo MiniMax provider' ([bool]$provider -and $provider.options.baseURL -eq 'http://127.0.0.1:48217/v1') "baseURL=$($provider.options.baseURL)"
    $modelCount = ($provider.models.PSObject.Properties | Measure-Object).Count
    Check 'Kilo MiniMax models' ($modelCount -ge 3) "models=$modelCount"
}
if (ValidJson $kiloMcp) {
    $kiloMcpData = Get-Content $kiloMcp -Raw | ConvertFrom-Json
    Check 'Kilo shared mini MCP' ($kiloMcpData.mini.enabled -eq $true) 'mini enabled'
}

$devinConfig = 'C:\Users\Admin\AppData\Roaming\devin\mcp_config.json'
$devinProjectConfig = 'C:\Users\Admin\.devin\mcp.json'
Check 'Devin user MCP JSON' (ValidJson $devinConfig) $devinConfig
Check 'Devin project MCP JSON' (ValidJson $devinProjectConfig) $devinProjectConfig
$devinText = Get-Content $devinConfig -Raw -ErrorAction SilentlyContinue
Check 'Devin no plaintext MiniMax key' ($devinText -notmatch 'sk-[A-Za-z0-9_-]{20,}') 'credential scan'
if (ValidJson $devinConfig) {
    $devin = Get-Content $devinConfig -Raw | ConvertFrom-Json
    Check 'Devin shared mini MCP' ($devin.mcpServers.'daves-tools'.command -eq 'C:\Users\Admin\go\bin\mini.exe') 'daves-tools -> mini'
}

$codexConfig = 'C:\Users\Admin\.codex\config.toml'
Check 'Codex config exists' (Test-Path $codexConfig) $codexConfig
$catalog = 'C:\Users\Admin\.codex\model-catalogs\minimax-catalog.json'
Check 'Codex MiniMax catalog' (Test-Path $catalog) $catalog

function PostJson([string]$Uri, [hashtable]$Headers, [string]$Body) {
    try { return Invoke-WebRequest -Uri $Uri -Method POST -Headers $Headers -Body $Body -TimeoutSec 90 -UseBasicParsing } catch { return $null }
}

$proxyToken = (Get-Content 'C:\private\.proxy-token' -Raw -ErrorAction SilentlyContinue).Trim()
$claudeHeaders = @{ 'X-Api-Key' = $proxyToken; 'anthropic-version' = '2023-06-01'; 'Content-Type' = 'application/json' }
$claudeBody = '{"model":"claude-sonnet-4-5","max_tokens":24,"messages":[{"role":"user","content":"say ok"}]}'
$claudeResponse = PostJson 'http://127.0.0.1:48217/anthropic/v1/messages' $claudeHeaders $claudeBody
Check 'Claude request contract' ([bool]$claudeResponse -and $claudeResponse.StatusCode -eq 200) 'POST /anthropic/v1/messages'

$codexBody = '{"model":"MiniMax-M3","input":[{"role":"user","content":[{"type":"input_text","text":"say ok"}]}],"max_output_tokens":24,"stream":false}'
$codexResponse = PostJson 'http://127.0.0.1:48218/v1/responses' @{ 'Authorization' = 'Bearer local'; 'Content-Type' = 'application/json' } $codexBody
Check 'Codex request contract' ([bool]$codexResponse -and $codexResponse.StatusCode -eq 200) 'POST /v1/responses'

foreach ($server in @('minimax', 'minimax-media', 'minimax-coding-plan', 'touchpoint', 'winremote', 'daves-tools-harness')) {
    $listing = & 'C:\Users\Admin\go\bin\mini.exe' ls $server 2>&1 | Out-String
    Check "MCP $server" (($LASTEXITCODE -eq 0) -and ($listing -match '(?m)^TOOL\s')) 'targeted handshake/list-tools'
}

$stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$failed = @($results | Where-Object Status -eq 'FAIL').Count
$results | Format-Table -AutoSize | Out-String | Write-Host
"[$stamp] $(if ($failed -eq 0) { 'HEALTHY' } else { "$failed FAILURES" }) :: " + (($results | ForEach-Object { "$($_.Check)=$($_.Status)" }) -join '; ') | Add-Content -LiteralPath $LogFile
if ($failed -eq 0) { Write-Host 'Client integrations: HEALTHY' -ForegroundColor Green; exit 0 }
Write-Host "Client integrations: $failed check(s) failed" -ForegroundColor Red
exit 1
