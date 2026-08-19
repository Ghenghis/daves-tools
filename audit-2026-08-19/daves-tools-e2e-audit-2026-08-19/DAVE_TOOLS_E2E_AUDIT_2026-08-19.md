# DAVE-AI Tools End-to-End Audit

**Audit date:** 2026-08-19  
**Audited inputs:** uploaded `daves-tools.zip`; GitHub `Ghenghis/daves-tools` at commit `d73de2f`; current upstream primary documentation for MCP, GitHub, GitLab, Serena, Playwright, Windows skills and WinApp CLI.  
**GitLab mirror:** not independently readable from the available connector/public fetch path, so mirror parity is unverified.


## Executive verdict

**No: the repository does not currently provide 49 installed, healthy, end-to-end MCP servers.** It is a useful catalog and an early management shell, but its count, classification, installer, preflight, launchers, routing and runtime proof are not trustworthy enough for professional project automation.


### Truth table

| Measure | Audited result |
|---|---|
| Unique catalog entries | 43 |
| Registry entries | 36 |
| Combined Claude config keys | 38 |
| Why preflight says 49 | 36 original phase rows + 13 duplicate repair rows |
| True MCP candidates after type classification | 16 |
| Skill/marketplace sources | 11 |
| CLI/GUI/service/benchmark/runtime dependencies | 14 |
| Duplicate/variant entries | 2 |
| Child MCP servers actually launched by included test | 0 |
| Management tools smoke-tested | 6 |
| Registry entries marked cloned=true | 0 of 36 |
| Registry entries carrying an empty tag | 36 of 36 |


## Critical findings

| Priority | Finding | Evidence/impact |
|---|---|---|
| P0 | False 49 count | `Run-Preflight.ps1` counts `phase-fix-status.json` as a fourth phase. Those 13 rows duplicate earlier failures, yielding 36 + 13 = 49. |
| P0 | Asset-type collapse | Skills, marketplaces, GUIs, CLIs, services, benchmarks and agent runtimes are all converted into child MCP launchers. |
| P0 | Fabricated launchers | When a repository has no detected Node main entry, the installer invents `npx -y <slug/package-name>`. This produces commands such as `npx x64dbg`, `npx mobsf`, `npx assetripper` and `npx androidworld` without proving they are MCP servers. |
| P0 | Preflight is not health verification | It only counts stored `cloned` booleans. It does not initialize a server, list tools, call a smoke tool, validate credentials, inspect dependencies, or detect process exits. |
| P0 | Registry/status contradiction | Preflight claims 49 cloned and zero failed, while every one of the 36 registry records says `cloned:false`. |
| P0 | Task routing bug | Missing tags become an empty string; every task text contains the empty string, so the recommender returns nearly the entire registry. |
| P0 | Child tool schemas are discarded | The proxy exposes every child tool with an empty input schema and generic description, preventing reliable model tool selection and argument generation. |
| P0 | No process supervision | There are no start deadlines, call timeouts, cancellation, crash/exit monitoring, retries/backoff, circuit breakers, concurrency locks or orphan cleanup. |
| P0 | No security boundary | No per-tool filesystem roots, network allowlists, credential references, mutation levels, approvals, secret redaction, sandboxing or audit event integration. |
| P1 | Transport and capability claims are inaccurate | README claims streamable HTTP, while the harness only constructs a stdio server. It declares prompts/resources but implements neither. |
| P1 | Hard-coded machine paths | PowerShell and sample configs are tied to `C:\Users\Admin` and `G:\Github`, preventing portable installation and clean rebuilds. |
| P1 | Config pollution and naming drift | Combined config has `claude-server`, `mcp-server-browserbase`, and `playwright-cli---skills` outside the registry; the registry has `playwright-cli-skills` instead. |
| P1 | No professional delivery surface | No Windows GUI, one-click profile selection, visible doctor/repair, evidence viewer, release dashboard or GitHub/GitLab parity check. |


## Correct classification of the 43 unique catalog entries

| Class | Count |
|---|---|
| Agent runtime | 1 |
| Benchmark/evaluation suite | 1 |
| CLI + skill pack | 1 |
| CLI dependency | 3 |
| CLI/E2E dependency | 1 |
| CLI/plugin dependency | 1 |
| Curated skill marketplace | 1 |
| Debugger GUI dependency | 1 |
| Duplicate profile variant | 1 |
| GUI dependency | 2 |
| GUI/CLI dependency | 1 |
| High-risk MCP server | 1 |
| Interactive MCP/plugin | 2 |
| MCP server | 9 |
| MCP server/connector | 1 |
| MCP/automation adapter | 1 |
| MCP/test framework | 1 |
| Plugin marketplace | 1 |
| RE framework dependency | 1 |
| RE suite dependency | 1 |
| Remote MCP server/connector | 1 |
| Security skill pack/marketplace | 1 |
| Service/API dependency | 1 |
| Skill pack | 3 |
| Skill pack/plugin | 1 |
| Skill pack/source | 1 |
| Skill/harness | 1 |
| Unproven duplicate/adapter concept | 1 |
| Windows skill/plugin pack | 1 |


