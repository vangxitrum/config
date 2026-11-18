-- SQL client: vim-dadbod runs queries through psql, dadbod-ui adds a DB tree
-- and saved query buffers, dadbod-completion feeds tables/columns to blink.
--
-- Connections come from ~/.pg_service.conf:
-- every [section] becomes a `postgresql:///?service=<name>` entry, so hosts
-- and passwords (~/.pgpass) never live in this repo.
--
-- On the host psql runs in Docker (scripts/pg-docker.sh, no sudo): /tmp, $HOME
-- and $XDG_RUNTIME_DIR are mounted at the same paths, so `psql -f <temp file>`
-- works. Local DBs and SSH tunnels on your localhost are therefore
-- host=host.docker.internal port=<published/forwarded port>, not localhost.

local function pg_services()
	local file = vim.env.PGSERVICEFILE or vim.fn.expand("~/.pg_service.conf")
	local dbs = {}
	if vim.fn.filereadable(file) == 0 then
		return dbs
	end
	for _, line in ipairs(vim.fn.readfile(file)) do
		local name = line:match("^%[(.+)%]$")
		if name then
			table.insert(dbs, { name = name, url = "postgresql:///?service=" .. name })
		end
	end
	return dbs
end

-- Labels for dadbod-ui's buffer keys (it maps them without descriptions).
local db_keys = {
	query = {
		{ "<C-CR>", desc = "Run query (selection in visual)", mode = { "n", "x", "i" } },
		{ "<leader>W", desc = "Save query" },
		{ "<leader>E", desc = "Edit bind parameters" },
		{ "<leader>sf", desc = "Show buffer in DB tree" },
		{ "<leader>su", desc = "Toggle DB tree" },
		-- Motions from Neovim's built-in sql ftplugin.
		{ "]]", desc = "Next statement start", mode = { "n", "x" } },
		{ "[[", desc = "Previous statement start", mode = { "n", "x" } },
		{ "][", desc = "Next statement end", mode = { "n", "x" } },
		{ "[]", desc = "Previous statement end", mode = { "n", "x" } },
		{ "]}", desc = "Next block (if/loop/begin)", mode = { "n", "x" } },
		{ "[{", desc = "Previous block (if/loop/begin)", mode = { "n", "x" } },
		{ ']"', desc = "Next comment", mode = { "n", "x" } },
		{ '["', desc = "Previous comment", mode = { "n", "x" } },
	},
	dbui = {
		{ "o", desc = "Open / expand" },
		{ "<CR>", desc = "Open / expand" },
		{ "<2-LeftMouse>", hidden = true },
		{ "S", desc = "Open in vertical split" },
		{ "R", desc = "Redraw tree" },
		{ "d", desc = "Delete saved query / connection" },
		{ "r", desc = "Rename saved query / connection" },
		{ "A", desc = "Add connection (stores plain URL)" },
		{ "H", desc = "Toggle connection details" },
		{ "J", desc = "Next sibling" },
		{ "K", desc = "Previous sibling" },
		{ "<C-j>", desc = "Last sibling" },
		{ "<C-k>", desc = "First sibling" },
		{ "<C-n>", desc = "Child node" },
		{ "<C-p>", desc = "Parent node" },
		{ "q", desc = "Close tree" },
	},
	dbout = {
		{ "<C-]>", desc = "Jump to foreign key row" },
		{ "vic", desc = "Select cell value" },
		{ "yh", desc = "Yank column header" },
		{ "<leader>R", desc = "Toggle expanded layout" },
		{ "q", desc = "Close results" },
		{ "gq", desc = "Close results (delete buffer)" },
		{ "R", desc = "Re-run query" },
	},
}

local function show_db_help()
	require("which-key").show({ global = false })
end

