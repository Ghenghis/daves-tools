# Remaining Work — End-to-End Completion Runbook

> Last updated: 2026-08-22. This document captures **everything left to finish**, in
> dependency order, with exact commands, verification steps, and acceptance criteria.
> Any agent or developer should be able to complete the project from this document alone.

---

## Current State Snapshot

| Area | Status | Evidence |
|---|---|---|
| ComfyUI installed | DONE — `S:\ComfyUI`, v0.33.0 | `logs/comfyui-server.log` |
| ComfyUI responding | DONE — HTTP 200 on `/system_stats`, CPU mode, port 8188 | Verified 2026-08-22 10:46 |
| Torch stack | DONE — `torch 2.13.0+cpu`, `torchvision 0.28.0+cpu`, `torchaudio 2.11.0+cpu` | `pip show torch` |
| Port auto-shift tooling | DONE — `toolkit/Find-OpenPort.ps1`, `toolkit/Start-ComfyUI.ps1`, `configs/known-ports.json` | Tested: selects 8189 when 8188 busy |
| LM Studio watchdog | BUILT, not yet verified green | `toolkit/Watch-LmStudio.ps1`, `configs/lmstudio-watchdog.json` |
| PowerShell popup audit | DONE — WAU (Winget-AutoUpdate) identified; user uninstalled it | `logs/audit-powershell.txt` |
| Docs suite | DONE — README, MCP-CATALOG, SETUP, SECURITY, ARCHITECTURE, TROUBLESHOOTING, RECOMMENDED-MODELS | committed `b4c50a7` |
| MCP certification | STALE (2026-08-19): 2 passed / 5 failed / 9 unknown | `docs/certification-summary.json` |
| Git push | NOT DONE — commit `b4c50a7` is local only; new files uncommitted | `git status` |

---

## Task 1 — Migrate ComfyUI to the port-shifting launcher

**Why:** ComfyUI currently runs from an ad-hoc background command pinned to port 8188.
The launcher adds auto port shifting, service-port registry, and hidden-window background start.

**Steps:**

1. Stop the ad-hoc instance (only the one running `main.py`):
   ```powershell
   Get-CimInstance Win32_Process -Filter "Name='python.exe'" |
     Where-Object { $_.CommandLine -match 'main\.py' } |
     ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
   ```
2. Relaunch via the launcher (CPU mode):
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\Admin\CascadeProjects\daves-tools\toolkit\Start-ComfyUI.ps1 -Cpu
   ```
3. Read the chosen port from `configs/service-ports.json` (`comfyui.port`).

**Verify:**
```powershell
$port = (Get-Content C:\Users\Admin\CascadeProjects\daves-tools\configs\service-ports.json | ConvertFrom-Json).comfyui.port
Invoke-WebRequest "http://127.0.0.1:$port/system_stats" -UseBasicParsing | Select-Object StatusCode
```

**Acceptance:** HTTP 200; `service-ports.json` contains a fresh `startedAt`; only one `python.exe main.py` process exists.

**Optional (GPU mode):** The machine has multiple NVIDIA GPUs but currently has CPU-only
torch wheels. To enable GPU:
```powershell
python -m pip install --force-reinstall torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
powershell -File toolkit\Start-ComfyUI.ps1     # omit -Cpu
```
Watch for the Windows multi-GPU note: add `--cuda-device all --disable-pinned-memory` to use all GPUs.

---

## Task 2 — Verify LM Studio watchdog goes green (todo T7)

**Steps:**

1. Confirm LM Studio server is running (default port 1234, see `configs/known-ports.json`).
2. Run one watchdog cycle manually:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\Admin\CascadeProjects\daves-tools\toolkit\Watch-LmStudio.ps1
   ```
3. Inspect the log referenced by `configs/lmstudio-watchdog.json` (`logPath`) — expect a
   heartbeat-OK line, or a restart action if LM Studio was down.