The correct design is **not 43 always-on child MCP servers**. It is a typed ecosystem: true MCP servers, workflow skills, dependencies, services, benchmarks and marketplaces, loaded by project profile.


## Item-by-item audit

| # | Item | Actual class | Current assessment | Decision | Priority | Missing skill coverage |
|---|---|---|---|---|---|---|
| 1 | Anthropic Skills | Skill pack/source | Misregistered as an MCP with a fabricated generic npx command. | Keep as skill source; never launch as MCP | P0 | skill-source-sync; skill-vetting-and-pin; skill-evaluation |
| 2 | Claude Plugins Official | Plugin marketplace | Marketplace is misregistered as an MCP process. | Keep as marketplace metadata; install selected plugins only | P1 | plugin-marketplace-sync; plugin-permission-audit; plugin-install-rollback |
| 3 | Serena | MCP server | Registry uses npx -y serena; upstream explicitly documents uv/uvx and warns against stale marketplace commands. | Keep as core MCP; replace launcher with official uv/uvx configuration | P0 | semantic-project-onboard; symbol-impact-refactor; serena-index-doctor |
| 4 | Superpowers | Skill pack/plugin | A local plugin file is placed in the MCP registry even though it is a workflow/plugin. | Keep as workflow skills; do not proxy as MCP | P0 | spec-to-worktree; autonomous-low-risk-execution; two-stage-review-proof |
| 5 | Trail of Bits Skills Curated | Curated skill marketplace | Catalogued but omitted from registry and combined config. | Keep as vetted on-demand source; merge governance with Trail of Bits Skills | P1 | security-skill-selection; pinned-security-pack-update; source-provenance |
| 6 | Context7 | MCP server | Launcher shape is plausible, but no child-server runtime test exists. | Keep as core research MCP; pin package/version and certify | P0 | version-pinned-doc-lookup; citation-and-api-drift-check; offline-fallback |
| 7 | GitHub MCP | MCP server/connector | Registry uses unverified npx github-mcp instead of the official server distribution. | Keep official server; use binary/Docker/remote and minimal read-only toolsets by default | P0 | repo-intake; issue-to-worktree; pr-ci-release; repo-mirror-sync |
| 8 | GitLab MCP | Remote MCP server/connector | Generated @gitlab/mcp-server launcher is not GitLab’s documented transport. | Keep official GitLab endpoint; use HTTP or mcp-remote OAuth flow | P0 | mr-pipeline-runner; gitlab-mirror-sync; oauth-connection-doctor; runner-proof |
| 9 | SearXNG MCP | MCP server | Local dist path is plausible but not launched or certified by the repository tests. | Keep optional/private research MCP; do not duplicate built-in web unnecessarily | P1 | privacy-research; source-quality-and-citation; query-budgeting |
| 10 | Trail of Bits Skills | Security skill pack/marketplace | Misregistered as a generic npx MCP process. | Keep as on-demand security skills; not an MCP child | P1 | secure-code-review; dependency-sbom-vuln-triage; secrets-scan |
| 11 | Android MCP | MCP server | Local dist launcher is plausible but unverified; registry reports cloned=false. | Keep one canonical Android control MCP | P1 | android-device-doctor; adb-safe-control; apk-install-logcat-proof |
| 12 | Android MCP Lean | Duplicate profile variant | Same upstream URL as Android MCP but treated as a second installed server/path. | Merge into Android MCP as a lean toolset/profile | P0 | android-lean-profile; capability-diff-test |
| 13 | AndroidWorld | Benchmark/evaluation suite | Benchmark is misregistered as npx androidworld MCP. | Keep as benchmark dependency; never expose as raw MCP | P2 | mobile-agent-benchmark; trajectory-replay-score; regression-baseline |
| 14 | Appium MCP | MCP server | Local dist path is plausible but no server initialize/listTools/smoke call is tested. | Keep optional cross-platform automation MCP | P1 | appium-session-doctor; cross-device-test-generation; flake-recovery |
| 15 | Maestro | CLI/E2E dependency | CLI is misregistered as an MCP through generic npx. | Keep CLI as deterministic test runner behind a skill/adapter | P1 | maestro-flow-authoring; maestro-proof-capture; flow-repair |
| 16 | Maestro MCP | Unproven duplicate/adapter concept | Points to the same upstream Maestro repo; no distinct MCP server is identified. | Remove duplicate unless a real MCP wrapper is separately implemented and tested | P0 | maestro-adapter-contract; maestro-tool-schema-tests |
| 17 | Mobile Harness | Skill/harness | Misregistered as a fabricated npx MCP process. | Keep as mobile workflow skill pack; not a child MCP | P1 | mobile-task-router; device-state-recovery; mobile-proof-bundle |
| 18 | Mobilerun | Agent runtime | Agent runtime is misregistered as generic npx MCP. | Keep behind a supervised adapter; never expose unrestricted runtime directly | P2 | mobile-agent-supervisor; safe-action-policy; runtime-recovery |
| 19 | Android Reverse Engineering Skill | Skill pack | Skill is misregistered as a generic MCP process. | Keep as authorized static-RE workflow; not MCP | P1 | apk-triage-router; authorized-scope-gate; artifact-chain-of-custody |
| 20 | Apktool | CLI dependency | CLI is misregistered as npx apktool MCP. | Keep as pinned Java dependency behind Apktool MCP/skill | P1 | apk-decode-rebuild-sign; diff-and-rollback; apktool-version-doctor |
| 21 | Apktool MCP | MCP server | Generic npx launcher is generated but not proven to match upstream packaging. | Keep MCP adapter; certify exact upstream install and tool schemas | P1 | apktool-mcp-contract-test; apk-rebuild-e2e |
| 22 | Frida MCP Skills | Skill pack | Skills are misregistered as a generic MCP; actual Frida server is absent from the 43-item catalog. | Keep skills and add/verify an actual Frida MCP or controlled runner | P1 | frida-session-lifecycle; hook-library-vetting; dynamic-evidence-capture |
| 23 | JADX AI MCP | Interactive MCP/plugin | Generic npx launcher is unverified. | Keep optional GUI-interactive adapter | P2 | jadx-gui-session; find-reference-export; gui-state-recovery |
| 24 | JADX MCP Server | MCP server | Generic npx launcher is unverified. | Keep as canonical headless JADX adapter | P1 | headless-apk-analysis; jadx-artifact-report; query-budgeting |
| 25 | MobSF | Service/API dependency | Web service/API is misregistered as npx mobsf MCP. | Keep service; add a typed MobSF MCP/API adapter | P1 | mobsf-scan-orchestrator; finding-dedupe-prioritize; report-export |
| 26 | Ghidra | RE suite dependency | Catalogued but omitted from registry; no installation method or health record. | Keep pinned release as dependency for selected Ghidra adapters | P1 | ghidra-project-import; analysis-cache; export-symbols |
| 27 | Ghidra MCP Headless | MCP server | Catalogued but omitted from registry and combined config. | Keep one canonical headless Ghidra adapter | P1 | headless-binary-triage; batch-analysis-proof; timeout-and-cache |
| 28 | GhidraMCP LaurieWired | Interactive MCP/plugin | Catalogued but omitted from registry and combined config. | Keep optional interactive Ghidra adapter | P2 | interactive-ghidra-control; state-sync; gui-handoff |
| 29 | iaito | GUI dependency | Catalogued but omitted; GUI application is not an MCP server. | Optional UI dependency; do not register as MCP | P3 | radare-gui-handoff; analyst-session-export |
| 30 | pyghidra-mcp | MCP server | Catalogued but omitted from registry and config. | Evaluate against the other two Ghidra adapters; keep only if it adds unique verified capabilities | P2 | ghidra-variant-selection; capability-diff-test; state-persistence |
| 31 | radare2 | RE framework dependency | Catalogued but omitted; framework is not an MCP server. | Keep pinned dependency for r2/iaito/r2unity workflows | P1 | radare2-analysis-pipeline; r2-project-export; cross-tool-handoff |
| 32 | AutoGenesis | MCP/test framework | Upstream exists and contains Windows/mobile MCP servers; registry launcher npx autogenesis is fabricated. | Keep Windows automation MCP; install its actual nested server instead of npx placeholder | P1 | windows-gui-test-plan; record-replay; test-flake-diagnosis |
| 33 | win-dev-skills | Windows skill/plugin pack | Upstream already provides eight Windows skills; registry incorrectly uses npx win-dev-skills as MCP. | Keep as official Windows E2E skills; install as plugin, not MCP | P0 | daveai-winui-router; gui-one-click-setup; hermesproof-winui-adapter |
| 34 | WinApp CLI | CLI dependency | Registry uses wrong generic package/name and treats the CLI as an MCP. | Keep official WinApp CLI as dependency used by Windows skills | P0 | windows-package-sign; msix-release; ui-accessibility-test |
| 35 | Hyper-V MCP | High-risk MCP server | Generic npx launcher is unverified. | Keep on-demand only with strict isolation and approval policy | P1 | lab-provision-snapshot-restore; network-isolation; guest-evidence |
| 36 | x64dbg | Debugger GUI dependency | Debugger is misregistered as npx x64dbg MCP. | Keep pinned release as dependency; never run as generic MCP | P1 | debug-session-setup; crash-repro; debugger-state-export |
| 37 | x64dbg Automate MCP | MCP/automation adapter | Generic npx launcher is unverified and likely does not match the Python client distribution. | Keep if upstream is certified; pair with x64dbg dependency | P1 | breakpoint-plan; trace-export; safe-patch-proof |
| 38 | x64dbg-skills | Skill pack | Skill pack is misregistered as generic npx MCP. | Keep skills as Windows RE operating procedures; not MCP | P1 | windows-re-orchestrator; x64dbg-recovery; trace-to-report |
| 39 | AssetRipper | GUI/CLI dependency | Application is misregistered as npx AssetRipper MCP. | Keep pinned dependency behind Unity-RE skill/adapter | P1 | unity-asset-extract-catalog; provenance-and-license; batch-export |
| 40 | Cpp2IL | CLI dependency | CLI is misregistered as npx Cpp2IL MCP. | Keep pinned dependency behind Unity IL2CPP workflow | P1 | il2cpp-reconstruction; metadata-validation; cross-version-fallback |
| 41 | dnSpyEx | GUI dependency | GUI is misregistered as npx dnSpyEx MCP. | Keep pinned dependency behind managed-assembly workflow | P1 | managed-assembly-triage; patch-build-verify; symbol-export |
| 42 | r2unity | CLI/plugin dependency | Plugin is misregistered as npx r2unity MCP. | Keep optional radare2 plugin in Unity-RE profile | P2 | unity-metadata-to-r2; cross-tool-handoff; plugin-version-doctor |
| 43 | Playwright CLI + Skills | CLI + skill pack | Correct CLI package is present, but it is routed through an MCP-only harness; key mismatch also creates a duplicate config entry. | Keep CLI skills and add official Playwright MCP plus Chrome DevTools MCP as separate adapters | P0 | web-e2e-generate-run-repair; visual-regression; accessibility-performance; electron-desktop-test |


