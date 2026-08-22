[CmdletBinding()]
param(
    [string]$Root = "C:\Users\Admin\CascadeProjects\daves-tools"
)

$ErrorActionPreference = "Stop"
$hookSrc = Join-Path $Root "toolkit\pre-push"
$hookDst = Join-Path $Root ".git\hooks\pre-push"

Copy-Item $hookSrc $hookDst -Force
Write-Output "Installed pre-push hook -> $hookDst"
Write-Output "Push will be blocked when the MCP smoke test fails."
