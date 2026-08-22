[CmdletBinding()]
param(
    [string]$Root = "C:\Users\Admin\CascadeProjects\daves-tools"
)

$ErrorActionPreference = "Continue"
node (Join-Path $Root "harness\service.js") stop
node (Join-Path $Root "harness\service.js") uninstall
