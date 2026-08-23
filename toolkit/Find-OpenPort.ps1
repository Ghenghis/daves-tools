# Finds an open TCP port using a tiered strategy:
#   1. Try the PreferList (customized, "most normal" ports) in order
#   2. Try PreferredPort, then PreferredPort..PreferredPort+RangeSize sequentially
#   3. Pick a random port from PreferredPort+RangeSize..PreferredPort+RangeSize+WideRange
#   4. If still nothing, retry the entire sequence MaxRetries times with RetryDelayMs between
# Designed to be dot-sourced or called by launcher scripts (ComfyUI, LM Studio,
# the MCP harness, etc.) so services never collide with ports already used
# elsewhere on this PC or a remote VPS. Set -Randomize to shuffle every phase.
[CmdletBinding()]
Param(
    [int]$PreferredPort = 8188,
    [int]$RangeSize = 50,
    [int]$WideRange = 500,
    [int]$MaxRetries = 5,
    [int]$RetryDelayMs = 250,
    [int[]]$Candidates,
    [int[]]$PreferList,
    [string]$BindAddress = '0.0.0.0',
    [string]$KnownPortsConfig,
    [string]$ServiceName,
    [switch]$SkipKnownPorts,
    [switch]$Randomize,
    [switch]$Quiet
)

function Test-PortFree {
    param([int]$Port, [string]$Address)
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Parse($Address), $Port)
        $listener.Start()
        $listener.Stop()
        return $true
    } catch {
        return $false
    }
}

function Get-ReservedPortSet {
    param([string]$ConfigPath, [string]$OwnServiceName)
    $reserved = New-Object System.Collections.Generic.HashSet[int]
    if (-not $ConfigPath -or -not (Test-Path $ConfigPath)) { return $reserved }
    try {
        $cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    } catch {
        return $reserved
    }
    if ($cfg.services) {
        foreach ($prop in $cfg.services.PSObject.Properties) {
            if ($OwnServiceName -and $prop.Name -eq $OwnServiceName) { continue }
            [void]$reserved.Add([int]$prop.Value)
        }
    }
    if ($cfg.reserved_ports) {
        foreach ($p in $cfg.reserved_ports) { [void]$reserved.Add([int]$p) }
    }
    if ($cfg.reserved_ranges) {
        foreach ($r in $cfg.reserved_ranges) {
            $rStart = [int]$r.start
            $rEnd = [int]$r.end
            if ($rEnd -lt $rStart) { $rEnd = $rStart }
            for ($p = $rStart; $p -le $rEnd; $p++) { [void]$reserved.Add($p) }
        }
    }
    return ,$reserved
}

