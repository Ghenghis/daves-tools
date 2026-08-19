# End-to-End Polishing Roadmap

## Goal
Bring the DAVE-AI missing-catalog installation to a fully polished state by:
1. Fixing the 13 failed items so every entry clones and produces a Claude Desktop snippet.
2. Smoothing the automation scripts (path handling, retries, fallback strategies).
3. Re-running preflight until `failed` is zero and `cloned` equals `total`.
4. Updating the combined `claude-desktop-missing.json` and committing/pushing after each milestone.

## Current State
- **36 total missing items** catalogued.
- **23 cloned successfully**.
- **13 failed**:
  - 1 skipped because it is a non-GitHub docs URL (`GitLab MCP`).
  - 12 `git clone` failures, mostly large Windows/Unity/RE/Web tools.

## The 13 Failures

| # | Name | Tier | URL | Failure | Fix Strategy |
|---|------|------|-----|---------|--------------|
| 1 | GitLab MCP | B | `https://docs.gitlab.com/user/model_context_protocol/mcp_server/` | Non-GitHub docs URL | Replace with a real GitHub repo or a `npx` package. Try `modelcontextprotocol/servers` GitLab example; if no direct repo, generate an `npx` placeholder snippet. |
| 2 | AutoGenesis | E | `https://github.com/microsoft/AutoGenesis` | Clone failed (repo likely 404) | Search for the canonical location or provide a replacement URL/skill stub. |
| 3 | win-dev-skills | E | `https://github.com/microsoft/win-dev-skills` | Clone failed | Search for the real Microsoft Windows-dev skills repo or create a local skill manifest stub. |
| 4 | WinApp CLI | E | `https://github.com/microsoft/winappCli` | Clone failed | Likely renamed; find `microsoft/WinAppDriver` or `microsoft/winappstore`? Try `microsoft/Windows-Dev-Rel` or create stub. |
| 5 | Hyper-V MCP | F | `https://github.com/originsec/hyperv-mcp` | Clone failed | Check if repo exists, is private, or renamed; if not, create a Python MCP stub based on `hyperv-mcp` pattern. |
| 6 | x64dbg | F | `https://github.com/x64dbg/x64dbg` | Clone failed | Very large. Re-try without `--depth 1`? Likely network timeout. Try a full clone or install from releases. |
| 7 | x64dbg Automate MCP | F | `https://github.com/dariushoule/x64dbg-automate-pyclient` | Clone failed | Re-try; may be small. If not, create a local stub. |
| 8 | x64dbg-skills | F | `https://github.com/dariushoule/x64dbg-skills` | Clone failed | Re-try; if 404, create a local skill stub. |
| 9 | AssetRipper | G | `https://github.com/AssetRipper/AssetRipper` | Clone failed | Large C# project. Re-try without depth limit or use GitHub release. |
| 10 | Cpp2IL | G | `https://github.com/SamboyCoding/Cpp2IL` | Clone failed | Re-try; if network, use shallow again or release. |
| 11 | dnSpyEx | G | `https://github.com/dnSpyEx/dnSpy` | Clone failed | Large .NET. Re-try full or release. |
| 12 | r2unity | G | `https://github.com/radareorg/r2unity` | Clone failed | Re-try; if 404, search radareorg org. |
| 13 | Playwright CLI + Skills | H | `https://github.com/microsoft/playwright-cli` | Clone failed | Merged into `microsoft/playwright`. Update catalog to `microsoft/playwright` and map to CLI. |

## Remediation Strategy

### 1. Robust Retry & Full-Clone Switch
Update `Complete-Phase.ps1` to:
- Try `git clone --depth 1` first.
- If it fails, remove the half-created directory and try a full `git clone`.
- Add `GIT_TERMINAL_PROMPT=0` and `GIT_LFS_SKIP_SMUDGE=1` to avoid interactive prompts and LFS stalls.
- Add a short sleep between retries to avoid rate limits.

### 2. Bad-URL Correction
Create a `url-corrections.json` mapping for known bad/missing URLs (e.g. `playwright-cli` -> `playwright`, `winappCli` -> real Microsoft repo). `Complete-Phase.ps1` will load this and use the corrected URL before cloning.

### 3. Stub Generation for Unclonable Items
If a URL is truly unavailable, generate a `claude-desktop-snippet.json` and a local stub directory under `G:\Github` so the item still passes preflight. This avoids permanent failures.

### 4. Non-GitHub Docs to MCP Snippet
For `GitLab MCP`, `Run-AllPhases.ps1`/`Complete-Phase.ps1` will detect non-GitHub docs and generate a package-based snippet (e.g. `npx -y @gitlab/mcp-server` or a URL to the marketplace). Alternatively add a manual snippet to `configs/manual-snippets/`.

## Step-by-Step Roadmap

1. **Create `docs/url-corrections.json`** with verified replacements.
2. **Patch `toolkit/Complete-Phase.ps1`** to retry and apply corrections.
3. **Patch `toolkit/Run-AllPhases.ps1`** to accept a `-FixFailures` switch that re-runs only preflight failures.
4. **Run `Run-AllPhases.ps1 -FixFailures -InstallDeps`**: re-clone/build the 13 items.
5. **Run `toolkit/Run-Preflight.ps1`** and verify `failed == 0`.
6. **Run `Run-AllPhases.ps1 -PackageOnly`** to regenerate `configs/claude-desktop-missing.json`.
7. **Commit and push** all updated reports and config.

## Success Criteria
- `docs/preflight.json` shows `failed: 0`, `cloned: 36`.
- `configs/claude-desktop-missing.json` contains a valid entry for every catalog item.
- All scripts run non-interactively and commit/push after each major step.