4. Register the recurring task:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File toolkit\Watch-LmStudio.ps1 -RegisterTask
   ```

**Acceptance:** log shows `heartbeat ok` (or successful restart), scheduled task exists
(`schtasks /query /tn` for the watchdog task name), and killing LM Studio manually results
in an automatic restart within one interval.

**Note (fixed 2026-08-22):** `Watch-LmStudio.ps1` had two invalid multi-argument
`Join-Path` calls that crash under Windows PowerShell 5.1. Both are fixed; if you copy
this pattern elsewhere, always nest: `Join-Path (Join-Path $a $b) $c`.

---

## Task 3 — Re-certify and fix remaining MCP servers

The 2026-08-19 run (`docs/certification-summary.json`) is stale. Re-run first, then fix
what still fails. Certifier internals: `harness/certifier.js` (protocol connect →
tools/list → schema check → safe call). Runner: `toolkit/Certify-Mcps.ps1`.

### 3.1 Re-run certification

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\Admin\CascadeProjects\daves-tools\toolkit\Certify-Mcps.ps1
```

Outputs refresh `docs/certification-summary.json`. Then triage per server below.

### 3.2 Per-server fix guide

| Server | Last verdict | Likely root cause | Fix |
|---|---|---|---|
| `context7` | PASSED | — | none |
| `github-mcp` | PASSED | — | none |
| `serena` | FAILED (connection closed) | `uvx` missing or `mcp-server-serena` package name wrong | `pip install uv` then `uvx mcp-server-serena --help` manually; correct the args in the registry if the entry point differs |
| `gitlab-mcp` | FAILED (connection closed) | Missing `GITLAB_PERSONAL_ACCESS_TOKEN` env — server exits at startup | Add token via `toolkit/Protect-PrivateEnv.ps1` flow; ensure `env_refs` includes it in the asset registry |
| `android-mcp` | FAILED (connection closed) | `G:\Github\android-mcp\dist\index.js` missing or stale build; needs `adb` on PATH | `cd G:\Github\android-mcp; npm install; npm run build`; verify `adb version` |
| `apktool-mcp` | FAILED (connection closed) | Requires Java + apktool on PATH | `java -version`; install apktool; retry `npx -y apktool-mcp` manually to read stderr |
| `autogenesis` | FAILED (connection closed) | npm package may not exist under that name or requires config | `npx -y autogenesis` manually; check npm registry; remove from registry if abandoned |
| `searxng-mcp` | UNKNOWN | Never run — `G:\Github\searxng-mcp\dist\index.js` may not be built; needs a running SearXNG instance URL | Build (`npm install && npm run build`); set `SEARXNG_URL` env |
| `appium-mcp` | UNKNOWN | Never run — same local-build pattern | Build; requires Appium server (`npm i -g appium`) |
| `jadx-ai-mcp` / `jadx-mcp-server` | UNKNOWN | Never run; require Java + jadx | Verify `java -version`; run npx manually first |
| `ghidra-mcp-headless`, `ghidramcp-lauriewired`, `pyghidra-mcp` | UNKNOWN | No `command` configured at all in registry | Decide install path: requires a local Ghidra installation + `GHIDRA_INSTALL_DIR`; fill in `runtime.command/args` in the asset registry, or mark `transport: none` to exclude |
| `hyper-v-mcp` | UNKNOWN | Never run; needs admin + Hyper-V feature | Run certifier from elevated shell; verify Hyper-V enabled |
| `x64dbg-automate-mcp` | UNKNOWN | Never run; needs x64dbg + automate plugin installed | Install x64dbg, set plugin path env; then certify |

### 3.3 Diagnosis pattern for any "connection closed" failure

`MCP error -32000: Connection closed` = the child process exited before the MCP handshake.
Always do this before changing anything:

```powershell
# Run the exact command the certifier runs, watch stderr directly:
npx -y <package-name> 2>&1 | Select-Object -First 40
```

The first lines of stderr almost always name the missing env var, missing binary, or
unsupported Node version.

### 3.4 Acceptance

- Every server in `docs/certification-summary.json` has verdict `passed` or a documented
  `not_applicable` reason (e.g., hardware/tool not present on this machine).
- `docs/CERTIFICATION-SUMMARY.md` regenerated to match (see `toolkit/Certification-Summary.ps1`).

---

## Task 4 — Port registry adoption (PC + VPS awareness)

**Built:** `toolkit/Find-OpenPort.ps1` (function + CLI), `configs/known-ports.json`
(reserved services/ranges), `configs/service-ports.json` (live registry, written by launchers).

**Remaining:**

