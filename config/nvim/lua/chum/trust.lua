-- Project trust for tools that run code from the project they work on:
-- eslint_d (eslint.config.js), prettierd (prettier configs and plugins) and
-- luacheck (.luacheckrc is a Lua script). On the host they only run in
-- projects trusted with :ProjectTrust, because the coding container can write
-- ~/work: opening or saving a file there must not run what it planted.
-- Inside the coding container (IS_SANDBOX=1) they always run.
--
--   :ProjectTrust [dir]     trust the current project (git root) or dir
--   :ProjectUntrust [dir]
--   :ProjectTrustList
--
-- The list is $XDG_STATE_HOME/nvim/trusted-projects (not mounted in the container).
local M = {}

local db = vim.fn.stdpath("state") .. "/trusted-projects"
local warned = {}

local function realpath(path)
	return vim.uv.fs_realpath(path) or path
end

-- Git root of the buffer's file (or of the cwd for unnamed buffers).
local function root(buf)
	local name = vim.api.nvim_buf_get_name(buf or 0)
	local start = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
	return realpath(vim.fs.root(start, { ".git" }) or start)
end

local function read()
	local ok, lines = pcall(vim.fn.readfile, db)
	return ok and lines or {}
end

local function write(lines)
	vim.fn.mkdir(vim.fs.dirname(db), "p")
	vim.fn.writefile(lines, db)
end

-- May project-code tools run for this buffer?
function M.allowed(buf)
	if vim.env.IS_SANDBOX == "1" then
		return true
	end
	local r = root(buf)
	for _, t in ipairs(read()) do
		if r == t or vim.startswith(r, t .. "/") then
			return true
		end
	end
	if not warned[r] then
		warned[r] = true
		vim.notify(
			("Untrusted project %s: eslint/prettier/luacheck are off (they run its code). :ProjectTrust to enable."):format(r),
			vim.log.levels.WARN
		)
	end
	return false
end

local function target(args)
	return args ~= "" and realpath(vim.fn.fnamemodify(args, ":p"):gsub("/$", "")) or root(0)
end

vim.api.nvim_create_user_command("ProjectTrust", function(o)
	local r = target(o.args)
	local lines = read()
	if not vim.tbl_contains(lines, r) then
		table.insert(lines, r)
		write(lines)
	end
	warned[r] = nil
	vim.notify("Trusted " .. r)
end, { nargs = "?", complete = "dir", desc = "Let eslint/prettier/luacheck run in this project" })

vim.api.nvim_create_user_command("ProjectUntrust", function(o)
	local r = target(o.args)
	write(vim.tbl_filter(function(t)
		return t ~= r
	end, read()))
	vim.notify("Untrusted " .. r)
end, { nargs = "?", complete = "dir", desc = "Stop eslint/prettier/luacheck in this project" })

vim.api.nvim_create_user_command("ProjectTrustList", function()
	local lines = read()
	print(#lines > 0 and table.concat(lines, "\n") or "No trusted projects")
end, { desc = "List trusted projects" })

return M
