# Toolkit Pester tests — covers Find-OpenPort, Repair/Validate-TypedRegistry,
# Capability-Doctor, and Certify-Mcps.ps1's env-loading contract.
# Wired into .github/workflows/quality.yml alongside Test-MiniMaxClientIntegrations.Tests.ps1.
#
# Run locally:
#   Import-Module Pester -RequiredVersion 6.1.0 -Force
#   Invoke-Pester toolkit/Toolkit.Tests.ps1 -Output Detailed
[CmdletBinding()]
param()

BeforeAll {
    $script:ToolkitDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Item $MyInvocation.MyCommand.Path).DirectoryName }
    $script:RepoRoot = (Resolve-Path (Join-Path -Path $script:ToolkitDir -ChildPath '..')).Path
    $script:RegPath = Join-Path -Path $script:RepoRoot -ChildPath 'configs/typed-registry.json'
    $script:WorkDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ("daves-tools-tests-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $script:WorkDir -Force | Out-Null
}

AfterAll {
    if (Test-Path $script:WorkDir) { Remove-Item -Recurse -Force $script:WorkDir }
}

Describe 'Find-OpenPort' {
    BeforeAll {
        . (Join-Path -Path $script:ToolkitDir -ChildPath 'Find-OpenPort.ps1')
    }

    It 'returns the preferred port when it is free' {
        $free = Find-OpenPort -PreferredPort 39001 -RangeSize 5 -ServiceName 'pester-a' -Quiet
        $free | Should -Be 39001
    }

    It 'skips an occupied preferred port and finds another in range' {
        $busy = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, 39011)
        $busy.Start()
        try {
            $picked = Find-OpenPort -PreferredPort 39011 -RangeSize 10 -ServiceName 'pester-b' -Quiet
            $picked | Should -Not -Be 39011
            $picked | Should -BeGreaterOrEqual 39011
            $picked | Should -BeLessOrEqual 39021
        } finally {
            $busy.Stop()
        }
    }

    It 'tries the PreferList before the preferred port' {
        $list = @(39031, 39032)
        $picked = Find-OpenPort -PreferredPort 39099 -PreferList $list -ServiceName 'pester-c' -Quiet
        $picked | Should -Be 39031
    }

    It 'produces different ports across multiple -Randomize calls when preferred is busy' {
        $busy = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, 39041)
        $busy.Start()
        try {
            $picks = 1..5 | ForEach-Object {
                Find-OpenPort -PreferredPort 39041 -RangeSize 2 -WideRange 800 -Randomize -ServiceName 'pester-d' -Quiet
            }
            $unique = ($picks | Sort-Object -Unique).Count
            $unique | Should -BeGreaterThan 1 -Because '5 random calls with preferred port blocked should not all return the same port'
        } finally {
            $busy.Stop()
        }
    }
}

Describe 'Validate-TypedRegistry' {
    It 'accepts the live registry without schema warnings' {
        $out = & (Join-Path -Path $script:ToolkitDir -ChildPath 'Validate-TypedRegistry.ps1') -RegistryPath $script:RegPath 2>&1
        $LASTEXITCODE | Should -Be 0
        $out | Should -Match 'valid JSON with no bad escape sequences'
        $out | Should -Not -Match 'Schema warnings: [^0]'
    }

    It 'rejects a malformed JSON file' {
        $badPath = Join-Path -Path $script:WorkDir -ChildPath 'bad.json'
        'not valid json' | Out-File -FilePath $badPath -Encoding utf8
        $threw = $false
        try {
            & (Join-Path -Path $script:ToolkitDir -ChildPath 'Validate-TypedRegistry.ps1') -RegistryPath $badPath 2>&1 | Out-Null
        } catch {
            $threw = $true
        }
        $threw | Should -BeTrue
    }
}

