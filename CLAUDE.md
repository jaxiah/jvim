# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**jvim** is a personal dual-editor configuration. The goal is to maintain a clean, flat, and self-contained setup that works well for both Vim and Neovim on the same machine — without the overhead of a full distribution.

## Code Quality

The only automated check is Lua formatting via **stylua**:

```bash
stylua --check .
stylua .          # auto-format
```

Formatting rules are in `.stylua.toml`: 160-column width, 2-space indent, Unix line endings.

## Architecture

This repo maintains **two parallel configuration systems**:

### Modern Neovim (primary): `init.lua`
- Entry point for all Neovim users
- Plugin management via **lazy.nvim** (auto-bootstrapped from GitHub on first launch)
- All plugin specs live directly in `init.lua` as Lua tables — no subdirectory imports
- `lua/` contains only flat standalone modules:
  - `lua/health.lua` — `:checkhealth` support (checks Neovim version + external tools)
  - `lua/debug.lua` — optional DAP debugger spec (nvim-dap + nvim-dap-ui); uncomment in `init.lua` to enable

### Legacy Vim (`vimrc` + `autoload/plug.vim`)
- Traditional Vim configuration with **vim-plug** for plugin management
- Includes coc.nvim (LSP), NERDTree, LeaderF, copilot.vim, and others
- `autoload/plug.vim` is the vim-plug runtime (do not edit manually)

### Key Configuration Choices
- **Leader**: `<Space>`
- **Completion**: blink.cmp with LuaSnip
- **LSP**: nvim-lspconfig + mason.nvim (manages LSP server installs)
- **Fuzzy finding**: telescope.nvim
- **Colorscheme**: retrobox (built-in, no plugin needed)
- **Statusline**: mini.statusline

### Plugin Install/Update Workflow
Plugins are managed at runtime inside Neovim:
- `:Lazy` — view lazy.nvim plugin status, install, update
- `:Mason` — view/install LSP servers and tools
- `:MasonInstall <server>` — install a specific LSP server

### Adding Plugins
- Add plugin specs directly as Lua tables inside the `require('lazy').setup({...})` call in `init.lua`
- For larger or optional configs, add a new file under `lua/` and reference it with `require 'filename'`
- For the legacy Vim setup: add `Plug '...'` entries in `vimrc` between `plug#begin()`/`plug#end()`, then run `:PlugInstall`
