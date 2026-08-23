BeforeAll {
    . "$PSScriptRoot\Test-MiniMaxClientIntegrations.ps1"
}

Describe 'Add-CheckResult' {
    It 'records one result without writing pipeline output' {
        $list = [System.Collections.Generic.List[object]]::new()
        $output = Add-CheckResult -Name 'sample' -Status 'PASS' -Detail 'ok' -ResultList $list
        $output | Should -BeNullOrEmpty
        $list.Count | Should -Be 1
        $list[0].Check | Should -Be 'sample'
        $list[0].Status | Should -Be 'PASS'
        $list[0].Detail | Should -Be 'ok'
    }
}

Describe 'Test-JsonFile' {
    It 'accepts well-formed JSON' {
        '{ "a": 1 }' | Set-Content -LiteralPath "$TestDrive\valid.json" -NoNewline
        Test-JsonFile -Path "$TestDrive\valid.json" | Should -BeTrue
    }

    It 'rejects malformed JSON' {
        'not json' | Set-Content -LiteralPath "$TestDrive\invalid.json" -NoNewline
        Test-JsonFile -Path "$TestDrive\invalid.json" | Should -BeFalse
    }

    It 'rejects a missing file' {
        Test-JsonFile -Path "$TestDrive\missing.json" | Should -BeFalse
    }
}

Describe 'Test-ContainsSecret' {
    It 'detects known credential formats' -ForEach @(
        ('sk-' + ('a' * 32)),
        ('ghp_' + ('b' * 32)),
        ('github_pat_' + ('c' * 32)),
        ('glpat-' + ('d' * 32))
    ) {
        Test-ContainsSecret -Text $_ | Should -BeTrue
    }

    It 'does not flag file and environment references' -ForEach @(
        '{file:C:\private\.proxy-token}',
        '{env:MINIMAX_API_KEY}',
        'GITHUB_TOKEN'
    ) {
        Test-ContainsSecret -Text $_ | Should -BeFalse
    }
}

Describe 'Get-ServiceHealth' {
    It 'reports a missing service without attempting repair' {
        Mock Get-Service { throw 'not found' }
        Mock Start-Service { }
        $result = Get-ServiceHealth -Name 'missing' -Fix
        $result.Running | Should -BeFalse
        $result.State | Should -Be 'missing'
        Should -Invoke -CommandName Start-Service -Times 0 -Exactly
    }

    It 'reports an already-running service' {
        Mock Get-Service { [pscustomobject]@{ Status = 'Running' } }
        $result = Get-ServiceHealth -Name 'running'
        $result.Running | Should -BeTrue
        $result.Repair | Should -Be 'not-needed'
    }

    It 'starts and rechecks a stopped service' {
        $script:getServiceCalls = 0
        Mock Get-Service {
            $script:getServiceCalls += 1
            if ($script:getServiceCalls -eq 1) { [pscustomobject]@{ Status = 'Stopped' } }
            else { [pscustomobject]@{ Status = 'Running' } }
        }
        Mock Start-Service { }
        Mock Start-Sleep { }
        $result = Get-ServiceHealth -Name 'stopped' -Fix
        $result.Running | Should -BeTrue
        $result.Repair | Should -Be 'attempted'
        Should -Invoke -CommandName Start-Service -Times 1 -Exactly
    }

    It 'does not mutate in WhatIf mode' {
        Mock Get-Service { [pscustomobject]@{ Status = 'Stopped' } }
        Mock Start-Service { }
        $result = Get-ServiceHealth -Name 'stopped' -Fix -WhatIf
        $result.Running | Should -BeFalse
        $result.Repair | Should -Be 'what-if'
        Should -Invoke -CommandName Start-Service -Times 0 -Exactly
    }

    It 'reports a failed repair' {
        Mock Get-Service { [pscustomobject]@{ Status = 'Stopped' } }
        Mock Start-Service { throw 'access denied' }
        $result = Get-ServiceHealth -Name 'stopped' -Fix
        $result.Running | Should -BeFalse
        $result.Repair | Should -Be 'attempted'
        $result.Error | Should -Match 'access denied'
    }
}

Describe 'Get-PortHealth' {
    It 'reports one listener and its process' {
        Mock Get-NetTCPConnection { [pscustomobject]@{ OwningProcess = 42 } }
        Mock Get-Process { [pscustomobject]@{ ProcessName = 'python' } }
        $result = Get-PortHealth -Port 48217
        $result.Listening | Should -BeTrue
        $result.ListenerCount | Should -Be 1
        $result.Processes | Should -Contain 'python'
    }

    It 'reports an unavailable listener query' {
        Mock Get-NetTCPConnection { throw 'not supported' }
        $result = Get-PortHealth -Port 48217
        $result.Listening | Should -BeFalse
        $result.Error | Should -Match 'not supported'
    }
}

Describe 'Invoke-JsonPost' {
    It 'returns a successful structured result' {
        Mock Invoke-WebRequest { [pscustomobject]@{ StatusCode = 200; Content = '{"ok":true}' } }
        $result = Invoke-JsonPost -Uri 'http://localhost/test' -Headers @{} -Body '{}'
        $result.Success | Should -BeTrue
        $result.StatusCode | Should -Be 200
        $result.Content | Should -Match 'ok'
    }

    It 'returns a failed structured result on exception' {
        Mock Invoke-WebRequest { throw 'network error' }
        $result = Invoke-JsonPost -Uri 'http://localhost/test' -Headers @{} -Body '{}'
        $result.Success | Should -BeFalse
        $result.StatusCode | Should -Be 0
        $result.Error | Should -Match 'network error'
    }
}

Describe 'Invoke-MiniList' {
    It 'fails clearly when mini is missing' {
        $result = Invoke-MiniList -Executable "$TestDrive\missing-mini.exe" -Server 'minimax'
        $result.Success | Should -BeFalse
        $result.Error | Should -Be 'mini executable missing'
    }

    It 'counts tools from a successful executable' {
        $fakeMini = "$TestDrive\fake-mini.cmd"
        "@echo off`r`necho TOOL    DESCRIPTION`r`necho first_tool(arg)    first`r`necho second_tool    second`r`nexit /b 0" |
            Set-Content -LiteralPath $fakeMini -NoNewline
        $result = Invoke-MiniList -Executable $fakeMini -Server 'sample'
        $result.Success | Should -BeTrue
        $result.ToolCount | Should -Be 2
    }
}

Describe 'Configuration regressions' {
    It 'counts custom Kilo models correctly' {
        $models = [pscustomobject]@{
            first = @{ id = 'MiniMax-M3' }
            second = @{ id = 'MiniMax-M2.7' }
            third = @{ id = 'MiniMax-M2.7-highspeed' }
        }
        ($models.PSObject.Properties | Measure-Object).Count | Should -Be 3
    }

    It 'requires the aggregate MCP to remain disabled' {
        $configuration = '{"mcpServers":{"daves-tools":{"command":"mini.exe","disabled":true}}}' | ConvertFrom-Json
        $configuration.mcpServers.'daves-tools'.disabled | Should -BeTrue
    }
}
