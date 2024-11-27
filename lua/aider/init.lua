local path = require("fzf-lua.path")

local M = {
	buf = nil,
	job_id = nil,
	config = {},
}

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

	-- TODO close session if args don't match previous
	local aider_args = opts and opts.aider_args or ""
	local command = "aider " .. aider_args .. " " .. paths
	vim.api.nvim_command("vnew")
	M.job_id = vim.fn.termopen(command, {
		on_exit = function()
			vim.cmd("bd!")
		end,
	})
	M.buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_input("A")
end

function M.toggle_aider()
	if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
		-- Get list of windows containing the aider buffer
		local wins = vim.fn.win_findbuf(M.buf)

		if #wins > 0 then
			-- Buffer is visible, close all windows containing it
			for _, win in ipairs(wins) do
				vim.api.nvim_win_close(win, false)
			end
		else
			-- Buffer isn't visible, show it in a vertical split
			vim.cmd("vnew")
			vim.api.nvim_win_set_buf(0, M.buf)
			vim.api.nvim_input("A")
		end
	else
		M.load_in_aider({})
	end
end

-- Kudos to to codecompanion.nvim for this function
function M.get_visual_selection(bufnr)
	local api = vim.api
	local esc_feedkey = api.nvim_replace_termcodes("<ESC>", true, false, true)
	bufnr = bufnr or 0

	api.nvim_feedkeys(esc_feedkey, "n", true)
	api.nvim_feedkeys("gv", "x", false)
	api.nvim_feedkeys(esc_feedkey, "n", true)

	local end_line, end_col = unpack(api.nvim_buf_get_mark(bufnr, ">"))
	local start_line, start_col = unpack(api.nvim_buf_get_mark(bufnr, "<"))
	local lines = api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)

	-- get whole buffer if there is no current/previous visual selection
	if start_line == 0 then
		lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
		start_line = 1
		start_col = 0
		end_line = #lines
		end_col = #lines[#lines]
	end

	-- use 1-based indexing and handle selections made in visual line mode (see :help getpos)
	start_col = start_col + 1
	end_col = math.min(end_col, #lines[#lines] - 1) + 1

	-- shorten first/last line according to start_col/end_col
	lines[#lines] = lines[#lines]:sub(1, end_col)
	lines[1] = lines[1]:sub(start_col)

	return lines, start_line, start_col, end_line, end_col
end

function M.ask()
	-- Save the current mode
	local mode = vim.fn.mode()
	local is_visual = mode == "v" or mode == "V"

	vim.schedule(function()
		vim.ui.input({ prompt = "Prompt: " }, function(input)
			if input and #vim.trim(input) > 0 then
				local command
				local filetype = vim.bo.filetype
				if is_visual then
					local selection = M.get_visual_selection()
					local selection_text = table.concat(selection, "\n")
					command = "{" .. filetype .. "\n" .. "/ask " .. input .. selection_text .. "\n" .. filetype .. "}"
				else
					command = "{" .. filetype .. "\n" .. "/ask " .. input .. "\n" .. filetype .. "}"
				end
				M.load_in_aider({})
				vim.fn.chansend(M.job_id, command .. "\n")
			else
				vim.notify("No input provided")
			end
		end)
	end)
end

-- Setup function to create commands
function M.setup(opts)
	opts = opts or {}

	-- Setup fzf-lua integration if it's available
	local ok, fzf_config = pcall(require, "fzf-lua.config")
	if ok then
		fzf_config.defaults.files.actions["ctrl-l"] = M.load_in_aider
	end

	-- Create commands for aider functionality
	vim.api.nvim_create_user_command("AiderToggle", function()
		M.toggle_aider()
	end, {
		desc = "Toggle Aider window",
	})

	vim.api.nvim_create_user_command("AiderLoad", function(opts)
		local files = opts.fargs
		if #files == 0 then
			files = { vim.api.nvim_buf_get_name(0) }
		end
		M.load_in_aider(files)
	end, {
		nargs = "*",
		desc = "Load files into Aider",
		complete = "file",
	})

	-- Create a command that can be called from visual mode
	vim.api.nvim_create_user_command("AiderAsk", function()
		M.ask()
	end, {
		range = true,
		desc = "Ask with visual selection",
	})
end

return M
