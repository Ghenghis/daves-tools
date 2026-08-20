# DAVE-AI MCP Server Detailed Reference

**Generated:** 2026-08-19T18:10:12.8652571-07:00

## Android MCP - `android-mcp`

- **Command:** `node`
- **Args:** `G:\Github\android-mcp\dist\index.js`
- **Profiles:** ANDROID-DEV
- **Capabilities:** android-device-doctor, adb-safe-control, apk-install-logcat-proof
- **Health:** False
- **Certification:** failed
- **Permissions:**
  - `filesystem_roots`: 
  - `network_hosts`: 
  - `credentials`: 
  - `mutation_level`: read_only
  - `approval_policy`: on_mutation

### Use cases


## Apktool MCP - `apktool-mcp`

- **Command:** `npx`
- **Args:** `-y apktool-mcp`
- **Profiles:** ANDROID-RE
- **Capabilities:** apktool-mcp-contract-test, apk-rebuild-e2e
- **Health:** False
- **Certification:** failed
- **Permissions:**
  - `filesystem_roots`: 
  - `network_hosts`: 
  - `credentials`: 
  - `mutation_level`: read_only
  - `approval_policy`: on_mutation

### Use cases


## Appium MCP - `appium-mcp`

- **Command:** `node`
- **Args:** `G:\Github\appium-mcp\dist\index.js`
- **Profiles:** ANDROID-DEV
- **Capabilities:** appium-session-doctor, cross-device-test-generation, flake-recovery
- **Health:** False
- **Certification:** unknown
- **Permissions:**
  - `filesystem_roots`: 
  - `network_hosts`: 
  - `credentials`: 
  - `mutation_level`: read_only
  - `approval_policy`: on_mutation

### Use cases


## AutoGenesis - `autogenesis`

- **Command:** `npx`
- **Args:** `-y autogenesis`
- **Profiles:** WINDOWS-DEV
- **Capabilities:** windows-gui-test-plan, record-replay, test-flake-diagnosis
- **Health:** False
- **Certification:** failed
- **Permissions:**
  - `filesystem_roots`: 
  - `network_hosts`: 
  - `credentials`: 
  - `mutation_level`: read_only
  - `approval_policy`: on_mutation

### Use cases


## Context7 - `context7`

- **Command:** `npx`
- **Args:** `-y @upstash/context7-mcp@latest`
- **Profiles:** RESEARCH
- **Capabilities:** version-pinned-doc-lookup, citation-and-api-drift-check, offline-fallback
- **Health:** True
- **Certification:** passed
- **Permissions:**
  - `filesystem_roots`: 
  - `network_hosts`: 
  - `credentials`: 
  - `mutation_level`: read_only
  - `approval_policy`: on_mutation

### Use cases


## Ghidra MCP Headless - `ghidra-mcp-headless`

- **Command:** ``
- **Args:** ``
- **Profiles:** NATIVE-RE
- **Capabilities:** headless-binary-triage, batch-analysis-proof, timeout-and-cache
- **Health:** False
- **Certification:** unknown
- **Permissions:**
  - `filesystem_roots`: 
  - `network_hosts`: 
  - `credentials`: 
  - `mutation_level`: read_only
  - `approval_policy`: on_mutation

### Use cases


## GhidraMCP LaurieWired - `ghidramcp-lauriewired`

- **Command:** ``
- **Args:** ``
- **Profiles:** NATIVE-RE
- **Capabilities:** interactive-ghidra-control, state-sync, gui-handoff
- **Health:** False
- **Certification:** unknown
- **Permissions:**
  - `filesystem_roots`: 
  - `network_hosts`: 
  - `credentials`: 
  - `mutation_level`: read_only
  - `approval_policy`: on_mutation

### Use cases


## GitHub MCP - `github-mcp`

- **Command:** `npx`
- **Args:** `-y @modelcontextprotocol/server-github`
- **Profiles:** REPO
- **Capabilities:** repo-intake, issue-to-worktree, pr-ci-release, repo-mirror-sync
- **Health:** True
- **Certification:** passed
- **Permissions:**
  - `filesystem_roots`: 
  - `network_hosts`: 
  - `credentials`: GITHUB_PERSONAL_ACCESS_TOKEN
  - `mutation_level`: read_only
  - `approval_policy`: on_mutation

