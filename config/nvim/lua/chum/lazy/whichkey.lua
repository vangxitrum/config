return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		delay = 500,
		spec = {
			{ "<leader>p", group = "Project/Find" },
			{ "<leader>c", group = "Code" },
			{ "<leader>d", group = "Document" },
			{ "<leader>w", group = "Workspace" },
			{ "<leader>r", group = "Rename" },
			{ "<leader>t", group = "Trouble" },
			{ "<leader>l", group = "Lint" },
			{ "<leader>v", group = "View" },
			{ "<leader>f", group = "File" },
		},
	},
}
