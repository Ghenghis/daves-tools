# DAVE-AI Tools E2E Audit — Remediation Status

**Last updated:** 2026-08-19

## P0 (critical) — COMPLETE

| # | Item | Status | Proof |
|---|---|---|---|
| 1 | Typed registry + JSON schema | Done | `configs/typed-registry.json`, `configs/typed-registry.schema.json` |
| 2 | Unique count / dedup / generated README | Done | `README.md` now states 43 unique assets, 16 MCP candidates; `docs/preflight.json` |
| 3 | Correct official launchers | Done | Serena, GitHub, GitLab, Context7, Playwright, HermesProof launchers in typed registry |
| 4 | Live certifier | Done | `harness/certifier.js`, `harness/certify-asset.js`, `toolkit/Certify-Mcps.ps1` |
| 5 | Preserve child descriptions and schemas | Done | `harness/proxy.js`, `harness/index.js` expose child tool metadata |
| 6 | Permission/secret broker and read-only defaults | Done | `harness/policy.js`, `harness/secrets.js` |
| 7 | HermesProof structured events | Done | `harness/events.js`, `docs/harness-events.ndjson` |
| 8 | Project router, capability doctor, tool lifecycle, recovery, mirror, release skills | Done | `toolkit/Project-Router.ps1`, `Capability-Doctor.ps1`, `Tool-Lifecycle.ps1`, `Recover-Asset.ps1`, `Mirror-Repo.ps1`, `Release-Gate.ps1` |
| 9 | Compact Windows operator dashboard | Done | `toolkit/Operator-Dashboard.ps1` |

## P1/P2 (deep end-to-end coverage) — IN PROGRESS

| Item | Status | Notes |
|---|---|---|
| E2E coverage definition and report | Done | `toolkit/EndToEnd-Coverage.ps1` produces `docs/e2e-coverage.json` and `docs/E2E-COVERAGE.md` |
| Per-asset deep certification | Pending | Requires actual install and live smoke of every asset |
| Missing skill implementations | Pending | e.g., `daveai-winui-router`, `daveai-vps-blink-operator` |
| Operator dashboard real-time refresh | Pending | Currently read-only on launch |
| Automated HermesProof ledger sync | Pending | Events written to local ndjson only |

## Current truth

- **43 unique catalog entries**, not 49.
- **16 MCP candidates**, not all installed.
- Health is now determined by `Capability-Doctor.ps1` and `Certify-Mcps.ps1`, not by clone presence.
- Read-only defaults and path sandboxing are enforced before any proxied tool call.
- Every asset must pass all 12 E2E coverage gates before being marked fully covered.

## How to continue

1. Run `toolkit\Certify-Mcps.ps1` against installed assets.
2. Run `toolkit\Capability-Doctor.ps1` to refresh install/env/protocol status.
3. Run `toolkit\EndToEnd-Coverage.ps1` to update the coverage report.
4. Implement the remaining P1/P2 missing skills listed in `docs/SKILL-ROADMAP.md`.
