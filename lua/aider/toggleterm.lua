local Terminal = require("toggleterm.terminal").Terminal
local config = require("aider").config
local utils = require("aider.utils")
local notify = require("aider.notify")
local aider = require("aider.aider")

local M = {
	__term = {},
}

---@return boolean
function M.is_running()
	return M.__term[utils.cwd()] ~= nil
end

function M.clear()
	local term = M.__term[utils.cwd()]
	if term then
		term:close()
	end
	M.__term[utils.cwd()] = nil
end

function M.clear_all()
	for _, term in pairs(M.__term) do
		if term then
			term:close()
		end
	end
	M.__term = {}
end

function M.is_open()
	local term = M.terminal()
	return term:is_open()
end

--- Get or generate a terminal object for Aider
---@return Terminal
function M.terminal()
	local cwd = utils.cwd()
	if M.__term[cwd] then
		local term = M.__term[cwd]
		return term
	end
	local term = Terminal:new({
		-- requires delay so aider can detect size correctly
		cmd = "sleep 0.3; " .. aider.command(),
		env = {
			AIDER_EDITOR = config.editor_command,
			GIT_PAGER = config.git_pager,
		},
		display_name = "Aider.nvim",
		close_on_exit = true,
		auto_scroll = config.auto_scroll,
		direction = config.win.direction,
		size = config.win.size,
		float_opts = config.win.float_opts,
		on_open = function(term)
			term:scroll_bottom()
			if config.auto_insert then
				term:set_mode("i")
			end
		end,
		on_exit = function()
			M.__term[cwd] = nil
		end,
	})
	term.on_stdout = function(_, _, data, _)
		notify.on_stdout(M, data)
	end
	term:spawn()
	M.__term[cwd] = term
	return term
end

---Load files into aider session
---@param files table|nil Files or path
function M.load_files(files)
	files = files or {}
	if #files > 0 then
		local add_paths = "/add " .. table.concat(files, " ")
		M.send_command(add_paths)
	end
	if config.auto_show.on_file_add then
		M.open()
	end
end

function M.open()
	local term = M.terminal()
	if not term:is_open() then
		M.toggle_window(nil, nil)
	end
end

function M.spawn()
	M.terminal()
end

---@param size? number
---@param direction? string
function M.toggle_window(size, direction)
	local term = M.terminal()
	if size then
		config.win.size = function()
			return size(term)
		end
	end
	if direction then
		config.win.direction = direction
	end

	if term:is_open() then
		if direction and direction ~= term.direction then
			term:close()
		end
	end

	term:toggle(config.win.size(term), config.win.direction)
end

--- Send a command to the active Aider terminal session
--- If no terminal is currently open, it will first create a new terminal
--- @param command string The command to send to the Aider session
function M.send_command(command)
	local term = M.terminal()
	local multi_line_command = string.format("{EOF\n%s\nEOF}", command)
	term:send(multi_line_command)
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
	M.open()
end

return M
