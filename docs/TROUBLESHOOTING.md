# Troubleshooting

## MCP error -32000: Connection closed

This is the most common certification failure. It means the child process started but could not complete the MCP handshake.

- Check that the runtime is installed (`node`, `npx`, `uvx`, `python`, or the referenced executable).
- Check that the path in `runtime.args` is correct.
- Try running the command manually in a terminal.
- If the server uses `npx`, make sure it can reach the registry without network blocks.
- Verify the working directory `runtime.cwd` exists.

## Command not found

- Add Node.js and Python to the system `PATH`.
- For `uvx`, install it with `pip install uv` or `pipx install uv`.
- For `npx` packages that fail, run `npm install -g <package>` once to pre-warm the cache.

## LM Studio is unreachable

- Confirm LM Studio is running and the local server is on port `1234`.
- `curl http://localhost:1234/v1/models` should return JSON.
- If LM Studio is not running, `toolkit/Watch-LmStudio.ps1` can restart it.
- Ensure a model is loaded before calling `/v1/chat/completions`.

## ComfyUI fails to import torchaudio

This happens when the installed PyTorch wheels do not match the CPU/GPU environment.

- For CPU mode: `python -m pip install --force-reinstall --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu`
- For GPU mode, use the CUDA or ROCm index URL instead.
- Re-run `python main.py --listen 0.0.0.0 --port 8188 --cpu`.

## Container fallback warning

If `harness/container.js` cannot find Docker, it falls back to the host runtime. This is logged but not fatal. To force container mode, start Docker Desktop and confirm `docker ps` works.

## Access denied / EPERM

The asset tried to read or write outside `permissions.filesystem_roots`. Either add the root to the registry or reject the call. Do not run the harness as administrator to bypass this.

## Certification returns unknown

An asset has no `last_verified` timestamp. Run `node harness/certifier.js --id <asset-id>` for that asset.

## IDE cannot find the harness

- Use the full absolute path to `harness/proxy.js` in the IDE config.
- Ensure `node` is in the IDE process environment.
- Restart the IDE after editing its MCP config.