[CmdletBinding()]
param(
    [string]$EnvLoader = "C:\Users\Admin\CascadeProjects\daves-tools\toolkit\Load-PrivateEnv.ps1",
    [string]$JsonPath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\provider-token-status.json",
    [string]$MdPath = "C:\Users\Admin\CascadeProjects\daves-tools\docs\PROVIDER-TOKEN-STATUS.md"
)

$ErrorActionPreference = "SilentlyContinue"

& $EnvLoader -Quiet

$providers = @(
    @{ name = 'MiniMax'; token_env = 'MINIMAX_API_KEY'; base_url = 'https://api.minimaxi.chat'; default = $true; models = @('MiniMax-M2.7-highspeed') }
    @{ name = 'DeepSeek'; token_env = 'DEEPSEEK_API_KEY'; base_url = 'https://api.deepseek.com'; default = $false; models = @('deepseek-chat','deepseek-reasoner') }
    @{ name = 'SiliconFlow'; token_env = 'SILICONFLOW_API_KEY'; base_url = 'https://api.siliconflow.cn'; default = $false; models = @() }
    @{ name = 'LM Studio'; token_env = 'LMSTUDIO_API_KEY'; base_url = 'http://127.0.0.1:1234'; default = $false; models = @() }
    @{ name = 'Ollama'; token_env = 'OLLAMA_API_KEY'; base_url = 'http://127.0.0.1:11434'; default = $false; models = @() }
    @{ name = 'OpenRouter'; token_env = 'OPENROUTER_API_KEY'; base_url = 'https://openrouter.ai/api'; default = $false; models = @('claude-sonnet-4','deepseek-v3') }
    @{ name = 'DeepInfra'; token_env = 'DEEPINFRA_TOKEN'; base_url = 'https://api.deepinfra.com'; default = $false; models = @() }
)

$results = @()
$ready = 0
foreach ($p in $providers) {
    $token = [Environment]::GetEnvironmentVariable($p.token_env)
    $hasToken = $token -and $token.Length -gt 0
    if ($hasToken) { $ready++ }
    $results += [ordered]@{
        name = $p.name
        token_env = $p.token_env
        present = $hasToken
        is_default = $p.default
        base_url = $p.base_url
        models = $p.models
    }
}

$json = [ordered]@{
    timestamp = (Get-Date -Format 'o')
    total = $providers.Count
    ready = $ready
    providers = $results
}

[System.IO.File]::WriteAllText($JsonPath, ($json | ConvertTo-Json -Depth 3))

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# LLM Provider Token Status")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("**Generated:** $($json.timestamp)**")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("- **Total providers:** $($json.total)")
[void]$sb.AppendLine("- **Ready:** $($json.ready)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("| Provider | Token Env | Present | Default | Base URL |")
[void]$sb.AppendLine("|---|---|---|---|---|")
foreach ($r in $results) {
    [void]$sb.AppendLine("| $($r.name) | ``$($r.token_env)`` | $($r.present) | $($r.is_default) | $($r.base_url) |")
}
[void]$sb.AppendLine("")
[void]$sb.AppendLine("Values are NOT shown. Place tokens in ``G:\private\*.env`` and run ``toolkit\Load-PrivateEnv.ps1``.")

[System.IO.File]::WriteAllText($MdPath, $sb.ToString())
Write-Output "Ready providers: $ready / $($providers.Count)"
Write-Output "Wrote $JsonPath and $MdPath"
