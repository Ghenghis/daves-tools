# Architecture

DAVE-AI Tools is a control plane, not a monolithic server. The source of truth is the typed registry; the harness enforces the registry at runtime.

## Source of truth

`configs/typed-registry.json` is a single file that describes every asset:

- What it is (`id`, `display_name`, `asset_type`)
- Where it comes from (`source`)
- Who should use it (`profiles`)
- What it can do (`capabilities`)
- How to run it (`runtime`)
- What it is allowed to touch (`permissions`)
- Whether it was proven to work (`verification`)

Any tool not in this file is not part of the supported ecosystem.

## Harness components

| Component | Responsibility |
|-----------|----------------|
| `harness/certifier.js` | Pre-flight certification: install, protocol, domain smoke |
| `harness/proxy.js` | Main MCP router: activates task-aware profiles, spawns servers, switches tools |
| `harness/container.js` | Builds Docker or host runtime commands for an asset |
| `harness/health.js` | Heartbeat monitoring and restart decisions |
| `harness/watchdog.js` | Global harness watchdog, persistence, and recovery |
| `harness/profiles.js` | Profile resolution and filtering |
| `harness/mcp-utils.js` | Shared MCP protocol helpers |

## Activation lifecycle

1. The IDE starts `harness/proxy.js` over stdio.
2. The user or agent sends a task with a profile hint.
3. `harness/profiles.js` resolves the active asset set.
4. `harness/certifier.js` ensures each asset is healthy.
5. `harness/container.js` builds the launch command, using Docker if flagged.
6. `StdioClientTransport` spawns the MCP child.
7. Calls are routed, results are returned, and the asset is stopped when the profile changes.

## Profile-based switching

Assets are tagged with one or more profiles: `CORE`, `CODE`, `MEDIA`, `SECURITY`, `REVERSE`, `SYSTEM`. The proxy can switch the active tool surface without restarting the IDE. This keeps the context window focused and reduces the chance of calling the wrong tool.

## Containerization

When `metadata.isolation` is `container`, the harness builds a `docker run` command that mounts only the approved `filesystem_roots`, uses the same stdio transport, and runs the MCP inside a container. If Docker is unavailable, it falls back to the native runtime and logs a warning.

## Secret resolution

The registry stores only secret names. At runtime, `harness/mcp-utils.js` resolves them from the DPAPI-backed vault. The child process receives the resolved value through an environment variable, never through the args array where it would be visible in process listings.

## Health and watchdog

`harness/health.js` sends periodic heartbeats to each spawned MCP. If an MCP fails, the watchdog restarts it and logs the event. `toolkit/Watch-LmStudio.ps1` does the same for the LM Studio local API, restarting the application if it stops responding.

## Event flow

```
IDE / Agent
    |
    v
harness/proxy.js
    +-- harness/profiles.js
    +-- harness/certifier.js
    +-- harness/container.js
    +-- harness/health.js
    |
    v
MCP server / skill pack / local model
```

## Failure isolation

- One failing MCP cannot crash the proxy.
- An asset with a failed certification is skipped for that session.
- Containerized failures are isolated from the host filesystem.
- LM Studio crashes are recovered outside the main harness process.

## Adding a new asset

1. Add the entry to `configs/typed-registry.json`.
2. Add the launch snippet if one exists.
3. Run `node harness/certifier.js --id <new-asset>`.
4. If it passes, the proxy will pick it up on the next start.