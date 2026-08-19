# Certification Lessons

This file records live certification results from `harness/certifier.js` and the commands that worked or failed.

## Live certifications that passed

| Asset | Command | Notes |
|---|---|---|
| `local-test` | `node harness/test-server.js` | Reference in-process MCP; full protocol, schema, and safe smoke verified. |
| `playwright-cli-skills` | `npx -y @playwright/mcp@latest` | Full browser automation tool surface listed; safe smoke succeeded. |
| `context7` | `npx -y @upstash/context7-mcp@latest` | Documentation resolver tools and schemas returned cleanly. |
| `github-mcp` | `npx -y @modelcontextprotocol/server-github` | Requires `GITHUB_TOKEN` / `GITHUB_PERSONAL_ACCESS_TOKEN` from `G:\private`. Corrected from non-existent `@github/mcp-server`. |

## Known-bad or not-yet-working packages

| Asset | Original command | Problem | Corrective action needed |
|---|---|---|---|
| `github-mcp` | `npx -y @github/mcp-server` | Package does not exist on npm (404). | Use `npx -y @modelcontextprotocol/server-github` instead. |
| `gitlab-mcp` | `none` | Not a runnable launcher. | Use `npx -y @modelcontextprotocol/server-gitlab` and ensure `GITLAB_TOKEN` or `GITLAB_PERSONAL_ACCESS_TOKEN` is present. |
| `serena` | `uvx mcp-server-serena` | Connection closed immediately; likely needs a real Python project and correct `UV_PYTHON` / `PATH`. | Rebuild with a pinned `uv` environment and a real project root. |
| `apktool-mcp` | `npx -y apktool-mcp` | Connection closed; package may not be a functional MCP server. | Replace with upstream `apktool` CLI wrapper or remove from MCP-only registry. |
| `autogenesis` | `npx -y autogenesis` | Connection closed; package not a functioning MCP server. | Verify upstream launcher or mark as not an MCP server. |
| `android-mcp` | `node G:\Github\android-mcp\dist\index.js` | Local build path missing / exited. | Build or clone `https://github.com/Graylurve/android-mcp` and confirm `dist/index.js` exists. |

## Token handling

- `G:\private\*.env` is the only secret store.
- `toolkit\Load-PrivateEnv.ps1` loads all `.env` files, newest file wins for each key, and aliases `GITHUB_TOKEN`/`GH_TOKEN` to `GITHUB_PERSONAL_ACCESS_TOKEN`.
- `toolkit\Provider-Status.ps1` checks which model-provider tokens are present **without ever printing values**.

## Provider tokens seen in `G:\private` (names only)

- `MINIMAX_API_KEY`
- `DEEPSEEK_API_KEY`
- `SILICONFLOW_API_KEY`
- `DEEPINFRA_TOKEN`
- `OPENROUTER_API_KEY` (when present)
- `HUGGINGFACE_TOKEN`
- `AZURE_SPEECH_KEY` / `AZURE_SPEECH_REGION`
- `LMSTUDIO_BASE_URL` / `OLLAMA_BASE_URL` (local endpoints, no token required)

## Recommended next steps

1. Fix `Build-TypedRegistry.ps1` to emit correct official launchers for `github-mcp` and `gitlab-mcp`.
2. Build or source missing local MCPs (`android-mcp`, `appium-mcp`, `searxng-mcp`) before certifying.
3. Remove or reclassify placeholder packages (`apktool-mcp`, `autogenesis`, `dnspyex` as GUI dependency).
4. Re-run `toolkit\Certify-Mcps.ps1` after fixes to produce an updated `docs\CERTIFICATION-SUMMARY.md`.
