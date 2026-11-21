return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		-- Configure custom linters using Mason-managed tools
		local mason_bin_dir = vim.fn.stdpath("data") .. "/mason/bin"

		-- Customize golangcilint to ignore exit codes (golangci-lint exits with code 1-3 when issues are found)
		local golangcilint = require("lint").linters.golangcilint
		golangcilint.ignore_exitcode = true
		golangcilint.args = {
			"--config",
			os.getenv("HOME") .. "/.golangci.yaml",
		}

		-- Configure linters by filetype (using Mason-managed tools)
		lint.linters_by_ft = {
			-- Go
			go = { "golangcilint" },

			-- JavaScript/TypeScript
			javascript = { "eslint_d" },
			typescript = { "eslint_d" },
			javascriptreact = { "eslint_d" },
			typescriptreact = { "eslint_d" },

			-- Lua
			lua = { "luacheck" },

			-- Shell
			-- sh = { "shellcheck" },
			-- bash = { "shellcheck" },
			-- zsh = { "shellcheck" },

			-- You can add more linters here as needed
			-- python = { "flake8", "mypy" },
			-- rust = { "clippy" },
		}

		-- Linters that run code from the project (eslint.config.js, .luacheckrc)
		-- only run in trusted projects on the host (chum/trust.lua).
		local runs_project_code = { eslint_d = true, luacheck = true }
		local function run_linters()
			local names = vim.tbl_filter(function(name)
				return not runs_project_code[name] or require("chum.trust").allowed(0)
			end, lint.linters_by_ft[vim.bo.filetype] or {})
			if #names > 0 then
				lint.try_lint(names)
			end
		end

		-- Auto-lint on save and text changes
		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = run_linters,
		})

		-- Manual linting command
		vim.keymap.set("n", "<leader>ll", function()
			run_linters()
			vim.notify("Linting...", vim.log.levels.INFO, { title = "nvim-lint" })
		end, { desc = "Trigger linting for current file" })

		-- Show linter status
		vim.keymap.set("n", "<leader>li", function()
			local linters = lint.linters_by_ft[vim.bo.filetype] or {}
			if #linters == 0 then
				print("No linters configured for filetype: " .. vim.bo.filetype)
			else
				print("Linters for " .. vim.bo.filetype .. ": " .. table.concat(linters, ", "))

				-- Show which tools are being used
				if vim.bo.filetype == "php" then
					if string.find(pint_cmd, "mason") then
						print("Using Mason pint: " .. pint_cmd)
					else
						print("Using system pint: " .. pint_cmd)
					end
				end
			end
		end, { desc = "Show available linters for current filetype" })
	end,
}
