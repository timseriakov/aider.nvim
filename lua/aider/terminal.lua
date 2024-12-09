local Terminal = require("toggleterm.terminal").Terminal
local config = require("aider")

local M = {
	term = nil,
}

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

--- Create a persistent terminal for Aider interactions
---
--- This function sets up a terminal using toggleterm with custom output handling
--- and notification management. It cleans terminal output, manages a buffer of
--- output lines, and provides persistent notifications.
---
--- @param cmd string The command to run in the terminal
--- @return table A new Terminal instance configured for Aider interactions
function M.create_aider_terminal(cmd)
	local terminal = Terminal:new({
		cmd = cmd,
		hidden = true,
		float_opts = config.values.float_opts,
		display_name = "Aider.nvim",
		close_on_exit = true,
		auto_scroll = true,
		direction = config.values.toggleterm.direction,
		size = config.values.toggleterm.size,
		start_in_insert = true,
		on_exit = function()
			M.term = nil
		end,
	})

	terminal.on_stdout = function(term, _, data, _)
		for _, line in ipairs(data) do
			if terminal:is_open() then
				return
			end

			if line:match("%(Y%)es/%(N%)o") then
				vim.ui.input({ prompt = clean_output(line) }, function(input)
					if input and #input > 0 then
						terminal:send(input)
					end
				end)
				-- terminal:open()
				return
			end

			local msg = clean_output(line)
			if #msg > 0 then
				local id = "aider"
				config.values.notify(msg, vim.log.levels.INFO, {
					title = "Aider.nvim",
					id = id,
					replace = id,
				})
			end
		end
	end

	return terminal
end

---Load files into aider session
---@param files table|nil Files or path
function M.load_aider(files)
	files = files or {}
	local path_args = table.concat(files, " ")

	if not M.term then
		local command = M.aider_command(path_args)
		vim.notify("Running: " .. command)
		M.term = M.create_aider_terminal(command)
		if not config.values.watch_files then
			M.term:open(M.size, M.direction)
		end
		return
	end

	if #files > 0 then
		local add_paths = "/add " .. path_args
		M.term:send(add_paths)
		return
	end
end

function M.aider_command(paths)
	local env_args = vim.env.AIDER_ARGS or ""
	local dark_mode = vim.o.background == "dark" and " --dark-mode" or ""

	---@diagnostic disable-next-line: undefined-global
	local hook_command = "/bin/sh -c "
		.. '"'
		.. 'nvim --server $NVIM --remote-send \\"<C-\\\\><C-n>:lua _G.AiderUpdateHook()<CR>\\"'
		.. '"'

	local command = string.format(
		"aider --no-pretty %s %s %s %s ",
		env_args,
		config.values.aider_args,
		dark_mode,
		"--auto-test --test-cmd " .. "'" .. hook_command .. "'"
	)
	if config.values.watch_files then
		command = command .. "--watch-files "
	end
	if paths then
		command = command .. paths
	end
	return command
end

--- Reload all open buffers after an AI update
--- This function is called after an AI-driven file modification to:
--- 1. Notify the user of the update
--- 2. Trigger a reload of all open buffers to reflect the changes
_G.AiderUpdateHook = function()
	vim.notify("File updated by AI!", vim.log.levels.INFO)
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_get_option_value("buftype", { buf = bufnr }) == "" then
			vim.api.nvim_buf_call(bufnr, function()
				vim.cmd("checktime")
			end)
		end
	end
	if config.values.after_update_hook then
		config.values.after_update_hook()
	end
end

--- Spawn an Aider terminal session with optional file paths
---@param paths string|nil Optional paths to load into the Aider session
---Initializes a new terminal if one doesn't exist and opens the Aider window
function M.spawn(paths)
	if not M.term then
		local cmd = M.aider_command(paths)
		M.term = M.create_aider_terminal(cmd)
	end
	M.toggle_aider_window()
	M.toggle_aider_window()
end

--- Toggle Aider window
---@param size? number
---@param direction? string
function M.toggle_aider_window(size, direction)
	if not M.term then
		if size then
			M.size = size
		end
		if direction then
			M.direction = direction
		end
		M.load_aider()
		return
	end

	if M.term:is_open() then
		if direction and direction ~= M.term.direction then
			M.term:close()
		end
	end

	M.term:toggle(size, direction)
end

--- Send a command to the active Aider terminal session
--- If no terminal is currently open, it will first create a new terminal
---
--- @param command string The command to send to the Aider session
--- @usage
--- -- Send a simple command
--- M.send_command_to_aider("/help")
---
--- -- Send a multi-line command
--- M.send_command_to_aider("Some complex\nmulti-line command")
function M.send_command_to_aider(command)
	if not M.term then
		M.load_aider()
	end
	local multi_line_command = string.format("{EOF\n%s\nEOF}", command)
	M.term:send(multi_line_command)
end

--- Send an AI query to the Aider session
--- @param prompt string The query or instruction to send
--- @param selection string? Optional selected text to include with the prompt
--- Sends a command to the Aider terminal to process an AI request
--- If no prompt is provided, a warning notification is shown
function M.ask_aider(prompt, selection)
	if not prompt or #vim.trim(prompt) == 0 then
		vim.notify("No input provided", vim.log.levels.WARN)
		return
	end

	local command
	if selection then
		prompt = string.format("%s\n%s", prompt, selection)
	end

	command = "/ask " .. prompt
	M.send_command_to_aider(command)

	if not M.term:is_open() then
		M.term:open()
	end
end

return M
