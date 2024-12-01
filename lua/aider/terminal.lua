local path = require("fzf-lua.path")
local config = require("aider.config")

local M = {
	buf = nil,
	job_id = nil,
	prev_buf = nil,
	is_visible = false,
}

---@param bufnr number|nil Buffer to display in the window
---@return number Window handle
local function create_or_reuse_window(bufnr)
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
		vim.api.nvim_set_option_value("number", false, { buf = bufnr })
		return vim.api.nvim_get_current_win()
	end
end

---Load files into aider session
---@param selected table Selected files or paths
---@param opts table|nil Additional options
function M.laod_files_in_aider(selected, opts)
	local cleaned_paths = {}
	for _, entry in ipairs(selected) do
		local file_info = path.entry_to_file(entry, opts)
		table.insert(cleaned_paths, file_info.path)
	end
	local paths = table.concat(cleaned_paths, " ")

	if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
		local add_paths = "/add " .. paths
		vim.fn.chansend(M.job_id, add_paths .. "\n")
		M.show_aider()
		vim.api.nvim_input("A")
		return
	end

	local env_args = vim.env.AIDER_ARGS or ""
	local dark_mode = vim.o.background == "dark" and " --dark-mode" or ""
	local command = string.format("aider %s %s%s %s", env_args, config.values.aider_args, dark_mode, paths)

	M.prev_buf = vim.api.nvim_get_current_buf()
	create_or_reuse_window()
	M.is_visible = true
	M.job_id = vim.fn.termopen(command, {
		on_exit = function()
			vim.cmd("bd!")
		end,
	})
	M.buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_input("A")
end

function M.show_aider()
	vim.api.nvim_set_current_buf(M.buf)
	vim.api.nvim_input("A")
	M.is_visible = true
end

---Toggle the aider terminal window
function M.toggle_aider_window()
	if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
		-- First time opening, create new aider session
		M.prev_buf = vim.api.nvim_get_current_buf()
		M.laod_files_in_aider({})
		M.is_visible = true
		return
	end

	if M.is_visible then
		-- Hide aider by switching to previous buffer
		if M.prev_buf and vim.api.nvim_buf_is_valid(M.prev_buf) then
			vim.api.nvim_set_current_buf(M.prev_buf)
		else
			-- If previous buffer is invalid, create a new buffer
			vim.cmd("enew")
			M.prev_buf = vim.api.nvim_get_current_buf()
		end
		M.is_visible = false
	else
		-- Show aider by switching to its buffer
		M.show_aider()
	end
end

---Send a question to aider
---@param prompt string The question to ask
---@param selection string|nil Optional code selection
function M.ask_aider(prompt, selection)
	if not prompt or #vim.trim(prompt) == 0 then
		vim.notify("No input provided", vim.log.levels.WARN)
		return
	end

	local command
	if selection then
		prompt = string.format("%s\n%s}", prompt, selection)
	end

	command = "/ask " .. prompt
	M.send_command_to_aider(command)
end

--- Send command to aider
---@param command string
function M.send_command_to_aider(command)
	local ft = vim.bo.filetype
	command = string.format("{%s\n%s\n%s}", ft, command, ft)
	M.laod_files_in_aider({})
	vim.fn.chansend(M.job_id, command .. "\n")
end

-- Quit terminal buffer on Vim exit
vim.api.nvim_create_autocmd("QuitPre", {
	callback = function()
		if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
			vim.api.nvim_buf_delete(M.buf, { force = true })
			vim.schedule(function()
				vim.cmd("quit")
			end)
		end
	end,
})

return M
