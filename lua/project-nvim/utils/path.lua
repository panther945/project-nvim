local uv = vim.loop
local M = {}

M.datapath = vim.fn.stdpath("data") -- directory
M.projectpath = M.datapath .. "/project" -- directory
M.historyfile = M.projectpath .. "/history" -- file
M.session_dir = "project-sessions"
M.homedir = nil
M.dir_pretty = nil -- directory of current project (respects user defined symlinks in config)

-- function M.init()
--   M.datapath = vim.fn.expand(require("project.config").options.datapath)
--   M.projectpath = M.datapath .. "/project" -- directory
--   M.historyfile = M.projectpath .. "/history" -- file
--   M.sessionspath = M.datapath .. "/project-sessions" --directory
--   M.homedir = vim.fn.expand("~")
-- end

M.dir_matches_project = function(dir)
	local dir_resolved = dir or M.resolve(M.cwd())
	-- Check if current working directory mathch project patterns
	local projects = M.get_all_projects()
	for _, path in ipairs(projects) do
		if M.resolve(path) == dir_resolved then
			M.dir_pretty = M.short_path(path) -- store path with user defined symlinks
			return true
		end
	end
	return false
end

M.get_all_projects = function()
	-- Get all existing projects from patterns
	local projects = {}
	local patterns = require("project-nvim.config").options.projects
	for _, pattern in ipairs(patterns) do
		local tbl = vim.fn.glob(pattern, true, true, true)
		for _, path in ipairs(tbl) do
			if vim.fn.isdirectory(path) == 1 then
				table.insert(projects, M.short_path(path))
			end
		end
	end
	return projects
end

M.short_path = function(path)
	-- Reduce file name to be relative to the home directory, if possible.
	path = M.resolve(path)
	return vim.fn.fnamemodify(path, ":~")
end

M.cwd = function()
	-- Get current working directory in short form
	return M.short_path(uv.cwd())
end

M.create_scaffolding = function(callback)
	-- Create directories
	if callback ~= nil then -- async
		uv.fs_mkdir(M.projectpath, 448, callback)
	else -- sync
		uv.fs_mkdir(M.projectpath, 448)
	end
end

M.resolve = function(filename)
	-- Replace symlink with real path
	filename = vim.fn.expand(filename)
	return vim.fn.resolve(filename)
end

M.delete_duplicates = function(tbl)
	-- Remove duplicates from table, preserving order
	local cache_dict = {}
	for _, v in ipairs(tbl) do
		if cache_dict[v] == nil then
			cache_dict[v] = 1
		else
			cache_dict[v] = cache_dict[v] + 1
		end
	end

	local res = {}
	for _, v in ipairs(tbl) do
		if cache_dict[v] == 1 then
			table.insert(res, v)
		else
			cache_dict[v] = cache_dict[v] - 1
		end
	end
	return res
end

M.fix_symlinks_for_history = function(dirs)
	-- Replace paths with paths from `projects` option
	local projects = M.get_all_projects()
	for i, dir in ipairs(dirs) do
		local dir_resolved = M.resolve(dir)
		for _, path in ipairs(projects) do
			if M.resolve(path) == dir_resolved then
				dirs[i] = path
				break
			end
		end
	end
	-- remove duplicates
	return M.delete_duplicates(dirs)
end

return M
