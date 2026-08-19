---
name: github-or-gitlab-connector
description: Connect to a GitHub or GitLab repository for issues, PRs, branches, and releases.
---

# github-or-gitlab-connector

**Use when:** the task involves a remote repository action.

## Steps
- Identify whether the target is GitHub or GitLab from project remotes.
- Choose the correct MCP server (`github` or `gitlab`).
- Verify the required token/credential is in the environment.
- Only perform read-only actions unless explicitly authorized.
- Record any repository-side change in the proof ledger.

## Proof required
- Remote URL and MCP server used.
- Action taken and its result.
