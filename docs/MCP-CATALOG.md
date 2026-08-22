# MCP Catalog

Generated from `configs/typed-registry.json` and the certification files in `docs/cert-*.json`.

**Asset totals:** 43 — 16 MCP servers, 10 skill packs, 12 runtime dependencies.

## AGENT RUNTIME (1)

### Mobilerun (`mobilerun`)

- **ID:** `mobilerun`
- **Type:** agent_runtime
- **Profiles:** MOBILE-AGENT
- **Capabilities:** mobile-agent-supervisor, safe-action-policy, runtime-recovery
- **Source:** https://github.com/droidrun/mobilerun
- **Transport:** none
- **Command:** `npx -y mobilerun`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

## BENCHMARK (1)

### AndroidWorld (`androidworld`)

- **ID:** `androidworld`
- **Type:** benchmark
- **Profiles:** EVAL
- **Capabilities:** mobile-agent-benchmark, trajectory-replay-score, regression-baseline
- **Source:** https://github.com/google-research/android_world
- **Transport:** none
- **Command:** `npx -y androidworld`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

## CLI DEPENDENCY (20)

### Apktool (`apktool`)

- **ID:** `apktool`
- **Type:** cli_dependency
- **Profiles:** ANDROID-RE
- **Capabilities:** apk-decode-rebuild-sign, diff-and-rollback, apktool-version-doctor
- **Source:** https://github.com/iBotPeaches/Apktool
- **Transport:** none
- **Command:** `npx -y apktool`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### AutoGenesis (`autogenesis`)

- **ID:** `autogenesis`
- **Type:** cli_dependency
- **Profiles:** WINDOWS-DEV
- **Capabilities:** windows-gui-test-plan, record-replay, test-flake-diagnosis
- **Source:** https://github.com/microsoft/AutoGenesis
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Last verified:** 2026-08-22T09:28:28.438Z
- **Certification verdict:** ➖ n/a

### Blender MCP (`blender-mcp`)

- **ID:** `blender-mcp`
- **Type:** cli_dependency
- **Profiles:** 
- **Capabilities:** 
- **Source:** https://www.npmjs.com/package/blender-mcp
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Timeout:** 30000 ms
- **Last verified:** 2026-08-22T10:06:02.164Z
- **Certification verdict:** ❌ failed
- **Certification error:** MCP error -32000: Connection closed

### Cpp2IL (`cpp2il`)

- **ID:** `cpp2il`
- **Type:** cli_dependency
- **Profiles:** UNITY-RE
- **Capabilities:** il2cpp-reconstruction, metadata-validation, cross-version-fallback
- **Source:** https://github.com/SamboyCoding/Cpp2IL
- **Transport:** none
- **Command:** `npx -y cpp2il`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### EDBG (`edbg`)

- **ID:** `edbg`
- **Type:** cli_dependency
- **Profiles:** EMBEDDED-DEV
- **Capabilities:** edbg-flash, edbg-swd-debug, edbg-target-reset
- **Source:** https://github.com/ataradov/edbg
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### GDB (`gdb`)

- **ID:** `gdb`
- **Type:** cli_dependency
- **Profiles:** NATIVE-RE, EMBEDDED-DEV
- **Capabilities:** gdb-debug-session, gdb-remote-target, gdb-scripting
- **Source:** https://sourceware.org/gdb/
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### Ghidra (`ghidra`)

- **ID:** `ghidra`
- **Type:** cli_dependency
- **Profiles:** NATIVE-RE
- **Capabilities:** ghidra-project-import, analysis-cache, export-symbols
- **Source:** https://github.com/NationalSecurityAgency/ghidra
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### Ghidra MCP Headless (`ghidra-mcp-headless`)

- **ID:** `ghidra-mcp-headless`
- **Type:** cli_dependency
- **Profiles:** NATIVE-RE
- **Capabilities:** headless-binary-triage, batch-analysis-proof, timeout-and-cache
- **Source:** https://github.com/SumTuusDeus/ghidra-mcp
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Last verified:** 2026-08-22T09:28:28.438Z
- **Certification verdict:** ➖ n/a

