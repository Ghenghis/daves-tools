[CmdletBinding()]
param(
    [string]$DestRoot = "G:\MCP-Servers"
)

$ErrorActionPreference = "Continue"

$jobs = @(
    @{ id = 'assetstudio'; repo = 'Perfare/AssetStudio'; pattern = '^AssetStudio.*\.zip$' },
    @{ id = 'uabe';        repo = 'SeriousCache/UABE';   pattern = '\.zip$' },
    @{ id = 'bepinex';     repo = 'BepInEx/BepInEx';     pattern = '^BepInEx_win_x64.*\.zip$' }
)

foreach ($j in $jobs) {
    $dst = Join-Path $DestRoot $j.id
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    try {
        $rel = Invoke-RestMethod "https://api.github.com/repos/$($j.repo)/releases/latest"
        $asset = $rel.assets | Where-Object { $_.name -match $j.pattern } | Select-Object -First 1
        if (-not $asset) {
            Write-Output "NO ASSET $($j.id) (repo $($j.repo), pattern $($j.pattern))"
            continue
        }
        $zip = Join-Path $dst $asset.name
        Invoke-WebRequest $asset.browser_download_url -OutFile $zip
        Expand-Archive $zip $dst -Force
        Write-Output ("OK {0} <- {1} ({2})" -f $j.id, $asset.name, $rel.tag_name)
    }
    catch {
        Write-Output ("FAIL {0}: {1}" -f $j.id, $_.Exception.Message)
    }
}
