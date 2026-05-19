return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	branch = "main",
	config = function()
		-- Define your custom installation directory
		-- (Example: stores inside ~/.local/share/nvim/custom_parsers)
		local custom_dir = vim.fn.stdpath("data") .. "/custom_parsers"

		require("nvim-treesitter.config").setup({
			-- A list of parser names, or "all"
			ensure_installed = {
				"vimdoc",
				"javascript",
				"typescript",
				"c",
				"lua",
				"rust",
				"jsdoc",
				"bash",
				"go",
			},
			install_dir = custom_dir,

			-- Install parsers synchronously (only applied to `ensure_installed`)
			sync_install = false,

			-- Automatically install missing parsers when entering buffer
			-- Recommendation: set to false if you don"t have `tree-sitter` CLI installed locally
			auto_install = true,

			indent = {
				enable = true,
			},

			highlight = {
				-- `false` will disable the whole extension
				enable = true,

				-- Setting this to true will run `:h syntax` and tree-sitter at the same time.
				-- Set this to `true` if you depend on "syntax" being enabled (like for indentation).
				-- Using this option may slow down your editor, and you may see some duplicate highlights.
				-- Instead of true it can also be a list of languages
				additional_vim_regex_highlighting = { "markdown" },
			},
		})
	end,
}
