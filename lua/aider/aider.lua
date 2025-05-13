local config = require("aider").config

local M = {}

M.StashMsgPrefix = "Aider.nvim Changes"

function M.dark_mode()
	if type(config.dark_mode) == "function" then
		return config.dark_mode()
	elseif type(config.dark_mode) == "boolean" then
		return config.dark_mode
	end
	return false
end

function M.env()
	local env = {
		AIDER_EDITOR = config.editor_command,
		GIT_PAGER = config.git_pager,
	}
	return env
end

function M.command()
	local cmd = { "aider" }

	if config.aider_args then
		if type(config.aider_args) == "table" then
			for _, arg in ipairs(config.aider_args) do
				table.insert(cmd, arg)
			end
		else
			vim.notify("config.aider_args must be a table", vim.log.levels.ERROR)
		end
	end

	if not config.theme then
		if M.dark_mode() then
			table.insert(cmd, "--dark-mode")
		else
			table.insert(cmd, "--light-mode")
		end
	end

	if not config.theme.code_theme then
		table.insert(cmd, "--code-theme")
		if M.dark_mode() then
			table.insert(cmd, config.code_theme_dark)
		else
			table.insert(cmd, config.code_theme_light)
		end
	end

	local test_command = "/bin/sh -c "
		.. '"'
		.. 'nvim --server $NVIM --remote-send \\"<C-\\\\><C-n>:lua _G.AiderTestCmd()<CR>\\"'

	if config.test_command then
		test_command = test_command .. " && " .. config.test_command
	end
	test_command = test_command .. '"'

	table.insert(cmd, "--auto-test")
	table.insert(cmd, "--test-cmd")
	table.insert(cmd, "'" .. test_command .. "'")

	if config.test_command then
		test_command = test_command .. " && " .. config.test_command
	end
	test_command = test_command .. '"'

	if config.watch_files then
		table.insert(cmd, "--watch-files")
	end

	if config.theme then
		for key, value in pairs(config.theme) do
			table.insert(cmd, "--" .. key:gsub("_", "-"))
			table.insert(cmd, '"' .. value .. '"')
		end
	end

	return table.concat(cmd, " ")
end

_G.AiderTestCmd = function()
	-- vim.notify("File updated by AI!", vim.log.levels.INFO)
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_get_option_value("buftype", { buf = bufnr }) == "" then
			vim.api.nvim_buf_call(bufnr, function()
				vim.cmd("checktime")
			end)
		end
	end
	local stashed = false
	local commands = require("aider.commands")
	local stash_msg = commands.stash_msg
	if config.use_git_stash and stash_msg then
		commands.stash_msg = nil
		require("aider.git").stash(M.StashMsgPrefix .. " " .. stash_msg)
		stashed = true
	end

	if config.after_update_hook then
		config.after_update_hook()
	else
		if stashed then
			if require("aider.snacks_picker").aider_changes() then
				return
			end
			local ok, diffview = pcall(require, "diffview")
			if ok then
				diffview.open({ "stash@{0}..stash@{1}" })
				return
			end
		end
	end
end

return M
