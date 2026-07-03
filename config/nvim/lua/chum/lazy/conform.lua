return {
	"stevearc/conform.nvim",

	event = { "BufWritePre" },
	version = "v9.1.0",
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>cf",
			function()
				require("conform").format({ async = true }, function(err, did_edit)
					if not err and did_edit then
						vim.notify("Code formatted", vim.log.levels.INFO, { title = "Conform" })
					end
				end)
			end,
			mode = { "n", "v" },
			desc = "Format buffer",
		},
	},
	opts = {
		formatters = {
			golines = { prepend_args = { "--max-len=80", "--base-formatter=gofumpt" } },
			-- ["golangci-lint"] = {
			-- 	append_args = {
			-- 		"--config",
			-- 		os.getenv("HOME") .. "/.golangci.yaml",
			-- 	},
			-- },
		},
		formatters_by_ft = {
			-- Go
			go = {
				"goimports",
				"golines",
				-- "golangci-lint",
			},

			-- Lua
			lua = { "stylua" },

			-- Web technologies
			javascript = { "prettierd" },
			typescript = { "prettierd" },
			javascriptreact = { "prettierd" },
			typescriptreact = { "prettierd" },
			json = { "prettierd" },
			jsonc = { "prettierd" },
			yaml = { "prettierd" },
			markdown = { "prettierd" },
			html = { "prettierd" },
			css = { "prettierd" },
			scss = { "prettierd" },

			-- Python
			python = { "isort", "black" },

			-- Shell
			sh = { "shfmt" },
			bash = { "shfmt" },

			-- Additional file types (uncomment as needed)
			toml = { "taplo" },
		},
		default_format_opts = {
			lsp_format = "fallback",
		},
		format_on_save = {
			timeout_ms = 3000,
			lsp_format = "fallback",
		},
	},
	init = function()
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
}
