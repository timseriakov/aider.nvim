local Terminal = require("toggleterm.terminal").Terminal
local path = require("fzf-lua.path")
local config = require("aider.config")

local M = {
	term = nil,
}

--- Create a persistent notification with incremental updates
---
--- This function manages a notification that can be updated incrementally,
--- tracking and displaying only new content since the last update.
---
--- @param title string The title of the notification
--- @param id string|number A unique identifier for the notification
--- @return table A table with methods to add text and clear the notification
--- Create a persistent notification with incremental updates
---
--- This function manages a notification that can be updated incrementally,
--- tracking and displaying only new content since the last update.
---
--- @param title string The title of the notification
--- @param id string|number A unique identifier for the notification
--- @return table A table with methods to add text and clear the notification
local function create_persistent_notification(title, id)
	local last_content_length = 0 -- Track the length of previously shown content
	-- Function to append new text to the notification
	local function add_text(data)
		-- If we're getting the full history each time, we need to slice only the new content
		local new_content = {}
		for i = last_content_length + 1, #data do
			local clean_line = data[i]
			if clean_line ~= "" then
				table.insert(new_content, clean_line)
			end
		end

		-- Update our tracker for next time
		last_content_length = #data

		-- Only notify if we have new content
		if #new_content > 0 then
			vim.notify(table.concat(new_content, "\n"), vim.log.levels.INFO, {
				id = id,
				title = title,
				replace = id,
			})
		end
	end

	local function clear()
		last_content_length = 0
		vim.notify("Done!", vim.log.levels.INFO, {
			id = id,
			title = title,
			replace = id,
		})
	end

	return {
		add_text = add_text,
		clear = clear,
	}
end

local function clean_output(line)
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
local function create_aider_terminal(cmd)
	local notification = create_persistent_notification("Aider.nvim", "aider")
	local buffer = {}
	--- Controls whether terminal output is displayed as persistent notifications
	--- When set to true, terminal output will be captured and shown in notifications
	--- When set to false, terminal output will not trigger notifications
	local use_notifications = config.values.use_notifications

	return Terminal:new({
		cmd = cmd,
		hidden = true,
		float_opts = config.values.float_opts,
		display_name = "Aider.nvim",
		close_on_exit = true,
		auto_scroll = true,
		on_stdout = function(term, job, data, name)
			if term:is_focused() then
				return
			end
			for _, line in ipairs(data) do
				-- add an if statement to check if the line contains a string "(Y)es/(N)o" ai!
				term:focus()
			end
			if use_notifications then
				for _, line in ipairs(data) do
					local clean_line = clean_output(line)
					if clean_line ~= "" then
						table.insert(buffer, clean_line)
					end
				end
				notification.add_text(buffer)
			end
		end,
		on_exit = function()
			M.term = nil
			notification.clear()
		end,
	})
end

---Load files into aider session
---@param selected table Selected files or paths
---@param opts table|nil Additional options
function M.laod_files_in_aider(selected, opts)
	local paths = ""
	if selected then
		local cleaned_paths = {}
		for _, entry in ipairs(selected) do
			local file_info = path.entry_to_file(entry, opts)
			table.insert(cleaned_paths, file_info.path)
		end
		paths = table.concat(cleaned_paths, " ")

		if M.term and M.term:is_open() then
			local add_paths = "/add " .. paths
			vim.notify("Running: " .. add_paths)
			M.term:send(add_paths)
			return
		end
	end

	local command = M.aider_command(paths)
	vim.notify("Running: " .. command)

	M.term = create_aider_terminal(command)

	M.term:open(M.size, M.direction)
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
		M.term = create_aider_terminal(cmd)
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
		M.laod_files_in_aider({})
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
		M.laod_files_in_aider({})
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
