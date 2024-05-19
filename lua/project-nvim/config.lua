local M = {}

---@class ProjectOptions
M.defaults = {
	-- Project directories
	projects = {
		"~/projects/*",
		"~/.config/*",
		"~/work/*",
	},
	-- Dashboard mode prevent session autoload on startup
	dashboard_mode = false,
}

---@type ProjectOptions
M.options = {}

M.setup = function(options)
	M.options = vim.tbl_deep_extend("force", M.defaults, options or {})

	vim.opt.autochdir = false -- implicitly unset autochdir

	local path = require("project-nvim.utils.path")
	local project = require("project-nvim.project")
	project.init()

	local start_session_here = false -- open or create session in current dir

	-- Don't load a session if nvim started with args, open just given files
	if vim.fn.argc() == 0 and not M.options.dashboard_mode then
		local cmd = require("project-nvim.utils.cmd")
		local is_man = cmd.check_open_cmd("+Man!")

		if path.dir_matches_project() and not is_man then
			-- nvim started in the project dir, open current dir session
			start_session_here = true
		end
	end

	local open_path = path.resolve("%:p")
	if open_path ~= nil and not M.options.dashboard_mode and path.dir_matches_project(open_path) then
		vim.api.nvim_set_current_dir(open_path)
		start_session_here = true
	end

	-- Register Telescope extension
	require("telescope").load_extension("project")

	if start_session_here then
		project.start_session_here()
	end
end

return M

-- 1. If nvim started with args, disable autoload. On project switch - close all buffers and load session
-- 2. If nvim started in project dir, open project's session. If session does not exist - create it
-- 3. Else open last session. If no sessions: not create and close all buffers prior to project switch.