## Cross-reference to Dave’s project portfolio

Scores use 0–5. **Potential** measures how much of the domain the catalog could cover after correct integration. **Verified** measures what this repository currently proves end-to-end.

| Project family | Potential | Verified | Current coverage | Largest gaps |
|---|---|---|---|---|
| AI coding/orchestration: DAVE-AI, Claude/Kilo/MiniMax, HermesProof | 3.0 | 1.0 | Serena, Superpowers, Anthropic skills, repo connectors; HermesProof exists outside this repo | Canonical event contract; project router; worktree/task state; proof integration; recovery; operator GUI |
| Repository portfolio and GitHub/GitLab mirrors | 3.0 | 0.5 | GitHub/GitLab entries and one thin repo-hygiene skill | Correct official connectors; mirror parity; dedupe/catalog; CI failure repair; release/signing; bulk GUI |
| Research and open-source stitching | 3.0 | 0.5 | Context7, SearXNG, security skill sources | Source ranking; citations; license compatibility; reproducibility; project-fit scoring; research-to-contract workflow |
| Web/PWA/Electron and DaveAI.tech | 2.5 | 0.5 | Playwright CLI/skills only | Playwright MCP; Chrome DevTools; visual regression; a11y; performance; API contract; deploy/rollback |
| Android app/game development and device QA | 4.0 | 0.75 | Android MCP, Appium, Maestro, Mobile Harness, Mobilerun, AndroidWorld | One canonical device layer; Gradle/build/sign/publish; device lab state; deterministic evidence; recovery |
| Android reverse engineering | 4.5 | 1.0 | Apktool, JADX, MobSF, Frida skills | Actual Frida adapter; authorized scope; tool handoffs; rebuild/sign/install loop; normalized proof bundle |
| Windows native app development | 4.0 | 1.0 | win-dev-skills, WinApp CLI, AutoGenesis | Correct installation; GUI one-click setup; cert/signing custody; fixture app; HermesProof/CI integration |
| Windows/native reverse engineering | 4.0 | 0.75 | x64dbg stack, Ghidra variants, radare2, Hyper-V | WinDbg/dump/symbol adapter; safe lab policy; canonical Ghidra choice; process supervision; evidence |
| Unity/IL2CPP reverse engineering | 4.0 | 0.75 | AssetRipper, Cpp2IL, dnSpyEx, r2unity plus native RE tools | Unity-RE orchestrator; version detection; cross-tool artifact graph; provenance; fixture certification |
| Game creation and AI gameplay | 1.0 | 0.25 | Almost no engine/editor/build-specific coverage | Unity/Godot/Unreal editor adapters; game design/spec skills; asset pipeline; playtest/balance; save/replay; build/release |
| 3D/media/ComfyUI/voice | 1.5 | 0.5 | minimax-media exists outside repo; no catalog coverage | Blender/ComfyUI adapters; asset manifest/provenance; Unity import; TTS/media QC; GPU job routing |
| Local AI/model/GPU management | 1.0 | 0.25 | No dedicated catalog entries | Provider registry; endpoint health; model install/checksum; VRAM routing; failover; usage/cost; privacy policy |
| VPS/Docker/WSL/Cloudflare/CI infrastructure | 1.0 | 0.25 | GitHub/GitLab only; no infrastructure control plane | Docker/WSL/SSH/VPS adapter; runner health; deploy/rollback; secrets; backups; Cloudflare profile |
| Embedded, robotics, 3D printers, motion rigs | 0.5 | 0.0 | No catalog coverage | Serial/firmware adapter; PlatformIO; device flash/recovery; motion safety; OctoPrint/Klipper integration |
| Data, databases, analytics and reporting | 0.5 | 0.0 | No database/data-quality profile | SQLite/Postgres adapter; migrations; backups; schema/data tests; analytics/report generation |
| Release, signing, provenance and professional delivery | 2.5 | 0.5 | Pieces in GitHub/GitLab, WinApp and external HermesProof | Cross-platform release train; SBOM; checksums; signing; clean rebuild; artifact retention; rollback |
| Accessibility, internationalization and design QA | 1.5 | 0.25 | Some upstream WinUI/UI automation capabilities | Cross-platform a11y; keyboard/screen reader; contrast; i18n; responsive/visual acceptance gates |
| Long-running autonomy, scheduling, recovery and observability | 1.5 | 0.25 | scheduled-tasks exists outside repo; harness has no supervisor | Durable task state; cancellation; retry/backoff; circuit breaker; OTel metrics; orphan cleanup; resume UI |


