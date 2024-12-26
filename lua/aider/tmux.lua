local config = require("aider").config
local utils = require("aider.utils")
local aider = require("aider.aider")

local M = {}

-- Helper to shell-escape a string using Lua's built-in %q
local function shellescape(str)
	return string.format("%q", str)
end

function M.session_name()
	return "aider"
end

function M.spawn()
	if M.job_id then
		local running = vim.fn.jobwait({ M.job_id }, 0)[0] == -1
		if running then
			return
		end
	end

	local session_name = M.session_name()
	local aider_command = aider.command()

	-- Build the tmux new-session command, escaping its arguments
	local new_session_cmd =
		string.format("tmux new-session -A -c %s -s %s %s", utils.cwd(), session_name, shellescape(aider_command))

	local job_id = vim.fn.jobstart(new_session_cmd, {
		pty = true,
	})
	M.job_id = job_id
end

function M.is_open()
	return false
end

function M.is_running()
	vim.fn.system("tmux has-session -t aider")
	return vim.v.shell_error == 0
end

function M.toggle_window()
	M.spawn()
	local attach_session_cmd = string.format("tmux attach-session -t %s", M.session_name())
	local popup_cmd = string.format(
		"tmux display-popup -E -w 90%% -h 90%% %s",
		shellescape("tmux bind-key -n C-x detach-client; " .. attach_session_cmd)
	)
	vim.fn.system(popup_cmd)
end

---Load files into aider session
---@param files table|nil Files or path
function M.load_files(files)
	files = files or {}
	if #files > 0 then
		local add_paths = "/add " .. table.concat(files, " ")
		M.send_command(add_paths)
	end
end

--- Send a command to the active Aider terminal session
--- If no terminal is currently open, it will first create a new terminal
--- @param command string The command to send to the Aider session
function M.send_command(command)
	M.spawn()
	local multi_line_command = string.format("{EOF\n%s\nEOF}\n", command)
	vim.fn.chansend(M.job_id, multi_line_command)
	M.toggle_window()
end

--- Send an AI query to the Aider session
--- @param prompt string The query or instruction to send
--- @param selection string? Optional selected text to include with the prompt
function M.ask(prompt, selection)
	if not prompt or #vim.trim(prompt) == 0 then
		vim.notify("No input provided", vim.log.levels.WARN)
		return
	end

	local command
	if selection then
		prompt = string.format("%s\n%s", prompt, selection)
	end

	command = "/ask " .. prompt
	M.send_command(command)
end

vim.api.nvim_create_autocmd("VimLeavePre", {
	pattern = "*",
	callback = function()
		vim.fn.system("tmux kill-session -t aider")
	end,
})

return M
