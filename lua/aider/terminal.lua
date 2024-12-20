local Terminal = require("toggleterm.terminal").Terminal
local config = require("aider").config
local utils = require("aider.utils")
local notify = require("aider.notify")

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

--- Get or generate a terminal object for Aider
---@return Terminal
function Aider.terminal()
	local cwd = utils.cwd()
	if Aider.__term[cwd] then
		return Aider.__term[cwd]
	end
	local term = Terminal:new({
		cmd = Aider.command(),
		hidden = true,
		float_opts = config.float_opts,
		display_name = "Aider.nvim",
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
	local term = Aider.terminal()

	if #files > 0 then
		local add_paths = "/add " .. table.concat(files, " ")
		term:send(add_paths)
	end

	if not config.watch_files then
		term:open(config.toggleterm.size(term), config.toggleterm.direction)
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

function Aider.command()
	local env_args = vim.env.AIDER_ARGS or ""
	local dark_mode = Aider.dark_mode() and " --dark-mode" or ""

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
