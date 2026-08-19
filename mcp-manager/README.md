# MCP Manager

Install and validate MCP servers from the DAVE-AI marketplace.

## Files

- `marketplace.json` — canonical 7 MCP server sources
- `Install-McpServer.ps1` — clone a marketplace repo, validate it, and print a `claude_desktop_config.json` snippet

## Usage

```powershell
.\Install-McpServer.ps1 -Name browserbase -InstallRoot G:\Github\MCP
```

Supported names: `awesome-mcp-servers`, `claude-server`, `JSON-MCP-Server`, `mcp-installer`, `mcp-marketplace`, `mcp-server-browserbase`, `modelcontextprotocol-servers`.