### GhidraMCP LaurieWired (`ghidramcp-lauriewired`)

- **ID:** `ghidramcp-lauriewired`
- **Type:** cli_dependency
- **Profiles:** NATIVE-RE
- **Capabilities:** interactive-ghidra-control, state-sync, gui-handoff
- **Source:** https://github.com/LaurieWired/GhidraMCP
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Last verified:** 2026-08-22T09:28:28.438Z
- **Certification verdict:** ➖ n/a

### JADX AI MCP (`jadx-ai-mcp`)

- **ID:** `jadx-ai-mcp`
- **Type:** cli_dependency
- **Profiles:** ANDROID-RE
- **Capabilities:** jadx-gui-session, find-reference-export, gui-state-recovery
- **Source:** https://github.com/zinja-coder/jadx-ai-mcp
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Last verified:** 2026-08-22T09:28:28.438Z
- **Certification verdict:** ➖ n/a

### JADX MCP Server (`jadx-mcp-server`)

- **ID:** `jadx-mcp-server`
- **Type:** cli_dependency
- **Profiles:** ANDROID-RE
- **Capabilities:** headless-apk-analysis, jadx-artifact-report, query-budgeting
- **Source:** https://github.com/Qtty/jadx-mcp-server
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Last verified:** 2026-08-22T09:28:28.438Z
- **Certification verdict:** ➖ n/a

### LLDB (`lldb`)

- **ID:** `lldb`
- **Type:** cli_dependency
- **Profiles:** NATIVE-RE, CROSS-DEV
- **Capabilities:** lldb-debug-session, lldb-scripting, lldb-remote-target
- **Source:** https://github.com/llvm/llvm-project
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### Maestro (`maestro`)

- **ID:** `maestro`
- **Type:** cli_dependency
- **Profiles:** ANDROID-DEV
- **Capabilities:** maestro-flow-authoring, maestro-proof-capture, flow-repair
- **Source:** https://github.com/mobile-dev-inc/Maestro
- **Transport:** none
- **Command:** `npx -y maestro`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### pyghidra-mcp (`pyghidra-mcp`)

- **ID:** `pyghidra-mcp`
- **Type:** cli_dependency
- **Profiles:** NATIVE-RE
- **Capabilities:** ghidra-variant-selection, capability-diff-test, state-persistence
- **Source:** https://github.com/clearbluejar/pyghidra-mcp
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Last verified:** 2026-08-22T09:28:28.438Z
- **Certification verdict:** ➖ n/a

### r2unity (`r2unity`)

- **ID:** `r2unity`
- **Type:** cli_dependency
- **Profiles:** UNITY-RE
- **Capabilities:** unity-metadata-to-r2, cross-tool-handoff, plugin-version-doctor
- **Source:** https://github.com/radareorg/r2unity
- **Transport:** none
- **Command:** `npx -y r2unity`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### radare2 (`radare2`)

- **ID:** `radare2`
- **Type:** cli_dependency
- **Profiles:** NATIVE-RE
- **Capabilities:** radare2-analysis-pipeline, r2-project-export, cross-tool-handoff
- **Source:** https://github.com/radareorg/radare2
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### Rizin (`rizin`)

- **ID:** `rizin`
- **Type:** cli_dependency
- **Profiles:** NATIVE-RE
- **Capabilities:** rizin-analysis, rizin-scripting, rizin-ghidra-decompiler
- **Source:** https://github.com/rizinorg/rizin
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### UnityPy (`unitypy`)

- **ID:** `unitypy`
- **Type:** cli_dependency
- **Profiles:** 
- **Capabilities:** 
- **Source:** https://github.com/K0lb3/UnityPy
- **Transport:** none
- **Command:** `python`
- **Args:** `-c import UnityPy`
- **Timeout:** 30000 ms
- **Last verified:** 2026-08-22T10:03:54.030Z
- **Certification verdict:** ➖ n/a

