vim.lsp.enable({
	"gopls",
	"lua_ls",
	-- "ts_ls",
	-- "pylsp",
	-- "cssls",
	-- "html",
	-- "eslint",
	-- "tailwindcss",
})

vim.diagnostic.config({
	virtual_lines = false,
	virtual_text = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = {
		border = "rounded",
		source = true,
	},
})