local function setup_db_keys(buf, ft)
	local kind = (ft == "dbui" or ft == "dbout") and ft or "query"
	if kind == "query" then
		-- Buffer-local copies so the help lists them; the global <C-CR> stays to
		-- stop dadbod-ui from adding <leader>S.
		local run = "<Plug>(DBUI_ExecuteQuery)"
		vim.keymap.set({ "n", "x" }, "<C-CR>", run, { buffer = buf, remap = true })
		vim.keymap.set("i", "<C-CR>", "<Esc>" .. run, { buffer = buf, remap = true })
		vim.keymap.set("n", "<leader>sf", "<cmd>DBUIFindBuffer<cr>", { buffer = buf })
		vim.keymap.set("n", "<leader>su", "<cmd>DBUIToggle<cr>", { buffer = buf })
		-- dadbod-ui defines <Plug>(DBUI_SaveQuery) only in new (tmp) queries, so
		-- in a saved query <leader>W did nothing. There it writes the file
		-- instead (always, so the "Query updated" notice confirms it even right
		-- after an auto-save).
		local save_dir = vim.g.db_ui_save_location .. "/"
		if vim.api.nvim_buf_get_name(buf):sub(1, #save_dir) == save_dir then
			vim.keymap.set("n", "<leader>W", "<cmd>write<cr>", { buffer = buf })
		end
	elseif kind == "dbout" then
		vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf })
	end
	if kind ~= "query" then
		-- Replaces dadbod-ui's stopinsert (removed in `config` below): only stop
		-- insert when you actually stay in this window.
		vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
			group = vim.api.nvim_create_augroup("dbui_stopinsert_" .. buf, { clear = true }),
			buffer = buf,
			callback = function()
				vim.schedule(function()
					if vim.api.nvim_get_current_buf() == buf then
						vim.cmd.stopinsert()
					end
				end)
			end,
		})
	end
	if kind == "dbui" then
		vim.keymap.set("n", "?", show_db_help, { buffer = buf, desc = "Key help" })
		-- The tree's colours are regex syntax (syntax/dbui.vim). A long session
		-- once lost them all (cause not found: not :cd, toggling the tree,
		-- toggleterm, queries or a colorscheme reload). Re-apply when they are
		-- gone; setting 'syntax' re-runs the Syntax autocmd even to the same value.
		vim.api.nvim_create_autocmd("BufEnter", {
			group = vim.api.nvim_create_augroup("dbui_syntax_" .. buf, { clear = true }),
			buffer = buf,
			callback = function()
				if vim.fn.execute("syntax list"):find("No Syntax items") then
					vim.bo[buf].syntax = "dbui"
				end
			end,
		})
	end
	vim.keymap.set("n", "<leader>?", show_db_help, { buffer = buf, desc = "Key help" })

	local spec = {}
	for _, key in ipairs(db_keys[kind]) do
		table.insert(spec, vim.tbl_extend("force", key, { buffer = buf }))
	end
	require("which-key").add(spec)
end

-- vim-dadbod opens results with `botright pedit`: a full-width strip under both
-- the DB tree and the query, 'previewheight' (12) rows tall. From there <C-h>
-- had nowhere to go and <C-k> landed in the tree. Move the results under the
-- query that ran them (tree | query over results) and give them 45% of the
-- screen. Once they sit there, keep the layout and any size you gave them.
local function place_results(buf)
	local out = vim.fn.bufwinid(buf)
	local src = vim.api.nvim_get_current_win()
	if out == -1 or out == src then
		return
	end
	local height = math.floor(vim.o.lines * 0.45)
	local ft = vim.bo[vim.api.nvim_win_get_buf(src)].filetype
	if ft ~= "sql" and ft ~= "mysql" and ft ~= "plsql" then
		-- :DB from some other buffer: leave the window where it is, just taller.
		if vim.api.nvim_win_get_height(out) < height then
			vim.api.nvim_win_set_height(out, height)
		end
		return
	end
	local src_pos = vim.api.nvim_win_get_position(src)
	local out_pos = vim.api.nvim_win_get_position(out)
	local below_src = out_pos[2] == src_pos[2]
		and vim.api.nvim_win_get_width(out) == vim.api.nvim_win_get_width(src)
		and out_pos[1] == src_pos[1] + vim.api.nvim_win_get_height(src) + 1
	if below_src then
		return
	end
	vim.fn.win_splitmove(out, src, { rightbelow = true })
	vim.api.nvim_win_set_height(out, height)
end

