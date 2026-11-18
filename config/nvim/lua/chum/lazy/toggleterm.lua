return {
	"akinsho/toggleterm.nvim",
	version = "*",

	config = function()
		local toggleterm = require("toggleterm")

		toggleterm.setup({
			size = 20,
			open_mapping = [[<A-i>]],
			hide_numbers = true,
			shade_filetypes = {},
			shading_factor = 2,
			start_in_insert = true,
			insert_mappings = true,
			persist_size = true,
			direction = "float",
			close_on_exit = true,
			shell = vim.o.shell,
			-- Keep TMUX set here: tmuxinator and other tmux-aware tools need it to
			-- switch-client instead of nesting an attach. Claude Code's OSC 52 issue
			-- in nvim terminals is handled by the claude() wrapper in ~/.zshrc.
			float_opts = {
				border = "curved",
				winblend = 0,
				highlights = {
					border = "Normal",
					background = "Normal",
				},
			},
		})
	end,
}
