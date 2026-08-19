# DAVE-AI Tools Remediation Brief

## Non-negotiable truth corrections

- Replace “49 installed MCP servers” with “43 catalog entries across multiple asset types.”
- Explain that preflight 49 is 36 phase rows plus 13 duplicated repair rows.
- Never mark an item healthy from clone/directory presence.
- Never generate a generic `npx` launcher when upstream installation is unknown.
- Never place skills, GUIs, CLIs, services, benchmarks or marketplaces in an MCP-only registry.

## P0 implementation order

1. Typed registry + JSON schema.
2. Unique count/deduplication and generated README.
3. Correct official launchers for Serena, GitHub, GitLab, Context7, Playwright MCP and existing HermesProof.
4. Live certifier: initialize, list tools, schema validation, safe call, timeout, cancel, stop, forced-crash recovery.
5. Preserve child descriptions and schemas.
6. Permission/secret broker and read-only defaults.
7. HermesProof structured event integration.
8. Project router, capability doctor, tool lifecycle, recovery, repo mirror and release skills.
9. Compact Windows operator dashboard.

## Definition of “end-to-end covered” for one asset

An entry is covered only when source/provenance, install, launch, protocol, exact tool schema, credentials, permissions, safe smoke call, domain fixture, failure/recovery, uninstall/rollback and HermesProof evidence all pass. Dependencies and skills use equivalent type-specific gates rather than MCP protocol gates.
