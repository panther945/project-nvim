local M = {}
local resession = require("resession")
local path = require("project-nvim.utils.path")

local function get_session_name(fullpath)
	local branch = vim.trim(vim.fn.system("git branch --show-current"))
	if vim.v.shell_error == 0 then
		return fullpath .. "-" .. branch
	else
		return fullpath
	end
end

M.setup_autocmds = function()
	vim.notify("setup")
	local augroup = vim.api.nvim_create_augroup("project-nvim", { clear = true })

	-- save session
	vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
		pattern = "*",
		group = augroup,
		callback = function()
			if path.dir_pretty ~= nil then
				local cwd = vim.fn.getcwd()
				resession.save(get_session_name(cwd), { dir = path.session_dir, notify = false })
			end
		end,
	})
end

-- M.switch_after_save_session = function(dir)
-- 	if path.dir_pretty ~= nil then
-- 		local cwd = vim.fn.getcwd()
-- 		resession.save(get_session_name(cwd), { dir = path.session_dir, notify = true, attach = false })
-- 	end
--
-- 	M.load_session(dir)
-- end

M.load_session = function(dir)
	if not dir then
		return
	end
	if path.cwd() ~= dir then
		path.dir_pretty = path.short_path(dir)
		vim.api.nvim_set_current_dir(dir)
	end

	M.start_session_here()
end
--
M.start_session_here = function()
	-- load session or create new one if not exists
	local cwd = path.cwd()
	if not cwd then
		return
	end
	local fullpath = vim.fn.expand(cwd)
	local session_name = get_session_name(fullpath)

	vim.cmd("silent! %bd") -- close all buffers from previous session
	resession.load(session_name, { dir = path.session_dir, silence_errors = true })
end

M.switch_project = function(dir)
	if path.dir_pretty ~= nil then
		local cwd = vim.fn.getcwd()
		resession.save(get_session_name(cwd), { dir = path.session_dir, notify = true, attach = false })
	end

	M.load_session(dir)
end

M.init = function()
	M.setup_autocmds()
end

return M