## Existing Dave ecosystem components to import, not duplicate

| Existing component | Role | Required treatment |
|---|---|---|
| hermes3d-locks / HermesProof | Task ownership, file locks, gates, evidence and handoffs | Make it the mandatory policy/proof kernel for every mutating tool call. |
| minimax-media | MiniMax-backed media generation | Attach to the media-asset pipeline with model/prompt/provenance records. |
| serena-semantic | Semantic code navigation/editing | Unify with catalog Serena; one canonical key and one verified install. |
| scheduled-tasks | Scheduled/recurring execution | Integrate with durable task state, cancellation, retry and resume. |
| Claude_Browser / browser connector | Browser interaction | Define overlap policy with Playwright CLI/MCP and Chrome DevTools. |
| directory/session management | Workspace and session lifecycle | Represent as an existing-core service with project-root restrictions and health checks. |


## Missing professional skills to implement

| Priority | Skill | Purpose | Required tools | Proof gates |
|---|---|---|---|---|
| P0 | daveai-project-router | Turn a plain-language idea into a project profile, lifecycle plan, tool allowlist, risks, and acceptance gates. | project-catalog, Serena, GitHub/GitLab, HermesProof | profile selected, tool allowlist, acceptance criteria |
| P0 | daveai-capability-doctor | Verify every dependency, MCP handshake, credential, device, runtime and build tool before work starts. | control-plane, all registered tools | machine-readable health report, repair actions, recheck result |
| P0 | daveai-tool-lifecycle | Install, pin, update, start, stop, supervise and roll back MCP servers, skills, CLIs, GUIs and services by asset type. | tool-registry, process supervisor | source commit/checksum, install log, protocol certification |
| P0 | daveai-proofed-task-loop | Run idea→spec→worktree→implementation→test→independent review→clean rebuild→signed proof. | HermesProof, Serena, repo connectors, test adapters | task ID, commit, tests, artifacts, evidence ID |
| P0 | daveai-recovery-resume | Persist task state, detect stalls/crashes, clean orphan processes and resume safely. | scheduled-tasks, process supervisor, HermesProof | checkpoint, recovery cause, resumed gate |
| P0 | daveai-repo-mirror-sync | Maintain GitHub/GitLab parity, detect conflicts and prove branch/tag/release synchronization. | GitHub MCP, GitLab MCP, git | remote SHAs, divergence report, sync result |
| P0 | daveai-release-train | Create professional releases for zip, VSIX, APK/AAB, MSIX, web and server artifacts. | repo connectors, WinApp, Android build, CI runners, HermesProof | clean build, SBOM, checksums/signatures, release URLs |
| P0 | daveai-security-permission-broker | Apply least privilege, scoped roots, network/credential allowlists and approval rules per task/tool. | control-plane, secret store, Trail of Bits skills | policy decision, scopes granted, secret scan |
| P0 | daveai-portfolio-catalog | Index, deduplicate, classify and search Dave’s 700+ repositories and connect ideas to reusable components. | GitHub/GitLab, Serena, local database | catalog snapshot, duplicate groups, reuse decisions |
| P0 | daveai-dependency-sbom | Resolve versions, licenses, advisories, lockfiles and SBOMs across Node, Python, Rust, Java, .NET and native tools. | package intelligence, security scanners | locked versions, license report, vulnerability triage, SBOM |
| P0 | daveai-provider-router | Route architecture, coding, local/private, vision, media and verification tasks across MiniMax, Claude, local models and fallbacks. | MiniMax, LM Studio, Ollama, provider registry | route reason, provider health, usage/latency |
| P0 | daveai-operator-dashboard | Give Dave a compact Windows GUI for profiles, health, approvals, progress, evidence, repair and resume without terminal work. | control-plane API, HermesProof | visible state, action history, one-click repair result |
| P1 | daveai-research-synthesis | Search papers, docs and repositories; score freshness, license, compatibility and reuse value; emit an implementation contract. | Context7, SearXNG, GitHub, citation store | source matrix, claims/citations, reuse/license decision |
| P1 | daveai-web-e2e | Generate, run, repair and prove web/PWA/Electron tests including traces, visual regression, accessibility and performance. | Playwright CLI, Playwright MCP, Chrome DevTools MCP | trace, screenshots, a11y/perf report, re-run pass |
| P1 | daveai-android-dev-release | Manage device state, build/install/test/logcat/sign and release Android apps and games. | Android MCP, Appium, Maestro, Gradle/release adapter | device snapshot, build hash, test flow, signed APK/AAB |
| P1 | daveai-android-re-static | Run authorized APK triage across Apktool, JADX and MobSF with normalized artifacts and clean-room boundaries. | Apktool MCP, JADX MCP, MobSF adapter | scope record, artifact manifest, findings, rebuild verification |
| P1 | daveai-android-re-dynamic | Run controlled Frida sessions with vetted hooks, device/process locks, cleanup and trace evidence. | Frida adapter, Android MCP, isolated lab | target authorization, hook hashes, trace, cleanup |
| P1 | daveai-windows-app | Route WinUI/Windows projects through design, build, UI test, packaging, signing and release. | win-dev-skills, WinApp CLI, AutoGenesis | build/test, a11y, MSIX/signature, release |
| P1 | daveai-windows-re | Coordinate PE/.NET analysis, debugging, symbols, crash dumps, safe patching and reports. | x64dbg adapter, Ghidra, radare2, WinDbg adapter, Hyper-V | target hash, analysis graph, trace/dump, patch verification |
| P1 | daveai-isolated-lab | Provision disposable Hyper-V labs with snapshots, network rules, guest execution and guaranteed rollback. | Hyper-V MCP, artifact transfer, HermesProof | base image hash, snapshot, network policy, rollback |
| P1 | daveai-unity-re | Detect Unity/Mono/IL2CPP versions and route AssetRipper, Cpp2IL, dnSpyEx, Ghidra/radare workflows. | Unity RE dependencies, native RE adapters | version fingerprint, artifact graph, cross-tool validation, provenance |
| P1 | daveai-game-project | Create and maintain Unity/Godot/Unreal/Three.js game projects with design contracts, asset import, playtests, balance and builds. | engine editor adapters, asset pipeline, test runners | playable build, playtest replay, performance, release artifact |
| P1 | daveai-media-asset | Route MiniMax/ComfyUI/Blender/TTS assets through generation, cleanup, metadata, provenance and engine import. | minimax-media, ComfyUI, Blender, engine adapters | prompt/model metadata, asset checks, license/provenance, import test |
| P1 | daveai-infra-deploy | Operate WSL, Docker, VPS, GitLab runners and Cloudflare deployments with health checks and rollback. | infra-runner, GitLab, Cloudflare, secret store | deployment plan, health checks, rollback point, post-deploy evidence |
| P1 | daveai-local-models | Install, verify and route local models across LM Studio/Ollama/GPU profiles with VRAM and fallback policies. | provider manager, model registry, GPU monitor | model checksum, endpoint health, VRAM profile, benchmark |
| P2 | daveai-data-migrations | Design schemas, run migrations, test data quality, back up and restore app databases. | SQLite/Postgres adapter, backup store | schema diff, migration test, backup/restore proof |
| P2 | daveai-embedded-device | Build, flash, monitor and recover Raspberry Pi/ESP/3D-printer/motion-controller projects safely. | serial/firmware adapter, PlatformIO, device inventory | firmware hash, device ID, flash log, rollback/safety check |
| P2 | daveai-accessibility-i18n | Enforce keyboard, screen-reader, contrast, responsive and localization requirements across GUIs. | Playwright/DevTools, WinApp UI, Android UI | a11y report, locale matrix, visual proof |


