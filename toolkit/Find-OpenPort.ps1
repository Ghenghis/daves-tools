# Finds an open TCP port, starting from a preferred port and shifting upward
# (or through an explicit candidate list) until an unbound port is found.
# Designed to be dot-sourced or called by launcher scripts (ComfyUI, LM Studio,
# the MCP harness, etc.) so services never collide with ports already used
# elsewhere on this PC or a remote VPS.
[CmdletBinding()]
Param(
    [int]$PreferredPort = 8188,
    [int]$RangeSize = 50,
    [int[]]$Candidates,
    [string]$BindAddress = '0.0.0.0',
    [string]$KnownPortsConfig,
    [string]$ServiceName,
    [switch]$SkipKnownPorts,
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
            for ($p = [int]$r.start; $p -le [int]$r.end; $p++) { [void]$reserved.Add($p) }
        }
    }
    return $reserved
}

function Find-OpenPort {
    [CmdletBinding()]
    param(
        [int]$PreferredPort = 8188,
        [int]$RangeSize = 50,
        [int[]]$Candidates,
        [string]$BindAddress = '0.0.0.0',
        [string]$KnownPortsConfig,
        [string]$ServiceName,
        [switch]$SkipKnownPorts,
        [switch]$Quiet
    )

    if (-not $KnownPortsConfig) {
        $KnownPortsConfig = Join-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'configs') 'known-ports.json'
    }

    $reservedPorts = if ($SkipKnownPorts) { New-Object System.Collections.Generic.HashSet[int] } else { Get-ReservedPortSet -ConfigPath $KnownPortsConfig -OwnServiceName $ServiceName }

    $tried = New-Object System.Collections.Generic.List[int]
    $skippedReserved = New-Object System.Collections.Generic.List[int]

    $portList = if ($Candidates -and $Candidates.Count -gt 0) {
        $Candidates
    } else {
        $PreferredPort..($PreferredPort + $RangeSize)
    }

    foreach ($port in $portList) {
        if ($reservedPorts.Contains($port) -and $port -ne $PreferredPort) {
            $skippedReserved.Add($port)
            continue
        }
        $tried.Add($port)
        if (Test-PortFree -Port $port -Address $BindAddress) {
            if (-not $Quiet) {
                $msg = "[Find-OpenPort] Selected port {0} (tried {1})" -f $port, ($tried -join ', ')
                if ($skippedReserved.Count -gt 0) {
                    $msg += "; skipped reserved: {0}" -f ($skippedReserved -join ', ')
                }
                Write-Host $msg
            }
            return $port
        }
    }

    throw ("[Find-OpenPort] No open port found in range starting at {0} after trying: {1}" -f $PreferredPort, ($tried -join ', '))
}

if ($MyInvocation.InvocationName -ne '.') {
    Find-OpenPort -PreferredPort $PreferredPort -RangeSize $RangeSize -Candidates $Candidates `
        -BindAddress $BindAddress -KnownPortsConfig $KnownPortsConfig -ServiceName $ServiceName `
        -SkipKnownPorts:$SkipKnownPorts -Quiet:$Quiet
}
