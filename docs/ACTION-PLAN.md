# DAVE-AI Completion Action Plan

**Goal:** Download, install, and package the 43 missing catalog items into a working state, phase by phase, without user interaction.

**Repo:** `daves-tools` companion to `claude-codex-devin`.

## Phase 1 — Tier A/B (CORE / REPO / RESEARCH)

Target items:
- Anthropic Skills
- Claude Plugins Official
- Trail of Bits Skills Curated
- Trail of Bits Skills
- Context7
- GitHub MCP
- GitLab MCP
- SearXNG MCP

Actions:
1. Clone each repo into `G:\Github\`.
2. Run `npm install` or `pnpm install` when `package.json` / `pnpm-lock.yaml` is present.
3. Generate a `claude-desktop-snippet.json` for each installable server.
4. Write `docs/phase-1-status.json` with the status of each item.

## Phase 2 — Tier C (MOBILE)

Target items:
- Android MCP, Android MCP Lean, Appium MCP, Maestro, Maestro MCP
- Mobile Harness, Mobilerun, AndroidWorld

Actions: same as Phase 1, write `docs/phase-2-status.json`.

## Phase 3 — Tier D/E/F/G/H (RE, WINDOWS, UNITY, WEB)

Target items:
- Android RE: Apktool, Apktool MCP, Frida MCP Skills, JADX AI MCP, JADX MCP Server, MobSF, Android Reverse Engineering Skill
- Native RE: Ghidra, Ghidra MCP variants, radare2, iaito, pyghidra-mcp
- Windows: AutoGenesis, win-dev-skills, WinApp CLI, Hyper-V MCP, x64dbg, x64dbg Automate MCP, x64dbg-skills
- Unity: AssetRipper, Cpp2IL, dnSpyEx, r2unity
- Web: Playwright CLI + Skills

Actions: same as Phase 1, write `docs/phase-3-status.json`.

## Phase 4 — Packaging and preflight

Actions:
1. Combine all `claude-desktop-snippet.json` files into `daves-tools/configs/claude-desktop-missing.json`.
2. Run the existing `preflight-safe.ps1` if present in the main workspace.
3. Update `README.md` with the final status.

## Commit / push policy

After each phase completes, commit with the phase status file and push to both GitLab and GitHub.

## No-user-interaction rules

- Use `-y` for `npx` and `npm install`.
- Do not prompt for API keys; write placeholder `<...>` in snippets.
- For Python repos, clone only; do not auto-run `pip install` outside a virtual environment.
- Skip an item if its repo is already cloned.
- If a build step is required, record it in the status file and skip live compilation when it needs interactive approval.
