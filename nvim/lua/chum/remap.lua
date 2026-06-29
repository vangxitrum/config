local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Diagnostic keymaps
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous [D]iagnostic message" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next [D]iagnostic message" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Change window
map("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
map("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
map("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
map("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })
map("n", "<leader>z", "<cmd>tab split<CR>", { desc = "[Z]oom current file in new tab (use :q to unzoom)" })

-- File operator
map("n", "<leader>pv", "<cmd>Oil<CR>", { desc = "Open file explorer" })
map("n", "-", "<cmd>Oil<CR>", { desc = "Open parent directory" })
map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "File Copy whole" })
map("n", "<leader>fp", function()
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	vim.notify(path, vim.log.levels.INFO)
end, { desc = "[F]ile [P]ath copy to clipboard" })
map(
	"n",
	"<leader>v",
	'<cmd>vsplit<CR><cmd>lua require("telescope.builtin").lsp_definitions()<CR>',
	{ desc = "[G]oto [D]efinition in new tab" }
)

-- LSP restart all buffers
map("n", "<leader>cr", function()
	for _, client in ipairs(vim.lsp.get_clients()) do
		client:stop()
	end
	vim.defer_fn(function()
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" then
				vim.api.nvim_exec_autocmds("BufReadPost", { buf = buf })
			end
		end
	end, 200)
end, { desc = "[C]ode LSP [R]estart" })

-- Reload current buffer from disk
map("n", "<leader>ce", "<cmd>edit<CR>", { desc = "[C]ode Buffer R[e]load" })

-- Comment
map("n", "<leader>/", function()
	require("Comment.api").toggle.linewise.current()
end, { desc = "Comment Toggle" })

map(
	"v",
	"<leader>/",
	"<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
	{ desc = "Comment Toggle" }
)
