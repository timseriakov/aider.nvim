local path = require("fzf-lua.path")
local config = require("aider.config")

local M = {
	buf = nil,
	job_id = nil,
}

---Create or reuse a window based on config
---@param bufnr number|nil Buffer to display in the window
---@return number Window handle
local function create_window(bufnr)
	local window = config.values.window
	local width = window.width > 1 and window.width or math.floor(vim.o.columns * window.width)
	local height = window.height > 1 and window.height or math.floor(vim.o.lines * window.height)

	if window.layout == "float" then
		local win_opts = {
			relative = window.relative,
			width = width,
			height = height,
			row = window.row or math.floor((vim.o.lines - height) / 2),
			col = window.col or math.floor((vim.o.columns - width) / 2),
			border = window.border,
			title = window.title,
			title_pos = window.title_pos,
			style = "minimal",
		}
		if not bufnr then
			vim.api.nvim_command("new")
			bufnr = vim.api.nvim_get_current_buf()
		end
		local winnr = vim.api.nvim_open_win(bufnr, true, win_opts)
		for k, v in pairs(window.opts) do
			vim.api.nvim_set_option_value(k, v, { win = winnr })
		end
		return winnr
	elseif window.layout == "vertical" then
		local cmd = width == 0 and "vnew" or width .. "vnew"
		vim.api.nvim_command(cmd)
		if bufnr then
			vim.api.nvim_win_set_buf(0, bufnr)
		end
		return vim.api.nvim_get_current_win()
	elseif window.layout == "horizontal" then
		local cmd = height == 0 and "new" or height .. "new"
		vim.api.nvim_command(cmd)
		if bufnr then
			vim.api.nvim_win_set_buf(0, bufnr)
		end
		return vim.api.nvim_get_current_win()
	else -- current
		vim.api.nvim_command("enew")
		if bufnr then
			vim.api.nvim_win_set_buf(0, bufnr)
		end
		return vim.api.nvim_get_current_win()
	end
end

---Load files into aider session
---@param selected table Selected files or paths
---@param opts table|nil Additional options
function M.load_in_aider(selected, opts)
	local cleaned_paths = {}
	for _, entry in ipairs(selected) do
		local file_info = path.entry_to_file(entry, opts)
		table.insert(cleaned_paths, file_info.path)
	end
	local paths = table.concat(cleaned_paths, " ")

	if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
		local paths_to_add = "/add " .. paths
		vim.fn.chansend(M.job_id, paths_to_add .. "\n")
		vim.api.nvim_input("A")
		return
	end

	local env_args = vim.env.AIDER_ARGS or ""
	local dark_mode = vim.o.background == "dark" and " --dark-mode" or ""
	local command = string.format("aider %s %s%s %s", env_args, config.values.aider_args, dark_mode, paths)

	create_window()
	M.job_id = vim.fn.termopen(command, {
		on_exit = function()
			vim.cmd("bd!")
		end,
	})
	M.buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_input("A")
end

---Toggle the aider terminal window
function M.toggle()
	if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
		local wins = vim.fn.win_findbuf(M.buf)

		if #wins > 0 then
			for _, win in ipairs(wins) do
				vim.api.nvim_win_close(win, false)
			end
		else
			create_window(M.buf)
			vim.api.nvim_input("A")
		end
	else
		M.load_in_aider({})
	end
end

---Send a question to aider
---@param prompt string The question to ask
---@param selection string|nil Optional code selection
function M.ask(prompt, selection)
	if not prompt or #vim.trim(prompt) == 0 then
		vim.notify("No input provided", vim.log.levels.WARN)
		return
	end

	local filetype = vim.bo.filetype
	local command
	if selection then
		command = string.format("{%s\n/ask %s%s\n%s}", filetype, prompt, selection, filetype)
	else
		command = string.format("{%s\n/ask %s\n%s}", filetype, prompt, filetype)
	end

	M.load_in_aider({})
	vim.fn.chansend(M.job_id, command .. "\n")
end

return M
