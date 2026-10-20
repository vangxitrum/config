# Filepath Copy + Which-Key Design

## Overview

Two small additions to the Neovim config:
1. A keymap to copy the current buffer's absolute path to the system clipboard.
2. The which-key plugin to display available keymaps on `<leader>` pause.

## Filepath Copy

- **Keymap:** `<leader>fp` (normal mode), in the "File operator" section of `lua/chum/remap.lua`
- **Behavior:** `vim.fn.expand("%:p")` → `setreg("+", ...)` → `vim.notify` confirmation
- **Register:** system clipboard (`+`)

## Which-Key

- **New file:** `lua/chum/lazy/whichkey.lua`
- **Remove:** commented-out which-key block from `lua/chum/lazy/others.lua`
- **API:** v3 (`event = "VeryLazy"`, `opts.spec` for groups, `opts.delay = 500`)
- **Groups registered:**

| Prefix | Label |
|--------|-------|
| `<leader>p` | Project/Find |
| `<leader>c` | Code |
| `<leader>d` | Document |
| `<leader>w` | Workspace |
| `<leader>r` | Rename |
| `<leader>t` | Trouble |
| `<leader>l` | Lint |
| `<leader>v` | View |
| `<leader>f` | File |
