# Setup Guide

This guide covers a first-time Windows install of DAVE-AI Tools and the main runtimes it orchestrates.

## Prerequisites

- Windows 10 or 11 (the harness is Windows-first; WSL is optional)
- Node.js LTS (18 or newer)
- Python 3.10 or newer (ComfyUI and several MCP servers require it)
- Git
- Docker Desktop (optional, only if you want container isolation for high-risk MCPs)
- LM Studio for local LLM inference
- Ollama (optional, for Ollama-compatible models)

## Install DAVE-AI Tools

```
git clone https://github.com/Ghenghis/daves-tools.git
cd daves-tools
npm install
```

## Install the harness as a Windows service

```powershell
.\toolkit\Install-McpService.ps1
```

This creates a `DAVE-AI-Harness` service that starts at boot. To run interactively instead, use:

```
node harness/proxy.js
```

## Add secrets and scopes

The registry references secrets by name. On Windows, DPAPI is used for `configs/secrets.json`. Do not put plaintext tokens in `claude_desktop_config.json` or any IDE config.

1. Copy `configs/secrets.example.json` to `configs/secrets.json` if it exists.
2. Add your keys using the names referenced in `configs/typed-registry.json`.
3. Never commit `configs/secrets.json`.

## Wire the MCP harness to your IDE

The `harness/proxy.js` exposes a combined MCP surface on stdio. Point your IDE at it.

### Claude Desktop

Edit `%APPDATA%\Claude\claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "daves-tools": {
      "command": "node",
      "args": ["C:/Users/Admin/CascadeProjects/daves-tools/harness/proxy.js"]
    }
  }
}
```

### Cline

Edit the Cline MCP settings file and add the same `command` and `args`.

### Windsurf

Open the MCP server list in Windsurf and add a new stdio server with command `node` and argument `harness/proxy.js` from the daves-tools root.

### Roo Code

Use the Roo Code MCP panel and add a stdio server with the full path to `harness/proxy.js`.

## Start ComfyUI

If you installed ComfyUI on `S:/` from this toolkit:

```
python S:/ComfyUI/main.py --listen 0.0.0.0 --port 8188 --cpu
```

For GPU mode, remove `--cpu` if you have a working CUDA or ROCm environment.

## Start LM Studio local server

1. Open LM Studio.
2. Load a model from `docs/RECOMMENDED-MODELS.md`.
3. Start the local server on port `1234`.
4. Verify with `curl http://localhost:1234/v1/models`.

## Certify the assets

```
node harness/certifier.js
```

Then check `docs/certification-summary.json` and `docs/MCP-CATALOG.md`.

## Next steps

- Read `docs/SECURITY.md` for the permission and secret model.
- Read `docs/ARCHITECTURE.md` for how the harness routes calls.
- Read `docs/TROUBLESHOOTING.md` when something fails.