# DAVE-AI Toolkit

PowerShell helpers that keep the DAVE-AI workspace complete and up to date.

## Scripts

- `Sync-RepoCatalog.ps1` — Compare the official `repo_catalog.json` against the local workspace and emit a `missing-from-catalog.json` report.

## Usage

```powershell
# Default: compare against claude-codex-devin
.\toolkit\Sync-RepoCatalog.ps1

# Custom catalog or workspace
.\toolkit\Sync-RepoCatalog.ps1 -CatalogPath "G:\Github\DAVEAI\repo_catalog.json" -Workspace "C:\Users\Admin\claude-codex-devin"
```
