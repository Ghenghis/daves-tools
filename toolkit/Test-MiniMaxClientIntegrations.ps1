[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [switch]$Fix,
    [switch]$Live,
    [ValidateRange(1, 300)][int]$RequestTimeoutSec = 90,
    [string]$LogFile = 'C:\Users\Admin\CascadeProjects\daves-tools\logs\client-integrations.jsonl',
    [string]$KiloConfig = 'C:\Users\Admin\.config\kilo\kilo.json',
    [string]$KiloMcpConfig = 'C:\Users\Admin\.kilocode\mcp.json',
    [string]$DevinConfig = 'C:\Users\Admin\AppData\Roaming\devin\mcp_config.json',
    [string]$CodexConfig = 'C:\Users\Admin\.codex\config.toml',
    [string]$CodexCatalog = 'C:\Users\Admin\.codex\model-catalogs\minimax-catalog.json',
    [string]$ProxyTokenFile = 'C:\private\.proxy-token',
    [string]$MiniExecutable = 'C:\Users\Admin\go\bin\mini.exe'
)

$ErrorActionPreference = 'Stop'

function Add-CheckResult {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateSet('PASS', 'FAIL', 'SKIP')][string]$Status,
        [Parameter(Mandatory)][string]$Detail,
        [System.Collections.Generic.List[object]]$ResultList = $script:IntegrationResults
    )
    [void]$ResultList.Add([pscustomobject]@{
        Check = $Name
        Status = $Status
        Detail = $Detail
    })
}

function Test-JsonFile {
    param([Parameter(Mandatory)][string]$Path)
    try {
        Get-Content -LiteralPath $Path -Raw -ErrorAction Stop |
            ConvertFrom-Json -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Test-ContainsSecret {
    param([AllowEmptyString()][string]$Text)
    if (-not $Text) { return $false }
    $patterns = @(
        '(?i)sk-[A-Za-z0-9_-]{20,}',
        '(?i)ghp_[A-Za-z0-9]{20,}',
        '(?i)github_pat_[A-Za-z0-9_]{20,}',
        '(?i)glpat-[A-Za-z0-9_-]{20,}'
    )
    return [bool]($patterns | Where-Object { $Text -match $_ } | Select-Object -First 1)
}

function Get-ServiceHealth {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)][string]$Name,
        [switch]$Fix,
        [ValidateRange(1, 60)][int]$TimeoutSec = 15
    )
    try {
        $service = Get-Service -Name $Name -ErrorAction Stop
    } catch {
        return [pscustomobject]@{ Running = $false; State = 'missing'; Repair = 'not-available'; Error = $_.Exception.Message }
    }
    $repair = 'not-needed'
    $errorMessage = ''
    if ($service.Status -ne 'Running' -and $Fix) {
        if ($PSCmdlet.ShouldProcess($Name, 'Start Windows service')) {
            $repair = 'attempted'
            try {
                Start-Service -Name $Name -ErrorAction Stop
                $deadline = (Get-Date).AddSeconds($TimeoutSec)
                do {
                    Start-Sleep -Milliseconds 500
                    $service = Get-Service -Name $Name -ErrorAction Stop
                } while ($service.Status -ne 'Running' -and (Get-Date) -lt $deadline)
            } catch {
                $errorMessage = $_.Exception.Message
            }
        } else {
            $repair = 'what-if'
        }
    }
    return [pscustomobject]@{
        Running = [bool]($service.Status -eq 'Running')
        State = [string]$service.Status
        Repair = $repair
        Error = $errorMessage
    }
}