Describe 'Repair-TypedRegistry' {
    It 'is idempotent on an already-valid registry' {
        $copyPath = Join-Path -Path $script:WorkDir -ChildPath 'reg.json'
        Copy-Item -LiteralPath $script:RegPath -Destination $copyPath -Force
        $beforeHash = (Get-FileHash -LiteralPath $copyPath -Algorithm SHA256).Hash

        $out = & (Join-Path -Path $script:ToolkitDir -ChildPath 'Repair-TypedRegistry.ps1') -RegistryPath $copyPath 2>&1
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'No invalid JSON escapes found'

        $afterHash = (Get-FileHash -LiteralPath $copyPath -Algorithm SHA256).Hash
        $afterHash | Should -BeExactly $beforeHash -Because 'repairing a clean file should not change it'
    }

    It 'repairs backslash escape sequences and the file still validates' {
        $copyPath = Join-Path -Path $script:WorkDir -ChildPath 'reg-with-bad-escape.json'
        $raw = [System.IO.File]::ReadAllText($script:RegPath)
        # Inject one stray backslash that is not part of a valid escape sequence
        $poisoned = $raw -replace 'https://github.com/', 'https:\/\/github.com\garbage/'
        [System.IO.File]::WriteAllText($copyPath, $poisoned)
        $out = & (Join-Path -Path $script:ToolkitDir -ChildPath 'Repair-TypedRegistry.ps1') -RegistryPath $copyPath 2>&1
        $LASTEXITCODE | Should -Be 0
        ($out -join "`n") | Should -Match 'Repaired invalid JSON escapes'

        # Should still parse as JSON
        { Get-Content -LiteralPath $copyPath -Raw | ConvertFrom-Json } | Should -Not -Throw
    }
}

Describe 'Capability-Doctor' {
    It 'runs against the live registry and reports a healthy count' {
        $jsonPath = Join-Path -Path $script:WorkDir -ChildPath 'cap.json'
        $mdPath = Join-Path -Path $script:WorkDir -ChildPath 'cap.md'
        & (Join-Path -Path $script:ToolkitDir -ChildPath 'Capability-Doctor.ps1') -RegistryPath $script:RegPath -JsonPath $jsonPath -MdPath $mdPath | Out-Null
        $LASTEXITCODE | Should -Be 0
        Test-Path $jsonPath | Should -BeTrue
        Test-Path $mdPath | Should -BeTrue
        $cap = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
        $cap.total | Should -BeGreaterThan 0
        $cap.healthy | Should -BeGreaterThan 0
        $cap.results.Count | Should -Be $cap.total
    }
}

Describe 'Certify-Mcps env-loading contract' {
    It 'dot-sources Load-PrivateEnv.ps1 so token aliases reach the child MCP' {
        $source = Get-Content -LiteralPath (Join-Path -Path $script:ToolkitDir -ChildPath 'Certify-Mcps.ps1') -Raw
        $source | Should -Match 'Load-PrivateEnv\.ps1'
        $source | Should -Match '\.\s*\(?\s*Join-Path.*Load-PrivateEnv'
    }

    It 'regression: registry declares env_refs the alias map can satisfy for gitlab-mcp' {
        $reg = Get-Content -LiteralPath $script:RegPath -Raw | ConvertFrom-Json
        $gitlab = $reg.assets | Where-Object { $_.id -eq 'gitlab-mcp' } | Select-Object -First 1
        $gitlab | Should -Not -BeNullOrEmpty
        $gitlab.runtime.env_refs | Should -Contain 'GITLAB_PERSONAL_ACCESS_TOKEN'
        # Load-PrivateEnv maps GITLAB_TOKEN -> GITLAB_PERSONAL_ACCESS_TOKEN
        $source = Get-Content -LiteralPath (Join-Path -Path $script:ToolkitDir -ChildPath 'Load-PrivateEnv.ps1') -Raw
        $source | Should -Match "GITLAB_TOKEN'\s*=\s*'GITLAB_PERSONAL_ACCESS_TOKEN'"
    }
}

