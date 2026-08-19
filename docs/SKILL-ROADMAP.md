# DAVE-AI Skill Roadmap

> This document is generated from the E2E audit `recommended-skills.json` and `daves-tools-item-matrix.csv`. Run `toolkit\Build-SkillRoadmap.ps1` to regenerate.

## P0 skills

| Skill | Purpose | Required tools | Proof |
|---|---|---|---|
| daveai-project-router | Turn a plain-language idea into a project profile, lifecycle plan, tool allowlist, risks, and acceptance gates. | project-catalog, Serena, GitHub/GitLab, HermesProof | profile selected; tool allowlist; acceptance criteria |
| daveai-capability-doctor | Verify every dependency, MCP handshake, credential, device, runtime and build tool before work starts. | control-plane, all registered tools | machine-readable health report; repair actions; recheck result |
| daveai-tool-lifecycle | Install, pin, update, start, stop, supervise and roll back MCP servers, skills, CLIs, GUIs and services by asset type. | tool-registry, process supervisor | source commit/checksum; install log; protocol certification |
| daveai-proofed-task-loop | Run idea→spec→worktree→implementation→test→independent review→clean rebuild→signed proof. | HermesProof, Serena, repo connectors, test adapters | task ID; commit; tests; artifacts; evidence ID |
| daveai-recovery-resume | Persist task state, detect stalls/crashes, clean orphan processes and resume safely. | scheduled-tasks, process supervisor, HermesProof | checkpoint; recovery cause; resumed gate |
| daveai-repo-mirror-sync | Maintain GitHub/GitLab parity, detect conflicts and prove branch/tag/release synchronization. | GitHub MCP, GitLab MCP, git | remote SHAs; divergence report; sync result |
| daveai-release-train | Create professional releases for zip, VSIX, APK/AAB, MSIX, web and server artifacts. | repo connectors, WinApp, Android build, CI runners, HermesProof | clean build; SBOM; checksums/signatures; release URLs |
| daveai-security-permission-broker | Apply least privilege, scoped roots, network/credential allowlists and approval rules per task/tool. | control-plane, secret store, Trail of Bits skills | policy decision; scopes granted; secret scan |
| daveai-portfolio-catalog | Index, deduplicate, classify and search Dave’s 700+ repositories and connect ideas to reusable components. | GitHub/GitLab, Serena, local database | catalog snapshot; duplicate groups; reuse decisions |
| daveai-dependency-sbom | Resolve versions, licenses, advisories, lockfiles and SBOMs across Node, Python, Rust, Java, .NET and native tools. | package intelligence, security scanners | locked versions; license report; vulnerability triage; SBOM |
| daveai-provider-router | Route architecture, coding, local/private, vision, media and verification tasks across MiniMax, Claude, local models and fallbacks. | MiniMax, LM Studio, Ollama, provider registry | route reason; provider health; usage/latency |
| daveai-operator-dashboard | Give Dave a compact Windows GUI for profiles, health, approvals, progress, evidence, repair and resume without terminal work. | control-plane API, HermesProof | visible state; action history; one-click repair result |

## P1 skills