## Additional adapters that materially close coverage

| Priority | Adapter/service | Why it is needed | Disposition |
|---|---|---|---|
| P0 | HermesProof control-plane adapter | The proof/lock kernel is central to Dave’s workflow but this repo never records enable/call/test/release evidence into it. | Integrate existing component; do not duplicate. |
| P0 | Project/portfolio catalog MCP | Dave has 700+ repos; project reuse, dedupe, ownership and source-of-truth selection need a first-class searchable catalog. | Implement new local MCP backed by SQLite plus GitHub/GitLab sync. |
| P0 | Typed tool doctor/installer supervisor | Current scripts only clone/create snippets; they do not certify installs, protocols, health, versions or rollback. | Replace current installer/preflight with asset-type adapters and protocol certification. |
| P0 | Scoped local repo service (filesystem + git + worktrees) | Every project needs safe local editing, branch/worktree state, diff and build execution under project-root restrictions. | Import existing connectors into the typed registry rather than installing duplicates. |
| P0 | Package intelligence / OSV / SBOM / license adapter | Professional builds need current dependency versions, advisories, licenses, lockfiles and provenance across many ecosystems. | Implement one normalized service rather than one server per package manager. |
| P0 | Official Playwright MCP | The catalog only has CLI+skills; persistent agentic browser loops and self-healing exploration need the official MCP option. | Add beside CLI and select by task profile. |
| P0 | Chrome DevTools MCP | Performance traces, network/console debugging and browser diagnostics are missing from web/PWA/Electron coverage. | Add on-demand with telemetry disabled by default. |
| P0 | Secrets/credential broker | Tokens must not be embedded in snippets or logs; connectors need scoped references, rotation and redaction. | Integrate Windows Credential Manager or an encrypted local vault; pass references, not raw secrets. |
| P1 | Docker/WSL/SSH/VPS/runner adapter | Dave’s VPS, Docker, WSL and GitLab runner workflows are not covered. | Implement a restricted infra MCP with host allowlists, plans, health and rollback. |
| P1 | WinDbg/crash-dump/symbol adapter | x64dbg is interactive user-mode debugging; Windows crash dumps, symbols and kernel/native diagnosis remain uncovered. | Add on-demand Windows RE profile. |
| P1 | Android build/sign/publish adapter | Device automation is broad, but Gradle, SDK/NDK, signing, AAB/APK validation and release are missing. | Implement as build/release service plus skill. |
| P1 | Unity, Godot and Unreal editor adapters | Most game-creation ideas need editor scene/project/build control; current catalog is almost entirely reverse engineering. | Add separate on-demand engine profiles; do not load all together. |
| P1 | Blender and ComfyUI asset adapters | 3D, textures, image-to-3D and production asset workflows are recurring project needs. | Add local GPU-aware media profile with asset manifests. |
| P1 | LM Studio/Ollama/model registry adapter | Local/cloud provider health, model installation, VRAM routing and fallback are core to Dave’s setup. | Implement one provider manager integrated with MiniMax routing. |
| P1 | Database/migration/backup adapter | Professional apps and dashboards need schema, migrations, data tests and restores. | Add SQLite-first, then Postgres/profile extensions. |
| P1 | Cloudflare/deployment adapter | Web services and agent backends need repeatable deploy, secrets, logs and rollback. | Use Cloudflare-specific skills/API only for Cloudflare projects. |
| P2 | Embedded serial/firmware adapter | Raspberry Pi, ESP, SKR motion and 3D-printer projects currently have no coverage. | Add device allowlists and physical safety gates. |


