-- Create sub folder when save file if not existed
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	group = vim.api.nvim_create_augroup("auto_create_dir", { clear = true }),
	callback = function(event)
		if event.match:match("^%w%w+://") then
			return
		end
		local file = vim.loop.fs_realpath(event.match) or event.match
		vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
	end,
})

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

-- Remove trailing space
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	pattern = { "*" },
	command = [[%s/\s\+$//e]],
})

-- Automatically reload file if changed outside of neovim
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
	group = vim.api.nvim_create_augroup("auto_reload_file", { clear = true }),
	pattern = "*",
	command = "silent! checktime",
})

-- NOTE: No manual LSP re-sync on external edits is needed. When `autoread`
-- reloads a buffer after an agent/external write, Neovim's native LSP client
-- sends a full-document didChange via its on_reload handler automatically.
-- A previous FileChangedShellPost detach/re-attach autocmd here caused the
-- server to be torn down and respawned on every external edit (restart loop).

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),

	callback = function(event)
		local map = function(keys, func, desc)
			vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
		end

		-- Jump to the definition of the word under your cursor.
		--  This is where a variable was first declared, or where a function is defined, etc.
		--  To jump back, press <C-t>.
		map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

		-- Find references for the word under your cursor.
		map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

		-- Jump to the implementation of the word under your cursor.
		--  Useful when your language has ways of declaring types without an actual implementation.
		map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")

		-- Jump to the type of the word under your cursor.
		--  Useful when you're not sure what type a variable is and you want to see
		--  the definition of its *type*, not where it was *defined*.
		map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")

		-- Fuzzy find all the symbols in your current document.
		--  Symbols are things like variables, functions, types, etc.
		map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")

		-- Fuzzy find all the symbols in your current workspace.
		--  Similar to document symbols, except searches over your entire project.
		map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

		-- Rename the variable under your cursor.
		--  Most Language Servers support renaming across files, etc.
		map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")

		-- Execute a code action, usually your cursor needs to be on top of an error
		-- or a suggestion from your LSP for this to activate.
		map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

		-- Opens a popup that displays documentation about the word under your cursor
		--  See `:help K` for why this keymap.
		map("K", vim.lsp.buf.hover, "Hover Documentation")

		-- WARN: This is not Goto Definition, this is Goto Declaration.
		--  For example, in C this would take you to the header.
		map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
	end,
})
-- Netrw: Shift+D sends to system trash (via gio) instead of permanent delete
vim.api.nvim_create_autocmd("FileType", {
	pattern = "netrw",
	group = vim.api.nvim_create_augroup("netrw_trash_delete", { clear = true }),
	callback = function(ev)
		vim.keymap.set("n", "D", function()
			local ok, fname = pcall(vim.fn["netrw#Call"], "NetrwGetWord")
			if not ok or fname == nil or fname == "" or fname == "./" or fname == "../" then
				return
			end
			local dir = vim.b.netrw_curdir or vim.fn.getcwd()
			local target = dir .. "/" .. (fname:gsub("/$", ""))
			if vim.fn.confirm("Trash " .. target .. "?", "&Yes\n&No", 2) ~= 1 then
				return
			end
			local out = vim.fn.system({ "gio", "trash", "--", target })
			if vim.v.shell_error ~= 0 then
				vim.notify("Trash failed: " .. out, vim.log.levels.ERROR)
			else
				vim.notify("Trashed: " .. target)
				vim.cmd.edit(dir)
			end
		end, { buffer = ev.buf, desc = "Send file to trash (gio)" })
	end,
})

-- Refresh statusline git branch after returning from lazygit (external or toggleterm)
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose" }, {
	group = vim.api.nvim_create_augroup("statusline_git_refresh", { clear = true }),
	callback = function()
		vim.cmd("redrawstatus!")
	end,
})

-- Diagnostics
vim.diagnostic.config({
	-- Use the default configuration
	-- virtual_lines = true

	-- Alternatively, customize specific options
	virtual_lines = {
		-- Only show virtual line diagnostics for the current cursor line
		current_line = true,
	},
})