| Skill | Purpose | Required tools | Proof |
|---|---|---|---|
| daveai-research-synthesis | Search papers, docs and repositories; score freshness, license, compatibility and reuse value; emit an implementation contract. | Context7, SearXNG, GitHub, citation store | source matrix; claims/citations; reuse/license decision |
| daveai-web-e2e | Generate, run, repair and prove web/PWA/Electron tests including traces, visual regression, accessibility and performance. | Playwright CLI, Playwright MCP, Chrome DevTools MCP | trace; screenshots; a11y/perf report; re-run pass |
| daveai-android-dev-release | Manage device state, build/install/test/logcat/sign and release Android apps and games. | Android MCP, Appium, Maestro, Gradle/release adapter | device snapshot; build hash; test flow; signed APK/AAB |
| daveai-android-re-static | Run authorized APK triage across Apktool, JADX and MobSF with normalized artifacts and clean-room boundaries. | Apktool MCP, JADX MCP, MobSF adapter | scope record; artifact manifest; findings; rebuild verification |
| daveai-android-re-dynamic | Run controlled Frida sessions with vetted hooks, device/process locks, cleanup and trace evidence. | Frida adapter, Android MCP, isolated lab | target authorization; hook hashes; trace; cleanup |
| daveai-windows-app | Route WinUI/Windows projects through design, build, UI test, packaging, signing and release. | win-dev-skills, WinApp CLI, AutoGenesis | build/test; a11y; MSIX/signature; release |
| daveai-windows-re | Coordinate PE/.NET analysis, debugging, symbols, crash dumps, safe patching and reports. | x64dbg adapter, Ghidra, radare2, WinDbg adapter, Hyper-V | target hash; analysis graph; trace/dump; patch verification |
| daveai-isolated-lab | Provision disposable Hyper-V labs with snapshots, network rules, guest execution and guaranteed rollback. | Hyper-V MCP, artifact transfer, HermesProof | base image hash; snapshot; network policy; rollback |
| daveai-unity-re | Detect Unity/Mono/IL2CPP versions and route AssetRipper, Cpp2IL, dnSpyEx, Ghidra/radare workflows. | Unity RE dependencies, native RE adapters | version fingerprint; artifact graph; cross-tool validation; provenance |
| daveai-game-project | Create and maintain Unity/Godot/Unreal/Three.js game projects with design contracts, asset import, playtests, balance and builds. | engine editor adapters, asset pipeline, test runners | playable build; playtest replay; performance; release artifact |
| daveai-media-asset | Route MiniMax/ComfyUI/Blender/TTS assets through generation, cleanup, metadata, provenance and engine import. | minimax-media, ComfyUI, Blender, engine adapters | prompt/model metadata; asset checks; license/provenance; import test |
| daveai-infra-deploy | Operate WSL, Docker, VPS, GitLab runners and Cloudflare deployments with health checks and rollback. | infra-runner, GitLab, Cloudflare, secret store | deployment plan; health checks; rollback point; post-deploy evidence |
| daveai-local-models | Install, verify and route local models across LM Studio/Ollama/GPU profiles with VRAM and fallback policies. | provider manager, model registry, GPU monitor | model checksum; endpoint health; VRAM profile; benchmark |

## P2 skills

| Skill | Purpose | Required tools | Proof |
|---|---|---|---|
| daveai-data-migrations | Design schemas, run migrations, test data quality, back up and restore app databases. | SQLite/Postgres adapter, backup store | schema diff; migration test; backup/restore proof |
| daveai-embedded-device | Build, flash, monitor and recover Raspberry Pi/ESP/3D-printer/motion-controller projects safely. | serial/firmware adapter, PlatformIO, device inventory | firmware hash; device ID; flash log; rollback/safety check |
| daveai-accessibility-i18n | Enforce keyboard, screen-reader, contrast, responsive and localization requirements across GUIs. | Playwright/DevTools, WinApp UI, Android UI | a11y report; locale matrix; visual proof |

## Asset-to-skill mapping

