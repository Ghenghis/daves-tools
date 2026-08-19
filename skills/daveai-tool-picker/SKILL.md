---
name: daveai-tool-picker
description: Given a DAVE-AI task, recommend and wire the right MCP server or skill from the catalog.
---

# daveai-tool-picker

**Use when:** you need to select a tool, MCP server, or skill for a DAVE-AI task.

## Steps
- Ask for the one-sentence project or task goal.
- Read `mcp-manager\marketplace.json` and `docs\MISSING-ITEMS.md`.
- Pick the smallest item that solves the task.
- Provide the exact copy-paste config or install command.
- Record the choice in the proof ledger.

## Proof required
- Tool/skill name and why it was selected.
- Config snippet path or install command.
- Required credential or env var.
