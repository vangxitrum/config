return {
	"mbbill/undotree",

	config = function()
		vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
		vim.keymap.set("n", "U", vim.cmd.redo, { desc = "Redo" })
	end,
}