## Recommended target architecture

1. **One operator-facing control plane**: compact Windows GUI plus one stable MCP endpoint.
2. **Typed registry**: `mcp_server`, `skill_pack`, `cli_dependency`, `gui_dependency`, `service`, `benchmark`, `agent_runtime`, `marketplace`.
3. **HermesProof policy kernel**: every mutation, install, tool start, tool call, test, release and recovery writes a structured event/evidence ID.
4. **Project profiles**: CORE, WEB, ANDROID-DEV, ANDROID-RE, WINDOWS-DEV, WINDOWS-RE, UNITY-RE, GAME-CREATION, MEDIA-3D, INFRA, LOCAL-AI, EMBEDDED.
5. **Stable dispatch surface**: keep management tools deterministic; preserve child schemas or use `server + tool + typed arguments` with schema lookup. Do not fabricate empty schemas.
6. **Asset-specific installers**: Git clone is not installation. Use Winget/releases for desktop tools, uv/venv for Python, Gradle/Java, npm/pnpm, Cargo, dotnet, Docker or remote HTTP according to upstream.
7. **Certification ladder**: source/provenance → install → protocol handshake → tool schema → domain smoke test → failure/recovery → project E2E → signed proof.
8. **Read-only by default**: mutation profiles require explicit policy, scoped roots, host/device allowlists and credential references.
9. **No all-tools context dump**: select a small profile per project/task; use GitHub dynamic toolsets and equivalent allowlists where available.
10. **GitHub/GitLab mirrors as a release gate**: compare commit, tags, release assets and CI state before claiming parity.


