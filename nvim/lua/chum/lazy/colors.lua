return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("catppuccin-mocha")
		end,
	},
	{
		"mcauley-penney/techbase.nvim",
		config = function(_, opts)
			vim.cmd.colorscheme("techbase")
		end,
		priority = 1000,
	},
}