function Find-OpenPort {
    [CmdletBinding()]
    param(
        [int]$PreferredPort = 8188,
        [int]$RangeSize = 50,
        [int]$WideRange = 500,
        [int]$MaxRetries = 5,
        [int]$RetryDelayMs = 250,
        [int[]]$Candidates,
        [int[]]$PreferList,
        [string]$BindAddress = '0.0.0.0',
        [string]$KnownPortsConfig,
        [string]$ServiceName,
        [switch]$SkipKnownPorts,
        [switch]$Randomize,
        [switch]$Quiet
    )

    if (-not $KnownPortsConfig) {
        $KnownPortsConfig = Join-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'configs') 'known-ports.json'
    }

    $reservedPorts = if ($SkipKnownPorts) {
        New-Object System.Collections.Generic.HashSet[int]
    } else {
        Get-ReservedPortSet -ConfigPath $KnownPortsConfig -OwnServiceName $ServiceName
    }

    # Build the base sequence inline (avoiding function-return-unrolling of List<>)
    $seq = New-Object System.Collections.Generic.List[int]
    if ($Candidates) {
        foreach ($p in $Candidates) { $seq.Add([int]$p) | Out-Null }
    }
    if ($PreferList) {
        foreach ($p in $PreferList) { $seq.Add([int]$p) | Out-Null }
    }
    $seq.Add([int]$PreferredPort) | Out-Null
    $seqEnd = [int]$PreferredPort + [int]$RangeSize
    for ($p = [int]$PreferredPort + 1; $p -le $seqEnd; $p++) {
        if (-not $seq.Contains($p)) { $seq.Add($p) | Out-Null }
    }
    if ($WideRange -gt 0) {
        $wideStart = $seqEnd + 1
        $wideEnd = $wideStart + $WideRange
        $widePool = New-Object System.Collections.Generic.List[int]
        for ($p = $wideStart; $p -le $wideEnd; $p++) {
            if (-not $seq.Contains($p)) { $widePool.Add($p) | Out-Null }
        }
        if ($Randomize -and $widePool.Count -gt 1) {
            $n = $widePool.Count
            for ($i = $n - 1; $i -gt 0; $i--) {
                $j = Get-Random -Minimum 0 -Maximum ($i + 1)
                $tmp = $widePool[$i]
                $widePool[$i] = $widePool[$j]
                $widePool[$j] = $tmp
            }
        }
        $take = [Math]::Min(64, $widePool.Count)
        for ($i = 0; $i -lt $take; $i++) { $seq.Add($widePool[$i]) | Out-Null }
    }
    if ($Randomize) {
        # Keep the head (Candidates/PreferList/PreferredPort) in order, shuffle the tail
        $headCount = 0
        if ($Candidates) { $headCount += $Candidates.Count }
        if ($PreferList) { $headCount += $PreferList.Count }
        $headCount += 1
        $tail = New-Object System.Collections.Generic.List[int]
        for ($i = $headCount; $i -lt $seq.Count; $i++) { $tail.Add($seq[$i]) | Out-Null }
        if ($tail.Count -gt 1) {
            $n = $tail.Count
            for ($i = $n - 1; $i -gt 0; $i--) {
                $j = Get-Random -Minimum 0 -Maximum ($i + 1)
                $tmp = $tail[$i]
                $tail[$i] = $tail[$j]
                $tail[$j] = $tmp
            }
        }
        # Rebuild seq with shuffled tail
        $newSeq = New-Object System.Collections.Generic.List[int]
        for ($i = 0; $i -lt $headCount; $i++) { $newSeq.Add($seq[$i]) | Out-Null }
        foreach ($p in $tail) { $newSeq.Add($p) | Out-Null }
        $seq = $newSeq
    }

    $tried = New-Object System.Collections.Generic.List[int]
    $skippedReserved = New-Object System.Collections.Generic.List[int]

    $attempts = [Math]::Max(1, $MaxRetries)
    for ($attempt = 1; $attempt -le $attempts; $attempt++) {
        $sequence = $seq
        if ($attempt -gt 1 -and $Randomize) {
            $shuffled = New-Object System.Collections.Generic.List[int]
            foreach ($p in $seq) { $shuffled.Add($p) | Out-Null }
            $n = $shuffled.Count
            for ($i = $n - 1; $i -gt 0; $i--) {
                $j = Get-Random -Minimum 0 -Maximum ($i + 1)
                $tmp = $shuffled[$i]
                $shuffled[$i] = $shuffled[$j]
                $shuffled[$j] = $tmp
            }
            $sequence = $shuffled
        }

        foreach ($port in $sequence) {
            $isExplicit = ($Candidates -and $Candidates -contains $port) -or ($PreferList -and $PreferList -contains $port)
            if ($reservedPorts.Contains($port) -and -not $isExplicit) {
                if (-not $skippedReserved.Contains($port)) { $skippedReserved.Add($port) | Out-Null }
                continue
            }
            if (-not $tried.Contains($port)) { $tried.Add($port) | Out-Null }
            if (Test-PortFree -Port $port -Address $BindAddress) {
                if (-not $Quiet) {
                    $msg = "[Find-OpenPort] Selected port {0} after attempt {1}/{2} (tried {3} port(s))" -f $port, $attempt, $attempts, $tried.Count
                    if ($skippedReserved.Count -gt 0) {
                        $msg += "; skipped reserved: {0}" -f ($skippedReserved -join ', ')
                    }
                    Write-Output $msg
                }
                return $port
            }
        }

        if ($attempt -lt $attempts -and $RetryDelayMs -gt 0) {
            Start-Sleep -Milliseconds $RetryDelayMs
        }
    }

    throw ("[Find-OpenPort] No open port found after {0} attempt(s) starting at {1}; tried: {2}" -f $attempts, $PreferredPort, ($tried -join ', '))
}

if ($MyInvocation.InvocationName -ne '.') {
    Find-OpenPort -PreferredPort $PreferredPort -RangeSize $RangeSize -WideRange $WideRange -MaxRetries $MaxRetries -RetryDelayMs $RetryDelayMs `
        -Candidates $Candidates -PreferList $PreferList -BindAddress $BindAddress -KnownPortsConfig $KnownPortsConfig -ServiceName $ServiceName `
        -SkipKnownPorts:$SkipKnownPorts -Randomize:$Randomize -Quiet:$Quiet
}
