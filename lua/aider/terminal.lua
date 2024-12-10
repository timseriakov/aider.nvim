local Terminal = require("toggleterm.terminal").Terminal
local config = require("aider").config

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

local M = {
	__term = nil,
}

--- @return Terminal A configured terminal object ready to be used
function M.aider_terminal()
	if M.__term then
		return M.__term
	end
	M.__term = Terminal:new({
		cmd = M.aider_command(),
		hidden = true,
		float_opts = config.float_opts,
		display_name = "Aider.nvim",
		close_on_exit = true,
		auto_scroll = true,
		direction = config.toggleterm.direction,
		size = config.toggleterm.size,
		on_exit = function()
			M.__term = nil
		end,
		on_open = function()
			if config.auto_insert then
				M.__term:set_mode("i")
			end
		end,
		on_stdout = function(term, _, data, _)
			for _, line in ipairs(data) do
				if term:is_open() then
					return
				end

				if line:match("%(Y%)es/%(N%)o") then
					term:open()
					return
				end

				local msg = clean_output(line)
				if #msg > 0 then
					local id = "aider"
					config.notify(msg, vim.log.levels.INFO, {
						title = "Aider.nvim",
						id = id,
						replace = id,
					})
				end
			end
		end,
	})

	return M.__term
end

---Load files into aider session
---@param files table|nil Files or path
function M.load_files(files)
	files = files or {}
	local term = M.aider_terminal()

	if #files > 0 then
		local add_paths = "/add " .. table.concat(files, " ")
		term:send(add_paths)
	end

	if not config.watch_files then
		term:open(config.toggleterm.size(term), config.toggleterm.direction)
	end
end

function M.aider_command()
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

function M.spawn()
	local term = M.aider_terminal()
	term:spawn()
end

---@param size? number
---@param direction? string
function M.toggle_aider_window(size, direction)
	local term = M.aider_terminal()
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
--- @usage
--- -- Send a simple command
--- M.send_command_to_aider("/help")
---
--- -- Send a multi-line command
--- M.send_command_to_aider("Some complex\nmulti-line command")
function M.send_command_to_aider(command)
	local term = M.aider_terminal()
	local multi_line_command = string.format("{EOF\n%s\nEOF}", command)
	term:send(multi_line_command)
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

	local term = M.aider_terminal()
	if not term:is_open() then
		term:open()
	end
end

return M
