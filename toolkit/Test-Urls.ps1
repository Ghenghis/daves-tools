$urls = @(
    'https://github.com/microsoft/AutoGenesis',
    'https://github.com/microsoft/win-dev-skills',
    'https://github.com/microsoft/winappCli',
    'https://github.com/originsec/hyperv-mcp',
    'https://github.com/x64dbg/x64dbg',
    'https://github.com/dariushoule/x64dbg-automate-pyclient',
    'https://github.com/dariushoule/x64dbg-skills',
    'https://github.com/AssetRipper/AssetRipper',
    'https://github.com/SamboyCoding/Cpp2IL',
    'https://github.com/dnSpyEx/dnSpy',
    'https://github.com/radareorg/r2unity',
    'https://github.com/microsoft/playwright-cli'
)
foreach ($u in $urls) {
    Write-Output "--- $u"
    git ls-remote --exit-code $u 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Output 'NOT FOUND / BLOCKED' } else { Write-Output 'OK' }
}
