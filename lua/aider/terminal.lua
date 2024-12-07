local Terminal = require("toggleterm.terminal").Terminal
local path = require("fzf-lua.path")
local config = require("aider.config")

local M = {
	term = nil,
	prev_buf = nil,
}

-- Create Aider terminal instance
local function create_aider_terminal(cmd)
	return Terminal:new({
		cmd = cmd,
		hidden = true,
		float_opts = config.values.toggleterm.float_opts,
		display_name = "Aider.nvim",
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
			M.term:send(add_paths)
			return
		end
	end

	local command = M.aider_command(paths)

	M.prev_buf = vim.api.nvim_get_current_buf()
	M.term = create_aider_terminal(command)

	M.term:open(M.size, M.direction)
end

function M.aider_command(paths)
	local env_args = vim.env.AIDER_ARGS or ""
	local dark_mode = vim.o.background == "dark" and " --dark-mode" or ""
	local command = string.format("aider %s %s %s ", env_args, config.values.aider_args, dark_mode)
	if paths then
		command = command .. paths
	end
	return command
end

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
		M.prev_buf = vim.api.nvim_get_current_buf()
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
