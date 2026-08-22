---
name: daveai-repo-hygiene
description: Audit, deduplicate, archive, and maintain DAVE-AI-created repositories across GitHub and GitLab.
---

# daveai-repo-hygiene

**Use when:** there are many DAVE-AI-created repos and you need to clean up, batch rename, archive, or add READMEs.

## Steps
- Use the `github` or `gitlab` MCP server to list repos.
- Identify duplicates by name prefix or description.
- Propose a batch action: archive, add README, update description, merge upstream.
- Get explicit approval before any destructive or public change.
- Execute approved actions via the MCP server or `gh`/`glab` CLI.
- Record the batch plan and results in the proof ledger.

## Proof required
- List of repos inspected.
- Proposed and approved actions.
- Summary of executed changes.
