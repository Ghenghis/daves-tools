# Recommended Local LLMs for the DAVE-AI MCP Harness

> These are **local text/reasoning models**, not ComfyUI diffusion checkpoints. They run in LM Studio on a second PC with an ASRock Challenger RX 7800 XT (16 GB VRAM) and are loaded as GGUF quantizations. Pick the right model for the asset profile you are working with.

## Target hardware

- GPU: ASRock Challenger RX 7800 XT
- VRAM: 16 GB
- Runtime: LM Studio with `LM Link` / OpenAI-compatible local server
- Quantization sweet spot: **Q4_K_M** for 9-14 B models, **Q5_K_M** for 7 B models

## Shortlist: 2-3 models that cover the catalog

| Rank | Model | Params | VRAM (Q4_K_M) | Best for | HuggingFace (GGUF) |
|---|---|---|---|---|---|
| 1 | **Qwen2.5-Coder-14B-Instruct** | 14.7 B | ~8.5 GB | Coding, reverse-engineering scripts, Ghidra/JADX workflows, tool-calling | [`Qwen/Qwen2.5-Coder-14B-Instruct-GGUF`](https://huggingface.co/Qwen/Qwen2.5-Coder-14B-Instruct-GGUF) |
| 2 | **Gemma 2 9B Instruct** | 9 B | ~5.5 GB | General agentic chat, fast tasks, low-VRAM fallback, the same family already loaded in your LM Studio | [`lmstudio-community/gemma-2-9b-it-GGUF`](https://huggingface.co/lmstudio-community/gemma-2-9b-it-GGUF) |
| 3 | **Mellum2 12B A2.5B Instruct** | 12 B (MoE, 8 active) | ~8.1 GB | Long-context code analysis, 131 k context, assistant-style reasoning | [`JetBrains/Mellum2-12B-A2.5B-Instruct-GGUF-Q4_K_M`](https://huggingface.co/JetBrains/Mellum2-12B-A2.5B-Instruct-GGUF-Q4_K_M) |

### Why these three?

1. **Qwen2.5-Coder-14B** is the strongest open code-specific model in the 14 B class. It is well above the coding benchmark of non-code-tuned 12-14 B models, and the 14 B size still leaves room on a 16 GB card with Q4_K_M.
2. **Gemma 2 9B** is a known-good model in LM Studio, has a very large vocabulary that helps with code and multilingual prompts, and is small enough to run alongside other tools.
3. **Mellum2 12B** is a Mixture-of-Experts coding assistant with a 131 k context. It is a strong alternative for long source files, disassembly listings, or large Ghidra/JADX outputs.

## Model-to-asset profile mapping

| Asset profile | Recommended model | Why |
|---|---|---|
| `REPO` (GitHub, GitLab, SearXNG) | Qwen2.5-Coder-14B | Commit messages, diffs, issue triage, PR reviews |
| `RESEARCH` (Context7, SearXNG) | Mellum2-12B | Long documents, 131 k context, citation-style answers |
| `ANDROID-RE` (Apktool, JADX, Frida) | Qwen2.5-Coder-14B | Smali, Java, resource extraction, exploit scripts |
| `NATIVE-RE` (Ghidra, x64dbg, radare2) | Qwen2.5-Coder-14B or Mellum2-12B | Disassembly, C/decompilation, large binary analysis |
| `WINDOWS-RE` (x64dbg, AutoGenesis) | Qwen2.5-Coder-14B | x86/64 assembly, Windows API, PowerShell/C# snippets |
| `ANDROID-DEV` (Android, Appium, Maestro) | Gemma 2 9B | Fast, general QA and UI automation script generation |
| `WINDOWS-DEV` (AutoGenesis, win-dev) | Qwen2.5-Coder-14B | WinForms/WPF test plans, C#, automation |
| `CORE` (Serena, Anthropic skills) | Gemma 2 9B | General coding assistant, fast enough for default use |

## Practical load targets in LM Studio

Use the smallest quant that still fits comfortably under 16 GB and leaves headroom for the OS / context cache.

| Model | Quant | Size | Fits 16 GB? | Notes |
|---|---|---|---|---|
| Qwen2.5-Coder-14B | Q4_K_M | ~8.5 GB | Yes, with room | Best balance for coding |
| Qwen2.5-Coder-14B | Q5_K_M | ~10.5 GB | Tight | Slightly better quality if you only load one model |
| Qwen2.5-Coder-14B | Q8_0 | ~15.7 GB | No | Too large for 16 GB once context KV is added |
| Gemma 2 9B | Q4_K_M | ~5.5 GB | Yes, lots of room | Good default / second slot |
| Gemma 2 9B | Q5_K_M | ~6.5 GB | Yes | Noticeably better for the size cost |
| Mellum2 12B | Q4_K_M | ~8.1 GB | Yes | Recommended for long context |

## How to load in LM Studio

1. Open LM Studio on the 7800 XT PC.
2. Search the model name in the HuggingFace model browser or use `Download from HuggingFace`.
3. Select the **Q4_K_M** (or **Q5_K_M**) GGUF file.
4. Set:
   - **Context length**: 4096-8192 for 14 B, 8192-16384 for 9/12 B
   - **GPU offload**: Max layers
   - **Batch size / n_ctx**: 4096 default
5. Enable the **Local Server** at `http://localhost:1234`.
6. Point DAVE-AI agents at `http://<other-pc-ip>:1234/v1/chat/completions` or use `LM Link` to route from the main PC.

## LM Link / OpenAI endpoint sample

```bash
curl http://<other-pc-ip>:1234/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5-coder-14b-instruct",
    "messages": [{"role": "user", "content": "Explain this ARM64 function in C"}],
    "temperature": 0.2
  }'
```

## What we did not include

These are **text-inference** recommendations. For image/video generation or ComfyUI, the required models are diffusion checkpoints (SDXL, Flux, etc.) stored in `G:\Github\ComfyUI\models`, not in LM Studio. The harness `comfyui-mcp` expects ComfyUI to be running on `http://localhost:8188` with those checkpoints installed; that is a separate stack.
