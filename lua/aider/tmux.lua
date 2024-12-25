local config = require("aider").config
local utils = require("aider.utils")
local aider = require("aider.aider")

local Aider = {}

function Aider.dark_mode()
	if type(config.dark_mode) == "function" then
		return config.dark_mode()
	elseif type(config.dark_mode) == "boolean" then
		return config.dark_mode
	end
	return false
end

-- Helper to shell-escape a string using Lua's built-in %q
local function shellescape(str)
	return string.format("%q", str)
end

function Aider.session_name()
	return "aider"
end

function Aider.ensure_running()
	local session_name = Aider.session_name()
	local aider_command = aider.command()

	-- Build the tmux new-session command, escaping its arguments
	local new_session_cmd =
		string.format("tmux new-session -d -A -c %s -s %s %s", utils.cwd(), session_name, shellescape(aider_command))
	vim.fn.system(new_session_cmd)
end

function Aider.is_open()
	return false
end

function Aider.toggle_window()
	Aider.ensure_running()
	local attach_session_cmd = string.format("tmux attach-session -t %s", Aider.session_name())
	local popup_cmd = string.format(
		"tmux display-popup -E -w 90%% -h 90%% %s",
		shellescape("tmux bind-key -n C-x detach-client; " .. attach_session_cmd)
	)
	vim.fn.system(popup_cmd)
end

---Load files into aider session
---@param files table|nil Files or path
function Aider.load_files(files)
	files = files or {}
	if #files > 0 then
		local add_paths = "/add " .. table.concat(files, " ")
		Aider.send_command(add_paths)
	end
end

--- Send a command to the active Aider terminal session
--- If no terminal is currently open, it will first create a new terminal
--- @param command string The command to send to the Aider session
function Aider.send_command(command)
	Aider.toggle_window()
	local multi_line_command = string.format("{EOF\n%s\nEOF}", command)
	local lines = vim.split(multi_line_command, "\n") -- or however you split lines in Lua
	for _, line in ipairs(lines) do
		vim.fn.system("tmux send-keys -t aider " .. shellescape(line) .. " C-m")
	end
end

--- Send an AI query to the Aider session
--- @param prompt string The query or instruction to send
--- @param selection string? Optional selected text to include with the prompt
function Aider.ask(prompt, selection)
	if not prompt or #vim.trim(prompt) == 0 then
		vim.notify("No input provided", vim.log.levels.WARN)
		return
	end

	local command
	if selection then
		prompt = string.format("%s\n%s", prompt, selection)
	end

	command = "/ask " .. prompt
	Aider.send_command(command)
end

vim.api.nvim_create_autocmd("VimLeavePre", {
	pattern = "*",
	callback = function()
		vim.fn.system("tmux kill-session -t aider")
	end,
})

return Aider
