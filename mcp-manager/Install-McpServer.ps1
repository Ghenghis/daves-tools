[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Name,

    [string]$InstallRoot = "G:\Github",
    [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"

$marketplace = Get-Content -Path "$PSScriptRoot\marketplace.json" -Raw | ConvertFrom-Json
$entry = $marketplace.sources | Where-Object { $_.name -eq $Name }

if (-not $entry) {
    throw "MCP server '$Name' not found in marketplace. Valid names: $($marketplace.sources.name -join ', ')"
}

$repoName = ($entry.repo -split '/')[-1]
$targetPath = Join-Path $InstallRoot $repoName

if (-not $SkipInstall) {
    if (Test-Path $targetPath) {
        Write-Host "Repo already exists at $targetPath" -ForegroundColor Cyan
    } else {
        Write-Host "Cloning $($entry.repo) into $targetPath" -ForegroundColor Cyan
        git clone $entry.repo $targetPath
    }
    $README = Join-Path $targetPath "README.md"
    if (-not (Test-Path $README)) {
        throw "Cloned repo is missing README.md; installation may have failed."
    }
}

$snippet = @"
{
    "$Name": {
        "command": "python",
        "args": [
            "$targetPath\server.py"
        ],
        "env": {}
    }
}
"@

Write-Host "Claude Desktop snippet:" -ForegroundColor Green
Write-Host $snippet

$outFile = Join-Path $targetPath "claude-desktop-snippet.json"
$snippet | Set-Content -Path $outFile -Encoding UTF8
Write-Host "Snippet saved to $outFile" -ForegroundColor Green