### Video2X (`video2x`)

- **ID:** `video2x`
- **Type:** cli_dependency
- **Profiles:** 
- **Capabilities:** 
- **Source:** https://github.com/k4yt3x/video2x
- **Transport:** none
- **Command:** `video2x`
- **Args:** `--help`
- **Timeout:** 30000 ms
- **Certification verdict:** ➖ n/a

### WinApp CLI (`winapp-cli`)

- **ID:** `winapp-cli`
- **Type:** cli_dependency
- **Profiles:** WINDOWS-DEV
- **Capabilities:** windows-package-sign, msix-release, ui-accessibility-test
- **Source:** https://github.com/microsoft/winappCli
- **Transport:** none
- **Command:** `npx -y winapp-cli`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

## GUI DEPENDENCY (11)

### AssetRipper (`assetripper`)

- **ID:** `assetripper`
- **Type:** gui_dependency
- **Profiles:** UNITY-RE
- **Capabilities:** unity-asset-extract-catalog, provenance-and-license, batch-export
- **Source:** https://github.com/AssetRipper/AssetRipper
- **Transport:** none
- **Command:** `npx -y assetripper`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### AssetStudio (`assetstudio`)

- **ID:** `assetstudio`
- **Type:** gui_dependency
- **Profiles:** 
- **Capabilities:** 
- **Source:** https://github.com/Perfare/AssetStudio
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Timeout:** 30000 ms
- **Last verified:** 2026-08-22T10:03:54.030Z
- **Certification verdict:** ➖ n/a

### Bytecode Viewer (`bytecode-viewer`)

- **ID:** `bytecode-viewer`
- **Type:** gui_dependency
- **Profiles:** JAVA-RE, ANDROID-RE
- **Capabilities:** bytecode-decompile, bytecode-edit, apk-jar-analysis
- **Source:** https://github.com/Konloch/bytecode-viewer
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### Cutter (`cutter`)

- **ID:** `cutter`
- **Type:** gui_dependency
- **Profiles:** NATIVE-RE
- **Capabilities:** cutter-disassembly-decompile, cutter-graph-navigation
- **Source:** https://github.com/rizinorg/cutter
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### dnSpyEx (`dnspyex`)

- **ID:** `dnspyex`
- **Type:** gui_dependency
- **Profiles:** UNITY-RE
- **Capabilities:** managed-assembly-triage, patch-build-verify, symbol-export
- **Source:** https://github.com/dnSpyEx/dnSpy
- **Transport:** none
- **Command:** `npx -y dnspyex`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### iaito (`iaito`)

- **ID:** `iaito`
- **Type:** gui_dependency
- **Profiles:** NATIVE-RE
- **Capabilities:** radare-gui-handoff, analyst-session-export
- **Source:** https://github.com/radareorg/iaito
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### ILSpy (`ilspy`)

- **ID:** `ilspy`
- **Type:** gui_dependency
- **Profiles:** DOTNET-RE
- **Capabilities:** ilspy-decompile-assembly, ilspy-browse-assembly
- **Source:** https://github.com/icsharpcode/ILSpy
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### UABE (Unity Assets Bundle Extractor) (`uabe`)

- **ID:** `uabe`
- **Type:** gui_dependency
- **Profiles:** 
- **Capabilities:** 
- **Source:** https://github.com/SeriousCache/UABE
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Timeout:** 30000 ms
- **Last verified:** 2026-08-22T10:03:54.030Z
- **Certification verdict:** ➖ n/a

### Wireshark (`wireshark`)

- **ID:** `wireshark`
- **Type:** gui_dependency
- **Profiles:** NETWORK-RE
- **Capabilities:** wireshark-capture, wireshark-protocol-analysis, wireshark-packet-export
- **Source:** https://gitlab.com/wireshark/wireshark
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### x64dbg (`x64dbg`)

