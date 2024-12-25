local Terminal = require("toggleterm.terminal").Terminal
local config = require("aider").config
local utils = require("aider.utils")
local notify = require("aider.notify")
local aider = require("aider.aider")

-- this that
local Aider = {
	__term = {},
}

---@return boolean
function Aider.is_running()
	return Aider.__term[utils.cwd()] ~= nil
end

function Aider.clear()
	local term = Aider.__term[utils.cwd()]
	if term then
		term:close()
	end
	Aider.__term[utils.cwd()] = nil
end

function Aider.clear_all()
	for _, term in pairs(Aider.__term) do
		if term then
			term:close()
		end
	end
	Aider.__term = {}
end

function Aider.is_open()
	local term = Aider.ensure_running()
	return term:is_open()
end

--- Get or generate a terminal object for Aider
---@return Terminal
function Aider.ensure_running()
	local cwd = utils.cwd()
	if Aider.__term[cwd] then
		return Aider.__term[cwd]
	end
	local term = Terminal:new({
		cmd = aider.command(),
		env = {
			AIDER_EDITOR = config.editor_command,
			GIT_PAGER = config.git_pager,
		},
		hidden = true,
		display_name = "Aider.nvim",
		close_on_exit = true,
		auto_scroll = config.auto_scroll,
		direction = config.win.direction,
		size = config.win.size,
		float_opts = config.win.float_opts,
		on_exit = function()
			Aider.__term[cwd] = nil
		end,
		on_stdout = function(term, _, data, _)
			notify.on_stdout(term, data)
		end,
	})
	term:spawn()
	Aider.__term[cwd] = term
	return term
end

---Load files into aider session
---@param files table|nil Files or path
function Aider.load_files(files)
	files = files or {}
	local term = Aider.ensure_running()

	if #files > 0 then
		local add_paths = "/add " .. table.concat(files, " ")
		term:send(add_paths)
	end

	if not config.watch_files then
		term:open(config.win.size(term), config.win.direction)
	end
end

function Aider.dark_mode()
	if type(config.dark_mode) == "function" then
		return config.dark_mode()
	elseif type(config.dark_mode) == "boolean" then
		return config.dark_mode
	end
	return false
end

function Aider.spawn()
	local term = Aider.ensure_running()
	term:open()
	term:close()
end

---@param size? number
---@param direction? string
function Aider.toggle_window(size, direction)
	local term = Aider.ensure_running()
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
function Aider.send_command(command)
	local term = Aider.ensure_running()
	local multi_line_command = string.format("{EOF\n%s\nEOF}", command)
	term:send(multi_line_command)
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

	local term = Aider.ensure_running()
	if not term:is_open() then
		Aider.toggle_window(nil, nil)
	end
end

return Aider
