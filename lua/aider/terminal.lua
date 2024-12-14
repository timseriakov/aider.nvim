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

	-- Remove cursor style codes (like [6 q)
	line = line:gsub("%[%d+ q", "")

	-- Remove ANSI escape sequences
	line = line:gsub("\27%[%d*;?%d*[A-Za-z]", "")
	line = line:gsub("\27%[%?%d+[hl]", "")
	line = line:gsub("\27%[[%d;]*[A-Za-z]", "")
	line = line:gsub("\27%[%d*[A-Za-z]", "")
	line = line:gsub("\27%(%[%d*;%d*[A-Za-z]", "")

	-- Remove other control characters
	line = line:gsub("[\r\n]", "")
	line = line:gsub("[\b]", "")
	line = line:gsub("[\a]", "")
	line = line:gsub("[\t]", "    ")
	line = line:gsub("[%c]", "")

	-- Remove leading '>' character if it's alone on a line
	line = line:gsub("^%s*>%s*$", "")

	-- Remove or clean up file headers that are alone on a line
	line = line:gsub("^%s*lua/[%w/_]+%.lua%s*$", "")

	-- Remove empty lines after cleaning
	if line:match("^%s*$") then
		return ""
	end

	return line
end

local Aider = {
	__term = nil,
}

--- Get or generate a terminal object for Aider
---@return Terminal
function Aider.terminal()
	if Aider.__term then
		return Aider.__term
	end
	Aider.__term = Terminal:new({
		cmd = Aider.command(),
		hidden = true,
		float_opts = config.float_opts,
		display_name = CONSTANTS.DEFAULT_TITLE,
		close_on_exit = true,
		auto_scroll = true,
		direction = config.toggleterm.direction,
		size = config.toggleterm.size,
		on_exit = function()
			Aider.__term = nil
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

				local msg = clean_output(line)
				if #msg > 0 then
					config.notify(msg, vim.log.levels.INFO, {
						title = CONSTANTS.DEFAULT_TITLE,
						id = CONSTANTS.NOTIFICATION_ID,
						replace = CONSTANTS.NOTIFICATION_ID,
					})
				end
			end
		end,
	})

	return Aider.__term
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
		"aider --no-pretty %s %s %s %s ",
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
	if not config.focus_on_spawn then
		term:close()
		vim.notify("Running Aider in background")
	end
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
