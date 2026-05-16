# AGENTS.md

Project guidance for coding agents and maintainers working in this repository.

## Project Overview

`jvim` is a personal Vim and Neovim configuration repository. It keeps a clean, flat, mostly self-contained setup for using both editors on the same machine without adopting a full editor distribution.

## Windows Setup

Both editors are linked to this repository with NTFS junctions. After cloning, run:

```powershell
.\setup-links.ps1 -RepoPath "D:\path\to\jvim"
```

This creates:

- `%LOCALAPPDATA%\nvim` -> repo, for Neovim
- `%USERPROFILE%\vimfiles` -> repo, for Vim

## Code Quality

Lua formatting is handled by `stylua`.

```bash
stylua --check .
stylua .
```

Formatting rules live in `.stylua.toml`: 160-column width, 2-space indent, Unix line endings, and single quotes where practical.

## Repository Structure

The repository contains two parallel editor configurations.

## Neovim

`init.lua` is the primary Neovim entry point.

- Plugin management uses `lazy.nvim`, bootstrapped from GitHub on first launch.
- Most plugin specs live directly in the `require('lazy').setup({...})` call in `init.lua`.
- The leader key is `\`; the local leader is `\\`.
- Completion uses `blink.cmp` with LuaSnip.
- LSP uses `nvim-lspconfig`, `mason.nvim`, and `mason-tool-installer.nvim`.
- Fuzzy finding uses `telescope.nvim`.
- The colorscheme is built-in `retrobox`.
- Statusline and tabline use `mini.statusline` and `mini.tabline`.

The `lua/` directory is intentionally flat and small:

- `lua/health.lua`: `:checkhealth` support for Neovim version and external tool checks.
- `lua/debug.lua`: optional DAP debugger spec. Enable it from `init.lua` if needed.
- `lua/codetour.lua`: code tour navigation using `.tour.json` files. Use `:TourLoad`, then `]q` and `[q`.

## Vim

`vimrc` is the legacy Vim configuration.

- Plugin management uses `vim-plug`.
- `autoload/plug.vim` is the vim-plug runtime and should not be edited manually.
- Vim plugins include lightline, NERDTree, NERDCommenter, LeaderF, Gutentags, Tagbar, vimcomplete, Copilot, termdbg, and coc.nvim.

## Plugin Workflow

For Neovim:

- `:Lazy` shows lazy.nvim plugin status and manages plugin installs and updates.
- `:Mason` shows installed LSP servers and external tools.
- `:MasonInstall <server>` installs a specific LSP server or tool.
- Add regular plugin specs directly in `init.lua`.
- For larger optional configs, place a flat module in `lua/` and require it from `init.lua`.

For Vim:

- Add `Plug '...'` lines in `vimrc` between `plug#begin()` and `plug#end()`.
- Run `:PlugInstall` after adding Vim plugins.