- **ID:** `x64dbg`
- **Type:** gui_dependency
- **Profiles:** WINDOWS-RE
- **Capabilities:** debug-session-setup, crash-repro, debugger-state-export
- **Source:** https://github.com/x64dbg/x64dbg
- **Transport:** none
- **Command:** `npx -y x64dbg`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### ZAP (`zap`)

- **ID:** `zap`
- **Type:** gui_dependency
- **Profiles:** WEB-RE, SECURITY
- **Capabilities:** zap-spider, zap-active-scan, zap-proxy-capture
- **Source:** https://github.com/zaproxy/zaproxy
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

## MARKETPLACE (3)

### Claude Plugins Official (`claude-plugins-official`)

- **ID:** `claude-plugins-official`
- **Type:** marketplace
- **Profiles:** CORE
- **Capabilities:** plugin-marketplace-sync, plugin-permission-audit, plugin-install-rollback
- **Source:** https://github.com/anthropics/claude-plugins-official
- **Transport:** none
- **Command:** `npx -y claude-plugins-official`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### Trail of Bits Skills (`trail-of-bits-skills`)

- **ID:** `trail-of-bits-skills`
- **Type:** marketplace
- **Profiles:** REVIEW
- **Capabilities:** secure-code-review, dependency-sbom-vuln-triage, secrets-scan
- **Source:** https://github.com/trailofbits/skills
- **Transport:** none
- **Command:** `npx -y trail-of-bits-skills`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### Trail of Bits Skills Curated (`trail-of-bits-skills-curated`)

- **ID:** `trail-of-bits-skills-curated`
- **Type:** marketplace
- **Profiles:** CORE, ON-DEMAND
- **Capabilities:** security-skill-selection, pinned-security-pack-update, source-provenance
- **Source:** https://github.com/trailofbits/skills-curated
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

## MCP SERVER (12)

### Android MCP (`android-mcp`)

- **ID:** `android-mcp`
- **Type:** mcp_server
- **Profiles:** ANDROID-DEV
- **Capabilities:** android-device-doctor, adb-safe-control, apk-install-logcat-proof
- **Source:** https://github.com/qalvinahmad/android-mcp
- **Transport:** stdio
- **Command:** `node`
- **Args:** `G:\MCP-Servers\android-mcp\dist\index.js`
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Last verified:** 2026-08-22T05:17:58.378Z
- **Certification verdict:** ✅ passed

### Apktool MCP (`apktool-mcp`)

- **ID:** `apktool-mcp`
- **Type:** mcp_server
- **Profiles:** ANDROID-RE
- **Capabilities:** apktool-mcp-contract-test, apk-rebuild-e2e
- **Source:** https://github.com/zinja-coder/apktool-mcp-server
- **Transport:** stdio
- **Command:** `uv`
- **Args:** `run G:/MCP-Servers/apktool-mcp/apktool_mcp_server.py`
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Container isolation:** container
- **Last verified:** 2026-08-20T03:00:02.633Z
- **Certification verdict:** ✅ passed

### Appium MCP (`appium-mcp`)

- **ID:** `appium-mcp`
- **Type:** mcp_server
- **Profiles:** ANDROID-DEV
- **Capabilities:** appium-session-doctor, cross-device-test-generation, flake-recovery
- **Source:** https://github.com/appium/appium-mcp
- **Transport:** stdio
- **Command:** `node`
- **Args:** `G:\MCP-Servers\appium-mcp\dist\index.js`
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Last verified:** 2026-08-22T05:17:58.378Z
- **Certification verdict:** ✅ passed

### ComfyUI MCP (`comfyui-mcp`)

