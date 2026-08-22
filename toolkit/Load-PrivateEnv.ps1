[CmdletBinding()]
param(
    [string[]]$SearchPaths = @("G:\private", "C:\Users\Admin\private", "$PSScriptRoot\..\private", "C:\Users\Admin"),
    [switch]$Quiet
)

$ErrorActionPreference = "SilentlyContinue"

$all = @()
foreach ($dir in $SearchPaths) {
    if (-not (Test-Path $dir)) { continue }
    $all += Get-ChildItem -Path $dir -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '.env*' }
}

$defaults = @{
    'PLAYWRIGHT_BROWSERS_PATH' = '0'
    'UV_PYTHON' = 'python'
}

$loaded = @{}
foreach ($k in $defaults.Keys) {
    [Environment]::SetEnvironmentVariable($k, $defaults[$k], 'Process')
    $loaded[$k] = '<default>'
}

foreach ($file in $all | Sort-Object LastWriteTime -Descending) {
    Get-Content $file.FullName | ForEach-Object {
        $line = $_.Trim()
        if ($line -and !$line.StartsWith('#') -and $line.Contains('=')) {
            $k = $line.Split('=', 2)[0].Trim()
            $v = $line.Split('=', 2)[1].Trim()
            $v = $v -replace '[\x22\x27]', ''
            if (-not $loaded.ContainsKey($k)) {
                [Environment]::SetEnvironmentVariable($k, $v, 'Process')
                $loaded[$k] = $file.FullName
            }

            $aliases = @{
                'GITHUB_TOKEN' = 'GITHUB_PERSONAL_ACCESS_TOKEN'
                'GH_TOKEN' = 'GITHUB_PERSONAL_ACCESS_TOKEN'
                'GITLAB_TOKEN' = 'GITLAB_PERSONAL_ACCESS_TOKEN'
                'GL_TOKEN' = 'GITLAB_PERSONAL_ACCESS_TOKEN'
            }
            foreach ($from in $aliases.Keys) {
                if ($k -ieq $from -and -not $loaded.ContainsKey($aliases[$from])) {
                    [Environment]::SetEnvironmentVariable($aliases[$from], $v, 'Process')
                    $loaded[$aliases[$from]] = $file.FullName
                }
            }
        }
    }
}

if (-not $Quiet) {
    Write-Output "Loaded $($loaded.Count) unique env vars from G:\private (newest wins)"
}
