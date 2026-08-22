# Security Model

DAVE-AI Tools is designed to let agents use powerful tools without giving them unlimited access to the host.

## Secret handling

- Secrets are referenced by name in `configs/typed-registry.json`.
- The actual values are resolved from `configs/secrets.json` and then encrypted with DPAPI on Windows.
- Credentials are never written into launch snippets or IDE config files.
- `configs/secrets.json` is excluded from Git by `.gitignore`.
- On Linux, the fallback is a 0600 JSON file in `~/.config/daves-tools/secrets.json`.

## Permission scopes

Every asset in the registry declares:

- `filesystem_roots` — the directories it may read or write
- `network_hosts` — the endpoints it may call
- `credentials` — the named secrets it may resolve
- `mutation_level` — `read_only` or `mutating`
- `approval_policy` — `on_mutation` or `never`

A mutating tool must pass an approval gate unless the policy says otherwise.

## Container isolation

Assets with `metadata.isolation: container` are wrapped by `harness/container.js`. The container command is built only when Docker is available. If Docker is not running, the harness falls back to the host runtime and logs a warning.

The certifier rejects a containerized asset if it would expose the host filesystem outside the allowed roots.

## Network egress

MCP servers with `network_hosts` set cannot call hosts outside the list. The proxy enforces this by filtering `fetch` and `http` tools at runtime where possible. Servers that violate the list are killed and marked failed.

## Audit trail

- `docs/certification-summary.json` records the last certification result for each asset.
- `harness/events.ndjson` (if enabled) logs every call, result, and failure.
- The watchdog writes restart and heartbeat events to `logs/watchdog.ndjson`.

## What is NOT protected

- A container that is misconfigured can still escape if Docker is run as administrator. Do not run Docker in admin mode for this harness unless required.
- The agent can still ask the user to approve a dangerous call. Read the call summary before approving.
- Tools with `mutation_level: mutating` and `approval_policy: never` are dangerous. Only set this for fully trusted servers.