| Asset | Class | Priority | Missing skills |
|---|---|---|---|
| Anthropic Skills | Skill pack/source | P0 | skill-source-sync; skill-vetting-and-pin; skill-evaluation |
| Claude Plugins Official | Plugin marketplace | P1 | plugin-marketplace-sync; plugin-permission-audit; plugin-install-rollback |
| Serena | MCP server | P0 | semantic-project-onboard; symbol-impact-refactor; serena-index-doctor |
| Superpowers | Skill pack/plugin | P0 | spec-to-worktree; autonomous-low-risk-execution; two-stage-review-proof |
| Trail of Bits Skills Curated | Curated skill marketplace | P1 | security-skill-selection; pinned-security-pack-update; source-provenance |
| Context7 | MCP server | P0 | version-pinned-doc-lookup; citation-and-api-drift-check; offline-fallback |
| GitHub MCP | MCP server/connector | P0 | repo-intake; issue-to-worktree; pr-ci-release; repo-mirror-sync |
| GitLab MCP | Remote MCP server/connector | P0 | mr-pipeline-runner; gitlab-mirror-sync; oauth-connection-doctor; runner-proof |
| SearXNG MCP | MCP server | P1 | privacy-research; source-quality-and-citation; query-budgeting |
| Trail of Bits Skills | Security skill pack/marketplace | P1 | secure-code-review; dependency-sbom-vuln-triage; secrets-scan |
| Android MCP | MCP server | P1 | android-device-doctor; adb-safe-control; apk-install-logcat-proof |
| Android MCP Lean | Duplicate profile variant | P0 | android-lean-profile; capability-diff-test |
| AndroidWorld | Benchmark/evaluation suite | P2 | mobile-agent-benchmark; trajectory-replay-score; regression-baseline |
| Appium MCP | MCP server | P1 | appium-session-doctor; cross-device-test-generation; flake-recovery |
| Maestro | CLI/E2E dependency | P1 | maestro-flow-authoring; maestro-proof-capture; flow-repair |
| Maestro MCP | Unproven duplicate/adapter concept | P0 | maestro-adapter-contract; maestro-tool-schema-tests |
| Mobile Harness | Skill/harness | P1 | mobile-task-router; device-state-recovery; mobile-proof-bundle |
| Mobilerun | Agent runtime | P2 | mobile-agent-supervisor; safe-action-policy; runtime-recovery |
| Android Reverse Engineering Skill | Skill pack | P1 | apk-triage-router; authorized-scope-gate; artifact-chain-of-custody |
| Apktool | CLI dependency | P1 | apk-decode-rebuild-sign; diff-and-rollback; apktool-version-doctor |
| Apktool MCP | MCP server | P1 | apktool-mcp-contract-test; apk-rebuild-e2e |
| Frida MCP Skills | Skill pack | P1 | frida-session-lifecycle; hook-library-vetting; dynamic-evidence-capture |
| JADX AI MCP | Interactive MCP/plugin | P2 | jadx-gui-session; find-reference-export; gui-state-recovery |
| JADX MCP Server | MCP server | P1 | headless-apk-analysis; jadx-artifact-report; query-budgeting |
| MobSF | Service/API dependency | P1 | mobsf-scan-orchestrator; finding-dedupe-prioritize; report-export |
| Ghidra | RE suite dependency | P1 | ghidra-project-import; analysis-cache; export-symbols |
| Ghidra MCP Headless | MCP server | P1 | headless-binary-triage; batch-analysis-proof; timeout-and-cache |
| GhidraMCP LaurieWired | Interactive MCP/plugin | P2 | interactive-ghidra-control; state-sync; gui-handoff |
| iaito | GUI dependency | P3 | radare-gui-handoff; analyst-session-export |
| pyghidra-mcp | MCP server | P2 | ghidra-variant-selection; capability-diff-test; state-persistence |
| radare2 | RE framework dependency | P1 | radare2-analysis-pipeline; r2-project-export; cross-tool-handoff |
| AutoGenesis | MCP/test framework | P1 | windows-gui-test-plan; record-replay; test-flake-diagnosis |
| win-dev-skills | Windows skill/plugin pack | P0 | daveai-winui-router; gui-one-click-setup; hermesproof-winui-adapter |
| WinApp CLI | CLI dependency | P0 | windows-package-sign; msix-release; ui-accessibility-test |
| Hyper-V MCP | High-risk MCP server | P1 | lab-provision-snapshot-restore; network-isolation; guest-evidence |
| x64dbg | Debugger GUI dependency | P1 | debug-session-setup; crash-repro; debugger-state-export |
| x64dbg Automate MCP | MCP/automation adapter | P1 | breakpoint-plan; trace-export; safe-patch-proof |
| x64dbg-skills | Skill pack | P1 | windows-re-orchestrator; x64dbg-recovery; trace-to-report |
| AssetRipper | GUI/CLI dependency | P1 | unity-asset-extract-catalog; provenance-and-license; batch-export |
| Cpp2IL | CLI dependency | P1 | il2cpp-reconstruction; metadata-validation; cross-version-fallback |
| dnSpyEx | GUI dependency | P1 | managed-assembly-triage; patch-build-verify; symbol-export |
| r2unity | CLI/plugin dependency | P2 | unity-metadata-to-r2; cross-tool-handoff; plugin-version-doctor |
| Playwright CLI + Skills | CLI + skill pack | P0 | web-e2e-generate-run-repair; visual-regression; accessibility-performance; electron-desktop-test |