### Use cases


## GitLab MCP - `gitlab-mcp`

- **Command:** `npx`
- **Args:** `-y @modelcontextprotocol/server-gitlab`
- **Profiles:** REPO
- **Capabilities:** mr-pipeline-runner, gitlab-mirror-sync, oauth-connection-doctor, runner-proof
- **Health:** False
- **Certification:** failed
- **Permissions:**
  - `filesystem_roots`: 
  - `network_hosts`: 
  - `credentials`: GITLAB_PERSONAL_ACCESS_TOKEN
  - `mutation_level`: read_only
  - `approval_policy`: on_mutation

### Use cases


## Hyper-V MCP - `hyper-v-mcp`

- **Command:** `npx`
- **Args:** `-y hyper-v-mcp`
- **Profiles:** ISOLATED-LAB
- **Capabilities:** lab-provision-snapshot-restore, network-isolation, guest-evidence
- **Health:** False
- **Certification:** unknown
- **Permissions:**
  - `filesystem_roots`: 
  - `network_hosts`: 
  - `credentials`: 
  - `mutation_level`: read_only
  - `approval_policy`: on_mutation

### Use cases


## JADX AI MCP - `jadx-ai-mcp`

- **Command:** `npx`
- **Args:** `-y jadx-ai-mcp`
- **Profiles:** ANDROID-RE
- **Capabilities:** jadx-gui-session, find-reference-export, gui-state-recovery
- **Health:** False
- **Certification:** unknown
- **Permissions:**
  - `filesystem_roots`: 
  - `network_hosts`: 
  - `credentials`: 
  - `mutation_level`: read_only
  - `approval_policy`: on_mutation

### Use cases


## JADX MCP Server - `jadx-mcp-server`

- **Command:** `npx`
- **Args:** `-y jadx-mcp-server`
- **Profiles:** ANDROID-RE
- **Capabilities:** headless-apk-analysis, jadx-artifact-report, query-budgeting
- **Health:** False
- **Certification:** unknown
- **Permissions:**
  - `filesystem_roots`: 
  - `network_hosts`: 
  - `credentials`: 
  - `mutation_level`: read_only
  - `approval_policy`: on_mutation

### Use cases


## pyghidra-mcp - `pyghidra-mcp`

- **Command:** ``
- **Args:** ``
- **Profiles:** NATIVE-RE
- **Capabilities:** ghidra-variant-selection, capability-diff-test, state-persistence
- **Health:** False
- **Certification:** unknown
- **Permissions:**
  - `filesystem_roots`: 
  - `network_hosts`: 
  - `credentials`: 
  - `mutation_level`: read_only
  - `approval_policy`: on_mutation

### Use cases


## SearXNG MCP - `searxng-mcp`

- **Command:** `node`
- **Args:** `G:\Github\searxng-mcp\dist\index.js`
- **Profiles:** RESEARCH
- **Capabilities:** privacy-research, source-quality-and-citation, query-budgeting
- **Health:** False
- **Certification:** unknown
- **Permissions:**
  - `filesystem_roots`: 
  - `network_hosts`: 
  - `credentials`: 
  - `mutation_level`: read_only
  - `approval_policy`: on_mutation

### Use cases


## Serena - `serena`

- **Command:** `uvx`
- **Args:** `mcp-server-serena --project <PROJECT_ROOT>`
- **Profiles:** CORE
- **Capabilities:** semantic-project-onboard, symbol-impact-refactor, serena-index-doctor
- **Health:** False
- **Certification:** failed
- **Permissions:**
  - `filesystem_roots`: 
  - `network_hosts`: 
  - `credentials`: UV_PYTHON PATH
  - `mutation_level`: read_only
  - `approval_policy`: on_mutation

### Use cases


## x64dbg Automate MCP - `x64dbg-automate-mcp`

- **Command:** `npx`
- **Args:** `-y x64dbg-automate-mcp`
- **Profiles:** WINDOWS-RE
- **Capabilities:** breakpoint-plan, trace-export, safe-patch-proof
- **Health:** False
- **Certification:** unknown
- **Permissions:**
  - `filesystem_roots`: 
  - `network_hosts`: 
  - `credentials`: 
  - `mutation_level`: read_only
  - `approval_policy`: on_mutation

### Use cases