return {
	"kristijanhusak/vim-dadbod-ui",
	dependencies = {
		{ "tpope/vim-dadbod", cmd = { "DB" }, lazy = true },
		-- Completion calls db#resolve(), so it must pull vim-dadbod in itself
		-- (SQL buffers opened without the DB tree, e.g. with b:db or $DATABASE_URL).
		{
			"kristijanhusak/vim-dadbod-completion",
			ft = { "sql", "mysql", "plsql" },
			dependencies = { "tpope/vim-dadbod" },
			lazy = true,
		},
	},
	cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
	keys = {
		{ "<leader>su", "<cmd>DBUIToggle<cr>", desc = "SQL: toggle DB UI" },
		{ "<leader>sf", "<cmd>DBUIFindBuffer<cr>", desc = "SQL: find buffer in DB UI" },
		{ "<leader>sa", "<cmd>DBUIAddConnection<cr>", desc = "SQL: add connection" },
	},
	config = function()
		-- dadbod-ui adds `stopinsert` on every enter of a results/tree window. A
		-- finished query enters the results window for a moment to reload it, so
		-- that kicked you out of insert mode in the query editor mid-typing.
		-- setup_db_keys() adds a version that ignores those passing visits.
		vim.api.nvim_clear_autocmds({ group = "dbui", event = "FileType" })
	end,
	init = function()
		vim.g.dbs = pg_services()
		vim.g.db_ui_use_nerd_fonts = 1
		vim.g.db_ui_show_database_icon = 1
		vim.g.db_ui_win_position = "left"
		vim.g.db_ui_winwidth = 35
		-- Saved queries live in this repo (config/db_ui), so they sync across
		-- machines. Connections added with `A` go to connections.json there,
		-- which is gitignored (it stores plain URLs, passwords included).
		vim.g.db_ui_save_location = vim.fn.expand("~/work/config/config/db_ui")
		-- dadbod-ui's save (<leader>W) is silent on success (it only reports
		-- errors), so confirm writes into the save folder: a new saved query,
		-- or :w on an existing one. Files are <save folder>/<connection>/<name>.
		local save_group = vim.api.nvim_create_augroup("dbui_save_notify", { clear = true })
		local save_pattern = vim.g.db_ui_save_location .. "/*"
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = save_group,
			pattern = save_pattern,
			callback = function(ev)
				vim.b[ev.buf].dbui_save_existed = vim.uv.fs_stat(ev.match) ~= nil
			end,
		})
		vim.api.nvim_create_autocmd("BufWritePost", {
			group = save_group,
			pattern = save_pattern,
			callback = function(ev)
				if vim.b[ev.buf].dbui_autosaving then
					return
				end
				local name = ev.match:sub(#vim.g.db_ui_save_location + 2)
				local verb = vim.b[ev.buf].dbui_save_existed and "updated" or "saved"
				vim.schedule(function()
					vim.notify(("Query %s: %s"):format(verb, name), vim.log.levels.INFO, { title = "DB" })
				end)
			end,
		})
		-- Saved queries auto-save (new, unsaved queries live in /tmp and are not
		-- matched): after edits in normal mode, on leaving insert mode, the buffer
		-- or nvim. `update` writes only when modified; no notification for these.
		vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged", "BufLeave", "FocusLost" }, {
			group = save_group,
			pattern = save_pattern,
			callback = function(ev)
				if not vim.bo[ev.buf].modified or vim.bo[ev.buf].buftype ~= "" then
					return
				end
				vim.b[ev.buf].dbui_autosaving = true
				local ok, err = pcall(vim.api.nvim_buf_call, ev.buf, function()
					vim.cmd("silent update")
				end)
				vim.b[ev.buf].dbui_autosaving = false
				if not ok then
					vim.notify("Auto-save failed: " .. tostring(err), vim.log.levels.WARN, { title = "DB" })
				end
			end,
		})
		-- Run with Ctrl+Enter instead of on every :w.
		vim.g.db_ui_execute_on_save = 0
		-- Ctrl+Enter runs the buffer (normal) or the selection (visual). Mapping the
		-- <Plug> globally makes dadbod-ui skip its default <leader>S. The <Plug> only
		-- exists in dadbod-ui query buffers, so the key is a no-op elsewhere.
		vim.keymap.set("n", "<C-CR>", "<Plug>(DBUI_ExecuteQuery)", { desc = "SQL: run query" })
		vim.keymap.set("x", "<C-CR>", "<Plug>(DBUI_ExecuteQuery)", { desc = "SQL: run selection" })
		vim.g.db_ui_auto_execute_table_helpers = 1

		-- Key help, only in DB buffers: <leader>? (and ? in the tree) opens a
		-- which-key popup listing just that buffer's keys.
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "sql", "mysql", "plsql", "dbui", "dbout" },
			callback = function(ev)
				if ev.match == "dbout" and vim.api.nvim_get_current_buf() == ev.buf then
					-- Runs in the results window (vim-dadbod opens it with :pedit).
					-- dadbod-ui folds each result set and opens the fold only once,
					-- before psql's rows arrive; a leading WARNING line left them
					-- under a closed "+-- 75 lines" fold. Start with folds open (zc/zM
					-- still close them).
					vim.opt_local.foldlevel = 99
					-- After :pedit returns, the query window is current again.
					vim.schedule(function()
						place_results(ev.buf)
					end)
				end
				-- After dadbod-ui's own ftplugin, so ? replaces its text help.
				vim.schedule(function()
					if vim.api.nvim_buf_is_valid(ev.buf) then
						setup_db_keys(ev.buf, ev.match)
					end
				end)
			end,
		})
	end,
}
