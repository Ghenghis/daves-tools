[CmdletBinding()]
param(
    [string[]]$SearchPaths = @("G:\private", "C:\Users\Admin\private", "$PSScriptRoot\..\private"),
    [string]$OutFile = "G:\private\.env.dpapi.json",
    [switch]$QuarantinePlaintext
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Security

$files = @()
foreach ($dir in $SearchPaths) {
    if (-not (Test-Path $dir)) { continue }
    $files += Get-ChildItem -Path $dir -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like '.env*' -and $_.Name -ne '.env.dpapi.json' }
}

$store = @{}
foreach ($file in $files | Sort-Object LastWriteTime -Descending) {
    Get-Content $file.FullName | ForEach-Object {
        $line = $_.Trim()
        if ($line -and !$line.StartsWith('#') -and $line.Contains('=')) {
            $k = $line.Split('=', 2)[0].Trim()
            $v = $line.Split('=', 2)[1].Trim() -replace '[\x22\x27]', ''
            if (-not $store.ContainsKey($k) -and $v) {
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($v)
                $cipher = [System.Security.Cryptography.ProtectedData]::Protect(
                    $bytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
                $store[$k] = [Convert]::ToBase64String($cipher)
            }
        }
    }
}

$payload = @{
    format    = 'dpapi-currentuser-json-v1'
    encrypted = (Get-Date).ToString('o')
    keys      = $store.Count
    values    = $store
}
$payload | ConvertTo-Json -Depth 3 | Set-Content -Path $OutFile -Encoding UTF8
Write-Output "Encrypted $($store.Count) secrets -> $OutFile (per-user DPAPI; only this Windows account can decrypt)"

if ($QuarantinePlaintext) {
    $quarantine = Join-Path (Split-Path $OutFile -Parent) "_plaintext_quarantine"
    New-Item -ItemType Directory -Force -Path $quarantine | Out-Null
    foreach ($file in $files) {
        Move-Item $file.FullName (Join-Path $quarantine $file.Name) -Force
    }
    Write-Output "Moved $($files.Count) plaintext .env files -> $quarantine"
}