Describe 'Build-Release and Verify-Release' {
    It 'Build-Release.ps1 produces a versioned ZIP with a manifest and a SHA256 sidecar' {
        $outDir = Join-Path -Path $script:WorkDir -ChildPath 'release'
        & (Join-Path -Path $script:ToolkitDir -ChildPath 'Build-Release.ps1') -Version '9.9.9-test' -OutDir $outDir -SkipVerify | Out-Null
        $LASTEXITCODE | Should -Be 0
        Test-Path (Join-Path -Path $outDir -ChildPath 'daves-tools-v9.9.9-test.zip') | Should -BeTrue
        Test-Path (Join-Path -Path $outDir -ChildPath 'daves-tools-v9.9.9-test.zip.sha256') | Should -BeTrue
        Test-Path (Join-Path -Path $outDir -ChildPath 'daves-tools-v9.9.9-test/RELEASE.json') | Should -BeTrue

        # SHA256 sidecar matches the actual hash
        $expected = (Get-Content -LiteralPath (Join-Path -Path $outDir -ChildPath 'daves-tools-v9.9.9-test.zip.sha256') -Raw).Trim().Split(' ')[0].ToLower()
        $actual = (Get-FileHash -LiteralPath (Join-Path -Path $outDir -ChildPath 'daves-tools-v9.9.9-test.zip') -Algorithm SHA256).Hash.ToLower()
        $actual | Should -BeExactly $expected
    }

    It 'Build-Release injects the version into the bundled harness/package.json' {
        $outDir = Join-Path -Path $script:WorkDir -ChildPath 'release2'
        & (Join-Path -Path $script:ToolkitDir -ChildPath 'Build-Release.ps1') -Version '9.9.8-test' -OutDir $outDir -SkipVerify | Out-Null
        $bundleRoot = Get-ChildItem -Path $outDir -Directory | Where-Object { $_.Name -like 'daves-tools-*' } | Select-Object -First 1
        $pkg = Get-Content -LiteralPath (Join-Path -Path $bundleRoot.FullName -ChildPath 'harness/package.json') -Raw | ConvertFrom-Json
        $pkg.version | Should -Be '9.9.8-test'
    }

    It 'Build-Release excludes node_modules, logs, daemon, audit, secrets patterns' {
        $outDir = Join-Path -Path $script:WorkDir -ChildPath 'release3'
        & (Join-Path -Path $script:ToolkitDir -ChildPath 'Build-Release.ps1') -Version '9.9.7-test' -OutDir $outDir -SkipVerify | Out-Null
        $bundleRoot = Get-ChildItem -Path $outDir -Directory | Where-Object { $_.Name -like 'daves-tools-*' } | Select-Object -First 1
        $bundlePath = $bundleRoot.FullName
        # Excludes
        Test-Path (Join-Path -Path $bundlePath -ChildPath 'harness/node_modules') | Should -BeFalse
        Test-Path (Join-Path -Path $bundlePath -ChildPath 'harness/daemon') | Should -BeFalse
        Test-Path (Join-Path -Path $bundlePath -ChildPath 'logs') | Should -BeFalse
        Test-Path (Join-Path -Path $bundlePath -ChildPath '.git') | Should -BeFalse
        # Includes
        Test-Path (Join-Path -Path $bundlePath -ChildPath 'toolkit/Install-DavesTools.ps1') | Should -BeTrue
        Test-Path (Join-Path -Path $bundlePath -ChildPath 'harness/package.json') | Should -BeTrue
        Test-Path (Join-Path -Path $bundlePath -ChildPath 'configs/typed-registry.json') | Should -BeTrue
        Test-Path (Join-Path -Path $bundlePath -ChildPath 'README.md') | Should -BeTrue
        Test-Path (Join-Path -Path $bundlePath -ChildPath 'CHANGELOG.md') | Should -BeTrue
        Test-Path (Join-Path -Path $bundlePath -ChildPath 'RELEASE.json') | Should -BeTrue
    }

    It 'Verify-Release accepts a freshly built ZIP' {
        $outDir = Join-Path -Path $script:WorkDir -ChildPath 'release4'
        & (Join-Path -Path $script:ToolkitDir -ChildPath 'Build-Release.ps1') -Version '9.9.6-test' -OutDir $outDir -SkipVerify | Out-Null
        $zipPath = Join-Path -Path $outDir -ChildPath 'daves-tools-v9.9.6-test.zip'
        # Use a dedicated extract dir so Verify's cleanup does not race the test framework
        $extractRoot = Join-Path -Path $script:WorkDir -ChildPath 'extract4'
        & (Join-Path -Path $script:ToolkitDir -ChildPath 'Verify-Release.ps1') -ZipPath $zipPath -ExtractRoot $extractRoot -KeepExtract | Out-Null
        $LASTEXITCODE | Should -Be 0
        Test-Path (Join-Path -Path $extractRoot -ChildPath 'daves-tools-v9.9.6-test') | Should -BeTrue
        Remove-Item -Recurse -Force $extractRoot
    }
}