- **ID:** `comfyui-mcp`
- **Type:** mcp_server
- **Profiles:** 
- **Capabilities:** 
- **Source:** https://www.npmjs.com/package/comfyui-mcp
- **Transport:** stdio
- **Command:** `npx`
- **Args:** `-y comfyui-mcp@0.52.57`
- **Timeout:** 30000 ms
- **Last verified:** 2026-08-22T10:33:34.766Z
- **Certification verdict:** ✅ passed
- **Tools exposed:** 41

  - `comfy_cli` — Drive the official comfy-cli (envelope/1 JSON contract) for the selected ComfyUI environment
  - `enqueue_workflow` — Submit work to the ComfyUI execution queue — the primary way an agent starts a render
  - `get_system_stats` — Inspect the connected ComfyUI server: what it is running on, what it has logged, and whether it is healthy enough to dispatch work to
  - `visualize_workflow` — DRAW a diagram of, or convert, workflow JSON you PASS IN (a JSON string or object) — it does NOT read the user's live canvas, so for 'show me what's on the canvas' / the CURRENTLY-OPEN graph use panel
  - `create_workflow` — Author and check ComfyUI workflow JSON
  - `queue` — Inspect and manage the ComfyUI execution queue
  - `search_custom_nodes` — Discover ComfyUI custom node PACKS in the public ComfyUI Registry (registry.comfy.org)
  - `download_model` — Find model weights and get them onto the connected ComfyUI, and track the transfers
  - `list_local_models` — Inspect what models this ComfyUI has installed, and where it looks for them
  - `get_history` — Read what has already been generated on this machine — execution history, why a run failed, and the settings your past renders actually used
  - `runpod` — Deploy, start, stop, inspect and connect to RunPod cloud GPU pods, and switch rendering between your local machine and a pod
  - `runpod_watch` — Watch a RunPod pod's live status in the control panel, stop watching it, or diagnose why it isn't usable
  - `get_workflow` — Return, list, summarize or query a SAVED workflow FILE — files on disk, named from the library or given as a path/JSON — NOT the graph open on the user's canvas (that is panel_graph_outline)
  - `save_workflow` — WRITE to the ComfyUI user library: persist a workflow, or capture/verify its provenance lock
  - `restart_comfyui` — Control the lifecycle of the ComfyUI server process
  - `get_image` — Fetch, browse and inspect ComfyUI images and registered assets
  - `upload_image` — Put a file where ComfyUI (or cloud storage) can read it
  - `clear_vram` — Free GPU VRAM by unloading cached models from ComfyUI
  - `get_defaults` — Read and write settings — either OUR generation defaults or ComfyUI's own frontend UI settings
  - `generate_image` — Generate media from a prompt or an existing image — the high-level entry points that build the graph for you
  - `node_snapshot` — Custom-node snapshots via ComfyUI-Manager (mirrors `comfy node save-snapshot` / `restore-snapshot`)
  - `bisect` — Binary-search (git-bisect style) over installed ComfyUI custom nodes to find which one causes a problem
  - `install_custom_node` — Install, repair, enable/disable and remove ComfyUI custom node packs on this ComfyUI
  - `report_issue` — File or triage a GitHub issue for a bug/problem you hit (ComfyUI, a workflow, a model, custom nodes, or comfyui-mcp/its panel)
  - `install_comfyui` — Install, update and configure the local ComfyUI installation, its sidebar panel, and this MCP server itself
  - `model_metadata` — Curate a model file's embedded .safetensors metadata (Model Explorer)
  - `workspace` — Inspect and manage ComfyUI workspaces (local installs)
  - `list_api_nodes` — Discover and run hosted partner/API nodes on the connected ComfyUI (e.g
  - `node_pack` — Author, edit, test and publish YOUR OWN ComfyUI custom-node pack under the custom_nodes/ directory the running ComfyUI actually scans
  - `apply_manifest` — Apply a ComfyUI setup manifest from an inline object or .json/.yaml/.yml file
  - `list_packs` — Bundled ComfyUI knowledge — installer packs, model-family skills, workflow templates — plus the two workflow-readiness checks
  - `calculate` — Evaluate a batch of math expressions exactly — no ComfyUI connection needed, so it works even in cloud mode or when ComfyUI is down
  - `train_prepare_dataset` — Stage and curate the training DATASETS a LoRA run consumes — the images and their captions
  - `train_start` — Run and inspect LoRA training JOBS — launch a run, poll it, stop it, delete it, and read back the settings behind it
  - `train_doctor` — Preflight and set up the TRAINER ITSELF — the docker/GPU/venv machinery every training job needs
  - `apps` — Micro-apps on this ComfyUI (panel Apps feature): named workflows packaged for one-click runs
  - `batch` — Run MANY ComfyUI workflows under one durable batch_id
  - `kitchen` — See what comfy-kitchen can do on this GPU, find where a graph is leaving it on the table, and apply the faster path
  - `list_tools` — List every comfyui-mcp capability as a token-light catalog: tool names with one-line summaries, grouped by category
  - `describe_tool` — Get the full description and JSON Schema of one tool from the catalog
  - `call_tool` — Execute a tool from the catalog by name

### Context7 (`context7`)

- **ID:** `context7`
- **Type:** mcp_server
- **Profiles:** RESEARCH
- **Capabilities:** version-pinned-doc-lookup, citation-and-api-drift-check, offline-fallback
- **Source:** https://github.com/upstash/context7
- **Transport:** stdio
- **Command:** `npx`
- **Args:** `-y @upstash/context7-mcp@4.0.3`
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Last verified:** 2026-08-19T22:57:48.633Z
- **Certification verdict:** ✅ passed

### FFmpeg MCP (`ffmpeg-mcp`)

- **ID:** `ffmpeg-mcp`
- **Type:** mcp_server
- **Profiles:** 
- **Capabilities:** 
- **Source:** https://www.npmjs.com/package/ffmpeg-mcp
- **Transport:** stdio
- **Command:** `npx`
- **Args:** `-y ffmpeg-mcp@0.0.3`
- **Timeout:** 30000 ms
- **Last verified:** 2026-08-22T10:22:25.379Z
- **Certification verdict:** ✅ passed
- **Tools exposed:** 2

  - `speed_up` — Speed up a video
  - `extract_audio` — Extract audio as mp3 from a video

### GitHub MCP (`github-mcp`)

- **ID:** `github-mcp`
- **Type:** mcp_server
- **Profiles:** REPO
- **Capabilities:** repo-intake, issue-to-worktree, pr-ci-release, repo-mirror-sync
- **Source:** https://github.com/github/github-mcp-server
- **Transport:** stdio
- **Command:** `npx`
- **Args:** `-y @modelcontextprotocol/server-github@2025.4.8`
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Last verified:** 2026-08-19T23:08:24.093Z
- **Certification verdict:** ✅ passed

### GitLab MCP (`gitlab-mcp`)

- **ID:** `gitlab-mcp`
- **Type:** mcp_server
- **Profiles:** REPO
- **Capabilities:** mr-pipeline-runner, gitlab-mirror-sync, oauth-connection-doctor, runner-proof
- **Source:** https://docs.gitlab.com/user/model_context_protocol/mcp_server/
- **Transport:** stdio
- **Command:** `npx`
- **Args:** `-y @modelcontextprotocol/server-gitlab@2025.4.25`
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Last verified:** 2026-08-20T22:03:48.988Z
- **Certification verdict:** ✅ passed

### Hyper-V MCP (`hyper-v-mcp`)

- **ID:** `hyper-v-mcp`
- **Type:** mcp_server
- **Profiles:** ISOLATED-LAB
- **Capabilities:** lab-provision-snapshot-restore, network-isolation, guest-evidence
- **Source:** https://github.com/originsec/hyperv-mcp
- **Transport:** stdio
- **Command:** `hyperv-mcp`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Last verified:** 2026-08-22T05:17:58.378Z
- **Certification verdict:** ✅ passed

### SearXNG MCP (`searxng-mcp`)

- **ID:** `searxng-mcp`
- **Type:** mcp_server
- **Profiles:** RESEARCH
- **Capabilities:** privacy-research, source-quality-and-citation, query-budgeting
- **Source:** https://github.com/ihor-sokoliuk/mcp-searxng
- **Transport:** stdio
- **Command:** `npx`
- **Args:** `-y mcp-searxng@2.0.0`
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Last verified:** 2026-08-22T05:17:58.378Z
- **Certification verdict:** ✅ passed

### Serena (`serena`)

- **ID:** `serena`
- **Type:** mcp_server
- **Profiles:** CORE
- **Capabilities:** semantic-project-onboard, symbol-impact-refactor, serena-index-doctor
- **Source:** https://github.com/oraios/serena
- **Transport:** stdio
- **Command:** `uv`
- **Args:** `run scripts/mcp_server.py`
- **Working directory:** G:/MCP-Servers/serena
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Last verified:** 2026-08-22T10:41:32.740Z
- **Certification verdict:** ✅ passed

### x64dbg Automate MCP (`x64dbg-automate-mcp`)

- **ID:** `x64dbg-automate-mcp`
- **Type:** mcp_server
- **Profiles:** WINDOWS-RE
- **Capabilities:** breakpoint-plan, trace-export, safe-patch-proof
- **Source:** https://github.com/dariushoule/x64dbg-automate-pyclient
- **Transport:** stdio
- **Command:** `x64dbg-automate-mcp`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Last verified:** 2026-08-20T09:26:58.454Z
- **Certification verdict:** ✅ passed

## SERVICE (1)

### MobSF (`mobsf`)

- **ID:** `mobsf`
- **Type:** service
- **Profiles:** ANDROID-RE
- **Capabilities:** mobsf-scan-orchestrator, finding-dedupe-prioritize, report-export
- **Source:** https://github.com/MobSF/Mobile-Security-Framework-MobSF
- **Transport:** none
- **Command:** `npx -y mobsf`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

## SKILL PACK (10)

### Android MCP Lean (`android-mcp-lean`)

- **ID:** `android-mcp-lean`
- **Type:** skill_pack
- **Profiles:** ANDROID-DEV
- **Capabilities:** android-lean-profile, capability-diff-test
- **Source:** https://github.com/qalvinahmad/android-mcp
- **Transport:** none
- **Command:** `node G:\MCP-Servers\android-mcp-lean\dist\index.js`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### Android Reverse Engineering Skill (`android-reverse-engineering-skill`)

- **ID:** `android-reverse-engineering-skill`
- **Type:** skill_pack
- **Profiles:** ANDROID-RE
- **Capabilities:** apk-triage-router, authorized-scope-gate, artifact-chain-of-custody
- **Source:** https://github.com/SimoneAvogadro/android-reverse-engineering-skill
- **Transport:** none
- **Command:** `npx -y android-reverse-engineering-skill`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### Anthropic Skills (`anthropic-skills`)

- **ID:** `anthropic-skills`
- **Type:** skill_pack
- **Profiles:** CORE
- **Capabilities:** skill-source-sync, skill-vetting-and-pin, skill-evaluation
- **Source:** https://github.com/anthropics/skills
- **Transport:** none
- **Command:** `npx -y anthropic-skills`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### Frida MCP Skills (`frida-mcp-skills`)

- **ID:** `frida-mcp-skills`
- **Type:** skill_pack
- **Profiles:** ANDROID-RE-DYNAMIC
- **Capabilities:** frida-session-lifecycle, hook-library-vetting, dynamic-evidence-capture
- **Source:** https://github.com/yfe404/frida-mcp-skills
- **Transport:** none
- **Command:** `npx -y frida-mcp-skills`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### Maestro MCP (`maestro-mcp`)

- **ID:** `maestro-mcp`
- **Type:** skill_pack
- **Profiles:** ANDROID-DEV
- **Capabilities:** maestro-adapter-contract, maestro-tool-schema-tests
- **Source:** https://github.com/mobile-dev-inc/Maestro
- **Transport:** none
- **Command:** `npx -y maestro-mcp`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### Mobile Harness (`mobile-harness`)

- **ID:** `mobile-harness`
- **Type:** skill_pack
- **Profiles:** MOBILE-AGENT
- **Capabilities:** mobile-task-router, device-state-recovery, mobile-proof-bundle
- **Source:** https://github.com/droidrun/mobile-harness
- **Transport:** none
- **Command:** `npx -y mobile-harness`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### Playwright CLI + Skills (`playwright-cli-skills`)

- **ID:** `playwright-cli-skills`
- **Type:** skill_pack
- **Profiles:** WEB-E2E
- **Capabilities:** web-e2e-generate-run-repair, visual-regression, accessibility-performance, electron-desktop-test
- **Source:** https://github.com/microsoft/playwright-cli
- **Transport:** stdio
- **Command:** `npx`
- **Args:** `-y @playwright/mcp@latest`
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Last verified:** 2026-08-20T00:58:20.769Z
- **Certification verdict:** ✅ passed

### Superpowers (`superpowers`)

- **ID:** `superpowers`
- **Type:** skill_pack
- **Profiles:** CORE
- **Capabilities:** spec-to-worktree, autonomous-low-risk-execution, two-stage-review-proof
- **Source:** https://github.com/obra/superpowers
- **Transport:** none
- **Command:** `node G:\MCP-Servers\superpowers\.opencode\plugins\superpowers.js`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### win-dev-skills (`win-dev-skills`)

- **ID:** `win-dev-skills`
- **Type:** skill_pack
- **Profiles:** WINDOWS-DEV
- **Capabilities:** daveai-winui-router, gui-one-click-setup, hermesproof-winui-adapter
- **Source:** https://github.com/microsoft/win-dev-skills
- **Transport:** none
- **Command:** `npx -y win-dev-skills`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

### x64dbg-skills (`x64dbg-skills`)

- **ID:** `x64dbg-skills`
- **Type:** skill_pack
- **Profiles:** WINDOWS-RE
- **Capabilities:** windows-re-orchestrator, x64dbg-recovery, trace-to-report
- **Source:** https://github.com/dariushoule/x64dbg-skills
- **Transport:** none
- **Command:** `npx -y x64dbg-skills`
- **Args:** ``
- **Timeout:** 30000 ms
- **Mutation level:** read_only
- **Approval policy:** on_mutation
- **Certification verdict:** ⚪ unknown

## TOOL PACK (3)

### BepInEx (`bepinex`)

- **ID:** `bepinex`
- **Type:** tool_pack
- **Profiles:** 
- **Capabilities:** 
- **Source:** https://github.com/BepInEx/BepInEx
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Timeout:** 30000 ms
- **Last verified:** 2026-08-22T10:03:54.030Z
- **Certification verdict:** ➖ n/a

### ComfyUI (local) (`comfyui`)

- **ID:** `comfyui`
- **Type:** tool_pack
- **Profiles:** 
- **Capabilities:** 
- **Source:** https://github.com/comfyanonymous/ComfyUI
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Working directory:** G:\Github\ComfyUI
- **Timeout:** 30000 ms
- **Last verified:** 2026-08-22T10:03:54.030Z
- **Certification verdict:** ➖ n/a

### Unity AI Harness (`unity-ai-harness`)

- **ID:** `unity-ai-harness`
- **Type:** tool_pack
- **Profiles:** 
- **Capabilities:** 
- **Source:** https://github.com/Ghenghis/UAH
- **Transport:** none
- **Command:** ``
- **Args:** ``
- **Working directory:** G:\MCP-Servers\unity-ai-harness
- **Timeout:** 30000 ms
- **Last verified:** 2026-08-22T10:00:48.780Z
- **Certification verdict:** ➖ n/a
