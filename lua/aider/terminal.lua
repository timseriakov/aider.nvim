local Terminal = require("toggleterm.terminal").Terminal
local path = require("fzf-lua.path")
local config = require("aider.config")

local M = {
	term = nil,
}

--- Create a new terminal instance for Aider
--- @param cmd string The command to run in the terminal
--- @return table A new Terminal instance configured for Aider
local function create_aider_terminal(cmd)
	return Terminal:new({
		cmd = cmd,
		hidden = true,
		float_opts = config.values.toggleterm.float_opts,
		display_name = "Aider.nvim",
		close_on_exit = true,
		on_exit = function()
			M.term = nil
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

--- Generate the command to launch aider with appropriate arguments
---@param paths string|nil Optional paths to load into the aider session
---@return string The full aider command with environment and configuration arguments
function M.aider_command(paths)
	local env_args = vim.env.AIDER_ARGS or ""
	local dark_mode = vim.o.background == "dark" and " --dark-mode" or ""
  -- stylua: ignore
	local hook_command = '/bin/bash -c "nvim --server $NVIM --remote-send \"<C-\\\\><C-n>:lua AiderUpdateHook()<CR>\""'
	local command = string.format(
		"aider %s %s %s %s",
		env_args,
		config.values.aider_args,
		dark_mode,
		"--test-cmd " .. "'" .. hook_command .. "'"
	)
	if paths then
		command = command .. paths
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

	-- if opts.update_hook_cmd then
	-- 	local current_buf = vim.api.nvim_get_current_buf()
	-- 	vim.api.nvim_buf_call(current_buf, function()
	-- 		vim.cmd(opts.update_hook_cmd)
	-- 	end)
	-- end
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

-- add docs to this command  ai!
function M.send_command_to_aider(command)
	if not M.term then
		M.laod_files_in_aider({})
	end
	local multi_line_command = string.format("{EOF\n%s\nEOF}", command)
	M.term:send(multi_line_command)
end

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
