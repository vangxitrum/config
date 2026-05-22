# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository

Personal Neovim configuration. Entry point is `init.lua`, which sources `lua/chum/init.lua`.

## Architecture

The config follows a `chum` module convention. `lua/chum/init.lua` requires five files **in order** — order matters because plugin loading depends on options/leader being set first, and LSP enablement assumes plugins are available:

1. `set.lua` — `vim.opt`/`vim.g` options. Sets `<space>` as leader (**must happen before plugins load**, otherwise plugin keymaps bind to the wrong leader).
2. `remap.lua` — global keymaps (non-LSP, non-plugin-local).
3. `package.lua` — bootstraps lazy.nvim and calls `require("lazy").setup({ spec = "chum.lazy" })`. The `spec = "chum.lazy"` form auto-discovers every file under `lua/chum/lazy/` — **adding a new plugin = adding a new file there**, no central registry to edit.
4. `autocmd.lua` — autocmds, including the `LspAttach` handlers that wire LSP keymaps (`gd`, `gr`, `K`, `<leader>rn`, `<leader>ca`, …) and enable native `vim.lsp.completion`.
5. `lsp.lua` — calls `vim.lsp.enable({...})` with server names. **This is the Neovim 0.11+ native LSP API**, not nvim-lspconfig. Each enabled name `X` must have a matching `lsp/X.lua` at the repo root returning a config table (`cmd`, `filetypes`, `root_markers`, `settings`). To add a server: install its binary via Mason → drop `lsp/<name>.lua` → add `"<name>"` to the `vim.lsp.enable` list.

## Tooling pipeline

Three plugins cooperate and must stay in sync — installing a tool in one but not referencing it in the others is the most common drift:

- `lazy/mason.lua` — installs LSP servers, formatters, linters into `~/.local/share/nvim/mason/bin`. The `ensure_installed` list is the source of truth for what gets installed.
- `lazy/conform.lua` — `formatters_by_ft` table maps filetype → formatter chain. `format_on_save` is enabled (1000ms timeout, `lsp_format = "fallback"`). Go chain is `goimports → gofumpt → golines` (golines `--max-len=80`).
- `lazy/lint.lua` — `linters_by_ft` table. Lints on `BufEnter`, `BufWritePost`, `InsertLeave`. `golangcilint` is patched to `ignore_exitcode = true` and reads `~/.golangci.yaml`.

When adding language support, update all three (Mason install + conform formatter + lint linter) plus `lsp.lua` and `lsp/<name>.lua` if an LSP server is involved.

## Conventions

- **Indentation: hard tabs** (tabstop/shiftwidth = 4, `expandtab` is set globally but Lua files in this repo use tabs — stylua handles formatting). Match existing file style; don't switch a tab-indented file to spaces.
- Trailing whitespace is auto-stripped on save (`autocmd.lua`).
- Missing parent directories are auto-created on save.
- Format-on-save is on — don't add manual formatting steps.
- The `python3_host_prog` is hardcoded to `/home/tuan/anaconda3/bin/python` in `set.lua`.

## Commands (run inside nvim)

- `:Lazy` — manage plugins (sync, update, check). `lazy-lock.json` pins versions; commit changes after `:Lazy update`.
- `:Mason` (or `<leader>cm`) — manage external tools. `:MasonUpdate` refreshes the registry.
- `:TSUpdate` — update treesitter parsers. Parsers install to `stdpath("data")/custom_parsers` (custom dir prepended to rtp), **not** the default location.
- `:ConformInfo` — debug formatter resolution. `<leader>cf` formats the current buffer manually.
- `<leader>ll` triggers nvim-lint manually; `<leader>li` shows configured linters for the current filetype.
- `:checkhealth` — diagnose plugin/runtime issues.

## Validating changes

There's no test suite. To verify config changes: launch `nvim`, watch for errors in `:messages` and `:Lazy log`, then exercise the affected feature (open a file of the relevant filetype for LSP/format/lint changes).
