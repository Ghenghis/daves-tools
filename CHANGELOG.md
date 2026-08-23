# Changelog

All notable changes to `daves-tools` are documented here. Versions follow [Semantic Versioning](https://semver.org/).

## [v1.2.0] - 2026-08-23

### Added
- `toolkit/Toolkit.Tests.ps1`: 11 Pester tests covering Find-OpenPort randomization + PreferList, Repair-TypedRegistry idempotency + escape repair, Validate-TypedRegistry clean + malformed cases, Capability-Doctor happy path, and the Certify-Mcps.ps1 env-loading contract
- `CHANGELOG.md`: this file

### Changed
- `.github/workflows/quality.yml`: Pester step now runs both `Test-MiniMaxClientIntegrations.Tests.ps1` and `Toolkit.Tests.ps1`; the build fails on any test failure across both suites
- `toolkit/Watch-LmStudio.ps1`: `Join-Path` calls now use named parameters (`-Path`/`-ChildPath`), eliminating the last 13 Information-level findings

### Verification
- PSScriptAnalyzer: 0 Warning, 0 Error across all `toolkit/*.ps1`
- Pester: 11/11 Toolkit.Tests pass; 24/24 MiniMax harness tests pass

## [v1.1.0] - 2026-08-23

### Added
- Per-toolkit-script PSScriptAnalyzer gate in CI (was: hardcoded list of 2 MiniMax scripts)

### Changed
- 16 toolkit scripts cleaned to zero PSScriptAnalyzer warnings:
  - `Write-Host` → `Write-Output` across 8 files (Audit-PowerShellPopup, Repair-TypedRegistry, Validate-TypedRegistry, Start-ComfyUI, Watch-LmStudio, Sync-RepoCatalog, Install-DavesTools, Find-OpenPort)
  - `Test-CommandExists` → `Test-CommandExist`; `Get-McpServers` → `Get-McpServer`; `Score-Overlap` → `Measure-Overlap` (approved PowerShell verbs, singular nouns)
  - `[switch]$WhatIf` removed from `Install-IdeConfigs` (redundant with `[CmdletBinding()]`); unused `$RegistryPath`/`$backup`/`$allHealthy`/`$allProfiles` removed
  - `$profile` (PowerShell automatic variable) → `$preflight` in `Project-Preflight.ps1`
  - `$PSScriptRoot = ...` → `$scriptRoot = ...` in Repair/Validate-TypedRegistry
  - `$r -ne $null` → `$null -ne $r` in `Watch-LmStudio.ps1` and `Capability-Doctor.ps1`
  - `[CmdletBinding(SupportsShouldProcess)]` added to `Stop-LmStudioProcess` and `Start-LmStudioProcess`

## [v1.0.0] - 2026-08-23

### Added
- Release-grade MiniMax four-client integration harness with Pester coverage (`Test-MiniMaxClientIntegrations.ps1` + `.Tests.ps1`)
- Atomic JSON writes in `harness/certify-asset.js` via tmp + rename
- `Find-OpenPort.ps1` randomization, retry, PreferList, and WideRange options
- `Repair-TypedRegistry.ps1` + `Validate-TypedRegistry.ps1` (with `-Strict`)
- Typed-registry schema and JSON-escape validation in CI

### Fixed
- `Release-Gate.ps1`: 12 PowerShell 7 `?:` ternaries replaced with `if/else` (was unparseable on Windows PowerShell 5.1)
- `Find-OpenPort.ps1`: pre-existing `reserved_ranges` bug where loop referenced undefined `$end` instead of `$r.end`
- `Certify-Mcps.ps1`: now dot-sources `Load-PrivateEnv.ps1` so token aliases (GITLAB_TOKEN → GITLAB_PERSONAL_ACCESS_TOKEN, etc.) reach child MCPs; this took GitLab-MCP from `failed` → `passed`
- `audit/cert-serena.json`: deleted (was corrupted by a non-atomic write race)
- ComfyUI HTTP endpoint restarted after 663 consecutive fetch failures; port 8188 CPU mode

### Changed
- Typed registry header counts corrected: total 43→62, mcp_server_count 16→12, dependency_count 12→32
- 10 assets received missing `profiles` + `permissions` defaults (Unity tool packs → `UNITY-RE`; media stack → `MEDIA`)
- README.md: dropped non-existent `tests/` row, added `harness/daemon/` row, replaced stale 2/16 cert citation
- `docs/certification-summary.{json,md}` regenerated: 12 passed / 0 failed / 14 total (was: 2/16/16 from 2026-08-19)

### Verified
- PSScriptAnalyzer: 0 ParseError across all `toolkit/*.ps1`
- 14/14 cert JSONs parse cleanly
- 21/21 Node.js files syntax-clean
- Pre-push smoke test green
- All 12 supervised MCP servers report `up`; ComfyUI HTTP 200 v0.33.0
