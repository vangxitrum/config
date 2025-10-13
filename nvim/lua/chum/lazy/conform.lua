return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
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
			golines = { prepend_args = { "--max-len=80" } },
			["golangci-lint"] = {
				append_args = {
					"--config",
					os.getenv("HOME") .. "/.golangci.yaml",
				},
			},
		},
		formatters_by_ft = {
			-- Go
			go = { "goimports", "gofumpt", "golines", "golangci-lint" },

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
			env = { "" },

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
			timeout_ms = 1000,
			lsp_format = "fallback",
		},
	},
	init = function()
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
}
