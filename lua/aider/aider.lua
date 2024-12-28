local config = require("aider").config

local M = {}

function M.dark_mode()
	if type(config.dark_mode) == "function" then
		return config.dark_mode()
	elseif type(config.dark_mode) == "boolean" then
		return config.dark_mode
	end
	return false
end

function M.command()
	local cmd = { "aider" }

	if config.aider_args then
		for _, arg in ipairs(config.aider_args) do
			table.insert(cmd, arg)
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

	local hook_command = "/bin/sh -c "
		.. '"'
		.. 'nvim --server $NVIM --remote-send \\"<C-\\\\><C-n>:lua _G.AiderUpdateHook()<CR>\\"'
		.. '"'

	table.insert(cmd, "--auto-test")
	table.insert(cmd, "--test-cmd")
	table.insert(cmd, "'" .. hook_command .. "'")

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

_G.AiderUpdateHook = function()
	vim.notify("File updated by AI!", vim.log.levels.INFO)
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_get_option_value("buftype", { buf = bufnr }) == "" then
			vim.api.nvim_buf_call(bufnr, function()
				vim.cmd("checktime")
			end)
		end
	end
	if config.after_update_hook then
		config.after_update_hook()
	end
end

return M
