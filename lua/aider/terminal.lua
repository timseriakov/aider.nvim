local Terminal = require("toggleterm.terminal").Terminal
local config = require("aider").config
local CONSTANTS = {
	DEFAULT_TITLE = "Aider.nvim",
	NOTIFICATION_ID = "aider",
	YES_NO_PATTERN = "%(Y%)es/%(N%)o",
}

--- Clean line outputs for aider
---@param line string
---@return string
local function clean_output(line)
	-- Remove EOF delimiters
	line = line:gsub(".*{EOF.*", "")
	line = line:gsub(".*EOF}.*", "")
	-- Remove cursor style codes
	line = line:gsub("%[%d+ q", "")
	-- Handle RGB color codes and extended ANSI sequences
	line = line:gsub("\27%[38;2;%d+;%d+;%d+m", "") -- RGB foreground
	line = line:gsub("\27%[48;2;%d+;%d+;%d+m", "") -- RGB background
	line = line:gsub("\27%[%d+;%d+;%d+;%d+;%d+m", "") -- Multiple color parameters
	-- Enhanced RGB and extended color handling
	line = line:gsub("\27%[%d+;%d+;%d+;%d+;%d+;%d+;%d+;%d+m", "") -- Extended color with multiple parameters
	line = line:gsub("\27%[38;2;%d+;%d+;%d+;48;2;%d+;%d+;%d+m", "") -- RGB fore/background combined
	line = line:gsub("\27%[48;2;%d+;%d+;%d+;38;2;%d+;%d+;%d+m", "") -- RGB back/foreground combined
	-- New patterns to catch RGB codes without escape character
	line = line:gsub("38;2;%d+;%d+;%d+;48;2;%d+;%d+;%d+m", "") -- RGB fore/background without escape
	line = line:gsub("48;2;%d+;%d+;%d+;38;2;%d+;%d+;%d+m", "") -- RGB back/foreground without escape
	line = line:gsub("38;2;%d+;%d+;%d+m", "") -- Single RGB foreground without escape
	line = line:gsub("48;2;%d+;%d+;%d+m", "") -- Single RGB background without escape
	-- Catch any remaining color codes with semicolons
	line = line:gsub("%[([%d;]+)m", "")
	line = line:gsub("([%d;]+)m", "") -- New pattern to catch remaining codes without brackets
	-- Remove standard ANSI escape sequences
	line = line:gsub("\27%[%?%d+[hl]", "")
	line = line:gsub("\27%[[%d;]*[A-Za-z]", "")
	line = line:gsub("\27%[%d*[A-Za-z]", "")
	line = line:gsub("\27%(%[%d*;%d*[A-Za-z]", "")
	-- Remove line numbers and decorators that appear in your output
	line = line:gsub("^%s*%d+%s*│%s*", "") -- Remove line numbers and vertical bars
	line = line:gsub("^%s*▎?│%s*", "") -- Remove just vertical bars with optional decorators
	-- Remove control characters
	line = line:gsub("[\r\n]", "")
	line = line:gsub("[\b]", "")
	line = line:gsub("[\a]", "")
	line = line:gsub("[\t]", "    ")
	line = line:gsub("[%c]", "")
	-- Remove leading '>' character if it's alone on a line
	line = line:gsub("^%s*>%s*$", "")
	-- Remove or clean up file headers
	line = line:gsub("^%s*lua/[%w/_]+%.lua%s*$", "")
	-- Remove the (Nx) count indicators
	line = line:gsub("%(%d+x%)", "")
	-- Remove trailing "INFO" markers
	line = line:gsub("%s*INFO%s*$", "")
	-- Remove empty lines after cleaning
	if line:match("^%s*$") then
		return ""
	end
	return line
end

---@return string
local cwd = function()
	return vim.fn.getcwd(-1, -1)
end

local function truncate_message(msg, max_length)
	if #msg > max_length then
		return msg:sub(1, max_length - 3) .. "..."
	end
	return msg
end

-- Store last 5 messages in a circular buffer
local MessageBuffer = {
	messages = {},
	capacity = 50,
	current = 0,
}

function MessageBuffer:add(msg)
	self.current = (self.current % self.capacity) + 1
	self.messages[self.current] = msg
end

