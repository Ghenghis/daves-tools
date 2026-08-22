[CmdletBinding()]
param(
    [string]$Root = "C:\Users\Admin\CascadeProjects\daves-tools",
    [switch]$EmitSystemdUnit
)

$ErrorActionPreference = "Stop"

if ($EmitSystemdUnit) {
    $unit = @"
[Unit]
Description=DavesTools MCP Watchdog
After=network.target

[Service]
Type=simple
WorkingDirectory=$Root
ExecStart=/usr/bin/node harness/watchdog.js
Restart=always
RestartSec=10
Environment=WATCHDOG_INTERVAL_MS=60000

[Install]
WantedBy=default.target
"@
    $out = Join-Path $Root "configs\daves-tools-mcp-watchdog.service"
    [System.IO.File]::WriteAllText($out, $unit)
    Write-Output "Wrote systemd unit: $out"
    Write-Output "Install on Linux: cp to ~/.config/systemd/user/ then: systemctl --user enable --now daves-tools-mcp-watchdog.service"
    return
}

$harness = Join-Path $Root "harness"
if (-not (Test-Path (Join-Path $harness "node_modules\node-windows"))) {
    Write-Output "Installing node-windows..."
    Push-Location $harness
    try { npm install node-windows --save } finally { Pop-Location }
}

Write-Output "Installing Windows service..."
node (Join-Path $harness "service.js") install