function Get-PortHealth {
    param([Parameter(Mandatory)][ValidateRange(1, 65535)][int]$Port)
    try {
        $listeners = @(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop)
        $processes = @($listeners | ForEach-Object {
            (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName
        } | Where-Object { $_ } | Sort-Object -Unique)
        return [pscustomobject]@{
            Listening = [bool]($listeners.Count -gt 0)
            ListenerCount = $listeners.Count
            Processes = $processes
            Error = ''
        }
    } catch {
        return [pscustomobject]@{ Listening = $false; ListenerCount = 0; Processes = @(); Error = $_.Exception.Message }
    }
}

function Invoke-JsonPost {
    param(
        [Parameter(Mandatory)][string]$Uri,
        [Parameter(Mandatory)][hashtable]$Headers,
        [Parameter(Mandatory)][string]$Body,
        [ValidateRange(1, 300)][int]$TimeoutSec = 90
    )
    try {
        $response = Invoke-WebRequest -Uri $Uri -Method POST -Headers $Headers -Body $Body -TimeoutSec $TimeoutSec -UseBasicParsing -ErrorAction Stop
        return [pscustomobject]@{ Success = $true; StatusCode = [int]$response.StatusCode; Content = [string]$response.Content; Error = '' }
    } catch {
        $statusCode = 0
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
        return [pscustomobject]@{ Success = $false; StatusCode = $statusCode; Content = ''; Error = $_.Exception.Message }
    }
}

function Invoke-MiniList {
    param(
        [Parameter(Mandatory)][string]$Executable,
        [Parameter(Mandatory)][string]$Server
    )
    if (-not (Test-Path -LiteralPath $Executable)) {
        return [pscustomobject]@{ Success = $false; ToolCount = 0; Error = 'mini executable missing' }
    }
    try {
        $previousErrorPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $output = & $Executable ls $Server 2>&1 | Out-String
        $exitCode = $LASTEXITCODE
        $ErrorActionPreference = $previousErrorPreference
        $toolCount = @($output -split "`r?`n" | Where-Object { $_ -match '^(?!TOOL\s)[A-Za-z][A-Za-z0-9_]*(?:\([^)]*\))?\s{2,}' }).Count
        return [pscustomobject]@{
            Success = [bool]($exitCode -eq 0 -and $toolCount -gt 0)
            ToolCount = $toolCount
            Error = $(if ($exitCode -eq 0) { '' } else { "mini exited $exitCode" })
        }
    } catch {
        $ErrorActionPreference = $previousErrorPreference
        return [pscustomobject]@{ Success = $false; ToolCount = 0; Error = $_.Exception.Message }
    }
}

function Invoke-ClientIntegrationCheck {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Fix,
        [switch]$Live,
        [int]$RequestTimeoutSec,
        [string]$LogFile,
        [string]$KiloConfig,
        [string]$KiloMcpConfig,
        [string]$DevinConfig,
        [string]$CodexConfig,
        [string]$CodexCatalog,
        [string]$ProxyTokenFile,
        [string]$MiniExecutable
    )
    $logDirectory = Split-Path -Parent $LogFile
    if ($logDirectory) { New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null }
    $script:IntegrationResults = [System.Collections.Generic.List[object]]::new()

    foreach ($serviceDefinition in @(
        @{ Name = 'claude-minimax-proxy'; Port = 48217 },
        @{ Name = 'api2codex-minimax'; Port = 48218 }
    )) {
        $service = Get-ServiceHealth -Name $serviceDefinition.Name -Fix:$Fix -WhatIf:$WhatIfPreference
        Add-CheckResult -Name "Service $($serviceDefinition.Name)" -Status $(if ($service.Running) { 'PASS' } else { 'FAIL' }) -Detail "state=$($service.State); repair=$($service.Repair)$(if ($service.Error) { '; error=' + $service.Error })"
        $port = Get-PortHealth -Port $serviceDefinition.Port
        if ($service.Repair -eq 'attempted' -and $service.Running -and -not $port.Listening) {
            $portDeadline = (Get-Date).AddSeconds(15)
            do {
                Start-Sleep -Milliseconds 500
                $port = Get-PortHealth -Port $serviceDefinition.Port
            } while (-not $port.Listening -and (Get-Date) -lt $portDeadline)
        }
        $portPass = $port.Listening -and $port.ListenerCount -eq 1
        $processDetail = if ($port.Processes.Count) { $port.Processes -join ',' } else { 'none' }
        Add-CheckResult -Name "Port $($serviceDefinition.Port) listener" -Status $(if ($portPass) { 'PASS' } else { 'FAIL' }) -Detail "listeners=$($port.ListenerCount); processes=$processDetail$(if ($port.Error) { '; error=' + $port.Error })"
        if (-not $service.Running -and $port.Listening) {
            Add-CheckResult -Name "Port $($serviceDefinition.Port) ownership conflict" -Status 'FAIL' -Detail 'listener exists while expected service is not running; no process was terminated'
        }
    }

    $claudeRegistry = Get-ItemProperty 'HKCU:\SOFTWARE\Policies\Claude' -ErrorAction SilentlyContinue
    Add-CheckResult -Name 'Claude registry endpoint' -Status $(if ($claudeRegistry.inferenceGatewayBaseUrl -eq 'http://127.0.0.1:48217/anthropic') { 'PASS' } else { 'FAIL' }) -Detail "endpoint=$($claudeRegistry.inferenceGatewayBaseUrl)"
    $claudeMcpServers = @()
    try { $claudeMcpServers = @($claudeRegistry.managedMcpServers | ConvertFrom-Json -ErrorAction Stop) } catch { $claudeMcpServers = @() }
    $claudeMcpNames = @($claudeMcpServers | ForEach-Object { $_.name })
    $claudeTargeted = @('minimax', 'minimax-media', 'minimax-coding-plan') | Where-Object { $_ -notin $claudeMcpNames }
    Add-CheckResult -Name 'Claude bounded MCP surface' -Status $(if ('mini' -notin $claudeMcpNames -and @($claudeTargeted).Count -eq 0) { 'PASS' } else { 'FAIL' }) -Detail "managed=$($claudeMcpNames -join ',')"

    $kiloValid = Test-JsonFile -Path $KiloConfig
    Add-CheckResult -Name 'Kilo provider JSON' -Status $(if ($kiloValid) { 'PASS' } else { 'FAIL' }) -Detail $KiloConfig
    if ($kiloValid) {
        $kilo = Get-Content -LiteralPath $KiloConfig -Raw | ConvertFrom-Json
        $provider = $kilo.provider.'minimax-local'
        Add-CheckResult -Name 'Kilo MiniMax endpoint' -Status $(if ($provider.options.baseURL -eq 'http://127.0.0.1:48217/v1') { 'PASS' } else { 'FAIL' }) -Detail "baseURL=$($provider.options.baseURL)"
        Add-CheckResult -Name 'Kilo file-backed proxy token' -Status $(if ($provider.options.apiKey -eq '{file:C:\private\.proxy-token}') { 'PASS' } else { 'FAIL' }) -Detail 'provider key must use file interpolation'
        $modelIds = @($provider.models.PSObject.Properties.Value | ForEach-Object { $_.id })
        $requiredModels = @('MiniMax-M3', 'MiniMax-M2.7', 'MiniMax-M2.7-highspeed')
        $missingModels = @($requiredModels | Where-Object { $_ -notin $modelIds })
        Add-CheckResult -Name 'Kilo MiniMax model IDs' -Status $(if ($missingModels.Count -eq 0) { 'PASS' } else { 'FAIL' }) -Detail "configured=$($modelIds -join ',')"
        $aggregate = $kilo.mcp.mini
        Add-CheckResult -Name 'Kilo bounded MCP surface' -Status $(if (-not $aggregate -or $aggregate.enabled -eq $false) { 'PASS' } else { 'FAIL' }) -Detail 'mini aggregate must be disabled; targeted MiniMax MCPs are used'
        foreach ($server in @('minimax', 'minimax-media', 'minimax-coding-plan')) {
            Add-CheckResult -Name "Kilo targeted MCP $server" -Status $(if ($kilo.mcp.$server.enabled -eq $true) { 'PASS' } else { 'FAIL' }) -Detail 'targeted MCP enabled'
        }
    }

    $kiloMcpValid = Test-JsonFile -Path $KiloMcpConfig
    Add-CheckResult -Name 'Kilo legacy MCP JSON' -Status $(if ($kiloMcpValid) { 'PASS' } else { 'FAIL' }) -Detail $KiloMcpConfig
    if ($kiloMcpValid) {
        $kiloMcp = Get-Content -LiteralPath $KiloMcpConfig -Raw | ConvertFrom-Json
        Add-CheckResult -Name 'Kilo legacy aggregate disabled' -Status $(if (-not $kiloMcp.mini -or $kiloMcp.mini.enabled -eq $false) { 'PASS' } else { 'FAIL' }) -Detail 'legacy mini aggregate disabled'
    }

    $devinValid = Test-JsonFile -Path $DevinConfig
    Add-CheckResult -Name 'Devin MCP JSON' -Status $(if ($devinValid) { 'PASS' } else { 'FAIL' }) -Detail $DevinConfig
    if ($devinValid) {
        $devinText = Get-Content -LiteralPath $DevinConfig -Raw
        Add-CheckResult -Name 'Devin no plaintext credentials' -Status $(if (-not (Test-ContainsSecret -Text $devinText)) { 'PASS' } else { 'FAIL' }) -Detail 'credential pattern scan'
        $devin = $devinText | ConvertFrom-Json
        $devinAggregate = $devin.mcpServers.'daves-tools'
        Add-CheckResult -Name 'Devin bounded MCP surface' -Status $(if (-not $devinAggregate -or $devinAggregate.disabled -eq $true) { 'PASS' } else { 'FAIL' }) -Detail '387-tool mini aggregate must remain disabled'
        foreach ($server in @('minimax-official', 'minimax-media', 'minimax-coding-plan-safe')) {
            Add-CheckResult -Name "Devin targeted MCP $server" -Status $(if ($devin.mcpServers.$server.disabled -eq $false) { 'PASS' } else { 'FAIL' }) -Detail 'targeted MCP enabled'
        }
        $githubCommand = $devin.mcpServers.'github-mcp-server'.command
        Add-CheckResult -Name 'Devin GitHub credential wrapper' -Status $(if ($githubCommand -and (Test-Path -LiteralPath $githubCommand)) { 'PASS' } else { 'FAIL' }) -Detail "command=$githubCommand"
    }

    $codexExists = Test-Path -LiteralPath $CodexConfig
    Add-CheckResult -Name 'Codex config exists' -Status $(if ($codexExists) { 'PASS' } else { 'FAIL' }) -Detail $CodexConfig
    if ($codexExists) {
        $codexText = Get-Content -LiteralPath $CodexConfig -Raw
        $targetedSections = @('minimax', 'minimax-media', 'minimax-coding-plan') | Where-Object { $codexText -notmatch "(?m)^\[mcp_servers\.$([regex]::Escape($_))\]" }
        $aggregateDisabled = $codexText -match '(?ms)^\[mcp_servers\.mini\].*?^enabled\s*=\s*false'
        Add-CheckResult -Name 'Codex bounded MCP surface' -Status $(if (@($targetedSections).Count -eq 0 -and $aggregateDisabled) { 'PASS' } else { 'FAIL' }) -Detail 'targeted MiniMax MCPs enabled; aggregate mini disabled'
    }
    $catalogValid = Test-JsonFile -Path $CodexCatalog
    Add-CheckResult -Name 'Codex catalog JSON' -Status $(if ($catalogValid) { 'PASS' } else { 'FAIL' }) -Detail $CodexCatalog
    if ($catalogValid) {
        $catalogModels = @((Get-Content -LiteralPath $CodexCatalog -Raw | ConvertFrom-Json).models | ForEach-Object { $_.slug })
        $missingCatalogModels = @('MiniMax-M3', 'MiniMax-M2.7', 'MiniMax-M2.7-highspeed') | Where-Object { $_ -notin $catalogModels }
        Add-CheckResult -Name 'Codex MiniMax model IDs' -Status $(if (@($missingCatalogModels).Count -eq 0) { 'PASS' } else { 'FAIL' }) -Detail "configured=$($catalogModels -join ',')"
    }

    $proxyToken = ''
    try { $proxyToken = (Get-Content -LiteralPath $ProxyTokenFile -Raw -ErrorAction Stop).Trim() } catch { $proxyToken = '' }
    Add-CheckResult -Name 'Proxy token present' -Status $(if ($proxyToken.Length -ge 32) { 'PASS' } else { 'FAIL' }) -Detail $ProxyTokenFile

    if ($Live -and $proxyToken) {
        $claude = Invoke-JsonPost -Uri 'http://127.0.0.1:48217/anthropic/v1/messages' -Headers @{ 'X-Api-Key' = $proxyToken; 'anthropic-version' = '2023-06-01'; 'Content-Type' = 'application/json' } -Body '{"model":"claude-sonnet-4-5","max_tokens":8,"messages":[{"role":"user","content":"Reply exactly OK"}]}' -TimeoutSec $RequestTimeoutSec
        Add-CheckResult -Name 'Claude live request' -Status $(if ($claude.Success -and $claude.StatusCode -eq 200) { 'PASS' } else { 'FAIL' }) -Detail "status=$($claude.StatusCode)$(if ($claude.Error) { '; error=' + $claude.Error })"
        $kiloRequest = Invoke-JsonPost -Uri 'http://127.0.0.1:48217/v1/chat/completions' -Headers @{ 'Authorization' = "Bearer $proxyToken"; 'Content-Type' = 'application/json' } -Body '{"model":"MiniMax-M3","messages":[{"role":"user","content":"Reply exactly OK"}],"max_tokens":8,"stream":false}' -TimeoutSec $RequestTimeoutSec
        Add-CheckResult -Name 'Kilo live request' -Status $(if ($kiloRequest.Success -and $kiloRequest.StatusCode -eq 200) { 'PASS' } else { 'FAIL' }) -Detail "status=$($kiloRequest.StatusCode)$(if ($kiloRequest.Error) { '; error=' + $kiloRequest.Error })"
        $codex = Invoke-JsonPost -Uri 'http://127.0.0.1:48218/v1/responses' -Headers @{ 'Authorization' = 'Bearer local'; 'Content-Type' = 'application/json' } -Body '{"model":"MiniMax-M3","input":[{"role":"user","content":[{"type":"input_text","text":"Reply exactly OK"}]}],"max_output_tokens":8,"stream":false}' -TimeoutSec $RequestTimeoutSec
        Add-CheckResult -Name 'Codex live request' -Status $(if ($codex.Success -and $codex.StatusCode -eq 200) { 'PASS' } else { 'FAIL' }) -Detail "status=$($codex.StatusCode)$(if ($codex.Error) { '; error=' + $codex.Error })"
    } else {
        foreach ($name in @('Claude live request', 'Kilo live request', 'Codex live request')) {
            Add-CheckResult -Name $name -Status 'SKIP' -Detail 'use -Live to run authenticated model contracts'
        }
    }

    foreach ($server in @('minimax', 'minimax-media', 'minimax-coding-plan', 'touchpoint', 'winremote', 'daves-tools-harness')) {
        $mini = Invoke-MiniList -Executable $MiniExecutable -Server $server
        Add-CheckResult -Name "MCP $server" -Status $(if ($mini.Success) { 'PASS' } else { 'FAIL' }) -Detail "tools=$($mini.ToolCount)$(if ($mini.Error) { '; error=' + $mini.Error })"
    }

    $script:IntegrationFailureCount = @($script:IntegrationResults | Where-Object { $_.Status -eq 'FAIL' }).Count
    $summary = [pscustomobject]@{
        Timestamp = (Get-Date).ToString('o')
        Verdict = $(if ($script:IntegrationFailureCount -eq 0) { 'PASS' } else { 'FAIL' })
        Failures = $script:IntegrationFailureCount
        Passed = @($script:IntegrationResults | Where-Object { $_.Status -eq 'PASS' }).Count
        Skipped = @($script:IntegrationResults | Where-Object { $_.Status -eq 'SKIP' }).Count
        Results = $script:IntegrationResults
    }
    $summary | ConvertTo-Json -Depth 6 -Compress | Add-Content -LiteralPath $LogFile
    $script:IntegrationResults | Format-Table -AutoSize | Out-String | Write-Output
    Write-Output "Client integrations: $($summary.Verdict) (pass=$($summary.Passed), fail=$($summary.Failures), skip=$($summary.Skipped))"
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-ClientIntegrationCheck -Fix:$Fix -Live:$Live -RequestTimeoutSec $RequestTimeoutSec -LogFile $LogFile -KiloConfig $KiloConfig -KiloMcpConfig $KiloMcpConfig -DevinConfig $DevinConfig -CodexConfig $CodexConfig -CodexCatalog $CodexCatalog -ProxyTokenFile $ProxyTokenFile -MiniExecutable $MiniExecutable -WhatIf:$WhatIfPreference
    exit $script:IntegrationFailureCount
}