## Remediation sequence and acceptance gates

| Phase | Work | Exit criteria |
|---|---|---|
| 0 — Truth reset | Rename README claims; remove the false 49 count; freeze current registry; generate a unique inventory with source URLs and duplicate IDs. | Catalog count equals unique IDs; no repair rows counted as assets; README generated from registry truth. |
| 1 — Typed registry | Migrate all 43 rows to the supplied schema; classify dependencies and skills; import existing external components. | Schema validation passes; no non-MCP asset has an MCP transport; every source has ref/license/checksum policy. |
| 2 — Correct installers | Implement per-ecosystem install adapters and official launch commands; remove generic npx fallback. | Fresh Windows VM install succeeds; every command exists; version and source commit recorded; uninstall/rollback works. |
| 3 — Runtime supervisor | Preserve schemas/descriptions; add stdio/HTTP support, startup/call timeout, cancellation, exit monitoring, retry/backoff and orphan cleanup. | Each MCP initializes, lists tools, calls a safe smoke tool, stops cleanly and survives forced child termination. |
| 4 — Security and proof | Add scoped permissions, read-only defaults, credential references, redaction and HermesProof events. | Secret canaries never appear; unauthorized roots/hosts fail; every mutation has evidence and approval policy. |
| 5 — Skills and profiles | Implement P0 skills first, then domain skills; map exact tool contracts and failure recovery. | Skill tests select only required tools, execute fixtures and emit proof; no one-sentence prompt forces manual CLI work. |
| 6 — Domain certification | Create representative fixtures for web, Android, Windows, native RE and Unity RE. | Each profile completes an end-to-end task from intake through artifact/report and clean rebuild. |
| 7 — Operator GUI and release | Add profile selector, health/repair, progress, approvals, logs/evidence, resume and mirror status. | Dave can install, run, diagnose, recover and release without terminal use; GitHub/GitLab mirror gate passes. |


