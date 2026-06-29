return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	branch = "main",
	config = function()
		-- Define your custom installation directory
		-- (Example: stores inside ~/.local/share/nvim/custom_parsers)
		local custom_dir = vim.fn.stdpath("data") .. "/custom_parsers"
		vim.opt.rtp:prepend(custom_dir)

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
				"markdown",
				"markdown_inline",
			},
			install_dir = custom_dir,
		})

		-- main branch removed the `highlight`/`indent` setup keys; start
		-- treesitter per-buffer via FileType, otherwise normal buffers fall
		-- back to vim regex syntax while telescope's previewer (which calls
		-- vim.treesitter.start itself) ends up more colorful than the editor.
		local extra_regex = { markdown = true }
		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("chum_treesitter_start", { clear = true }),
			callback = function(args)
				local ft = vim.bo[args.buf].filetype
				local lang = vim.treesitter.language.get_lang(ft) or ft
				if not lang or lang == "" then
					return
				end
				local ok, has_parser = pcall(vim.treesitter.language.add, lang)
				if not ok or not has_parser then
					return
				end
				pcall(vim.treesitter.start, args.buf, lang)
				if extra_regex[ft] then
					vim.bo[args.buf].syntax = "ON"
				end
			end,
		})
	end,
}
