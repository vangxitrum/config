return {
	"beauwilliams/statusline.lua",
	dependencies = {
		"nvim-lua/lsp-status.nvim",
	},
	config = function()
		require("statusline").setup({
			match_colorscheme = false, -- Enable colorscheme inheritance (Default: false)
			tabline = true, -- Enable the tabline (Default: true)
			lsp_diagnostics = true, -- Enable Native LSP diagnostics (Default: true)
			ale_diagnostics = false, -- Enable ALE diagnostics (Default: false)
		})
		local bufname = require("sections._bufname")
		bufname.get_buffer_name = function()
			local path = vim.fn.expand("%:~:.")
			local modified = vim.bo.modified and " ●" or ""
			if path == "" then
				local ft = vim.bo.ft
				return ft ~= "" and ft .. modified .. " " or ""
			end
			if path:find("NvimTree") then
				return "File Tree "
			end
			return path .. modified .. " "
		end
	end,
}
