[CmdletBinding()]
param(
    [string[]]$SearchPaths = @("G:\private", "C:\Users\Admin\private", "$PSScriptRoot\..\private")
)

$ErrorActionPreference = "SilentlyContinue"

foreach ($dir in $SearchPaths) {
    if (-not (Test-Path $dir)) { continue }
    $files = Get-ChildItem -Path $dir -File -Filter '*.env' -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        Get-Content $file.FullName | ForEach-Object {
            $line = $_.Trim()
            if ($line -and !$line.StartsWith('#') -and $line.Contains('=')) {
                $k = $line.Split('=', 2)[0].Trim()
                $v = $line.Split('=', 2)[1].Trim()
                $v = $v -replace '[\x22\x27]', ''
                [Environment]::SetEnvironmentVariable($k, $v, 'Process')
            }
        }
    }
}
