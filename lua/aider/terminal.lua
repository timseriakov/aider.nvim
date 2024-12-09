local Terminal = require("toggleterm.terminal").Terminal
local config = require("aider")

local M = {
	term = nil,
}

--- Create a persistent notification with incremental updates
---
--- This function manages a notification that can be updated incrementally,
--- tracking and displaying only new content since the last update.
function M.create_persistent_notification(title, id)
	local last_content_length = 0
	local is_suppressed = false

	local function add_text(data, display)
		-- Don't process if notifications are suppressed
		if is_suppressed then
			return {}
		end

		local new_content = {}
		for i = last_content_length + 1, #data do
			local clean_line = data[i]
			if clean_line ~= "" then
				table.insert(new_content, clean_line)
			end
		end

		last_content_length = #data

		-- Check for Yes/No prompt before sending notification
		local has_prompt = table.concat(new_content, "\n"):match("%(Y%)es/%(N%)o")

		-- Only notify if we have new content, display is true, and no prompt
		if display and #new_content > 0 and not has_prompt then
			vim.notify(table.concat(new_content, "\n"), vim.log.levels.INFO, {
				id = id,
				title = title,
				replace = id,
			})
		end

		return new_content
	end

	-- Add methods to control notification suppression
	return {
		add_text = add_text,
		suppress = function()
			is_suppressed = true
		end,
		resume = function()
			is_suppressed = false
		end,
	}
end

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
	local notification_handler = M.create_persistent_notification("Aider.nvim", "aider")
	local buffer = {}

	local terminal = Terminal:new({
		cmd = cmd,
		hidden = true,
		float_opts = config.values.float_opts,
		display_name = "Aider.nvim",
		close_on_exit = true,
		auto_scroll = true,
		on_exit = function()
			M.term = nil
		end,
		on_open = function()
			notification_handler.suppress()
		end,
		on_close = function()
			notification_handler.resume()
		end,
	})

	terminal.on_stdout = function(term, _, data, _)
		for _, line in ipairs(data) do
			local clean_line = clean_output(line)
			if clean_line ~= "" then
				table.insert(buffer, clean_line)
			end
		end

		local new_content = notification_handler.add_text(buffer, not term:is_focused())

		-- Focus terminal immediately if we detect a prompt
		if table.concat(new_content, "\n"):match("%(Y%)es/%(N%)o") then
			terminal:focus()
		end
	end

	return terminal
end

---Load files into aider session
---@param selected table Selected files or paths
---@param opts table|nil Additional options
function M.load_files_in_aider(selected, opts)
	local use_fzf, fzf_path = pcall(require, "fzf-lua.path")

	local paths = ""
	if selected then
		local cleaned_paths = {}
		for _, entry in ipairs(selected) do
			local file_info = entry
			if use_fzf then
				file_info = fzf_path.entry_to_file(entry, opts)
			end
			table.insert(cleaned_paths, file_info.path)
		end
		paths = table.concat(cleaned_paths, " ")

		if M.term then
			local add_paths = "/add " .. paths
			vim.notify("Running: " .. add_paths)
			M.term:send(add_paths)
			return
		end
	end

	local command = M.aider_command(paths)
	vim.notify("Running: " .. command)

	M.term = M.create_aider_terminal(command)

	if not config.values.watch_files then
		M.term:open(M.size, M.direction)
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
		M.load_files_in_aider({})
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
		M.load_files_in_aider({})
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
end

return M
