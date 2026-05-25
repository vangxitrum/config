return {
	"tomasky/bookmarks.nvim",
	event = "VimEnter",
	config = function()
		require("bookmarks").setup({
			save_file = vim.fn.stdpath("data") .. "/bookmarks",
			on_attach = function()
				local bm = require("bookmarks")
				vim.keymap.set("n", "<leader>m", bm.bookmark_ann, { desc = "Toggle bookmark with message" })
				vim.keymap.set("n", "<C-b>", bm.bookmark_list, { desc = "Bookmark list" })
				vim.keymap.set("n", "<leader>mc", bm.bookmark_clean, { desc = "Clean bookmarks in current buffer" })
				vim.keymap.set("n", "]b", bm.bookmark_next, { desc = "Next bookmark" })
				vim.keymap.set("n", "[b", bm.bookmark_prev, { desc = "Previous bookmark" })
			end,
		})
	end,
}
