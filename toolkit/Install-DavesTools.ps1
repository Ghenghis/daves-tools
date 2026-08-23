# Installs the DAVE-AI Tools harness and registers the LM Studio watchdog.
# Run from the repository root or from any directory after cloning.
[CmdletBinding()]
Param(
    [string]$RepoPath = '.',
    [switch]$SkipService,
    [switch]$SkipWatchdog
)

$ErrorActionPreference = 'Stop'

function Test-Command($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Write-Step($message) {
    Write-Output ('[daves-tools] {0}' -f $message)
}

$RepoPath = Resolve-Path $RepoPath
Write-Step ('Installing from {0}' -f $RepoPath)

# Verify prerequisites
$prereqs = @('node', 'npm', 'python', 'git')
$missing = @()
foreach ($p in $prereqs) {
    if (-not (Test-Command $p)) { $missing += $p }
}
if ($missing.Count -gt 0) {
    throw 'Missing prerequisites: ' + ($missing -join ', ')
}

# Install Node dependencies
Set-Location $RepoPath
Write-Step 'Running npm install'
npm install

# Ensure directories
if (-not (Test-Path 'logs')) { New-Item -ItemType Directory -Path 'logs' | Out-Null }
if (-not (Test-Path 'configs/secrets.json') -and (Test-Path 'configs/secrets.example.json')) {
    Copy-Item 'configs/secrets.example.json' 'configs/secrets.json'
    Write-Step 'Created configs/secrets.json from example. Add your secrets and keep it secret.'
}

# Run a quick certification of the core profile
Write-Step 'Certifying CORE profile'
node harness/certifier.js --profile CORE

# Install the main harness service
if (-not $SkipService) {
    Write-Step 'Registering DAVE-AI Harness service'
    .\toolkit\Install-McpService.ps1
}

# Register the LM Studio watchdog
if (-not $SkipWatchdog) {
    Write-Step 'Registering LM Studio watchdog task'
    .\toolkit\Watch-LmStudio.ps1 -RegisterTask
}

Write-Step 'Install complete. Read docs/SETUP.md for IDE wiring.'