1. Fill in real reserved ports: edit `configs/known-ports.json` and add every port your
   VPS tunnels/forwards use (they are placeholders right now — `lm-studio: 1234`,
   `comfyui: 8188`, `ollama: 11434`, `mcp-harness: 7331`, ranges 3000-3010 / 5000-5010).
2. Adopt `Find-OpenPort` in the MCP harness daemon (`harness/daemon/`) the same way
   `Start-ComfyUI.ps1` uses it: dot-source, call with `-ServiceName`, write chosen port
   into `configs/service-ports.json`.
3. Point the LM Studio watchdog at `service-ports.json` so it probes the *actual* port
   rather than a hard-coded one.

**Acceptance:** two services started at once never collide; `service-ports.json` always
reflects live ports; watchdog reads its target port from the registry.

---

## Task 5 — Commit and push everything (todo T8)

Local commit `b4c50a7` (docs + installer + watchdog) exists but was **never pushed**.
New/changed since that commit:

- `toolkit/Audit-PowerShellPopup.ps1` (new — timeout-hardened popup audit)
- `toolkit/Find-OpenPort.ps1` (new)
- `toolkit/Start-ComfyUI.ps1` (new)
- `toolkit/Watch-LmStudio.ps1` (fixed Join-Path bugs)
- `configs/known-ports.json` (new)
- `configs/service-ports.json` (generated — decide: commit or gitignore)
- `docs/REMAINING-WORK-E2E.md` (this file)
- `logs/` (generated — should be gitignored)
- `daves-tools.zip` (untracked — likely delete or gitignore, do not commit a zip of the repo into itself)
- `harness/daemon/`, `toolkit/Build-DavesCatalog.js`, `toolkit/fix-json-escapes.js` (review + commit)

**Steps:**

```powershell
# 1. Hygiene first
Add-Content .gitignore "`nlogs/`ndaves-tools.zip`nconfigs/service-ports.json"

# 2. Stage + commit
git add -A
git commit -m "feat: port auto-shift launcher, popup audit tool, watchdog fixes, E2E runbook"

# 3. Push (both the old commit and this one go up together)
git push github master
```

**Acceptance:** `git status` clean; `git log origin/master..master` empty after push.

---

## Task 6 — Final system verification checklist

Run top-to-bottom once Tasks 1-5 are done:

- [ ] `Invoke-WebRequest http://127.0.0.1:<comfyui-port>/system_stats` → 200
- [ ] LM Studio watchdog log shows green heartbeat within last interval
- [ ] Kill LM Studio → auto-restarted within one interval
- [ ] `toolkit/Certify-Mcps.ps1` → 0 unexplained failures
- [ ] `git status` clean, pushed
- [ ] Reboot the PC → ComfyUI launcher + watchdog scheduled task come back on their own
      (if autostart desired: register `Start-ComfyUI.ps1` as a logon scheduled task —
      mirror the `-RegisterTask` pattern in `Watch-LmStudio.ps1`)

---

## Known environment gotchas (hard-won, do not rediscover)

- **Windows PowerShell 5.1 is the default shell.** No multi-arg `Join-Path`, no
  `ConvertFrom-Json -AsHashtable`, no `??` operator. Target 5.1 syntax in all toolkit scripts.
- **Long-running commands must be backgrounded with output redirected to a log file**
  (`*> logs\x.log`) — pip/console progress bars stall the terminal harness.
- **Wrap slow WMI/Task Scheduler queries in `Start-Job` + `Wait-Job -Timeout`**
  (`Get-ScheduledTask` and `Get-CimInstance Win32_Process` have both hung >20s on this
  machine). Use `schtasks /query /fo csv /v` as the fast alternative.
- **WAU (Winget-AutoUpdate) was uninstalled 2026-08-22** — it ran daily 6:00 AM
  unattended `winget upgrade` jobs as SYSTEM and was the prime suspect for background
  PowerShell activity. If unexplained popups return, re-run
  `toolkit/Audit-PowerShellPopup.ps1` first.
- **Torch uninstalls can leave locked-DLL debris** (`~il`, `~arkupsafe` dirs in
  site-packages). If pip stalls silently, reboot, then `pip install --force-reinstall`.
- **Python is 3.14 at `C:\Python314`** — some MCP/py packages may not have wheels yet;
  prefer Node-based servers or pin older Python via `uv` when needed.