## Code locations requiring immediate correction

| File/lines | Issue |
|---|---|
| `toolkit/Run-Preflight.ps1:16–31` | Counts repair status as new assets and checks only stored booleans. |
| `toolkit/Complete-Phase.ps1:42–48, 56–76, 85–125` | Creates fake GitLab install, ignores real exit codes, and invents generic launchers. |
| `toolkit/Build-McpRegistry.ps1:13–35` | Silently drops items and injects empty tags. |
| `toolkit/Run-AllPhases.ps1:23–41` | Sweeps every snippet under `G:\Github`, allowing stale/unrelated entries into config. |
| `mcp-manager/Install-McpServer.ps1:19–51` | Assumes every marketplace source has `python server.py`. |
| `harness/index.js:11–31` | Declares unsupported capabilities and replaces child schemas with `{}`. |
| `harness/proxy.js:12–40, 44–79` | No schema metadata, timeout, cancellation, crash supervision, security policy or robust cleanup. |
| `harness/recommender.js:16–29` | Empty-tag bug and brittle substring routing. |
| `harness/test.js:13–24` | Never enables, invokes, disables or failure-tests a child server. |


## Bottom line

The repository should be retained as the beginning of a **DAVE-AI capability registry and control plane**, but its current “49 MCP server ecosystem” claim should be withdrawn. After classification, the present catalog contains about **16 true MCP candidates**, **11 skill/marketplace sources**, **14 dependencies/services/benchmarks/runtimes**, and **2 duplicate variants**. The highest-value work is not adding dozens more raw servers; it is making a smaller set of verified adapters complete, safe, profile-driven, GUI-operated and proof-gated, then adding the missing game-creation, media/3D, infrastructure, local-model, database and embedded profiles.


## Source notes

- Current GitHub `Ghenghis/daves-tools` master commit: `d73de2fecbfb92fc5dc56757502377720592af03`.
- GitLab official MCP documentation currently recommends direct HTTP transport or `mcp-remote` with OAuth, not `@gitlab/mcp-server`.
- GitHub official MCP supports read-only mode and toolset/dynamic-toolset restriction.
- Serena upstream documents uv/uvx installation and warns against stale marketplace launch commands.
- Microsoft maintains separate Playwright CLI+skills and Playwright MCP paths; Chrome DevTools MCP covers performance/network/console diagnosis.
- Microsoft `win-dev-skills` is a plugin/skill collection and `WinApp CLI` is its underlying Windows toolchain, not two generic MCP servers.
- Current MCP specifications require truthful capabilities, tool metadata/schema, user control, authorization safeguards, cancellation/progress/error handling as applicable.