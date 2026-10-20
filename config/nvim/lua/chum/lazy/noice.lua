return {
	"folke/noice.nvim",
	event = "VeryLazy",
	enabled = true,
	opts = {},
	dependencies = {
		"MunifTanjim/nui.nvim",
		-- "rcarriga/nvim-notify",
	},
	config = function()
		require("noice").setup({
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
				hover = {
					silent = true,
				},
			},
			presets = {
				bottom_search = true, -- use a classic bottom cmdline for search
				command_palette = true, -- position the cmdline and popupmenu together
				long_message_to_split = true, -- long messages will be sent to a split
				inc_rename = false, -- enables an input dialog for inc-rename.nvim
				lsp_doc_border = true, -- add a border to hover docs and signature help
			},
		})

		vim.keymap.set("n", "<C-n>", function()
			local manager = require("noice.message.manager")
			local messages = manager.get({ event = "notify" }, { sort = true })
			if #messages > 0 then
				manager.remove(messages[#messages])
			end
		end, { desc = "Dismiss one notification" })
	end,
}