function MessageBuffer:contains(msg)
	for _, stored_msg in pairs(self.messages) do
		if stored_msg == msg then
			return true
		end
	end
	return false
end

local Aider = {
	__term = {},
}

--- Write data to a temporary markdown file
---@param data table
function Aider.write_to_file(data)
	if Aider.__chat_file == nil then
		Aider.__chat_file = vim.fn.tempname() .. ".md"
		vim.notify(Aider.__chat_file, vim.log.levels.Error)
	end

	local chat_file = Aider.__chat_file
	for _, row in ipairs(data) do
		-- cervert row into blob ai!
		vim.fn.writefile(row, chat_file)
	end
end

---@return boolean
function Aider.is_running()
	return Aider.__term[cwd()] ~= nil
end

function Aider.clear()
	Aider.__term[cwd()] = nil
end

--- Get or generate a terminal object for Aider
---@return Terminal
function Aider.terminal()
	local cwd = cwd()
	if Aider.__term[cwd] then
		return Aider.__term[cwd]
	end
	local message_buffer = MessageBuffer
	local term = Terminal:new({
		cmd = Aider.command(),
		hidden = true,
		float_opts = config.float_opts,
		display_name = CONSTANTS.DEFAULT_TITLE,
		close_on_exit = true,
		auto_scroll = config.auto_scroll,
		direction = config.toggleterm.direction,
		size = config.toggleterm.size,
		on_exit = function()
			Aider.__term[cwd] = nil
		end,
		on_open = function(term)
			if config.auto_insert then
				term:set_mode("i")
			end
		end,
		on_stdout = function(term, _, data, _)
			for _, line in ipairs(data) do
				if term:is_open() then
					return
				end

				if line:match(CONSTANTS.YES_NO_PATTERN) then
					term:open()
					return
				end

				if config.write_to_buffer then
					Aider.write_to_file(data)
				end
				local msg = clean_output(line)
				if #msg > 0 then
					-- Check if message is duplicate before processing
					msg = truncate_message(msg, 60)
					if not message_buffer:contains(msg) then
						message_buffer:add(msg)
						config.notify(msg, vim.log.levels.INFO, {
							title = CONSTANTS.DEFAULT_TITLE,
							id = CONSTANTS.NOTIFICATION_ID,
							replace = CONSTANTS.NOTIFICATION_ID,
						})
					end
				end
			end
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
	local term = Aider.terminal()

	if #files > 0 then
		local add_paths = "/add " .. table.concat(files, " ")
		term:send(add_paths)
	end

	if not config.watch_files then
		term:open(config.toggleterm.size(term), config.toggleterm.direction)
	end
end

function Aider.command()
	local env_args = vim.env.AIDER_ARGS or ""
	local dark_mode = config.dark_mode and " --dark-mode" or ""

	---@diagnostic disable-next-line: undefined-global
	local hook_command = "/bin/sh -c "
		.. '"'
		.. 'nvim --server $NVIM --remote-send \\"<C-\\\\><C-n>:lua _G.AiderUpdateHook()<CR>\\"'
		.. '"'

	local command = string.format(
		"aider %s %s %s %s ",
		env_args,
		config.aider_args,
		dark_mode,
		"--auto-test --test-cmd " .. "'" .. hook_command .. "'"
	)
	if config.watch_files then
		command = command .. "--watch-files "
	end
	return command
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

function Aider.spawn()
	local term = Aider.terminal()
	term:open()
	term:close()
	vim.notify("Running Aider in background")
end

---@param size? number
---@param direction? string
function Aider.toggle_window(size, direction)
	local term = Aider.terminal()
	if size then
		config.toggleterm.size = function()
			return size(term)
		end
	end
	if direction then
		config.toggleterm.direction = direction
	end

	if term:is_open() then
		if direction and direction ~= term.direction then
			term:close()
		end
	end

	term:toggle(config.toggleterm.size(term), config.toggleterm.direction)
end

--- Send a command to the active Aider terminal session
--- If no terminal is currently open, it will first create a new terminal
---
--- @param command string The command to send to the Aider session
function Aider.send_command(command)
	local term = Aider.terminal()
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

	local term = Aider.terminal()
	if not term:is_open() then
		term:open()
	end
end

return Aider
