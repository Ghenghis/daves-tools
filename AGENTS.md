# DAVE-AI Tools Contributor Notes

## MiniMax integration verification

Run the PowerShell unit tests before changing the four-client integration harness:

```powershell
Import-Module Pester -RequiredVersion 6.1.0
Invoke-Pester toolkit\Test-MiniMaxClientIntegrations.Tests.ps1 -Output Detailed
```

Run full-severity static analysis and require zero findings:

```powershell
Import-Module PSScriptAnalyzer -RequiredVersion 1.25.0
Invoke-ScriptAnalyzer toolkit\Test-MiniMaxClientIntegrations.ps1
Invoke-ScriptAnalyzer toolkit\Test-MiniMaxClientIntegrations.Tests.ps1
```

The default harness run is cost-free. Use `-Live` only when authenticated text
calls are intended. Use `-Fix -WhatIf` before applying service repairs. Never
terminate an unexpected port owner automatically.

Do not configure desktop clients with unrestricted `mini connect`; the measured
aggregate exposed 387 tools. Use targeted MiniMax MCP servers.

## Node harness verification

```powershell
npm ci --prefix harness
npm test --prefix harness --if-present
npm audit --prefix harness --omit=dev --audit-level=high
```

Generated JSONL reports under `logs/` are local evidence and must not be
committed. Credentials belong outside the repository.
